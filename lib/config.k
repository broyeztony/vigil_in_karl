let envStr = (name, fallback) -> {
    let value = env(name)
    if value == null { fallback } else { value }
}
let envInt = (name, fallback) -> parseInt(envStr(name, str(fallback))) ? { fallback }

let get = () -> {
    database_url: envStr("DATABASE_URL", "postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable"),
    tenant_id: envStr("TENANT_ID", "00000000-0000-0000-0000-000000000001"),
    provider_type: toLower(envStr("PROVIDER_TYPE", "google")),
    provider_api_url: envStr("PROVIDER_API_URL", "http://localhost:8080"),

    mock_addr: ":" + envStr("PORT", "8080"),
    mock_initial_users: envInt("MOCK_INITIAL_USERS", 5000),
    mock_email_tick_ms: envInt("MOCK_EMAIL_TICK_MS", 30000),
    mock_max_emails_per_tick: envInt("MOCK_MAX_EMAILS_PER_TICK", 3),

    user_poll_ms: envInt("USER_POLL_MS", 60000),
    email_poll_ms: envInt("EMAIL_POLL_MS", 30000),
    email_jitter_ms: envInt("EMAIL_JITTER_MS", 30000),
    initial_lookback_ms: envInt("INITIAL_LOOKBACK_MS", 24 * 60 * 60 * 1000),
    metrics_ms: envInt("METRICS_MS", 5000),
    shutdown_timeout_ms: envInt("SHUTDOWN_TIMEOUT_MS", 10000),

    analysis_queue_mode: toLower(envStr("ANALYSIS_QUEUE_MODE", "log")),
}
