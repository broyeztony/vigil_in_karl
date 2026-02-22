let providerRoot = cfg -> match cfg.provider_type {
    case "microsoft" -> "microsoft"
    case _ -> "google"
}

let usersURL = (cfg, tenant_id) -> cfg.provider_api_url + "/" + providerRoot(cfg) + "/users/" + tenant_id
let emailsURL = (cfg, user_id, received_after, order_by) ->
    cfg.provider_api_url + "/" + providerRoot(cfg) + "/emails/" + user_id + "?receivedAfter=" + received_after + "&orderBy=" + order_by

let decode = (text, label) -> jsonDecode(text) ? { fail(label + ": " + error.message) }

let getUsers = (cfg, tenant_id) -> {
    let resp = http({ method: "GET", url: usersURL(cfg, tenant_id), }) ? { fail("provider users request failed: " + error.message) }
    if resp.status != 200 { fail("provider users status " + str(resp.status) + ": " + resp.body) }
    decode(resp.body, "provider users decode failed")
}

let getEmails = (cfg, user_id, received_after, order_by) -> {
    let resp = http({
        method: "GET",
        url: emailsURL(cfg, user_id, received_after, order_by),
    }) ? { fail("provider emails request failed: " + error.message) }
    if resp.status != 200 { fail("provider emails status " + str(resp.status) + ": " + resp.body) }
    decode(resp.body, "provider emails decode failed")
}
