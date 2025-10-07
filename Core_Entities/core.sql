CREATE SCHEMA IF NOT EXISTS core AUTHORIZATION current_user;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'supplier_type_t' AND n.nspname = 'core'
  ) THEN
    CREATE TYPE core.supplier_type_t AS ENUM ('manufacturer','distributor','service_provider','consultant');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'supplier_status_t' AND n.nspname = 'core'
  ) THEN
    CREATE TYPE core.supplier_status_t AS ENUM ('active','inactive','suspended');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'contact_type_t' AND n.nspname = 'core'
  ) THEN
    CREATE TYPE core.contact_type_t AS ENUM ('primary','billing','sales','technical','support');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'address_type_t' AND n.nspname = 'core'
  ) THEN
    CREATE TYPE core.address_type_t AS ENUM ('head_office','billing','warehouse','factory','other');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'rating_risk_t' AND n.nspname = 'core'
  ) THEN
    CREATE TYPE core.rating_risk_t AS ENUM ('Low','Medium','High','Critical');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'cert_status_t' AND n.nspname = 'core'
  ) THEN
    CREATE TYPE core.cert_status_t AS ENUM ('Valid','Expired','Suspended','Revoked');
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS core.supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_type core.supplier_type_t NOT NULL,
    supplier_status core.supplier_status_t DEFAULT 'active',
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20),
    website VARCHAR(150),
    tax_id VARCHAR(50) UNIQUE,
    date_registered TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS core.supplier_contact (
    contact_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES core.supplier(supplier_id) ON DELETE CASCADE,
    contact_type core.contact_type_t NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    email VARCHAR(150),
    phone VARCHAR(20),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS core.supplier_address (
    address_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES core.supplier(supplier_id) ON DELETE CASCADE,
    address_type core.address_type_t DEFAULT 'other',
    country VARCHAR(100),
    state_province VARCHAR(100),
    city VARCHAR(100),
    address_text TEXT,
    postal_code VARCHAR(20),
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS core.supplier_payment_info (
    info_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES core.supplier(supplier_id) ON DELETE CASCADE,
    payment_term_days INT,
    description TEXT,
    currency CHAR(3),
    bank_name VARCHAR(200),
    account_number VARCHAR(128),
    account_name VARCHAR(200),
    iban VARCHAR(64),
    swift_code VARCHAR(64),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS core.supplier_certifications (
    certification_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES core.supplier(supplier_id) ON DELETE CASCADE,
    certification_name VARCHAR(255) NOT NULL,
    certificate_number VARCHAR(100),
    certifying_body VARCHAR(200),
    issuing_body VARCHAR(200),
    issue_date DATE,
    expiry_date DATE,
    status core.cert_status_t DEFAULT 'Valid',
    certificate_file_path VARCHAR(1000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS core.supplier_ratings (
    rating_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES core.supplier(supplier_id) ON DELETE CASCADE,
    rating_period_start DATE NOT NULL,
    rating_period_end DATE NOT NULL,
    quality_rating NUMERIC(3,1) CHECK (quality_rating >= 0 AND quality_rating <= 5),
    delivery_rating NUMERIC(3,1) CHECK (delivery_rating >= 0 AND delivery_rating <= 5),
    service_rating NUMERIC(3,1) CHECK (service_rating >= 0 AND service_rating <= 5),
    price_rating NUMERIC(3,1) CHECK (price_rating >= 0 AND price_rating <= 5),
    overall_rating NUMERIC(3,1) CHECK (overall_rating >= 0 AND overall_rating <= 5),
    risk_rating core.rating_risk_t,
    rating_notes TEXT,
    rated_by INT,
    approved_by INT,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS core.supplier_performance_metrics (
    metric_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES core.supplier(supplier_id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    orders_placed INT DEFAULT 0,
    orders_delivered_on_time INT DEFAULT 0,
    orders_delivered_late INT DEFAULT 0,
    quality_issues_count INT DEFAULT 0,
    total_order_value NUMERIC(18,2) DEFAULT 0,
    average_delivery_days NUMERIC(7,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);