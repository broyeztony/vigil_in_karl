let open = cfg -> sqlOpen(cfg.database_url)
let close = db -> sqlClose(db)
let begin = db -> sqlBegin(db) ? { fail("begin tx: " + error.message) }
let commit = tx -> sqlCommit(tx) ? { fail("commit tx: " + error.message) }
let rollback = tx -> sqlRollback(tx) ? { fail("rollback tx: " + error.message) }

let exec = (conn, query, params, label) ->
    sqlExec(conn, query, params) ? { fail(label + ": " + error.message) }

let all = (conn, query, params, label) ->
    sqlQuery(conn, query, params) ? { fail(label + ": " + error.message) }

let one = (conn, query, params, label) ->
    sqlQueryOne(conn, query, params) ? { fail(label + ": " + error.message) }
