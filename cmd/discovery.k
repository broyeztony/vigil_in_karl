let Config = (import "../lib/config.k")()
let Discovery = (import "../lib/discovery_app.k")()

let cfg = Config.get()
let app = Discovery.start(cfg)
log({ discovery: "running", tenant_id: cfg.tenant_id, })

let [sig, done] = signalWatch(["SIGINT", "SIGTERM"]).recv()
if !done { log("shutdown", sig) }

Discovery.stop(app)
