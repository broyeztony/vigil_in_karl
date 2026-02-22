let makeMockData = import "../lib/mock_data.k"
let MockData = makeMockData()

let assert = (ok, message) -> if ok { () } else { fail(message) }

let state = MockData.new({ tenant_id: "00000000-0000-0000-0000-000000000001", })
MockData.seedUsers(state, 3)
assert(state.users.length == 3, "seedUsers should create 3 users")

MockData.tick(state, { mock_max_emails_per_tick: 2, })
let users = MockData.getUsers(state, "00000000-0000-0000-0000-000000000001")
assert(users.length == 3, "getUsers should return all seeded users")
assert(MockData.getUsers(state, "wrong-tenant").length == 0, "getUsers should filter tenant")

let user_id = users[0].id
let emails = MockData.getEmails(state, user_id, 0, "received_at")
assert(emails.length >= 0, "getEmails should return an array")

"ok"
