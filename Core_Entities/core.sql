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
