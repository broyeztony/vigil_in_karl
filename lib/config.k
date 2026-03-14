let strEnv = (name, fallback) -> trim(env(name)) ? fallback
let intEnv = (name, fallback) -> parseInt(trim(env(name))) ? fallback

let get = () -> {
    database_url: strEnv("DATABASE_URL", "postgres://vigil:vigil@127.0.0.1:55432/vigil?sslmode=disable"),
    tenant_id: strEnv("TENANT_ID", "00000000-0000-0000-0000-000000000001"),
    provider_api_url: strEnv("PROVIDER_API_URL", "http://127.0.0.1:8080"),
    mock_addr: ":" + strEnv("PORT", "8080"),
    mock_initial_users: intEnv("MOCK_INITIAL_USERS", 32),
    mock_tick_ms: intEnv("MOCK_TICK_MS", 900),
    mock_max_per_tick: intEnv("MOCK_MAX_PER_TICK", 3),
    user_sync_ms: intEnv("USER_SYNC_MS", 1200),
    email_poll_ms: intEnv("EMAIL_POLL_MS", 1500),
    initial_lookback_ms: intEnv("INITIAL_LOOKBACK_MS", 3600000),
    queue_size: intEnv("QUEUE_SIZE", 8192),
    consumer_count: intEnv("CONSUMER_COUNT", 4),
}
