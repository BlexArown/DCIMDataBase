
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DROP TABLE IF EXISTS incident_updates CASCADE;
DROP TABLE IF EXISTS incident_services CASCADE;
DROP TABLE IF EXISTS incidents CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS ip_addresses CASCADE;
DROP TABLE IF EXISTS server_components CASCADE;
DROP TABLE IF EXISTS maintenance_logs CASCADE;
DROP TABLE IF EXISTS servers CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;
DROP TABLE IF EXISTS rack_climate_metrics CASCADE;
DROP TABLE IF EXISTS racks CASCADE;
DROP TABLE IF EXISTS datacenters CASCADE;
DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(150) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    phone       VARCHAR(20)  NOT NULL UNIQUE,
    role        VARCHAR(60)  NOT NULL CHECK (
                    role IN ('engineer','admin','manager','security','noc_operator', 'field_tech')
                )
);

CREATE TABLE datacenters (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(120) NOT NULL UNIQUE,
    location        VARCHAR(200) NOT NULL,
    tier_level      SMALLINT     NOT NULL CHECK (tier_level BETWEEN 1 AND 4),
    total_power_kw  NUMERIC(10,2) NOT NULL CHECK (total_power_kw > 0),
    contact_email   VARCHAR(150)  NOT NULL UNIQUE
);

CREATE TABLE racks (
    id              SERIAL PRIMARY KEY,
    datacenter_id   INT          NOT NULL REFERENCES datacenters(id) ON DELETE RESTRICT,
    label           VARCHAR(20)  NOT NULL,
    row_label       VARCHAR(10)  NOT NULL,
    position        SMALLINT     NOT NULL CHECK (position > 0),
    max_units       SMALLINT     NOT NULL DEFAULT 42 CHECK (max_units BETWEEN 1 AND 52),
    max_power_w     INT          NOT NULL CHECK (max_power_w > 0),
    UNIQUE (datacenter_id, label)
);

CREATE TABLE rack_climate_metrics (
    id              BIGSERIAL PRIMARY KEY,
    rack_id         INT          NOT NULL REFERENCES racks(id) ON DELETE CASCADE,
    recorded_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    power_w         INT          NOT NULL CHECK (power_w >= 0),
    temperature_c   NUMERIC(4,1) NOT NULL CHECK (temperature_c BETWEEN 10.0 AND 45.0)
);

CREATE TABLE vendors (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    support_email   VARCHAR(150) CHECK (support_email LIKE '%@%.%'),
    support_phone   VARCHAR(30)
);

CREATE TABLE contracts (
    id              SERIAL PRIMARY KEY,
    vendor_id       INT          NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
    contract_number VARCHAR(50)  NOT NULL UNIQUE,
    start_date      DATE         NOT NULL,
    end_date        DATE         NOT NULL CHECK (end_date >= start_date),
    sla_hours       SMALLINT     NOT NULL CHECK (sla_hours > 0)
);

CREATE TABLE servers (
    id                  SERIAL PRIMARY KEY,
    rack_id             INT          NOT NULL REFERENCES racks(id) ON DELETE RESTRICT,
    contract_id         INT          REFERENCES contracts(id) ON DELETE SET NULL, 
    serial_number       VARCHAR(60)  NOT NULL UNIQUE,
    hostname            VARCHAR(100) NOT NULL UNIQUE,
    manufacturer        VARCHAR(80)  NOT NULL,
    model               VARCHAR(100) NOT NULL,
    status              VARCHAR(20)  NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active','maintenance','decommissioned','reserved')),
    cpu_cores           SMALLINT     NOT NULL CHECK (cpu_cores > 0),
    ram_gb              SMALLINT     NOT NULL CHECK (ram_gb > 0),
    storage_tb          NUMERIC(8,2) NOT NULL CHECK (storage_tb >= 0),
    power_w             INT          NOT NULL CHECK (power_w > 0),
    rack_unit_position  SMALLINT     NOT NULL CHECK (rack_unit_position > 0),
    rack_units_height   SMALLINT     NOT NULL DEFAULT 1 CHECK (rack_units_height BETWEEN 1 AND 10),
    installed_at        DATE         NOT NULL DEFAULT CURRENT_DATE,
    assigned_engineer   INT          REFERENCES employees(id) ON DELETE SET NULL,
    UNIQUE (rack_id, rack_unit_position) 
);

