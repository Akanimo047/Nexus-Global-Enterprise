CREATE SCHEMA IF NOT EXISTS core AUTHORIZATION current_user;
SET search_path = core;


CREATE TYPE core.gender_t AS ENUM ('Male','Female','Other','Prefer not to say');
CREATE TYPE core.employment_type_t AS ENUM ('fulltime','parttime','contract','intern');
CREATE TYPE core.employee_status_t AS ENUM ('Active','On Leave','Terminated','Retired','Suspended');
CREATE TYPE core.company_status_t AS ENUM ('Active','Inactive','Merged','Closed');
CREATE TYPE core.division_status_t AS ENUM ('Active','Inactive','Restructuring','Dissolved');
CREATE TYPE core.department_type_t AS ENUM ('Operations','Support','Revenue','Cost Center','Profit Center');
CREATE TYPE core.department_status_t AS ENUM ('Active','Inactive','Restructuring','Merged');
CREATE TYPE core.budget_period_t AS ENUM ('Annual','Quarterly','Monthly');
CREATE TYPE core.budget_status_t AS ENUM ('Draft','Submitted','Approved','Rejected','Active','Closed');
CREATE TYPE core.compliance_status_t AS ENUM ('Compliant','Non-Compliant','In Progress','Not Applicable');
CREATE TYPE core.job_level_t AS ENUM ('entry','junior','mid','senior','lead');
CREATE TYPE core.company_type_t AS ENUM ('Manufacturing','Healthcare','Entertainment','Retail','Technology','Finance','Energy','Public','NonProfit','Other');
CREATE TYPE core.pay_frequency_t AS ENUM ('Monthly','BiWeekly','Weekly','Daily');


CREATE OR REPLACE FUNCTION core.trigger_set_timestamp()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---- locations
CREATE TABLE core.locations (
  location_id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  country                VARCHAR(100) NOT NULL,
  country_code           VARCHAR(10),
  province               VARCHAR(100),
  timezone               VARCHAR(100),
  city                   VARCHAR(100),
  location_address       TEXT,
  postal_code            VARCHAR(30),
  email                  VARCHAR(200),
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL,
  created_by             INT,
  updated_by             INT
);

CREATE INDEX ix_locations_country ON core.locations(country);
CREATE INDEX ix_locations_city ON core.locations(city);



---- companies
CREATE TABLE core.companies (
  company_id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  location_id            INT REFERENCES core.locations(location_id) ON DELETE SET NULL,
  company_code           VARCHAR(20) UNIQUE NOT NULL,
  company_name           VARCHAR(200) NOT NULL,
  legal_name             VARCHAR(200),
  company_type           core.company_type_t,
  manager_employee_id    INT, -- FK to employees defined later (add constraint after employees created)
  employee_count         INT DEFAULT 0,
  tax_id                 VARCHAR(50) UNIQUE,
  registration_number    VARCHAR(50),
  parent_company_id      INT REFERENCES core.companies(company_id) ON DELETE SET NULL,
  website                VARCHAR(200),
  founded_date           DATE,
  company_status         core.company_status_t DEFAULT 'Active',
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL,
  created_by             INT,
  updated_by             INT
);

CREATE UNIQUE INDEX ux_companies_company_code ON core.companies(company_code);
CREATE INDEX ix_companies_location_id ON core.companies(location_id);

---- divisions
CREATE TABLE core.divisions (
  division_id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  division_code          VARCHAR(20) UNIQUE NOT NULL,
  division_name          VARCHAR(200) NOT NULL,
  division_type          VARCHAR(100), -- free text for "manufacturing, healthcare, ..."; alternative: enum
  parent_division_id     INT REFERENCES core.divisions(division_id) ON DELETE SET NULL,
  division_head_employee_id INT, -- FK to employees (added later)
  headquarters_location_id INT REFERENCES core.locations(location_id) ON DELETE SET NULL,
  established_date       DATE,
  country                VARCHAR(100),
  division_status        core.division_status_t DEFAULT 'Active',
  annual_revenue         DECIMAL(20,2),
  revenue_currency       VARCHAR(10),
  employee_count         INT DEFAULT 0,
  fte_count              DECIMAL(8,2),
  organizational_level   INT DEFAULT 1,
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL,
  created_by             INT,
  updated_by             INT
);

