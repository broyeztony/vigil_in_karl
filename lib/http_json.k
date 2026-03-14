let ok = payload -> {
    status: 200,
    headers: map().set("Content-Type", "application/json"),
    body: toJson(payload),
}

let bad = msg -> {
    status: 400,
    headers: map().set("Content-Type", "application/json"),
    body: toJson({ error: msg, }),
}

{ ok, bad, }
