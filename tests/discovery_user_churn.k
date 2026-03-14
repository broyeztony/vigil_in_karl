let Config = (import "../lib/config.k")()
let MockServer = (import "../lib/mock_server_app.k")()
let Discovery = (import "../lib/discovery_app.k")()
let DbCore = (import "../lib/db_core.k")()

let cfg = Config.get()
cfg.mock_addr = ":18082"
cfg.provider_api_url = "http://127.0.0.1:18082"
cfg.mock_initial_users = 10
cfg.user_sync_ms = 600
cfg.email_poll_ms = 600

let db0 = DbCore.open(cfg)
DbCore.exec(db0, "TRUNCATE user_emails, emails, users CASCADE", [], "reset tables")
DbCore.close(db0)

let mock = MockServer.start(cfg)
let app = Discovery.start(cfg)
sleep(1500)
http({ method: "POST", url: "http://127.0.0.1:18082/admin/users/set?num_users=4", })
sleep(2000)
Discovery.stop(app)
MockServer.stop(mock)

let db = DbCore.open(cfg)
let users = DbCore.one(db, "SELECT COUNT(*) AS n FROM users", [], "count users")
DbCore.close(db)

if users.n != 4 { fail("expected user count 4") }
log({ churn_smoke: "ok", users: users.n, })
