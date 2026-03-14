let DbUsers = (import "./db_users.k")()
let DbEmails = (import "./db_emails.k")()
let Provider = (import "./provider_api.k")()

let syncOneUser = (state, user) -> {
    DbUsers.upsert(state.db, user)
    let current = DbUsers.byId(state.db, user.id)
    let since = if current == null || current.last_email_received == null {
        timeFormatRFC3339(now() - state.cfg.initial_lookback_ms)
    } else { str(current.last_email_received) }

    Provider.emails(state.cfg, user.id, since)
        .forEach(email -> DbEmails.store(state.db, user.id, email))
}

let sync = state -> {
    let users = Provider.users(state.cfg, state.cfg.tenant_id)
    let seen = users.reduce((acc, u) -> set(acc, u.id, true), map())

    users
        .map(user -> spawn (() -> syncOneUser(state, user))())
        .forEach(task -> wait task ? log("sync user error", error.message))

    DbUsers.all(state.db)
        .filter(u -> !has(seen, u.id))
        .forEach(u -> DbUsers.remove(state.db, u.id))

    { users: users.length, }
}

{ sync, }
