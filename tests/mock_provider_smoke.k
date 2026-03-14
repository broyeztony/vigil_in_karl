let Config = (import "../lib/config.k")()
let MockServer = (import "../lib/mock_server_app.k")()

let cfg = Config.get()
let app = MockServer.start(cfg)
let base = "http://127.0.0.1:" + trim(env("PORT"))

let users = fromJson(http({ method: "GET", url: base + "/users", }).body)
if users.length < 1 { fail("expected users") }

let first = users[0]
let q = base + "/emails?user_id=" + first.id + "&received_after="
let emails = fromJson(http({ method: "GET", url: q, }).body)
if emails.length < 1 { fail("expected emails") }

MockServer.stop(app)
log({ mock_smoke: "ok", users: users.length, emails: emails.length, })
