let mk = i -> {
    id: uuidNew(),
    email: "user." + str(i) + "@example.com",
}

let seed = (count, start) ->
    for i < count with i = 0, xs = [] {
        xs += [mk(start + i)]
        i++
    } then xs

let indexById = users -> users.reduce((acc, u) -> set(acc, u.id, u), map())

{ seed, indexById, }
