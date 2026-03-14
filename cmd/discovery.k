let Config = (import "../lib/config.k")()
let Discovery = (import "../lib/discovery_app.k")()

let cfg = Config.get()
let app = Discovery.start(cfg)
log({ discovery: "running", tenant_id: cfg.tenant_id, })

spawn (() -> {
    let [sig, done] = signalWatch(["SIGINT", "SIGTERM"]).recv()
    if !done { log("shutdown", sig) }
    Discovery.stop(app)
    exit(0)
})()

for true { sleep(1000) } then ()
