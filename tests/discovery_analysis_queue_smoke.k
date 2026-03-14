let Config = (import "../lib/config.k")()
let MockServer = (import "../lib/mock_server_app.k")()
let Discovery = (import "../lib/discovery_app.k")()
let DbCore = (import "../lib/db_core.k")()

let cfg = Config.get()
cfg.mock_addr = ":18084"
cfg.provider_api_url = "http://127.0.0.1:18084"
cfg.mock_initial_users = 8
cfg.user_sync_ms = 700
cfg.email_poll_ms = 700

let db0 = DbCore.open(cfg)
DbCore.exec(db0, "TRUNCATE user_emails, emails, users CASCADE", [], "reset tables")
DbCore.close(db0)

let mock = MockServer.start(cfg)
let app = Discovery.start(cfg)
sleep(2800)
Discovery.stop(app)
MockServer.stop(mock)

if app.analysis_enqueued < 1 { fail("expected analysis enqueue count") }
log({ analysis_queue_smoke: "ok", enqueued: app.analysis_enqueued, })
