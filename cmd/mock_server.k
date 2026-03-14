let Config = (import "../lib/config.k")()
let MockServer = (import "../lib/mock_server_app.k")()

let cfg = Config.get()
let app = MockServer.start(cfg)
log({ mock_addr: cfg.mock_addr, users: app.users.length, })

spawn (() -> {
    let [sig, done] = signalWatch(["SIGINT", "SIGTERM"]).recv()
    if !done { log("shutdown", sig) }
    MockServer.stop(app)
    exit(0)
})()

for true { sleep(1000) } then ()
