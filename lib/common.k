let jsonHeaders = () -> map().set("Content-Type", "application/json")
let textHeaders = () -> map().set("Content-Type", "text/plain")

let jsonResponse = (status, payload) -> { status: status, headers: jsonHeaders(), body: jsonEncode(payload), }
let textResponse = (status, body) -> { status: status, headers: textHeaders(), body: body, }

let badRequest = msg -> jsonResponse(400, { error: msg, })
let internalError = msg -> jsonResponse(500, { error: msg, })

let parseJSON = text -> jsonDecode(text) ? { null }

let trimTrailingSlash = path -> if path.length > 1 && endsWith(path, "/") { path[0..-1] } else { path }

let lastPathPart = path -> {
    let p = trimTrailingSlash(path)
    let parts = split(p, "/")
    parts[parts.length - 1] ? { "" }
}
