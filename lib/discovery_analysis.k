let consumeOne = state -> {
    for true {
        let [msg, done] = state.analysis_queue.recv()
        if done { break () }
        state.analysis_enqueued = state.analysis_enqueued + 1
    } then ()
}

let start = state -> {
    state.analysis_tasks = [spawn (() -> consumeOne(state))()]
}

let stop = state -> {
    done(state.analysis_queue)
    state.analysis_tasks.forEach(t -> (wait t) ? {})
}
