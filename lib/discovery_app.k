let makeDB = import "./db.k"
let DB = makeDB()

let makeProvider = import "./provider_client.k"
let Provider = makeProvider()

let minSleep = ms -> if ms < 1 { 1 } else { ms }

let cursorMs = (user, cfg) -> {
    if user == null {
        now() - cfg.initial_lookback_ms
    } else if user.last_email_received != null {
        user.last_email_received - 1000
    } else if user.last_email_check != null {
        user.last_email_check - 1000
    } else {
        now() - cfg.initial_lookback_ms
    }
}

let pollUserOnce = (state, user) -> {
    let fresh = DB.getUserById(state.db, user.id) ? { user }
    let from_ms = cursorMs(fresh, state.cfg)
    let received_after = timeFormatRFC3339(if from_ms < 0 { 0 } else { from_ms })

    let emails = Provider.getEmails(state.cfg, user.id, received_after, "received_at") ? {
        log("provider.getEmails error", { user_id: user.id, message: error.message, })
        let fallback = []
        fallback
    }

    DB.setLastEmailCheck(state.db, user.id, timeFormatRFC3339(now())) ? {
        log("setLastEmailCheck error", { user_id: user.id, message: error.message, })
    }

    for i < emails.length with i = 0 {
        let sent = state.queue.send({ user_id: user.id, email: emails[i], }) ? { null }
        if sent == null { return }
        i++
    } then ()
}

let runUserPoller = (state, user, jitter_ms) -> {
    if jitter_ms > 0 { sleep(jitter_ms) }
    let poll_ms = minSleep(state.cfg.email_poll_ms)
    for true with running = true {
        pollUserOnce(state, user)
        sleep(poll_ms)
    } then ()
}

let stopUserWorker = (state, user_id) -> {
    let worker = get(state.active, user_id)
    if worker != null {
        worker.cancel()
        (wait worker) ? {}
        delete(state.active, user_id)
    }
}

let stopAllWorkers = state -> {
    let ids = keys(state.active)
    for i < ids.length with i = 0 {
        stopUserWorker(state, ids[i])
        i++
    } then ()
}

let syncUsers = state -> {
    let users = Provider.getUsers(state.cfg, state.cfg.tenant_id) ? {
        log("provider.getUsers error", error.message)
        let fallback = []
        fallback
    }
    let seen = map()

    for i < users.length with i = 0 {
        let user = users[i]
        set(seen, user.id, true)
        DB.upsertUser(state.db, user) ? {
            log("upsertUser error", { user_id: user.id, message: error.message, })
        }

        if !has(state.active, user.id) {
            let jitter_ms = if state.cfg.email_jitter_ms < 1 { 0 } else { randInt(0, state.cfg.email_jitter_ms) }
            set(state.active, user.id, & runUserPoller(state, user, jitter_ms))
        }
        i++
    } then ()

    let ids = keys(state.active)
    for i < ids.length with i = 0 {
        let user_id = ids[i]
        if !has(seen, user_id) { stopUserWorker(state, user_id) }
        i++
    } then ()
}

let userDiscoveryLoop = state -> {
    let poll_ms = minSleep(state.cfg.user_poll_ms)
    syncUsers(state)
    for true with running = true {
        sleep(poll_ms)
        syncUsers(state)
    } then ()
}

let processLoop = state -> {
    for true with running = true {
        let [msg, done] = state.queue.recv()
        if done { break }

        let saved = DB.storeDiscoveredEmail(state.db, msg.email, msg.user_id) ? {
            log("storeDiscoveredEmail error", { user_id: msg.user_id, message: error.message, })
            null
        }
        if saved != null && saved.is_new {
            state.stats.discovered = state.stats.discovered + 1
            state.stats.queued = state.stats.queued + 1
        }
    } then ()
}

let metricsLoop = state -> {
    let every_ms = minSleep(state.cfg.metrics_ms)
    for true with running = true {
        sleep(every_ms)
        log("metrics", {
            users: keys(state.active).length,
            discovered: state.stats.discovered,
            queued: state.stats.queued,
        })
    } then ()
}

let setup = cfg -> {
    let db = DB.open(cfg.database_url) ? { fail("db open failed: " + error.message) }
    DB.setup(db, cfg.tenant_id) ? {
        DB.close(db) ? {}
        fail("db setup failed: " + error.message)
    }
    DB.close(db) ? { fail("db close failed: " + error.message) }
    { tenant_id: cfg.tenant_id, database_url: cfg.database_url, }
}

let run = cfg -> {
    let db = DB.open(cfg.database_url) ? { fail("db open failed: " + error.message) }
    let state = {
        cfg: cfg,
        db: db,
        queue: rendezvous(),
        active: map(),
        stats: { discovered: 0, queued: 0, },
    }

    let processor = & processLoop(state)
    let user_discovery = & userDiscoveryLoop(state)
    let metrics = & metricsLoop(state)

    let [signal_name, done] = signalWatch(["SIGINT", "SIGTERM"]).recv()
    if !done { log("shutdown", signal_name) }

    user_discovery.cancel()
    metrics.cancel()
    stopAllWorkers(state)
    processor.cancel()

    (wait user_discovery) ? {}
    (wait metrics) ? {}
    (wait processor) ? {}
    DB.close(db) ? { fail("db close failed: " + error.message) }

    {
        users: keys(state.active).length,
        discovered: state.stats.discovered,
        queued: state.stats.queued,
    }
}
