let Config = (import "../lib/config.k")()
let DbCore = (import "../lib/db_core.k")()
let DbSchema = (import "../lib/db_schema.k")()

let cfg = Config.get()
let db = DbCore.open(cfg)
DbSchema.migrate(db)
DbSchema.seedTenant(db, cfg.tenant_id)
DbCore.close(db)

log({ setup: "ok", tenant: cfg.tenant_id, })
