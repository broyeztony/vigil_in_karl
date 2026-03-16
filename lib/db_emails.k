let DbCore = (import "./db_core.k")()
let DbUsers = (import "./db_users.k")()

let link = (db, user_id, email_id) ->
    DbCore.exec(
        db,
        "INSERT INTO user_emails (user_id, email_id) VALUES ($1, $2) ON CONFLICT (user_id, email_id) DO NOTHING",
        [user_id, email_id],
        "link user email"
    )

let resolveEmail = (db, incoming_id, fp, received_at) -> {
    let byFp = DbCore.one(db, "SELECT id FROM emails WHERE fingerprint = $1", [fp], "find email")
    if byFp != null { { id: byFp.id, isNew: false, } } else {
        let ins = DbCore.exec(
            db,
            "INSERT INTO emails (id, fingerprint, received_at) VALUES ($1, $2, $3) ON CONFLICT (fingerprint) DO NOTHING",
            [incoming_id, fp, received_at],
            "insert email"
        )
        let done = DbCore.one(db, "SELECT id FROM emails WHERE fingerprint = $1", [fp], "resolve email")
        if done == null { fail("resolve email failed") }
        { id: done.id, isNew: ins.rowsAffected > 0, }
    }
}

let store = (db, user_id, email) -> {
    let body = trim(email.body) ? ""
    let received_at = trim(email.received_at) ? timeFormatRFC3339(now())
    let incoming_id = trim(email.message_id) ? uuidNew()
    let tx = DbCore.begin(db)
    let stored = (() -> {
        let resolved = resolveEmail(tx, incoming_id, sha256(body), received_at)
        link(tx, user_id, resolved.id)
        DbUsers.markChecked(tx, user_id, timeFormatRFC3339(now()))
        DbUsers.markReceived(tx, user_id, received_at)
        { isNew: resolved.isNew, email_id: resolved.id, }
    })() ? {
        DbCore.rollback(tx) ? {}
        fail("store email: " + error.message)
    }
    DbCore.commit(tx)
    stored
}
