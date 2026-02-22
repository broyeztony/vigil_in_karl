let makeCommon = import "./common.k"
let Common = makeCommon()

let makeMockData = import "./mock_data.k"
let MockData = makeMockData()

let defaultReceivedAfter = () -> timeFormatRFC3339(timeAdd(now(), -24 * 60 * 60 * 1000))

let parseNumUsers = req -> {
    let body = if trim(req.body ? { "" }) == "" { null } else { Common.parseJSON(req.body) }
    let from_body = if body == null { null } else { body.numUsers }
    let from_query = req.query.numUsers
    let raw = if from_body != null { from_body } else { from_query ? { 1 } }
    let n = parseInt(str(raw)) ? { 1 }
    if n < 1 { 1 } else { n }
}

let handleHealth = req -> Common.jsonResponse(200, { status: "ok", })

let handleGetUsers = (state, req) -> {
    let tenant_id = Common.lastPathPart(req.path)
    if !uuidValid(tenant_id) { Common.badRequest("invalid tenant_id") } else { Common.jsonResponse(200, MockData.getUsers(state, tenant_id)) }
}

let handleGetEmails = (state, req) -> {
    let user_id = Common.lastPathPart(req.path)
    if !uuidValid(user_id) { Common.badRequest("invalid user_id") } else {
        let received_after = req.query.receivedAfter ? { defaultReceivedAfter() }
        let received_after_ms = timeParseRFC3339(received_after) ? { now() - 24 * 60 * 60 * 1000 }
        let order_by = req.query.orderBy ? { "received_at" }
        Common.jsonResponse(200, MockData.getEmails(state, user_id, received_after_ms, order_by))
    }
}

let handleAddUsers = (state, req) -> {
    let n = parseNumUsers(req)
    let total = MockData.addUsers(state, n)
    Common.jsonResponse(200, {
        added: n,
        total: total,
        message: "Added " + str(n) + " user(s). Total users: " + str(total),
    })
}

let routes = state -> [
    { method: "GET", path: "/health", handler: req -> handleHealth(req), },
    { method: "GET", path: "/google/users/", handler: req -> handleGetUsers(state, req), },
    { method: "GET", path: "/google/emails/", handler: req -> handleGetEmails(state, req), },
    { method: "POST", path: "/admin/users/add", handler: req -> handleAddUsers(state, req), },
]

let start = cfg -> {
    let state = MockData.new(cfg)
    MockData.seedUsers(state, cfg.mock_initial_users)

    let server = httpServe({ addr: cfg.mock_addr, routes: routes(state), }) ? { fail("mock server start failed: " + error.message) }
    let tick_ms = if cfg.mock_email_tick_ms < 1 { 1 } else { cfg.mock_email_tick_ms }
    let ticker = & (() -> {
        for true with running = true {
            sleep(tick_ms)
            MockData.tick(state, cfg)
        } then ()
    })()

    { server: server, ticker: ticker, state: state, }
}

let stop = app -> {
    app.ticker.cancel()
    (wait app.ticker) ? {}
    httpServerStop(app.server) ? { fail("mock server stop failed: " + error.message) }
}
