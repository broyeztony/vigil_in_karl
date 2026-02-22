let makeDB = import "../lib/db.k"
let DB = makeDB()

let assert = (ok, message) -> if ok { () } else { fail(message) }

let database_url = env("DATABASE_URL")
if database_url == null { fail("DATABASE_URL is required") }

let db = DB.open(database_url) ? { fail("open db: " + error.message) }
DB.setup(db, "00000000-0000-0000-0000-000000000001") ? { fail("setup: " + error.message) }
DB.exec(db, "TRUNCATE TABLE user_emails, emails, users", [], "truncate") ? { fail(error.message) }

let u1 = { id: "11111111-1111-1111-1111-111111111111", email: "u1@acme.com", }
let u2 = { id: "22222222-2222-2222-2222-222222222222", email: "u2@acme.com", }
DB.upsertUser(db, u1) ? { fail("upsert u1: " + error.message) }
DB.upsertUser(db, u2) ? { fail("upsert u2: " + error.message) }

let ts = timeFormatRFC3339(now())
let email_a = {
    message_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    user_id: u1.id,
    body: "same-body",
    received_at: ts,
}
let email_b = {
    message_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    user_id: u2.id,
    body: "same-body",
    received_at: ts,
}
let email_c = {
    message_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    user_id: u1.id,
    body: "different-body",
    received_at: ts,
}

let s1 = DB.storeDiscoveredEmail(db, email_a, u1.id) ? { fail("store a: " + error.message) }
let s2 = DB.storeDiscoveredEmail(db, email_b, u2.id) ? { fail("store b: " + error.message) }
let s3 = DB.storeDiscoveredEmail(db, email_c, u1.id) ? { fail("store c: " + error.message) }

let emails = DB.countRows(db, "emails")
let links = DB.countRows(db, "user_emails")
let users = DB.countRows(db, "users")
let u1_links = (DB.queryOne(db, "SELECT COUNT(*) AS n FROM user_emails WHERE user_id = $1", [u1.id], "count u1 links") ? { null }).n
let u2_links = (DB.queryOne(db, "SELECT COUNT(*) AS n FROM user_emails WHERE user_id = $1", [u2.id], "count u2 links") ? { null }).n

assert(s1.is_new, "first email should be new")
assert(!s2.is_new, "same fingerprint on different message_id should dedupe")
assert(!s3.is_new, "same message_id on different fingerprint should not insert new row")
assert(emails == 1, "emails table should contain one deduped row")
assert(links == 2, "user_emails should link deduped email to two users")
assert(users == 2, "users table should keep both users")
assert(u1_links == 1, "user1 should have one link")
assert(u2_links == 1, "user2 should have one link")

DB.close(db) ? { fail("close db: " + error.message) }
log("dedupe", { emails: emails, links: links, users: users, })
"ok"
