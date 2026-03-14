let DbCore = (import "./db_core.k")()

let migrate = db -> {
    let steps = [
        "CREATE TABLE IF NOT EXISTS tenant (id UUID PRIMARY KEY, name VARCHAR(255), provider VARCHAR(16))",
        "ALTER TABLE tenant ALTER COLUMN provider TYPE VARCHAR(16)",
        "CREATE TABLE IF NOT EXISTS users (id UUID PRIMARY KEY, email VARCHAR(255) NOT NULL UNIQUE, last_email_check TIMESTAMPTZ, last_email_received TIMESTAMPTZ)",
        "CREATE TABLE IF NOT EXISTS emails (id UUID PRIMARY KEY, fingerprint VARCHAR(64) NOT NULL UNIQUE, received_at TIMESTAMPTZ NOT NULL)",
        "CREATE TABLE IF NOT EXISTS user_emails (user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, email_id UUID NOT NULL REFERENCES emails(id) ON DELETE CASCADE, PRIMARY KEY (user_id, email_id))",
        "CREATE INDEX IF NOT EXISTS idx_users_last_email_received ON users(last_email_received)",
        "CREATE INDEX IF NOT EXISTS idx_emails_received_at ON emails(received_at)",
    ]

    for i < steps.length with i = 0 {
        DbCore.exec(db, steps[i], [], "migration")
        i++
    } then ()
}

let seedTenant = (db, tenant_id) ->
    DbCore.exec(
        db,
        "INSERT INTO tenant (id, name, provider) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, provider = EXCLUDED.provider",
        [tenant_id, "ACME Corp", "google"],
        "seed tenant"
    )

{ migrate, seedTenant, }
