let defaultDatabaseURL = () -> {
    let value = env("DATABASE_URL")
    if value == null { "postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable" } else { value }
}

let open = dsn -> sqlOpen(dsn)
let close = db -> sqlClose(db)

let exec = (conn, query, params, label) -> sqlExec(conn, query, params) ? { fail(label + ": " + error.message) }
let query = (conn, stmt, params, label) -> sqlQuery(conn, stmt, params) ? { fail(label + ": " + error.message) }
let queryOne = (conn, stmt, params, label) -> sqlQueryOne(conn, stmt, params) ? { fail(label + ": " + error.message) }

let migrate = db -> {
    let steps = [
        "CREATE TABLE IF NOT EXISTS tenant (id UUID PRIMARY KEY, name VARCHAR(255), provider VARCHAR(2))",
        "CREATE TABLE IF NOT EXISTS users (id UUID PRIMARY KEY, email VARCHAR(255) NOT NULL UNIQUE, last_email_check TIMESTAMP WITH TIME ZONE, last_email_received TIMESTAMP WITH TIME ZONE)",
        "CREATE INDEX IF NOT EXISTS idx_users_last_email_received ON users(last_email_received)",
        "CREATE TABLE IF NOT EXISTS emails (id UUID PRIMARY KEY, fingerprint VARCHAR(64) NOT NULL UNIQUE, received_at TIMESTAMP WITH TIME ZONE NOT NULL)",
        "CREATE INDEX IF NOT EXISTS idx_emails_received_at ON emails(received_at)",
        "CREATE INDEX IF NOT EXISTS idx_emails_fingerprint ON emails(fingerprint)",
        "CREATE TABLE IF NOT EXISTS user_emails (user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, email_id UUID NOT NULL REFERENCES emails(id) ON DELETE CASCADE, PRIMARY KEY (user_id, email_id))",
        "CREATE INDEX IF NOT EXISTS idx_user_emails_user_id ON user_emails(user_id)",
        "CREATE INDEX IF NOT EXISTS idx_user_emails_email_id ON user_emails(email_id)",
    ]

    for i < steps.length with i = 0 {
        exec(db, steps[i], [], "migration")
        i++
    } then ()
}

let seedTenant = (db, tenant_id) ->
    exec(
        db,
        "INSERT INTO tenant (id, name, provider) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, provider = EXCLUDED.provider",
        [tenant_id, "ACME Corp.", "GA"],
        "seed tenant"
    )

let setup = (db, tenant_id) -> {
    migrate(db)
    seedTenant(db, tenant_id)
}

let upsertUser = (db, user) ->
    exec(db, "INSERT INTO users (id, email) VALUES ($1, $2) ON CONFLICT (email) DO NOTHING", [user.id, user.email], "upsert user")

let listUsers = db -> query(db, "SELECT id, email, last_email_check, last_email_received FROM users", [], "list users")

let getUserById = (db, user_id) ->
    queryOne(db, "SELECT id, email, last_email_check, last_email_received FROM users WHERE id = $1", [user_id], "get user")

let setLastEmailCheck = (db, user_id, ts) ->
    exec(db, "UPDATE users SET last_email_check = $1 WHERE id = $2", [ts, user_id], "set last_email_check")

let setLastEmailReceived = (db, user_id, ts) ->
    exec(
        db,
        "UPDATE users SET last_email_received = $1 WHERE id = $2 AND (last_email_received IS NULL OR $1 > last_email_received)",
        [ts, user_id],
        "set last_email_received"
    )

let linkUserEmail = (db, user_id, email_id) ->
    exec(
        db,
        "INSERT INTO user_emails (user_id, email_id) VALUES ($1, $2) ON CONFLICT (user_id, email_id) DO NOTHING",
        [user_id, email_id],
        "link user email"
    )

let storeDiscoveredEmail = (db, email, user_id) -> {
    let body = email.body ? { "" }
    let fingerprint = sha256(body)
    let received_at = email.received_at ? { timeFormatRFC3339(now()) }
    let incoming_id = email.message_id ? { uuidNew() }

    let ins = exec(
        db,
        "INSERT INTO emails (id, fingerprint, received_at) VALUES ($1, $2, $3) ON CONFLICT (fingerprint) DO NOTHING",
        [incoming_id, fingerprint, received_at],
        "insert email metadata"
    )
    let existing = queryOne(db, "SELECT id FROM emails WHERE fingerprint = $1 LIMIT 1", [fingerprint], "find email by fingerprint")
    if existing == null { fail("find email by fingerprint: no row after insert") }

    let email_id = existing.id
    let is_new = ins.rowsAffected > 0

    linkUserEmail(db, user_id, email_id)
    setLastEmailCheck(db, user_id, timeFormatRFC3339(now()))
    if is_new { setLastEmailReceived(db, user_id, received_at) }

    { is_new: is_new, email_id: email_id, fingerprint: fingerprint, }
}

let countRows = (db, table_name) -> {
    let row = queryOne(db, "SELECT COUNT(*) AS n FROM " + table_name, [], "count rows")
    row.n ? { 0 }
}
