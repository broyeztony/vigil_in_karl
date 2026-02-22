let first_names = ["John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Eve", "Frank"]
let last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis"]
let domains = ["example.com", "company.com", "business.org", "enterprise.net"]
let subjects = [
    "Meeting tomorrow",
    "Project update",
    "Budget review",
    "Team lunch",
    "Quarterly report",
    "Client feedback",
    "Urgent: Action required",
    "Follow up",
]

let pick = xs -> xs[randInt(0, xs.length - 1)]

let makeUser = (tenant_id, index) -> {
    let first = first_names[index % first_names.length]
    let last = last_names[index % last_names.length]
    let domain = domains[index % domains.length]
    {
        id: uuidNew(),
        email: toLower(first) + "." + toLower(last) + "." + str(index) + "@" + domain,
        name: first + " " + last,
        tenant_id: tenant_id,
        active: true,
        created_at: timeFormatRFC3339(timeAdd(now(), -randInt(0, 365 * 24 * 60 * 60 * 1000))),
    }
}

let makeEmail = (user, email_index, batch_index) -> {
    let subject = pick(subjects)
    let from_domain = pick(domains)
    let from_email = "sender" + str(randInt(0, 50000)) + "@" + from_domain
    let message_id = uuidNew()
    let received_at = timeFormatRFC3339(timeAdd(now(), -randInt(0, 30 * 1000)))
    let body =
        "Dear " + user.name + " (" + user.email + "),\n\n" +
        "Full email body for: " + subject + "\n\n" +
        "Received at: " + received_at + "\n" +
        "Message ID: " + message_id + "\n" +
        "Email index: " + str(email_index) + "\n" +
        "Batch index: " + str(batch_index) + "\n" +
        "Random token: " + str(randInt(0, 5000000)) + "\n" +
        "User ID: " + user.id + "\n\n" +
        "Best regards,\nThe Mock Server"

    let email = {
        message_id: message_id,
        user_id: user.id,
        to: user.email,
        subject: subject + " [" + str(email_index) + "]",
        snippet: "This is a snippet for: " + subject,
        received_at: received_at,
        body: body,
    }
    email["from"] = from_email
    email
}

let parseEmailMs = email -> timeParseRFC3339(email.received_at) ? { 0 }

let new = cfg -> { tenant_id: cfg.tenant_id, users: [], emails: map(), counter: 0, }

let addUser = state -> {
    let index = state.counter
    let user = makeUser(state.tenant_id, index)
    state.users = state.users + [user]
    set(state.emails, user.id, [])
    state.counter = index + 1
    user
}

let addUsers = (state, num) -> {
    let n = if num < 1 { 1 } else { num }
    for i < n with i = 0 {
        addUser(state)
        i++
    } then ()
    state.users.length
}

let setUsers = (state, num) -> {
    let target = if num < 0 { 0 } else { num }
    let current = state.users.length

    if target > current {
        addUsers(state, target - current)
    } else if target < current {
        let old = state.users
        state.users = for i < target with i = 0, kept = [] {
            kept = kept + [old[i]]
            i++
        } then kept

        for i < old.length with i = target {
            delete(state.emails, old[i].id)
            i++
        } then ()
    }

    state.users.length
}

let seedUsers = (state, num) -> addUsers(state, num)

let getUsers = (state, tenant_id) -> {
    if tenant_id != state.tenant_id { [] } else { state.users.map(u -> u) }
}

let getEmails = (state, user_id, received_after_ms, order_by) -> {
    let raw = get(state.emails, user_id)
    let emails = if raw == null { [] } else { raw }
    let filtered = emails.filter(email -> parseEmailMs(email) >= received_after_ms)
    let normalized = if order_by == null { "received_at" } else { toLower(trim(order_by)) }
    filtered.sort((a, b) -> {
        let ams = parseEmailMs(a)
        let bms = parseEmailMs(b)
        if normalized == "received_at desc" { bms - ams } else { ams - bms }
    })
}

let tick = (state, cfg) -> {
    let max_per_tick = if cfg.mock_max_emails_per_tick < 0 { 0 } else { cfg.mock_max_emails_per_tick }
    for i < state.users.length with i = 0 {
        let user = state.users[i]
        let batch_size = randInt(0, max_per_tick)
        let raw = get(state.emails, user.id)
        let base = if raw == null { [] } else { raw }
        let next = for j < batch_size with j = 0, out = base {
            out = out + [makeEmail(user, out.length, j)]
            j++
        } then out
        set(state.emails, user.id, next)
        i++
    } then ()
}

let snapshot = state -> {
    let ids = keys(state.emails)
    let total_emails = for i < ids.length with i = 0, total = 0 {
        let bucket = get(state.emails, ids[i])
        total = total + (if bucket == null { 0 } else { bucket.length })
        i++
    } then total
    let out = { users: state.users.length, emails: total_emails, counter: state.counter, }
    out
}
