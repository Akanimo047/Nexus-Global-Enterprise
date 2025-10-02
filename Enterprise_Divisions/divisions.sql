CREATE DATABASE if NOT EXISTS nexus_divisions; 
use nexus_divisions;

CREATE SCHEMA IF NOT EXISTS Manufacturing
CREATE Table Manufacturing.Facilities(
    Facility_id  SERIAL primary key, 
    location_id int not null references core.locations(location_id),
    Facility_name Varchar(100) not null,
    Facility_type Varchar(20) Check (Facility_type in ('Assembly', 'Fabrication', 'Packaging', 'Testing','Warehouse', 'Expansion')),
    Capacity_rating Decimal (10,2),
    Capacity_unit Varchar(20),
    certification_iso Varchar(50),
    environmental_rating Varchar(30),
    manager_employee_id int references core.employees(employee_id),
    operational_status varchar(20) check (operational_status in ('Active', 'Maintenance', 'Shutdown')),
    last_inspection_date Date
 );

 CREATE Table Manufacturing.Orders(
 order_id serial primary key,
 order_number varchar(100) unique not null,
 product_id int not null references core.products(product_id),
 Facility_id int not null references Manufacturing.Facilities(Facility_id),
 quantity_ordered decimal (10,3)not null,
 quantity_produced decimal (10,3) default 0,
 quantity_defective decimal(10,3) default 0,
 scheduled_start_date Date,
 scheduled_completion_date Date,
 actual_start_date Timestamp,
 actual_completion_date Timestamp,
 order_status varchar(30) check (order_status in('Scheduled', 'In progress', 'Completed', 'Cancelled')),
 priority_levels varchar(30) check (priority_levels in ('Low', 'Normal', 'High', 'Urgent')),
 supervisor_employee_id int references core.employees(employee_id),
 total_cost decimal (12,2),
 material_cost decimal(12,2),
 labor_cost decimal(12,2),
 overhead_cost decimal(12,2));

 create Table Manufacturing.Production (
Production_id serial primary key,
 order_id int not null references Manufacturing.orders(order_id),
 facility_id int not null references Manufacturing.Facilities(Facility_id),
 product_id int not null references core.products(product_id),
 start_time Timestamp not null,
 end_time Timestamp,
 shift varchar(30) check (shift in ('Day', 'Night', 'Overtime')),
 employees_involved int[],
 quantity_produced decimal(10,3) not null,
 quantity_defective decimal(10,3)default 0,
 remarks Text);

 Create Table Manufacturing.maintenance_records (maintenance_id serial primary key,
 Facility_id int not null references Manufacturing.Facilities(Facility_id),
 equipment_name varchar(100)not null,
 maintenance_type varchar(60) check (maintenance_type in ('Preventive', 'Corrective', 'Inspection', 'Upgrade')),
 performed_by_employee_id int references core. employees(employee_id),
 maintenance_date date not null,
 downtime_hours decimal(10,2),
 notes text);

 create Table Manufacturing.raw_materials_inventory(material_id serial primary key,
 material_name varchar(50) not null,
 supplier_id int not null references core.suppliers(supplier_id),
 quantity_available decimal (12,3) not null,
 unit varchar(20) not null,
 reorder_level decimal (12,3),
 last_restock_date date);


CREATE SCHEMA if NOT EXISTS Retail and E-commerce;

Create TABLE Retail.categories (
category_id serial primary key,
category_name Varchar(50) not null,
parent_category_id int null references Retail.categories(category_id),
descriptions Text,
is_active Boolean Default True);

CREATE TABLE Retail.stores (
store_id Serial primary key,
store_name varchar(50) not null,
location_id int not null references core.location(location_id),
opening_date Date,
manager_name varchar(50),
store_size_sqft int,
contact_number varchar(30)
);

CREATE TABLE Retail.websites (
website_id serial primary key,
domain_name varchar(100) not null,
market_region varchar(50),
launch_date date,
support_email varchar(100),
default_currency varchar(5)
);

CREATE TABLE Retail.products(
product_id serial primary key,
product_name varchar(50) not null,
category_id int not null references Retail.categories(category_id),
supplier_id int not null references core.suppliers(supplier_id),
sku_code varchar(30) unique,
unit_price decimal(12,2) not null,
currency_code char(3),
brand_name varchar(100),
model_number varchar(50),
descriptions text,
weights decimal (12,2),
dimensions varchar(100),
date_added date default current_date,
is_active boolean default True
);

CREATE TABLE Retail.inventory(
inventory_id serial primary key,
product_id int not null references Retail.products(product_id),
store_id int null references Retail.stores(store_id),
website_id int null references Retail.website(website_id),
quantity_available int not null,
reorder_level int,
last_restock_date date,
shelf_location varchar(50),
batch_number varchar(30)
);

CREATE TABLE Retail.orders(
order_id serial primary key,
customer_id int not null references core.customers(customer_id),
order_date Timestamp not null,
store_id int null references Retail.stores(store_id),
website_id int null references Retail.website(website_id),
total_amount decimal(12,2)not null,
currency_code char(3),
order_status varchar(30),
payment_method varchar(40),
shipping_address varchar(100),
billing_address varchar(100),
delivery_date date);

CREATE TABLE Retail.reviews(
review_id serial primary key,
order_id int not null references Retail.orders(order_id),
product_id int not null references Retail.products(product_id),
customer_id int not null references core.customer(customer_id),
rating int check (rating between 1 and 5),
review_text TEXT,
review_date Timestamp,
verified_purchase boolean default True);

CREATE TABLE Retail.promotions(
promotion_id serial primary key,
promotion_name varchar(50) not null,
start_date date not null,
end_date date not null,
discount_percentage decimal(10,2),
category_id int null references Retail.categories(category_id),
product_id int null references Retail.products(product_id),
descriptions text,
promo_code varchar(50),
is_active boolean default True
);
