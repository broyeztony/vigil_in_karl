let Config = (import "../lib/config.k")()
let Discovery = (import "../lib/discovery_app.k")()
let DbCore = (import "../lib/db_core.k")()

let cfg = Config.get()
let app = Discovery.start(cfg)
sleep(3000)
Discovery.stop(app)

let db = DbCore.open(cfg)
let users = DbCore.one(db, "SELECT COUNT(*) AS n FROM users", [], "count users")
let emails = DbCore.one(db, "SELECT COUNT(*) AS n FROM emails", [], "count emails")
DbCore.close(db)

if users.n < 1 { fail("expected users in DB") }
if emails.n < 1 { fail("expected emails in DB") }

log({ discovery_smoke: "ok", users: users.n, emails: emails.n, })
