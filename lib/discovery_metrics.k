let DbCore = (import "./db_core.k")()

let sample = state ->
    DbCore.one(
        state.db,
        "SELECT (SELECT COUNT(*) FROM users) AS users, (SELECT COUNT(*) FROM emails) AS emails, (SELECT COUNT(*) FROM user_emails) AS links",
        [],
        "metrics sample"
    )

let start = state -> {
    if state.cfg.metrics_log_ms <= 0 { state.metrics_task = null }
    else {
        state.metrics_task = spawn (() -> {
            for state.running.get("on") with _ = 0 {
                let row = sample(state) ? {
                    log("metrics error", error.message)
                    null
                }
                if row != null { log("metrics", row) }
                sleep(state.cfg.metrics_log_ms)
            } then ()
        })()
    }
}

let stop = state -> {
    if state.metrics_task != null {
        state.metrics_task.cancel()
        (wait state.metrics_task) ? {}
    }
}
