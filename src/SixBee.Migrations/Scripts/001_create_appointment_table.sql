CREATE TABLE appointment (
    "Id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "Name"            VARCHAR(255) NOT NULL,
    "DateTime"        TIMESTAMPTZ NOT NULL,
    "Description"     TEXT NOT NULL,
    "ContactNumber"   VARCHAR(20) NOT NULL,
    "Email"           VARCHAR(255) NOT NULL,
    "Status"          VARCHAR(20) NOT NULL DEFAULT 'pending'
                      CHECK ("Status" IN ('pending', 'approved')),
    "CreatedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_appointment_datetime ON appointment ("DateTime");
