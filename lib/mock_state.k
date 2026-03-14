let MockUsers = (import "./mock_users.k")()

let build = cfg -> {
    let users = MockUsers.seed(cfg.mock_initial_users, 0)
    {
        users: users,
        byId: MockUsers.indexById(users),
        next_index: users.length,
    }
}

let resetUsers = (state, n) -> {
    let keep = if n < 0 { 0 } else { n }
    let base = state.users[..keep]
    let add = if keep > base.length {
        MockUsers.seed(keep - base.length, state.next_index)
    } else { [] }

    state.users = base + add
    state.next_index = state.next_index + add.length
    state.byId = MockUsers.indexById(state.users)
}

let addUsers = (state, n) -> {
    let count = if n < 0 { 0 } else { n }
    let add = MockUsers.seed(count, state.next_index)
    state.users = state.users + add
    state.next_index = state.next_index + add.length
    state.byId = MockUsers.indexById(state.users)
}
