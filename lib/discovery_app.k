let DbCore = (import "./db_core.k")()
let DbSchema = (import "./db_schema.k")()
let DiscoveryCycle = (import "./discovery_cycle.k")()

let start = cfg -> {
    let db = DbCore.open(cfg)
    DbSchema.migrate(db)
    DbSchema.seedTenant(db, cfg.tenant_id)

    let running = map().set("value", true)
    let worker = spawn (() -> {
        for running.get("value") with _ = 0 {
            let out = DiscoveryCycle.sync({ cfg: cfg, db: db, }) ? {
                log("sync error", error.message)
                { users: -1, }
            }
            if out.users >= 0 { log("sync", out) }
            sleep(cfg.user_sync_ms)
        } then ()
    })()

    { cfg: cfg, db: db, running: running, worker: worker, }
}

let stop = app -> {
    app.running.set("value", false)
    app.worker.cancel()
    (wait app.worker) ? {}
    DbCore.close(app.db)
}

{ start, stop, }
