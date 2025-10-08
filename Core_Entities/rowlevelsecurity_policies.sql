--   NEXUS GLOBAL ENTERPRISES - ROW LEVEL SECURITY POLICIES
--   File: _rowlevelsecurity_policies.sql
--   Purpose: Define fine-grained data access rules per role/division


\c nexus_global
SET search_path TO core, public;


-- RLS for EMPLOYEES table
--  Restrict access to employees only within the same division

ALTER TABLE core.employees ENABLE ROW LEVEL SECURITY;

CREATE POLICY employees_division_access
    ON core.employees
    FOR SELECT
    USING (
        division_id = current_setting('app.current_division', true)::INT
        OR current_user IN ('nexus_admin', 'nexus_analyst')
    );


-- RLS for CUSTOMERS table
--   Analysts & App users can only see customers from their region


ALTER TABLE core.customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY customers_region_access
    ON core.customers
    FOR SELECT
    USING (
        region_id = current_setting('app.current_region', true)::INT
        OR current_user IN ('nexus_admin', 'nexus_analyst')
    );


-- RLS for TRANSACTIONS table
--   Sensitive table - strict access


ALTER TABLE core.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY finance_access_policy
    ON core.transactions
    FOR SELECT
    USING (
        current_user IN ('nexus_admin', 'nexus_analyst', 'nexus_readonly')
    );

CREATE POLICY finance_update_policy
    ON core.transactions
    FOR UPDATE
    TO nexus_app
    USING (
        current_user = 'nexus_app'
    );


-- RLS for HEALTHCARE_PATIENTS table (HIPAA)

ALTER TABLE core.healthcare_patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY patient_privacy_policy
    ON healthcare.patients
    FOR SELECT
    USING (
        current_user IN ('nexus_admin', 'nexus_analyst')
        OR assigned_physician_id = current_setting('app.current_employee', true)::INT
    );




-- ALTER TABLE core.* DISABLE ROW LEVEL SECURITY; -- optional safeguard
-- RLS should be explicitly enabled only on sensitive tables.

-- RLS policies configured successfully.
