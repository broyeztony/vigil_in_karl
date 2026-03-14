let open = cfg -> sqlOpen(cfg.database_url)
let close = db -> sqlClose(db)

let exec = (conn, query, params, label) ->
    sqlExec(conn, query, params) ? { fail(label + ": " + error.message) }

let all = (conn, query, params, label) ->
    sqlQuery(conn, query, params) ? { fail(label + ": " + error.message) }

let one = (conn, query, params, label) ->
    sqlQueryOne(conn, query, params) ? { fail(label + ": " + error.message) }

{ open, close, exec, all, one, }
