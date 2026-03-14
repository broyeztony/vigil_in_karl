let mkUser = i -> {
    id: uuidNew(),
    email: "user." + str(i) + "@example.com",
}

let seed = n ->
    for i < n with i = 0, xs = [] {
        xs += [mkUser(i)]
        i++
    } then xs

{ seed, }
