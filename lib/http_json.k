let headers = () -> map().set("Content-Type", "application/json")

let ok = payload -> {
    status: 200,
    headers: headers(),
    body: toJson(payload),
}

let bad = msg -> {
    status: 400,
    headers: headers(),
    body: toJson({ error: msg, }),
}

{ ok, bad, }
