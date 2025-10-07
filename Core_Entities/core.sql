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
