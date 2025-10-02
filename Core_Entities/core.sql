USE nexus_core;
CREATE SCHEMA core;
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
