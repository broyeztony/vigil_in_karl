let DbCore = (import "./db_core.k")()
let DbUsers = (import "./db_users.k")()

let link = (db, user_id, email_id) ->
    DbCore.exec(
        db,
        "INSERT INTO user_emails (user_id, email_id) VALUES ($1, $2) ON CONFLICT (user_id, email_id) DO NOTHING",
        [user_id, email_id],
        "link user email"
    )

let resolveEmailId = (db, incoming_id, fingerprint, received_at) -> {
    let byFp = DbCore.one(db, "SELECT id FROM emails WHERE fingerprint = $1", [fingerprint], "find by fp")
    if byFp != null { byFp.id } else {
        DbCore.exec(
            db,
            "INSERT INTO emails (id, fingerprint, received_at) VALUES ($1, $2, $3) ON CONFLICT (id) DO NOTHING",
            [incoming_id, fingerprint, received_at],
            "insert email"
        )
        let done = DbCore.one(db, "SELECT id FROM emails WHERE fingerprint = $1", [fingerprint], "resolve email")
        if done == null { fail("resolve email id failed") }
        done.id
    }
}

let store = (db, user_id, email) -> {
    let body = trim(email.body) ? ""
    let received_at = trim(email.received_at) ? timeFormatRFC3339(now())
    let incoming_id = trim(email.message_id) ? uuidNew()
    let email_id = resolveEmailId(db, incoming_id, sha256(body), received_at)
    link(db, user_id, email_id)
    DbUsers.markChecked(db, user_id, timeFormatRFC3339(now()))
    DbUsers.markReceived(db, user_id, received_at)
}

{ store, }
