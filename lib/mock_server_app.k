let Json = (import "./http_json.k")()
let MockUsers = (import "./mock_users.k")()
let MockEmails = (import "./mock_emails.k")()

let start = cfg -> {
    let users = MockUsers.seed(cfg.mock_initial_users)
    let byId = users.reduce((acc, u) -> set(acc, u.id, u), map())

    let srv = httpServe({
        addr: cfg.mock_addr,
        routes: [
            { method: "GET", path: "/health", handler: req -> Json.ok({ status: "ok", }), },
            { method: "GET", path: "/users", handler: req -> Json.ok(users), },
            {
                method: "GET",
                path: "/emails",
                handler: req -> {
                    let user_id = trim(req.query.user_id) ? ""
                    let since = trim(req.query.received_after) ? ""
                    if user_id == "" || !has(byId, user_id) { Json.bad("unknown user_id") }
                    else { Json.ok(MockEmails.list(cfg, user_id, since)) }
                },
            },
            { method: "GET", path: "/admin/state", handler: req -> Json.ok({ users: users.length, }), },
        ],
    })

    { server: srv, users: users, }
}

let stop = app -> httpServerStop(app.server)

{ start, stop, }