CREATE TABLE server_components (
    id              SERIAL PRIMARY KEY,
    server_id       INT          NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    component_type  VARCHAR(30)  NOT NULL CHECK (component_type IN ('CPU','RAM','HDD','SSD','NIC','PSU')),
    model           VARCHAR(100) NOT NULL,
    serial_number   VARCHAR(60)  UNIQUE,
    capacity_gb     INT          CHECK (capacity_gb > 0),
    status          VARCHAR(20)  NOT NULL DEFAULT 'healthy' CHECK (status IN ('healthy','failed','replaced'))
);

CREATE TABLE ip_addresses (
    id              SERIAL PRIMARY KEY,
    server_id       INT          REFERENCES servers(id) ON DELETE SET NULL,
    ip_address      INET         NOT NULL UNIQUE,
    subnet          CIDR         NOT NULL,
    ip_type         VARCHAR(20)  NOT NULL CHECK (ip_type IN ('management', 'production', 'internal', 'public')),
    is_vip          BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE services (
    id               SERIAL PRIMARY KEY,
    server_id        INT          NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    owner_id         INT          REFERENCES employees(id) ON DELETE SET NULL,
    name             VARCHAR(120) NOT NULL,
    service_type     VARCHAR(60)  NOT NULL CHECK (
                         service_type IN ('web','database','cache','monitoring',
                                          'vpn','dns','storage','api','other')
                     ),
    port             INT          CHECK (port BETWEEN 1 AND 65535),
    status           VARCHAR(20)  NOT NULL DEFAULT 'running'
                         CHECK (status IN ('running','stopped','degraded','migrating')),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE incidents (
    id              SERIAL PRIMARY KEY,
    server_id       INT          NOT NULL REFERENCES servers(id) ON DELETE RESTRICT,
    reported_by     INT          NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    assigned_to     INT          REFERENCES employees(id) ON DELETE SET NULL,
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    severity        VARCHAR(10)  NOT NULL CHECK (severity IN ('low','medium','high','critical')),
    status          VARCHAR(20)  NOT NULL DEFAULT 'open'
                        CHECK (status IN ('open','in_progress','resolved','closed')),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    resolved_at     TIMESTAMPTZ,
    CONSTRAINT resolved_after_created CHECK (resolved_at IS NULL OR resolved_at >= created_at)
);

CREATE TABLE incident_updates (
    id              SERIAL PRIMARY KEY,
    incident_id     INT          NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    author_id       INT          NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    update_text     TEXT         NOT NULL,
    status_state    VARCHAR(20)  NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE incident_services (
    incident_id INT NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    service_id  INT NOT NULL REFERENCES services(id)  ON DELETE CASCADE,
    PRIMARY KEY (incident_id, service_id)
);

CREATE TABLE maintenance_logs (
    id            SERIAL PRIMARY KEY,
    server_id     INT          NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    performed_by  INT          NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    action        VARCHAR(100) NOT NULL,
    notes         TEXT,
    performed_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_servers_status         ON servers(status);
CREATE INDEX idx_servers_rack           ON servers(rack_id);
CREATE INDEX idx_incidents_composite    ON incidents(status, severity);
CREATE INDEX idx_services_server        ON services(server_id);
CREATE INDEX idx_ip_addresses_search    ON ip_addresses(ip_address);
CREATE INDEX idx_components_server      ON server_components(server_id);
CREATE INDEX idx_climate_rack_time      ON rack_climate_metrics(rack_id, recorded_at DESC);
CREATE INDEX idx_incident_updates_inc   ON incident_updates(incident_id);
CREATE INDEX idx_maintenance_server    ON maintenance_logs(server_id);
CREATE INDEX idx_maintenance_performed ON maintenance_logs(performed_at DESC);
