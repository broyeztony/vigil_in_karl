let consumeOne = state -> {
    let total = for true with n = 0 {
        let [msg, done] = state.analysis_queue.recv()
        if done { break n }
        msg
        n = n + 1
    } then n
    state.analysis_enqueued = total
}

let start = state -> state.analysis_tasks = [spawn (() -> consumeOne(state))()]

let stop = state -> {
    done(state.analysis_queue)
    state.analysis_tasks.forEach(t -> (wait t) ? {})
}
