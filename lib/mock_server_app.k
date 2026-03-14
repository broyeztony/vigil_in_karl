let Json = (import "./http_json.k")()
let MockState = (import "./mock_state.k")()
let MockEmails = (import "./mock_emails.k")()
let Admin = (import "./mock_admin.k")()

let start = cfg -> {
    let state = MockState.build(cfg)
    let srv = httpServe({
        addr: cfg.mock_addr,
        routes: [
            { method: "GET", path: "/health", handler: req -> Json.ok({ status: "ok", }), },
            { method: "GET", path: "/users", handler: req -> Json.ok(state.users), },
            {
                method: "GET",
                path: "/emails",
                handler: req -> {
                    let user_id = trim(req.query.user_id) ? ""
                    let since = trim(req.query.received_after) ? ""
                    if user_id == "" || !has(state.byId, user_id) { Json.bad("unknown user_id") }
                    else { Json.ok(MockEmails.list(cfg, user_id, since)) }
                },
            },
            { method: "POST", path: "/admin/users/set", handler: req -> Admin.setUsers(state, req, Json, MockState), },
            { method: "POST", path: "/admin/users/add", handler: req -> Admin.addUsers(state, req, Json, MockState), },
            { method: "GET", path: "/admin/state", handler: req -> Json.ok({ users: state.users.length, }), },
        ],
    })
    { server: srv, state: state, }
}

let stop = app -> httpServerStop(app.server)
