let DbCore = (import "./db_core.k")()

let upsert = (db, user) -> {
    DbCore.exec(db, "DELETE FROM users WHERE email = $1 AND id <> $2", [user.email, user.id], "drop stale user")
    DbCore.exec(
        db,
        "INSERT INTO users (id, email) VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email",
        [user.id, user.email],
        "upsert user"
    )
}

let byId = (db, user_id) ->
    DbCore.one(db, "SELECT id, email, last_email_check, last_email_received FROM users WHERE id = $1", [user_id], "user by id")

let all = db ->
    DbCore.all(db, "SELECT id, email, last_email_check, last_email_received FROM users", [], "list users")

let remove = (db, user_id) ->
    DbCore.exec(db, "DELETE FROM users WHERE id = $1", [user_id], "remove user")

let markChecked = (db, user_id, ts) ->
    DbCore.exec(db, "UPDATE users SET last_email_check = $1 WHERE id = $2", [ts, user_id], "mark checked")

let markReceived = (db, user_id, ts) ->
    DbCore.exec(db, "UPDATE users SET last_email_received = $1 WHERE id = $2", [ts, user_id], "mark received")

{ upsert, byId, all, remove, markChecked, markReceived, }
