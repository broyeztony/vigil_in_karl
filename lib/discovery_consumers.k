let DbEmails = (import "./db_emails.k")()

let consumeOne = state -> {
    for true {
        let [msg, done] = state.queue.recv()
        if done { break () }
        DbEmails.store(state.db, msg.user_id, msg.email) ? {
            log("consumer store error", { user_id: msg.user_id, message: error.message, })
            ()
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
