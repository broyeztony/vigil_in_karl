let makeDB = import "../lib/db.k"
let DB = makeDB()

let assert = (ok, message) -> if ok { () } else { fail(message) }

let database_url = env("DATABASE_URL")
if database_url == null { fail("DATABASE_URL is required") }

let db = DB.open(database_url) ? { fail("open db: " + error.message) }
DB.setup(db, "00000000-0000-0000-0000-000000000001") ? { fail("setup: " + error.message) }
DB.exec(db, "TRUNCATE TABLE user_emails, emails, users", [], "truncate") ? { fail(error.message) }

let user_old = { id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", email: "same.user@acme.com", }
let user_new = { id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", email: "same.user@acme.com", }

DB.upsertUser(db, user_old) ? { fail("upsert old: " + error.message) }
let t1 = timeFormatRFC3339(now())
DB.storeDiscoveredEmail(db, { message_id: "11111111-1111-1111-1111-111111111111", body: "one", received_at: t1, }, user_old.id) ? {
    fail("store old email: " + error.message)
}

DB.upsertUser(db, user_new) ? { fail("upsert new: " + error.message) }

let users = DB.query(db, "SELECT id, email FROM users WHERE email = $1", [user_new.email], "list same-email users")
assert(users.length == 1, "same email should map to one user row")
assert(users[0].id == user_new.id, "same email should point to latest user id")

let links_after_rekey = DB.countRows(db, "user_emails")
assert(links_after_rekey == 0, "rekey should remove stale user links via cascade")

let t2 = timeFormatRFC3339(now())
DB.storeDiscoveredEmail(db, { message_id: "22222222-2222-2222-2222-222222222222", body: "two", received_at: t2, }, user_new.id) ? {
    fail("store new email: " + error.message)
}

let final_links = DB.queryOne(
    db,
    "SELECT COUNT(*) AS n FROM user_emails WHERE user_id = $1",
    [user_new.id],
    "count new links"
).n
assert(final_links == 1, "new user id should link emails without FK errors")

DB.close(db) ? { fail("close db: " + error.message) }
log("rekey", { links_after_rekey: links_after_rekey, final_links: final_links, })
"ok"
