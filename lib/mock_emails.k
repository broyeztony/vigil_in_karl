let levelOf = i -> match i % 4 {
    case 0 -> "INFO"
    case 1 -> "DEBUG"
    case 2 -> "WARN"
    case _ -> "ERROR"
}

let bodyFor = (user_id, slot, i, level) ->
    match i % 3 {
        case 0 -> "shared:" + str(slot) + ":" + str(i) + ":" + level
        case 1 -> "shared:" + str(slot) + ":" + str(i) + ":" + level
        case _ -> "user:" + user_id + ":" + str(slot) + ":" + str(i) + ":" + level
    }

let row = (cfg, user_id, slot, i) -> {
    let level = levelOf(i)
    let at = slot * cfg.mock_tick_ms + i * 100
    {
        message_id: uuidNew(),
        subject: level + " message",
        body: bodyFor(user_id, slot, i, level),
        received_at: timeFormatRFC3339(at),
    }
}

let list = (cfg, user_id, received_after) ->
    for i < randInt(0, cfg.mock_max_per_tick) with i = 0, xs = [] {
        let slot = floor(now() / cfg.mock_tick_ms)
        let e = row(cfg, user_id, slot, i)
        if received_after == "" || e.received_at > received_after { xs += [e] }
        i++
    } then xs
