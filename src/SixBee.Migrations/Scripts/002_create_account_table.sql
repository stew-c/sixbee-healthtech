CREATE TABLE account (
    "Id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "Email"           VARCHAR(255) NOT NULL UNIQUE,
    "PasswordHash"    VARCHAR(255) NOT NULL,
    "CreatedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
