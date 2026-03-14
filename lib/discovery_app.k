let DbCore = (import "./db_core.k")()
let DbSchema = (import "./db_schema.k")()
let Analysis = (import "./discovery_analysis.k")()
let Consumers = (import "./discovery_consumers.k")()
let Reconciler = (import "./discovery_reconciler.k")()
let Workers = (import "./discovery_workers.k")()

let start = cfg -> {
    let db = DbCore.open(cfg)
    DbSchema.migrate(db)
    DbSchema.seedTenant(db, cfg.tenant_id)

    let state = {
        cfg: cfg,
        db: db,
        queue: buffered(cfg.queue_size),
        analysis_queue: buffered(cfg.queue_size),
        active: map(),
        running: map().set("on", true),
        analysis_tasks: [],
        analysis_enqueued: 0,
        consumer_tasks: [],
    }

    Analysis.start(state)
    Consumers.start(state)
    state.reconciler = spawn (() -> {
        for state.running.get("on") with _ = 0 {
            log("sync", Reconciler.run(state))
            sleep(state.cfg.user_sync_ms)
        } then ()
    })()

    state
}

let stop = state -> {
    state.running.set("on", false)
    state.reconciler.cancel()
    (wait state.reconciler) ? {}
    Workers.stopAll(state)
    Consumers.stop(state)
    Analysis.stop(state)
    DbCore.close(state.db)
}
