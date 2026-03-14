let parseCount = req -> parseInt(trim(req.query.num_users)) ? 0

let setUsers = (state, req, Json, MockState) -> {
    let n = parseCount(req)
    MockState.resetUsers(state, n)
    Json.ok({ users: state.users.length, })
}

let addUsers = (state, req, Json, MockState) -> {
    let n = parseCount(req)
    MockState.addUsers(state, n)
    Json.ok({ users: state.users.length, })
}
