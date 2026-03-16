let Config = (import "../lib/config.k")()
let MockServer = (import "../lib/mock_server_app.k")()

let cfg = Config.get()
let app = MockServer.start(cfg)
log({ mock_addr: cfg.mock_addr, users: app.state.users.length, })

for true { sleep(1000) } then ()
