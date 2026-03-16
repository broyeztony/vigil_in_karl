let DbEmails = (import "./db_emails.k")()

let consumeOne = state -> {
    for true {
        let [msg, done] = state.queue.recv()
        if done { break () }
        let stored = DbEmails.store(state.db, msg.user_id, msg.email) ? {
            log("consumer store error", { user_id: msg.user_id, })
            null
        }
        if stored != null && stored.isNew {
            state.analysis_queue.send({ user_id: msg.user_id, email_id: stored.email_id, email: msg.email, }) ? {
                log("analysis enqueue error", { user_id: msg.user_id, })
                ()
            }
        }
    } then ()
}

let start = state -> {
    state.consumer_tasks = []
    for i < state.cfg.consumer_count with i = 0 {
        state.consumer_tasks += [spawn (() -> consumeOne(state))()]
        i++
    } then ()
}

let stop = state -> {
    done(state.queue)
    state.consumer_tasks.forEach(t -> (wait t) ? {})
}
