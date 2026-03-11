let makeDB = import "./db.k"
let DB = makeDB()

let makeProvider = import "./provider_client.k"
let Provider = makeProvider()

let makeAnalysisQueue = import "./analysis_queue.k"
let AnalysisQueue = makeAnalysisQueue()

let minSleep = ms -> if ms < 1 { 1 } else { ms }

let bumpUserDiscovered = (state, user_id) -> {
    let current = get(state.stats.by_user, user_id)
    let next = if current == null { 1 } else { current + 1 }
    set(state.stats.by_user, user_id, next)
}

let topUsers = (state, limit) -> {
    let rows = keys(state.stats.by_user).map(user_id -> {
        let email = get(state.user_emails, user_id)
        let count = get(state.stats.by_user, user_id)
        { user_id: user_id, email: email, count: if count == null { 0 } else { count }, }
    })
    let sorted = rows.sort((a, b) -> b.count - a.count)
    for i < sorted.length && i < limit with i = 0, out = [] {
        out = out + [sorted[i]]
        i++
    } then out
}

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

let sendToAnalysisQueue = (state, msg, saved) -> {
    let ok = AnalysisQueue.enqueue(state.analysis_queue, {
        user_id: msg.user_id,
        email_id: saved.email_id,
        fingerprint: saved.fingerprint,
        subject: msg.email.subject,
        received_at: msg.email.received_at,
    })
    if ok {
        state.stats.queued = state.stats.queued + 1
    } else {
        state.stats.queue_errors = state.stats.queue_errors + 1
    }
}

let pollUserOnce = (state, user) -> {
    let fresh = DB.getUserById(state.db, user.id) ? { user }
    let from_ms = cursorMs(fresh, state.cfg)
    let received_after = timeFormatRFC3339(if from_ms < 0 { 0 } else { from_ms })

    let emails = Provider.getEmails(state.cfg, user.id, received_after, "received_at") ? {
        state.stats.provider_emails_errors = state.stats.provider_emails_errors + 1
        log("provider.getEmails error", { user_id: user.id, message: error.message, })
        let fallback = []
        fallback
    }

    DB.setLastEmailCheck(state.db, user.id, timeFormatRFC3339(now())) ? {
        log("setLastEmailCheck error", { user_id: user.id, message: error.message, })
    }

    for i < emails.length && open with i = 0, open = true {
        let ok = state.queue.send({ user_id: user.id, email: emails[i], }) ? { false }
        if !ok { open = false }
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

let stopUserWorker = (state, user_id, reason) -> {
    let worker = get(state.active, user_id)
    if worker != null {
        worker.cancel()
        (wait worker) ? {}
        delete(state.active, user_id)
        state.stats.workers_stopped = state.stats.workers_stopped + 1
    }
}

let stopAllWorkers = state -> {
    let ids = keys(state.active)
    for i < ids.length with i = 0 {
        stopUserWorker(state, ids[i], "shutdown")
        i++
    } then ()
}

let syncOneUser = (state, seen, user) -> {
    set(seen, user.id, true)
    set(state.user_emails, user.id, user.email)

    DB.upsertUser(state.db, user) ? {
        log("upsertUser error", { user_id: user.id, message: error.message, })
    }

    if !has(state.active, user.id) {
        let jitter_ms = if state.cfg.email_jitter_ms < 1 { 0 } else { randInt(0, state.cfg.email_jitter_ms) }
        set(state.active, user.id, & runUserPoller(state, user, jitter_ms))
        state.stats.users_added = state.stats.users_added + 1
        state.stats.workers_started = state.stats.workers_started + 1
    }
}

let syncUsers = state -> {
    let users = Provider.getUsers(state.cfg, state.cfg.tenant_id) ? {
        state.stats.provider_users_errors = state.stats.provider_users_errors + 1
        log("provider.getUsers error", error.message)
        let fallback = []
        fallback
    }

    let seen = map()
    // Phase 1: upsert current provider users and ensure workers are running.
    for i < users.length with i = 0 {
        syncOneUser(state, seen, users[i])
        i++
    } then ()

    // Phase 2: stop workers for users no longer present in provider snapshot.
    let active_ids = keys(state.active)
    for i < active_ids.length with i = 0 {
        let id = active_ids[i]
        if !has(seen, id) {
            state.stats.users_removed = state.stats.users_removed + 1
            stopUserWorker(state, id, "provider_removed")
        }
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

let processMessage = (state, msg) -> {
    state.stats.seen = state.stats.seen + 1

    let saved = DB.storeDiscoveredEmail(state.db, msg.email, msg.user_id) ? {
        log("storeDiscoveredEmail error", { user_id: msg.user_id, message: error.message, })
        null
    }

    if saved == null {
        { ok: false, }
    } else if saved.is_new {
        state.stats.discovered = state.stats.discovered + 1
        bumpUserDiscovered(state, msg.user_id)
        sendToAnalysisQueue(state, msg, saved)
        { ok: true, is_new: true, }
    } else {
        state.stats.duplicated = state.stats.duplicated + 1
        { ok: true, is_new: false, }
    }
}

// Queue consumer stream: drains discovered emails until queue.done().
let processStream = state -> fromChannel(state.queue) | map(msg -> processMessage(state, msg)) | count()

let metricsSnapshot = state -> {
    active_workers: keys(state.active).length,
    seen: state.stats.seen,
    discovered: state.stats.discovered,
    duplicated: state.stats.duplicated,
    queued: state.stats.queued,
    queue_errors: state.stats.queue_errors,
    users_added: state.stats.users_added,
    users_removed: state.stats.users_removed,
    workers_started: state.stats.workers_started,
    workers_stopped: state.stats.workers_stopped,
    provider_users_errors: state.stats.provider_users_errors,
    provider_emails_errors: state.stats.provider_emails_errors,
    top_users: topUsers(state, 3),
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
        user_emails: map(),
        analysis_queue: AnalysisQueue.new(cfg),
        stats: {
            seen: 0,
            discovered: 0,
            duplicated: 0,
            queued: 0,
            queue_errors: 0,
            users_added: 0,
            users_removed: 0,
            workers_started: 0,
            workers_stopped: 0,
            provider_users_errors: 0,
            provider_emails_errors: 0,
            by_user: map(),
        },
    }

    let processor = & processStream(state)
    let user_discovery = & userDiscoveryLoop(state)

    let [signal_name, done] = signalWatch(["SIGINT", "SIGTERM"]).recv()
    if !done { log("shutdown", signal_name) }

    user_discovery.cancel()
    (wait user_discovery) ? {}
    stopAllWorkers(state)
    // Closing queue after workers stop lets processor drain and terminate.
    state.queue.done()
    (wait processor) ? {}

    DB.close(db) ? { fail("db close failed: " + error.message) }
    metricsSnapshot(state)
}
