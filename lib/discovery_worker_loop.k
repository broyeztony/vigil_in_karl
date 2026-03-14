let DbUsers = (import "./db_users.k")()
let Provider = (import "./provider_api.k")()

let sinceFor = (state, user_id) -> {
    let u = DbUsers.byId(state.db, user_id)
    if u == null || u.last_email_received == null {
        timeFormatRFC3339(now() - state.cfg.initial_lookback_ms)
    } else { str(u.last_email_received) }
}

let run = (state, user_id, stop) -> {
    for stop.get("on") with _ = 0 {
        let since = sinceFor(state, user_id)
        let rows = Provider.emails(state.cfg, user_id, since) ? {
            log("worker emails error", { user_id: user_id, message: error.message, })
            let fallback = []
            fallback
        }

        rows.forEach(email -> {
            state.queue.send({ user_id: user_id, email: email, })
        })

        sleep(state.cfg.email_poll_ms)
    } then ()
}

{ run, }
