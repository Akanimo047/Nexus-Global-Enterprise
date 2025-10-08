
--   NEXUS GLOBAL ENTERPRISES - DATABASE INITIALIZATION SCRIPT
--   File: init_nexus.sql
--   Purpose: Initialize base database, roles, and core schema


-- Connect to an existing database first (postgres)
-- \c postgres

-- Create the NEXUS_GLOBAL database

DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'nexus_owner') THEN
        CREATE ROLE nexus_owner LOGIN PASSWORD 'StrongOwnerPasswordHere';
    END IF;
END
$$;


DO
$$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_database WHERE datname = 'nexus_global'
    ) THEN
        CREATE DATABASE nexus_global
        WITH 
            OWNER = nexus_owner
            ENCODING = 'UTF8'
            LC_COLLATE = 'en_US.UTF-8'
            LC_CTYPE = 'en_US.UTF-8'
            TEMPLATE = template0
            CONNECTION LIMIT = -1;
    END IF;
END
$$;



--  Connect to the Nexus Global database
-- \c nexus_global

--   ROLE HIERARCHY

-- Admin Role - Full Control
DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'nexus_admin') THEN
        CREATE ROLE nexus_admin LOGIN PASSWORD 'nexusglobal' INHERIT;
        GRANT nexus_owner TO nexus_admin;
    END IF;
END
$$;

-- Application Role - CRUD operations only
DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'nexus_app') THEN
        CREATE ROLE nexus_app LOGIN PASSWORD 'nexusglobal' INHERIT;
    END IF;
END
$$;

-- Analyst Role - Read-only, can create temp tables
DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'nexus_analyst') THEN
        CREATE ROLE nexus_analyst LOGIN PASSWORD 'nexusglobal' INHERIT;
    END IF;
END
$$;

-- Readonly Role - Strict read-only access
DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'nexus_readonly') THEN
        CREATE ROLE nexus_readonly LOGIN PASSWORD 'nexusglobal' INHERIT;
    END IF;
END
$$;

--   SCHEMA CREATION

-- Core operational schema
CREATE SCHEMA IF NOT EXISTS core;


-- Restrict default access
REVOKE ALL ON DATABASE nexus_global FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;


--   ROLE PRIVILEGES


-- Admins
GRANT ALL PRIVILEGES ON DATABASE nexus_global TO nexus_admin;
GRANT ALL PRIVILEGES ON SCHEMA core TO nexus_admin;

-- App role
GRANT CONNECT ON DATABASE nexus_global TO nexus_app;
GRANT USAGE ON SCHEMA core TO nexus_app;

-- Analysts
GRANT ALL PRIVILEGES ON DATABASE nexus_global TO nexus_analyst;
GRANT ALL PRIVILEGES ON SCHEMA core TO nexus_analyst;

-- Readonly users
GRANT CONNECT ON DATABASE nexus_global TO nexus_readonly;
GRANT USAGE ON SCHEMA core TO nexus_readonly;


--   DEFAULT PRIVILEGES (for new tables)


ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT 
    SELECT ON TABLES TO nexus_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT 
    SELECT, INSERT, UPDATE, DELETE ON TABLES TO nexus_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT 
    ALL ON TABLES TO nexus_admin, nexus_analyst;

ALTER DATABASE nexus_global SET search_path = core, public;

--  Initialization complete.
