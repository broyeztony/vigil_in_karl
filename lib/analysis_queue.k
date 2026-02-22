let modeOf = cfg -> {
    let value = cfg.analysis_queue_mode
    if value == null { "log" } else { toLower(value) }
}

let new = cfg -> { mode: modeOf(cfg), }

let enqueue = (queue, item) -> match queue.mode {
    case "off" -> true
    case _ -> {
        log("analysis.enqueue", item)
        true
    }
}
