let WorkerLoop = (import "./discovery_worker_loop.k")()

let ensure = (state, user_id) -> {
    if has(state.active, user_id) { () } else {
        let stop = map().set("on", true)
        let task = spawn (() -> WorkerLoop.run(state, user_id, stop))()
        set(state.active, user_id, { stop: stop, task: task, })
    }
}

let stopOne = (state, user_id) -> {
    if has(state.active, user_id) {
        let rec = get(state.active, user_id)
        rec.stop.set("on", false)
        rec.task.cancel()
        (wait rec.task) ? {}
        delete(state.active, user_id)
    }
}

let stopAll = state -> keys(state.active).forEach(id -> stopOne(state, id))
