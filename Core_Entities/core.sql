CREATE TABLE PRODUCTS (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_type ENUM('Physical Product', 'Digital Product', 'Service', 'Subscription', 'Bundle', 'Kit') NOT NULL,
    brand VARCHAR(100),
    manufacturer VARCHAR(150),
    country_of_origin VARCHAR(100),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    product_description TEXT,
    product_status ENUM('active', 'inactive', 'discontinued', 'draft', 'pending approval') DEFAULT 'draft',
    launch_date DATE,
    discontinue_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    
    INDEX idx_product_code (product_code),
    INDEX idx_product_name (product_name),
    INDEX idx_product_type (product_type),
    INDEX idx_brand (brand),
    INDEX idx_manufacturer (manufacturer),
    INDEX idx_category (category, sub_category),
    INDEX idx_product_status (product_status),
    INDEX idx_launch_date (launch_date)
);


CREATE TABLE PRODUCT_DIMENSIONS (
    dimension_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL UNIQUE,
    length_metres DECIMAL(10,4),
    width_metres DECIMAL(10,4),
    height_metres DECIMAL(10,4),
    weight_kg DECIMAL(10,4), 
    volume_cubic_metre DECIMAL(10,4),
    packaging_length_metres DECIMAL(10,4),
    packaging_width_metres DECIMAL(10,4),
    packaging_height_metres DECIMAL(10,4),
    packaging_weight_kg DECIMAL(10,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_weight (weight_kg),
    INDEX idx_volume (volume_cubic_metre)
);


CREATE TABLE SPECIFICATION_ATTRIBUTES (
    attribute_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    attribute_name VARCHAR(100) NOT NULL,
    attribute_value TEXT,
    attribute_type ENUM('Text', 'Number', 'Boolean', 'Date', 'List', 'URL') DEFAULT 'Text',
    unit_of_measure VARCHAR(20),
    is_searchable BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_attribute_name (attribute_name),
    INDEX idx_is_searchable (is_searchable),
    INDEX idx_display_order (display_order)
);


CREATE TABLE PRODUCT_PRICING (
    pricing_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    price_type ENUM('Base', 'Cost', 'Retail', 'Wholesale', 'Promotional', 'MSRP', 'Discount') NOT NULL,
    price_amount DECIMAL(12,2) NOT NULL, 
    currency VARCHAR(3) DEFAULT 'USD',
    effective_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    expiry_date DATE,
    min_quantity INT DEFAULT 1,
    max_quantity INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_price_type (price_type),
    INDEX idx_currency (currency),
    INDEX idx_effective_date (effective_date),
    INDEX idx_is_active (is_active)
);


CREATE TABLE PRODUCT_IDENTIFIERS (
    identifier_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    identifier_type ENUM('Barcode', 'UPC', 'EAN', 'ISBN', 'SKU', 'GTIN', 'Internal', 'Model Number', 'Serial Number') NOT NULL,
    identifier_value VARCHAR(100) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_identifier_type (identifier_type),
    INDEX idx_identifier_value (identifier_value),
    INDEX idx_is_primary (is_primary),
    UNIQUE KEY unique_identifier (identifier_type, identifier_value)
);


CREATE TABLE PRODUCT_INVENTORY (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    current_stock INT DEFAULT 0,
    reserved_stock INT DEFAULT 0,
    available_stock AS (current_stock - reserved_stock) STORED,
    minimum_stock INT DEFAULT 0,
    maximum_stock INT,
    reorder_point INT DEFAULT 0,
    last_counted_date DATE,
    last_moved_date TIMESTAMP,
    cost_per_unit DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES WAREHOUSES(warehouse_id),
    INDEX idx_product_id (product_id),
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_available_stock (available_stock),
    INDEX idx_reorder_point (reorder_point),
    INDEX idx_last_moved_date (last_moved_date),
    UNIQUE KEY unique_product_warehouse (product_id, warehouse_id)
);


CREATE TABLE PRODUCT_REGULATORY_INFO (
    regulatory_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL UNIQUE,
    is_hazardous BOOLEAN DEFAULT FALSE,
    hazard_classification ENUM('Explosives', 'Flammable', 'Oxidizers', 'Toxic substances', 'Corrosives', 'Environmental hazard', 'None') DEFAULT 'None',
    un_number VARCHAR(10), 
    has_age_restriction BOOLEAN DEFAULT FALSE,
    minimum_age INT,
    requires_license BOOLEAN DEFAULT FALSE,
    license_type VARCHAR(100),
    export_restricted BOOLEAN DEFAULT FALSE,
    import_restricted BOOLEAN DEFAULT FALSE,
    restricted_countries TEXT, 
    msds_document_path VARCHAR(500), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_is_hazardous (is_hazardous),
    INDEX idx_hazard_classification (hazard_classification),
    INDEX idx_has_age_restriction (has_age_restriction),
    INDEX idx_export_restricted (export_restricted)
);

CREATE TABLE PRODUCT_CERTIFICATIONS (
    certification_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    certification_name VARCHAR(100) NOT NULL,
    certifying_body VARCHAR(100),
    certificate_number VARCHAR(100),
    issue_date DATE,
    expiry_date DATE,
    certificate_document_path VARCHAR(500),
    status ENUM('Valid', 'Expired', 'Pending', 'Revoked') DEFAULT 'Valid',
    certification_scope TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_certification_name (certification_name),
    INDEX idx_certifying_body (certifying_body),
    INDEX idx_status (status),
    INDEX idx_expiry_date (expiry_date)
);

DELIMITER $
CREATE TRIGGER trg_product_identifier_primary_check
    BEFORE INSERT ON PRODUCT_IDENTIFIERS
    FOR EACH ROW
BEGIN
    IF NEW.is_primary = TRUE THEN
        UPDATE PRODUCT_IDENTIFIERS 
        SET is_primary = FALSE 
        WHERE product_id = NEW.product_id AND identifier_type = NEW.identifier_type AND is_primary = TRUE;
    END IF;
END$
DELIMITER ;


DELIMITER $
CREATE TRIGGER trg_product_certification_expiry_check
    BEFORE UPDATE ON PRODUCT_CERTIFICATIONS
    FOR EACH ROW
BEGIN
    IF NEW.expiry_date < CURRENT_DATE AND OLD.status = 'Valid' THEN
        SET NEW.status = 'Expired';
    END IF;
END$
DELIMITER ;


DELIMITER $
CREATE TRIGGER trg_product_status_date_check
    BEFORE UPDATE ON PRODUCTS
    FOR EACH ROW
BEGIN
    
    IF NEW.launch_date <= CURRENT_DATE AND OLD.product_status = 'draft' THEN
        SET NEW.product_status = 'active';
    END IF;
    
    
    IF NEW.discontinue_date <= CURRENT_DATE AND OLD.product_status = 'active' THEN
        SET NEW.product_status = 'discontinued';
    END IF;
END$
DELIMITER ;


DELIMITER $
CREATE TRIGGER trg_inventory_negative_check
    BEFORE UPDATE ON PRODUCT_INVENTORY
    FOR EACH ROW
BEGIN
    IF NEW.current_stock < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Current stock cannot be negative';
    END IF;
    
    IF NEW.reserved_stock < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reserved stock cannot be negative';
    END IF;
    
    
    IF NEW.current_stock != OLD.current_stock THEN
        SET NEW.last_moved_date = CURRENT_TIMESTAMP;
    END IF;
END$
DELIMITER ;
USE nexus_core;
CREATE SCHEMA core;

-- Customers table
CREATE TABLE core.customers (
    customer_id  BIGSERIAL PRIMARY KEY,
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    customer_type   VARCHAR(20) NOT NULL CHECK (customer_type IN ('Individual','Corporate')),
    customer_status  VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (customer_status IN ('Active','Inactive','Suspended','Closed')),
    registration_date DATE NOT NULL,
    created_at   TIMESTAMP DEFAULT now(),
    updated_at   TIMESTAMP DEFAULT now(),
    created_by   BIGINT REFERENCES core.employees(employee_id),
    updated_by   BIGINT REFERENCES core.employees(employee_id)
);


CREATE TABLE core.customers_profile (
    profile_id    BIGSERIAL PRIMARY KEY,
    customer_id   BIGINT NOT NULL REFERENCES core.customers(customer_id) ON DELETE CASCADE,
    first_name    VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    middle_name   VARCHAR(100),
    date_of_birth   DATE,
    gender     VARCHAR(20) CHECK (gender IN ('Male','Female','Other')),
    nationality  VARCHAR(100),
    marital_status  VARCHAR(20) CHECK (marital_status IN ('Single','Married','Divorced','Widowed')),
    created_at  TIMESTAMP DEFAULT now(),
    updated_at  TIMESTAMP DEFAULT now(),
    created_by  BIGINT REFERENCES core.employees(employee_id),
    updated_by  BIGINT REFERENCES core.employees(employee_id)
);


CREATE TABLE core.customers_business (
    corporate_id   BIGSERIAL PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES core.customers(customer_id) ON DELETE CASCADE,
    corporate_name    VARCHAR(200) NOT NULL,
    tax_id    VARCHAR(50),
    industry_classification VARCHAR(100),
    registration_number   VARCHAR(100),
    employee_count     INT,
    annual_revenue   DECIMAL(18,2),
    website    VARCHAR(200),
    created_at    TIMESTAMP DEFAULT now(),
    updated_at    TIMESTAMP DEFAULT now(),
    created_by    BIGINT REFERENCES core.employees(employee_id),
    updated_by    BIGINT REFERENCES core.employees(employee_id)
);


CREATE TABLE core.customer_country (
    country_id    BIGSERIAL PRIMARY KEY,
    customer_id   BIGINT NOT NULL REFERENCES core.customers(customer_id) ON DELETE CASCADE,
    country_name   VARCHAR(100) NOT NULL,
    country_code   VARCHAR(10) NOT NULL  -- e.g. +1, +234
);


CREATE TABLE core.customer_contact (
    contact_id BIGSERIAL PRIMARY KEY,
    customer_id  BIGINT NOT NULL REFERENCES core.customers(customer_id) ON DELETE CASCADE,
    contact_type VARCHAR(20) NOT NULL CHECK (contact_type IN ('Primary','Billing','Shipping','Emergency')),
    country_id   BIGINT REFERENCES core.customer_country(country_id),
    city    VARCHAR(50),
    state_province VARCHAR(50),
    customer_address  VARCHAR(100),
    postal_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    created_by  BIGINT REFERENCES core.employees(employee_id),
    updated_by  BIGINT REFERENCES core.employees(employee_id)
);


CREATE TABLE core.customer_phone (
    phone_id  BIGSERIAL PRIMARY KEY,
    customer_id  BIGINT NOT NULL REFERENCES core.customers(customer_id) ON DELETE CASCADE,
    country_id   BIGINT REFERENCES core.customer_country(country_id),
    phone_type   VARCHAR(20) NOT NULL CHECK (phone_type IN ('Mobile','Home','Work','Fax')),
    phone_number VARCHAR(30) NOT NULL,
    is_primary  BOOLEAN DEFAULT FALSE,
    created_at    TIMESTAMP DEFAULT now(),
    updated_at   TIMESTAMP DEFAULT now(),
    created_by  BIGINT REFERENCES core.employees(employee_id),
    updated_by   BIGINT REFERENCES core.employees(employee_id)
);



CREATE TABLE core.customer_emails (
    email_id       BIGSERIAL PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES core.customers(customer_id) ON DELETE CASCADE,
    email_type     VARCHAR(20) CHECK (email_type IN ('Personal','Work','Billing','Marketing')),
    email_address  VARCHAR(200) NOT NULL,
    is_primary     BOOLEAN DEFAULT FALSE,
    opt_in_marketing BOOLEAN DEFAULT FALSE
);


CREATE TABLE core.customer_credit (
    credit_id   BIGSERIAL PRIMARY KEY,
    customer_id  BIGINT NOT NULL REFERENCES core.customers(customer_id) ON DELETE CASCADE,
    credit_score  INT,
    risk_level   VARCHAR(20) CHECK (risk_level IN ('Low','Medium','High','Critical')),
    credit_limit  DECIMAL(18,2),
    available_credit DECIMAL(18,2),
    payment_terms_days INT,
    created_at  TIMESTAMP DEFAULT now(),
    updated_at  TIMESTAMP DEFAULT now(),
    created_by  BIGINT REFERENCES core.employees(employee_id),
    updated_by  BIGINT REFERENCES core.employees(employee_id)
);


-- Transactions tables
CREATE TABLE core.transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    transaction_number  VARCHAR(50) UNIQUE NOT NULL,
    customer_id   BIGINT NOT NULL REFERENCES core.customers(customer_id),
    employee_id   BIGINT REFERENCES core.employees(employee_id),
    division_id   BIGINT REFERENCES core.divisions(division_id),
    location_id   BIGINT REFERENCES core.locations(location_id),
    is_online    BOOLEAN DEFAULT FALSE,
    transaction_date  TIMESTAMP NOT NULL,
    currency    VARCHAR(10) NOT NULL,
    subtotal_amount  DECIMAL(15,2) DEFAULT 0,
    tax_amount  DECIMAL(15,2) DEFAULT 0,
    discount_amount  DECIMAL(15,2) DEFAULT 0,
    shipping_amount  DECIMAL(15,2) DEFAULT 0,
    total_amount   DECIMAL(15,2) NOT NULL,
    paid_amount    DECIMAL(15,2) DEFAULT 0,
    balance_due    DECIMAL(15,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    transaction_status  VARCHAR(20) NOT NULL DEFAULT 'Draft' CHECK (transaction_status IN ('Draft','Pending','Confirmed','Paid','Shipped','Delivered','Completed','Cancelled','Refunded')),
    reference_number    VARCHAR(100),
    transaction_description   TEXT,
    notes   TEXT,
    receipt_number  VARCHAR(50),
    invoice_number  VARCHAR(50),
    created_at   TIMESTAMP DEFAULT now(),
    updated_at   TIMESTAMP DEFAULT now(),
    created_by    BIGINT REFERENCES core.employees(employee_id),
    updated_by   BIGINT REFERENCES core.employees(employee_id)
);



CREATE TABLE core.transaction_addresses (
    address_id   BIGSERIAL PRIMARY KEY,
    transaction_id  BIGINT NOT NULL REFERENCES core.transactions(transaction_id) ON DELETE CASCADE,
    address_type  VARCHAR(20) NOT NULL CHECK (address_type IN ('Billing','Shipping')),
    recipient_name  VARCHAR(100),
    address_line1   VARCHAR(100),
    city   VARCHAR(50),
    state_province  VARCHAR(50),
    postal_code   VARCHAR(20),
    country_id  VARCHAR(10) REFERENCES core.customer_country(country_code),
    phone   VARCHAR(20),
    email   VARCHAR(50),
    delivery_instructions TEXT
);


CREATE TABLE core.transaction_items (
    transaction_item_id BIGSERIAL PRIMARY KEY,
    transaction_id   BIGINT NOT NULL REFERENCES core.transactions(transaction_id) ON DELETE CASCADE,
    product_id     BIGINT NOT NULL REFERENCES core.products(product_id),
    item_description  TEXT,
    quantity    DECIMAL(10,4) NOT NULL,
    unit_price  DECIMAL(15,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount  DECIMAL(15,2) DEFAULT 0,
    subtotal   DECIMAL(15,2) GENERATED ALWAYS AS (quantity * unit_price - discount_amount) STORED,
    tax_amount   DECIMAL(15,2) DEFAULT 0,
    line_total   DECIMAL(15,2) GENERATED ALWAYS AS (subtotal + tax_amount) STORED,
    cost_price   DECIMAL(15,2),
    margin   DECIMAL(15,2) GENERATED ALWAYS AS ((quantity * unit_price - discount_amount + tax_amount) - (quantity * cost_price)) STORED,
    item_status  VARCHAR(20) NOT NULL DEFAULT 'Ordered' CHECK (item_status IN ('Ordered','Backordered','Shipped','Delivered','Returned','Cancelled')),
    warehouse_id  BIGINT REFERENCES core.warehouses(warehouse_id),
    batch_number  VARCHAR(50),
    serial_number   VARCHAR(100),
    item_expiry_date   DATE,
    warranty_start_date  DATE,
    warranty_end_date   DATE,
    warranty_terms   TEXT,
    created_at   TIMESTAMP DEFAULT now(),
    updated_at   TIMESTAMP DEFAULT now(),
    created_by   BIGINT REFERENCES core.employees(employee_id),
    updated_by   BIGINT REFERENCES core.employees(employee_id)
);


CREATE TABLE core.transaction_payments (
    payment_id    BIGSERIAL PRIMARY KEY,
    transaction_id    BIGINT NOT NULL REFERENCES core.transactions(transaction_id) ON DELETE CASCADE,
    payment_method   VARCHAR(50) NOT NULL,
    payment_amount    DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    exchange_rate   DECIMAL(10,6),
    payment_date   TIMESTAMP NOT NULL,
    payment_reference  VARCHAR(100),
    payment_status  VARCHAR(20) NOT NULL DEFAULT 'Pending'  CHECK (payment_status IN ('Pending','Authorized','Captured','Settled','Failed','Cancelled','Refunded')),
    refund_amount   DECIMAL(15,2) DEFAULT 0,
    created_at   TIMESTAMP DEFAULT now(),
    updated_at   TIMESTAMP DEFAULT now(),
    created_by   BIGINT REFERENCES core.employees(employee_id),
    updated_by  BIGINT REFERENCES core.employees(employee_id)
);


CREATE TABLE core.shipping_methods (
    shipping_method_id  BIGSERIAL PRIMARY KEY,
    method_name         VARCHAR(100) NOT NULL,
    carrier_name        VARCHAR(100),
    estimated_days      INT,
    base_cost           DECIMAL(15,2),
    is_active           BOOLEAN DEFAULT TRUE
);


CREATE TABLE core.transaction_shipments (
    shipment_id         BIGSERIAL PRIMARY KEY,
    transaction_id      BIGINT NOT NULL REFERENCES core.transactions(transaction_id) ON DELETE CASCADE,
    shipment_number     VARCHAR(50) UNIQUE,
    shipping_method_id  BIGINT REFERENCES core.shipping_methods(shipping_method_id),
    carrier_name        VARCHAR(100),
    tracking_number     VARCHAR(100),
    shipped_date        TIMESTAMP,
    estimated_delivery_date DATE,
    delivered_date      TIMESTAMP,
    delivery_confirmation VARCHAR(100),
    shipping_cost    DECIMAL(15,2) DEFAULT 0,
    weight_kg    DECIMAL(8,3),
    dimensions_cm   VARCHAR(50),
    package_count   INT DEFAULT 1,
    shipment_status  VARCHAR(20) NOT NULL DEFAULT 'Preparing'  CHECK (shipment_status IN ('Preparing','Shipped','In Transit','Delivered','Exception','Returned')),
    delivery_notes   TEXT,
    signature_required  BOOLEAN DEFAULT FALSE,
    created_at    TIMESTAMP DEFAULT now(),
    updated_at   TIMESTAMP DEFAULT now()
);


CREATE TABLE core.shipment_items (
    shipment_item_id    BIGSERIAL PRIMARY KEY,
    shipment_id         BIGINT NOT NULL REFERENCES core.transaction_shipments(shipment_id) ON DELETE CASCADE,
    transaction_item_id BIGINT NOT NULL REFERENCES core.transaction_items(transaction_item_id) ON DELETE CASCADE,
    quantity_shipped    DECIMAL(10,4) NOT NULL
);


CREATE TABLE core.return_reasons (
    return_reason_id BIGSERIAL PRIMARY KEY,
    reason_name  VARCHAR(100) NOT NULL,
    reason_code  VARCHAR(20),
    requires_inspection BOOLEAN DEFAULT TRUE,
    is_customer_fault   BOOLEAN DEFAULT FALSE
);


CREATE TABLE core.transaction_returns (
    return_id    BIGSERIAL PRIMARY KEY,
    transaction_id  BIGINT NOT NULL REFERENCES core.transactions(transaction_id) ON DELETE CASCADE,
    return_number   VARCHAR(50) UNIQUE NOT NULL,
    return_date   DATE NOT NULL,
    return_reason_id  BIGINT REFERENCES core.return_reasons(return_reason_id),
    return_status  VARCHAR(20) NOT NULL DEFAULT 'Requested'  CHECK (return_status IN ('Requested','Approved','Received','Inspected','Processed','Rejected')),
    customer_notes  TEXT,
    inspection_notes  TEXT,
    return_shipping_cost DECIMAL(15,2) DEFAULT 0,
    restocking_fee  DECIMAL(15,2) DEFAULT 0,
    total_refund_amount DECIMAL(15,2) DEFAULT 0,
    processed_by    BIGINT REFERENCES core.employees(employee_id),
    processed_date  TIMESTAMP,
    created_at  TIMESTAMP DEFAULT now(),
    updated_at  TIMESTAMP DEFAULT now(),
    created_by  BIGINT REFERENCES core.employees(employee_id),
    updated_by  BIGINT REFERENCES core.employees(employee_id)
);



CREATE TABLE core.return_items (
    return_item_id   BIGSERIAL PRIMARY KEY,
    return_id   BIGINT NOT NULL REFERENCES core.transaction_returns(return_id) ON DELETE CASCADE,
    transaction_item_id BIGINT NOT NULL REFERENCES core.transaction_items(transaction_item_id),
    quantity_returned   DECIMAL(10,4) NOT NULL,
    condition_received  VARCHAR(20) CHECK (condition_received IN ('New','Like New','Good','Fair','Poor','Damaged')),
    refund_amount   DECIMAL(15,2) DEFAULT 0,
    restock_quantity DECIMAL(10,4) DEFAULT 0,
    disposal_quantity DECIMAL(10,4) DEFAULT 0
);
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
