let Config = (import "../lib/config.k")()
let Discovery = (import "../lib/discovery_app.k")()

let cfg = Config.get()
let app = Discovery.start(cfg)
log({ discovery: "running", tenant_id: cfg.tenant_id, })

let sigTask = spawn (() -> signalWatch(["SIGINT", "SIGTERM"]).recv())()
let [sig, done] = wait sigTask
if !done { log("shutdown", sig) }
Discovery.stop(app)
