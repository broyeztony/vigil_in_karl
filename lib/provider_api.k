let decode = (text, label) -> fromJson(text) ? { fail(label + ": " + error.message) }

let fetch = (url, label) -> {
    let resp = http({ method: "GET", url: url, }) ? { fail(label + " request: " + error.message) }
    if resp.status != 200 { fail(label + " status " + str(resp.status) + ": " + resp.body) }
    decode(resp.body, label)
}

let users = (cfg, tenant_id) ->
    fetch(cfg.provider_api_url + "/users?tenant_id=" + tenant_id, "provider users")

let emails = (cfg, user_id, received_after) ->
    fetch(
        cfg.provider_api_url + "/emails?user_id=" + user_id + "&received_after=" + received_after,
        "provider emails"
    )

{ users, emails, }
