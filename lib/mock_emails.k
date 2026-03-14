let levelOf = i -> match i % 4 {
    case 0 -> "INFO"
    case 1 -> "DEBUG"
    case 2 -> "WARN"
    case _ -> "ERROR"
}

let one = (user_id, slot, i, tick_ms) -> {
    let ts = slot * tick_ms + i * 200
    let level = levelOf(i)
    {
        message_id: uuidNew(),
        subject: level + " message",
        body: level + " payload for " + user_id,
        received_at: timeFormatRFC3339(ts),
    }
}

let list = (cfg, user_id, received_after) ->
    for i < cfg.mock_max_per_tick with i = 0, xs = [] {
        let slot = floor(now() / cfg.mock_tick_ms)
        let row = one(user_id, slot, i, cfg.mock_tick_ms)
        if received_after == "" || row.received_at > received_after { xs += [row] }
        i++
    } then xs

{ list, }
