-- V1__init_schema.sql
-- Initial database schema

CREATE TABLE IF NOT EXISTS services (
    id         BIGSERIAL    PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    status     VARCHAR(50)  NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_services_status ON services(status);

COMMENT ON TABLE services IS 'Registered infrastructure services';