CREATE UNIQUE INDEX ux_divisions_division_code ON core.divisions(division_code);
CREATE INDEX ix_divisions_headquarters_location ON core.divisions(headquarters_location_id);


CREATE TABLE core.regulatory_framework (
  framework_id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  division_id            INT REFERENCES core.divisions(division_id) ON DELETE CASCADE,
  framework_name         VARCHAR(200) NOT NULL,
  framework_code         VARCHAR(100),
  regulatory_body        VARCHAR(200),
  country                VARCHAR(100),
  framework_description       TEXT,
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ix_regframework_division_id ON core.regulatory_framework(division_id);


CREATE TABLE core.division_regulatory_requirements (
  requirement_id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  division_id            INT NOT NULL REFERENCES core.divisions(division_id) ON DELETE CASCADE,
  framework_id           INT NOT NULL REFERENCES core.regulatory_framework(framework_id) ON DELETE CASCADE,
  compliance_status      core.compliance_status_t DEFAULT 'In Progress',
  effective_date         DATE,
  review_date            DATE,
  expirydate            DATE,
  certification_number   VARCHAR(100),
  notes                  TEXT,
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ix_divreq_division ON core.division_regulatory_requirements(division_id);
CREATE INDEX ix_divreq_framework ON core.division_regulatory_requirements(framework_id);


---- departments
CREATE TABLE core.departments (
  department_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  department_code        VARCHAR(20) UNIQUE NOT NULL,
  department_name        VARCHAR(200) NOT NULL,
  division_id            INT NOT NULL REFERENCES core.divisions(division_id) ON DELETE RESTRICT,
  parent_department_id   INT REFERENCES core.departments(department_id) ON DELETE SET NULL,
  manager_id             INT, -- FK to employees (added later)
  location_id            INT REFERENCES core.locations(location_id) ON DELETE SET NULL,
  department_type        core.department_type_t DEFAULT 'Operations',
  cost_center_code       VARCHAR(20),
  department_status      core.department_status_t DEFAULT 'Active',
  established_date       DATE,
  employee_count         INT DEFAULT 0,
  fte_count              DECIMAL(8,2),
  organizational_level   INT DEFAULT 1,
  dept_description            TEXT,
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL,
  created_by             INT,
  updated_by             INT
);

CREATE UNIQUE INDEX ux_departments_department_code ON core.departments(department_code);
CREATE INDEX ix_departments_division_id ON core.departments(division_id);


CREATE TABLE core.budgets (
  budget_id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  entity_type            VARCHAR(20) NOT NULL, -- 'Company', 'Division', 'Department'
  entity_id              INT NOT NULL,
  budget_year            INT NOT NULL,
  budget_period          core.budget_period_t DEFAULT 'Annual',
  startdate             DATE,
  enddate               DATE,
  budget_category        VARCHAR(100),
  allocated_amount       DECIMAL(20,2) NOT NULL,
  currency               VARCHAR(10) NOT NULL,
  approved_amount        DECIMAL(20,2),
  spent_amount           DECIMAL(20,2) DEFAULT 0,
  remaining_amount       DECIMAL(20,2) GENERATED ALWAYS AS (COALESCE(approved_amount,0) - COALESCE(spent_amount,0)) STORED,
  budget_status          core.budget_status_t DEFAULT 'Draft',
  approved_by            INT,
  approved_date          DATE,
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL,
  created_by             INT,
  updated_by             INT
);

CREATE INDEX ix_budgets_entity ON core.budgets(entity_type, entity_id, budget_year);
CREATE INDEX ix_budgets_status ON core.budgets(budget_status);


---- employees
CREATE TABLE core.employees (
  employee_id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  employee_no            VARCHAR(50) UNIQUE,
  first_name             VARCHAR(100) NOT NULL,
  last_name              VARCHAR(100) NOT NULL,
  middle_name            VARCHAR(100),
  email                  VARCHAR(200) UNIQUE,
  date_of_birth          DATE,
  phone                  VARCHAR(50),
  gender                 core.gender_t,
  nationality            VARCHAR(100),
  company_id             INT REFERENCES core.companies(company_id) ON DELETE SET NULL,
  hire_date              DATE,
  termination_date       DATE,
  employee_status        core.employee_status_t DEFAULT 'Active',
  employment_type        core.employment_type_t DEFAULT 'fulltime',
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL,
  created_by             INT,
  updated_by             INT
);

CREATE UNIQUE INDEX ux_employees_employee_no ON core.employees(employee_no);
-- Case-insensitive index for email searches
CREATE UNIQUE INDEX ux_employees_email_lower ON core.employees(LOWER(email));
CREATE INDEX ix_employees_company_id ON core.employees(company_id);
CREATE INDEX ix_employees_name ON core.employees(last_name, first_name);

-- Add companies.manager_employee_id -> employees.employee_id as FK now:
ALTER TABLE core.companies
  ADD CONSTRAINT fk_companies_manager_employee
  FOREIGN KEY (manager_employee_id) REFERENCES core.employees(employee_id) ON DELETE SET NULL;

-- Add divisions.division_head_employee_id FK:
ALTER TABLE core.divisions
  ADD CONSTRAINT fk_divisions_head_employee
  FOREIGN KEY (division_head_employee_id) REFERENCES core.employees(employee_id) ON DELETE SET NULL;

-- Add departments.manager_id FK:
ALTER TABLE core.departments
  ADD CONSTRAINT fk_departments_manager_employee
  FOREIGN KEY (manager_id) REFERENCES core.employees(employee_id) ON DELETE SET NULL;


CREATE TABLE core.employee_location (
  location_id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  employee_id            INT NOT NULL REFERENCES core.employees(employee_id) ON DELETE CASCADE,
  country                VARCHAR(100),
  employee_address                TEXT,
  city                   VARCHAR(100),
  postal_code            VARCHAR(30),
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ix_emp_loc_employee_id ON core.employee_location(employee_id);



CREATE TABLE core.employee_contacts (
  contact_id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  employee_id            INT NOT NULL REFERENCES core.employees(employee_id) ON DELETE CASCADE,
  emergency_name         VARCHAR(200),
  emergency_number       VARCHAR(50),
  relation               VARCHAR(100),
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ix_emp_contacts_employee ON core.employee_contacts(employee_id);


CREATE TABLE core.employee_job_title (
  job_id                 INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  employee_id            INT NOT NULL REFERENCES core.employees(employee_id) ON DELETE CASCADE,
  job_title              VARCHAR(200) NOT NULL,
  job_level              core.job_level_t,
  department_id          INT REFERENCES core.departments(department_id) ON DELETE SET NULL,
  startdate             DATE,
  enddate               DATE,
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ix_emp_job_employee ON core.employee_job_title(employee_id);
CREATE INDEX ix_emp_job_department ON core.employee_job_title(department_id);


CREATE TABLE core.employee_bank_info (
  bank_info_id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  employee_id            INT NOT NULL REFERENCES core.employees(employee_id) ON DELETE CASCADE,
  salary                 DECIMAL(20,2),
  currency               VARCHAR(10),
  pay_frequency          core.pay_frequency_t,
  bank_name              VARCHAR(200),
  account_number         VARCHAR(100),
  swift_code             VARCHAR(50),
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ix_emp_bank_employee ON core.employee_bank_info(employee_id);
CREATE INDEX ix_emp_bank_acct ON core.employee_bank_info(account_number);



CREATE TABLE core.employee_department (
  employee_department_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  department_id          INT NOT NULL REFERENCES core.departments(department_id) ON DELETE RESTRICT,
  employee_id            INT NOT NULL REFERENCES core.employees(employee_id) ON DELETE CASCADE,
  division_id            INT REFERENCES core.divisions(division_id) ON DELETE SET NULL,
  manager_id             INT REFERENCES core.employees(employee_id) ON DELETE SET NULL,
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ix_emp_dept_employee ON core.employee_department(employee_id);
CREATE INDEX ix_emp_dept_department ON core.employee_department(department_id);


CREATE TABLE core.employee_assignment (
  assignment_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  employee_id            INT NOT NULL REFERENCES core.employees(employee_id) ON DELETE CASCADE,
  job_id                 INT REFERENCES core.employee_job_title(job_id) ON DELETE SET NULL,
  department_id          INT REFERENCES core.departments(department_id) ON DELETE SET NULL,
  startdate             DATE DEFAULT CURRENT_DATE,
  enddate               DATE,
  is_active              BOOLEAN DEFAULT TRUE,
  created_at             timestamptz DEFAULT now() NOT NULL,
  updated_at             timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX ix_emp_assign_employee ON core.employee_assignment(employee_id);
CREATE INDEX ix_emp_assign_is_active ON core.employee_assignment(is_active);


-- Triggers to maintain updated_at, attach trigger to all tables that have updated_at columns
DO $$
DECLARE
  tbl text;
BEGIN
  FOR tbl IN
    SELECT table_name
    FROM information_schema.columns
    WHERE table_schema = 'core'
      AND column_name = 'updated_at'
  LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS trg_set_timestamp ON core.%I;
      CREATE TRIGGER trg_set_timestamp
      BEFORE UPDATE ON core.%I
      FOR EACH ROW EXECUTE FUNCTION core.trigger_set_timestamp();
    ', tbl, tbl);
  END LOOP;
END;
$$;




-- enum types
CREATE TYPE core.product_type_t AS ENUM ('Physical Product', 'Digital Product', 'Service', 'Subscription', 'Bundle', 'Kit');
CREATE TYPE core.product_status_t AS ENUM ('active', 'inactive', 'discontinued', 'draft', 'pending approval');
CREATE TYPE core.attribute_type_t AS ENUM ('Text', 'Number', 'Boolean', 'Date', 'List', 'URL');
CREATE TYPE core.price_type_t AS ENUM ('Base', 'Cost', 'Retail', 'Wholesale', 'Promotional', 'MSRP', 'Discount');
CREATE TYPE core.identifier_type_t AS ENUM ('Barcode', 'UPC', 'EAN', 'ISBN', 'SKU', 'GTIN', 'Internal', 'Model Number', 'Serial Number');
CREATE TYPE core.hazard_classification_t AS ENUM ('Explosives', 'Flammable', 'Oxidizers', 'Toxic substances', 'Corrosives', 'Environmental hazard', 'None');
CREATE TYPE core.cert_status_t AS ENUM ('Valid', 'Expired', 'Pending', 'Revoked');


---- Generic trigger to update "updated_at"

CREATE OR REPLACE FUNCTION core.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---- products

CREATE TABLE core.products (
    product_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_type core.product_type_t NOT NULL,
    brand VARCHAR(100),
    manufacturer VARCHAR(150),
    country_of_origin VARCHAR(100),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    product_description TEXT,
    product_status core.product_status_t DEFAULT 'draft',
    launch_date DATE,
    discontinue_date DATE,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

CREATE INDEX idx_products_code ON core.products(product_code);
CREATE INDEX idx_products_name ON core.products(product_name);
CREATE INDEX idx_products_type ON core.products(product_type);
CREATE INDEX idx_products_category ON core.products(category, sub_category);
CREATE INDEX idx_products_status ON core.products(product_status);
CREATE INDEX idx_products_launch_date ON core.products(launch_date);

CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON core.products
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

 
---- product_dimensions

CREATE TABLE core.product_dimensions (
    dimension_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INT NOT NULL UNIQUE REFERENCES core.products(product_id) ON DELETE CASCADE,
    length_metres DECIMAL(10,4),
    width_metres DECIMAL(10,4),
    height_metres DECIMAL(10,4),
    weight_kg DECIMAL(10,4),
    volume_cubic_metre DECIMAL(10,4),
    packaging_length_metres DECIMAL(10,4),
    packaging_width_metres DECIMAL(10,4),
    packaging_height_metres DECIMAL(10,4),
    packaging_weight_kg DECIMAL(10,4),
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX idx_dimensions_weight ON core.product_dimensions(weight_kg);
CREATE INDEX idx_dimensions_volume ON core.product_dimensions(volume_cubic_metre);

CREATE TRIGGER trg_dimensions_updated_at
BEFORE UPDATE ON core.product_dimensions
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();


--== specification_attributes

CREATE TABLE core.specification_attributes (
    attribute_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INT NOT NULL REFERENCES core.products(product_id) ON DELETE CASCADE,
    attribute_name VARCHAR(100) NOT NULL,
    attribute_value TEXT,
    attribute_type core.attribute_type_t DEFAULT 'Text',
    unit_of_measure VARCHAR(20),
    is_searchable BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX idx_attributes_product ON core.specification_attributes(product_id);
CREATE INDEX idx_attributes_name ON core.specification_attributes(attribute_name);
CREATE INDEX idx_attributes_searchable ON core.specification_attributes(is_searchable);

CREATE TRIGGER trg_attributes_updated_at
BEFORE UPDATE ON core.specification_attributes
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();


-- product_pricing

CREATE TABLE core.product_pricing (
    pricing_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INT NOT NULL REFERENCES core.products(product_id) ON DELETE CASCADE,
    price_type core.price_type_t NOT NULL,
    price_amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    effective_date DATE DEFAULT CURRENT_DATE,
    expirydate DATE,
    min_quantity INT DEFAULT 1,
    max_quantity INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

CREATE INDEX idx_pricing_product ON core.product_pricing(product_id);
CREATE INDEX idx_pricing_type ON core.product_pricing(price_type);
CREATE INDEX idx_pricing_currency ON core.product_pricing(currency);
CREATE INDEX idx_pricing_effective ON core.product_pricing(effective_date);
CREATE INDEX idx_pricing_active ON core.product_pricing(is_active);

CREATE TRIGGER trg_pricing_updated_at
BEFORE UPDATE ON core.product_pricing
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();


---- product_identifiers
CREATE TABLE core.product_identifiers (
    identifier_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INT NOT NULL REFERENCES core.products(product_id) ON DELETE CASCADE,
    identifier_type core.identifier_type_t NOT NULL,
    identifier_value VARCHAR(100) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE (identifier_type, identifier_value)
);

CREATE INDEX idx_identifiers_product ON core.product_identifiers(product_id);
CREATE INDEX idx_identifiers_type ON core.product_identifiers(identifier_type);
CREATE INDEX idx_identifiers_value ON core.product_identifiers(identifier_value);
CREATE INDEX idx_identifiers_primary ON core.product_identifiers(is_primary);

CREATE TRIGGER trg_identifiers_updated_at
BEFORE UPDATE ON core.product_identifiers
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

---- Ensure only one primary identifier per product/type
CREATE OR REPLACE FUNCTION core.ensure_single_primary_identifier()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary THEN
    UPDATE core.product_identifiers
    SET is_primary = FALSE
    WHERE product_id = NEW.product_id
      AND identifier_type = NEW.identifier_type
      AND identifier_id <> NEW.identifier_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_primary_identifier_check
BEFORE INSERT OR UPDATE ON core.product_identifiers
FOR EACH ROW EXECUTE FUNCTION core.ensure_single_primary_identifier();


---- product_inventory

CREATE TABLE core.product_inventory (
    inventory_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INT NOT NULL REFERENCES core.products(product_id) ON DELETE CASCADE,
    warehouse_id INT NOT NULL REFERENCES core.warehouses(warehouse_id),
    current_stock INT DEFAULT 0,
    reserved_stock INT DEFAULT 0,
    available_stock INT GENERATED ALWAYS AS (current_stock - reserved_stock) STORED,
    minimum_stock INT DEFAULT 0,
    maximum_stock INT,
    reorder_point INT DEFAULT 0,
    last_counted_date DATE,
    last_moved_date timestamptz,
    cost_per_unit DECIMAL(12,2),
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE (product_id, warehouse_id)
);

CREATE INDEX idx_reginfo_product ON core.product_regulatory_info(product_id);
CREATE INDEX idx_reginfo_hazardous ON core.product_regulatory_info(is_hazardous);
CREATE INDEX idx_reginfo_hazard_class ON core.product_regulatory_info(hazard_classification);

CREATE TRIGGER trg_reginfo_updated_at
BEFORE UPDATE ON core.product_regulatory_info
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();


-- product_certifications

CREATE TABLE core.product_certifications (
    certification_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INT NOT NULL REFERENCES core.products(product_id) ON DELETE CASCADE,
    certification_name VARCHAR(100) NOT NULL,
    certifying_body VARCHAR(100),
    certificate_number VARCHAR(100),
    issuedate DATE,
    expirydate DATE,
    certificate_document_path VARCHAR(500),
    status core.cert_status_t DEFAULT 'Valid',
    certification_scope TEXT,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX idx_certs_product ON core.product_certifications(product_id);
CREATE INDEX idx_certs_status ON core.product_certifications(status);
CREATE INDEX idx_certs_expiry ON core.product_certifications(expiry_date);

CREATE TRIGGER trg_certs_updated_at
BEFORE UPDATE ON core.product_certifications
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

---- Automatically expire outdated certifications
CREATE OR REPLACE FUNCTION core.auto_expire_certifications()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expiry_date IS NOT NULL AND NEW.expiry_date < CURRENT_DATE THEN
    NEW.status := 'Expired';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_certifications_expiry
BEFORE INSERT OR UPDATE ON core.product_certifications
FOR EACH ROW EXECUTE FUNCTION core.auto_expire_certifications();


-- Auto-activate/discontinue products by date

CREATE OR REPLACE FUNCTION core.auto_update_product_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.launch_date IS NOT NULL AND NEW.launch_date <= CURRENT_DATE AND OLD.product_status = 'draft' THEN
    NEW.product_status := 'active';
  END IF;
  IF NEW.discontinue_date IS NOT NULL AND NEW.discontinue_date <= CURRENT_DATE AND OLD.product_status = 'active' THEN
    NEW.product_status := 'discontinued';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_status
BEFORE UPDATE ON core.products
FOR EACH ROW EXECUTE FUNCTION core.auto_update_product_status();



USE core;

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



-- Customers indexes
CREATE INDEX idx_customers_status ON core.customers(customer_status);
CREATE INDEX idx_customers_type ON core.customers(customer_type);
CREATE INDEX idx_customers_registration_date ON core.customers(registration_date);

-- Customer Profiles
CREATE INDEX idx_customers_profile_customer_id ON core.customers_profile(customer_id);
CREATE INDEX idx_customers_profile_name ON core.customers_profile(last_name, first_name);

-- Customer Business
CREATE INDEX idx_customers_business_customer_id ON core.customers_business(customer_id);
CREATE INDEX idx_customers_business_name ON core.customers_business(corporate_name);
CREATE INDEX idx_customers_business_tax_id ON core.customers_business(tax_id);

-- Customer Country
CREATE INDEX idx_customer_country_customer_id ON core.customer_country(customer_id);
CREATE INDEX idx_customer_country_name ON core.customer_country(country_name);

-- Customer Contact
CREATE INDEX idx_customer_contact_customer_id ON core.customer_contact(customer_id);
CREATE INDEX idx_customer_contact_country_id ON core.customer_contact(country_id);

-- Customer Phone
CREATE INDEX idx_customer_phone_customer_id ON core.customer_phone(customer_id);
CREATE INDEX idx_customer_phone_country_id ON core.customer_phone(country_id);
CREATE INDEX idx_customer_phone_number ON core.customer_phone(phone_number);

-- Customer Emails
CREATE INDEX idx_customer_emails_customer_id ON core.customer_emails(customer_id);
CREATE INDEX idx_customer_emails_email_address ON core.customer_emails(email_address);

-- Customer Credit
CREATE INDEX idx_customer_credit_customer_id ON core.customer_credit(customer_id);
CREATE INDEX idx_customer_credit_risk_level ON core.customer_credit(risk_level);

-- Transactions indexes
CREATE INDEX idx_transactions_customer_id ON core.transactions(customer_id);
CREATE INDEX idx_transactions_employee_id ON core.transactions(employee_id);
CREATE INDEX idx_transactions_division_id ON core.transactions(division_id);
CREATE INDEX idx_transactions_location_id ON core.transactions(location_id);
CREATE INDEX idx_transactions_status ON core.transactions(transaction_status);
CREATE INDEX idx_transactions_date ON core.transactions(transaction_date);

-- Transaction Items
CREATE INDEX idx_transaction_items_transaction_id ON core.transaction_items(transaction_id);
CREATE INDEX idx_transaction_items_product_id ON core.transaction_items(product_id);
CREATE INDEX idx_transaction_items_warehouse_id ON core.transaction_items(warehouse_id);

-- Transaction Payments
CREATE INDEX idx_transaction_payments_transaction_id ON core.transaction_payments(transaction_id);
CREATE INDEX idx_transaction_payments_status ON core.transaction_payments(payment_status);
CREATE INDEX idx_transaction_payments_date ON core.transaction_payments(payment_date);

-- Transaction Shipments
CREATE INDEX idx_transaction_shipments_transaction_id ON core.transaction_shipments(transaction_id);
CREATE INDEX idx_transaction_shipments_status ON core.transaction_shipments(shipment_status);
CREATE INDEX idx_transaction_shipments_tracking ON core.transaction_shipments(tracking_number);

-- Shipment Items
CREATE INDEX idx_shipment_items_shipment_id ON core.shipment_items(shipment_id);
CREATE INDEX idx_shipment_items_transaction_item_id ON core.shipment_items(transaction_item_id);

-- Transaction Returns
CREATE INDEX idx_transaction_returns_transaction_id ON core.transaction_returns(transaction_id);
CREATE INDEX idx_transaction_returns_status ON core.transaction_returns(return_status);
CREATE INDEX idx_transaction_returns_date ON core.transaction_returns(return_date);

-- Return Items
CREATE INDEX idx_return_items_return_id ON core.return_items(return_id);
CREATE INDEX idx_return_items_transaction_item_id ON core.return_items(transaction_item_id);



-- TRIGGER FUNCTION FOR updated_at

CREATE OR REPLACE FUNCTION core.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- APPLY updated_at TRIGGERS TO TABLES
-- Customer tables
CREATE TRIGGER trg_customers_updated_at
BEFORE UPDATE ON core.customers
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_customers_profile_updated_at
BEFORE UPDATE ON core.customers_profile
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_customers_business_updated_at
BEFORE UPDATE ON core.customers_business
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_customer_contact_updated_at
BEFORE UPDATE ON core.customer_contact
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_customer_phone_updated_at
BEFORE UPDATE ON core.customer_phone
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_customer_credit_updated_at
BEFORE UPDATE ON core.customer_credit
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

-- Transaction tables
CREATE TRIGGER trg_transactions_updated_at
BEFORE UPDATE ON core.transactions
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_transaction_items_updated_at
BEFORE UPDATE ON core.transaction_items
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_transaction_payments_updated_at
BEFORE UPDATE ON core.transaction_payments
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_transaction_shipments_updated_at
BEFORE UPDATE ON core.transaction_shipments
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER trg_transaction_returns_updated_at
BEFORE UPDATE ON core.transaction_returns
FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();



USE core;

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
    supp_description TEXT,
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
    expirydate DATE,
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
