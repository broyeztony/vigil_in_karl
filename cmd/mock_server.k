let makeConfig = import "../lib/config.k"
let Config = makeConfig()

let makeMockServer = import "../lib/mock_server_app.k"
let MockServer = makeMockServer()

let cfg = Config.get()
let app = MockServer.start(cfg) ? { exit("mock server failed: " + error.message) }
log("mock server", { addr: cfg.mock_addr, users: app.state.users.length, })

let [signal_name, done] = signalWatch(["SIGINT", "SIGTERM"]).recv()
if !done { log("shutdown", signal_name) }

MockServer.stop(app) ? { exit("mock server stop failed: " + error.message) }
