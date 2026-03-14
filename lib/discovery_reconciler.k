let DbUsers = (import "./db_users.k")()
let Provider = (import "./provider_api.k")()
let Workers = (import "./discovery_workers.k")()

let run = state -> {
    let users = Provider.users(state.cfg, state.cfg.tenant_id) ? {
        log("users fetch error", error.message)
        let fallback = []
        fallback
    }

    let seen = map()
    users.forEach(user -> {
        DbUsers.upsert(state.db, user)
        set(seen, user.id, true)
        Workers.ensure(state, user.id)
    })

    keys(state.active)
        .filter(id -> !has(seen, id))
        .forEach(id -> {
            Workers.stopOne(state, id)
            DbUsers.remove(state.db, id)
        })

    { users: users.length, active: len(keys(state.active)), }
}

{ run, }
