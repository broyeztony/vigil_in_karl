let parse = (body, label) -> fromJson(body) ? { fail(label + ": decode error") }

let fetch = (url, label) -> {
    let resp = http({ method: "GET", url: url, }) ? { fail(label + " request failed") }
    if resp.status != 200 { fail(label + " status " + str(resp.status) + ": " + resp.body) }
    parse(resp.body, label)
}

let users = (cfg, tenant_id) ->
    fetch(cfg.provider_api_url + "/users?tenant_id=" + tenant_id, "provider users")

let emails = (cfg, user_id, received_after) -> {
    let url = cfg.provider_api_url + "/emails?user_id=" + user_id + "&received_after=" + received_after
    let resp = http({ method: "GET", url: url, }) ? { fail("provider emails request failed") }
    match resp.status {
        case 200 -> parse(resp.body, "provider emails")
        case 400 -> if resp.body.contains("unknown user_id") { [] } else {
            fail("provider emails status 400: " + resp.body)
        }
        case _ -> fail("provider emails status " + str(resp.status) + ": " + resp.body)
    }
}
