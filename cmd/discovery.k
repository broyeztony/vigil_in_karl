let makeConfig = import "../lib/config.k"
let Config = makeConfig()

let makeDiscovery = import "../lib/discovery_app.k"
let Discovery = makeDiscovery()

let cfg = Config.get()
log("discovery", {
    tenant_id: cfg.tenant_id,
    provider_type: cfg.provider_type,
    provider_api_url: cfg.provider_api_url,
    database_url: cfg.database_url,
})

let out = Discovery.run(cfg) ? { exit("discovery failed: " + error.message) }
log("stopped", out)
