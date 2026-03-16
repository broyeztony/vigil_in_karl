let DbUsers = (import "./db_users.k")()
let Provider = (import "./provider_api.k")()
let Workers = (import "./discovery_workers.k")()

let run = state -> {
    let users = Provider.users(state.cfg, state.cfg.tenant_id) ? {
        log("users fetch error", error.message)
        null
    }

    if users == null {
        { ok: false, users: 0, active: len(keys(state.active)), }
    } else {
        let seen = map()
        users.forEach(user -> {
            DbUsers.upsert(state.db, user)
            set(seen, user.id, true)
            Workers.ensure(state, user.id)
        })

        DbUsers.all(state.db)
            .map(u -> u.id)
            .filter(id -> !has(seen, id))
            .forEach(id -> {
                Workers.stopOne(state, id)
                DbUsers.remove(state.db, id)
            })

        { ok: true, users: users.length, active: len(keys(state.active)), }
    }
}
