let Config = (import "../lib/config.k")()
let MockServer = (import "../lib/mock_server_app.k")()

let cfg = Config.get()
cfg.mock_addr = ":18080"
let app = MockServer.start(cfg)

let users = fromJson(http({ method: "GET", url: "http://127.0.0.1:18080/users", }).body)
if users.length < 1 { fail("expected users") }

let one = users[0]
let url = "http://127.0.0.1:18080/emails?user_id=" + one.id + "&received_after="
let emails = for i < 12 with i = 0, xs = [] {
    xs = fromJson(http({ method: "GET", url: url, }).body)
    if xs.length > 0 { break xs }
    sleep(120)
    i++
} then xs
if emails.length < 1 { fail("expected emails") }

MockServer.stop(app)
log({ mock_smoke: "ok", users: users.length, emails: emails.length, })
