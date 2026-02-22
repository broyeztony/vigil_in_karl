let makeConfig = import "../lib/config.k"
let Config = makeConfig()

let makeDiscovery = import "../lib/discovery_app.k"
let Discovery = makeDiscovery()

let cfg = Config.get()
let out = Discovery.setup(cfg) ? { exit("setup failed: " + error.message) }
log("setup", out)
