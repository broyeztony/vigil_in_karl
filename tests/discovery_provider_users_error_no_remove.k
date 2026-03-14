let Config = (import "../lib/config.k")()
let MockServer = (import "../lib/mock_server_app.k")()
let Discovery = (import "../lib/discovery_app.k")()
let DbCore = (import "../lib/db_core.k")()

let cfg = Config.get()
cfg.mock_addr = ":18083"
cfg.provider_api_url = "http://127.0.0.1:18083"
cfg.mock_initial_users = 8
cfg.user_sync_ms = 500
cfg.email_poll_ms = 500

let db0 = DbCore.open(cfg)
DbCore.exec(db0, "TRUNCATE user_emails, emails, users CASCADE", [], "reset tables")
DbCore.close(db0)

let mock = MockServer.start(cfg)
let app = Discovery.start(cfg)
sleep(1600)

let db1 = DbCore.open(cfg)
let before = DbCore.one(db1, "SELECT COUNT(*) AS n FROM users", [], "count users before failure")
DbCore.close(db1)
if before.n < 1 { fail("expected users before failure") }

app.cfg.provider_api_url = "http://127.0.0.1:18999"
sleep(1600)

let db2 = DbCore.open(cfg)
let after = DbCore.one(db2, "SELECT COUNT(*) AS n FROM users", [], "count users after failure")
DbCore.close(db2)

Discovery.stop(app)
MockServer.stop(mock)

if after.n != before.n { fail("provider users fetch failure removed users") }
log({ provider_error_no_remove: "ok", users: after.n, })
