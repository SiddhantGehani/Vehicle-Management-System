CREATE DATABASE UsedCarDealership;
USE UsedCarDealership;

CREATE TABLE Vehicle (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    make VARCHAR(50),
    model VARCHAR(50),
    year YEAR,
    mileage INT,
    vehicle_condition VARCHAR(50),  -- Renamed to avoid reserved keyword
    VIN VARCHAR(20) UNIQUE,
    purchase_price DECIMAL(10, 2),
    notes TEXT,
    status VARCHAR(50) DEFAULT 'available'
);

CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    contact_details VARCHAR(255),
    preferences TEXT,
    notes TEXT
);

CREATE TABLE Sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    vehicle_id INT,
    customer_id INT,
    salesperson_id INT,
    sale_price DECIMAL(10, 2),
    payment_method VARCHAR(50),
    trade_in_details TEXT,
    cost_price DECIMAL(10, 2),
    profit DECIMAL(10, 2) AS (sale_price - cost_price) STORED,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

CREATE TABLE Supplier (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    contact_details VARCHAR(255)
);

CREATE TABLE Purchases (
    purchase_id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    vehicle_id INT,
    supplier_id INT,
    purchase_price DECIMAL(10, 2),
    fees DECIMAL(10, 2),
    transaction_cost DECIMAL(10, 2),
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id),
    FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id)
);

CREATE TABLE Financials (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    amount DECIMAL(10, 2),
    type ENUM('revenue', 'expense', 'adjustment'),
    category VARCHAR(100),
    description TEXT,
    related_id INT, -- Optional, links to Sales or Purchases table if related to a specific transaction
    FOREIGN KEY (related_id) REFERENCES Sales(sale_id) -- Adjust as necessary; could also link to Purchases
);


DELIMITER //

CREATE PROCEDURE AddSale(
    IN p_date DATE,
    IN p_vehicle_id INT,
    IN p_customer_id INT,
    IN p_salesperson_id INT,
    IN p_sale_price DECIMAL(10, 2),
    IN p_payment_method VARCHAR(50),
    IN p_cost_price DECIMAL(10, 2)
)
BEGIN
    -- Insert into Sales
    INSERT INTO Sales (date, vehicle_id, customer_id, salesperson_id, sale_price, payment_method, cost_price)
    VALUES (p_date, p_vehicle_id, p_customer_id, p_salesperson_id, p_sale_price, p_payment_method, p_cost_price);

    -- Mark vehicle as sold
    UPDATE Vehicle SET status = 'sold' WHERE vehicle_id = p_vehicle_id;
END //

CREATE PROCEDURE GenerateMonthlySalesReport()
BEGIN
    SELECT YEAR(date) AS Year, MONTH(date) AS Month, SUM(sale_price) AS Total_Sales, SUM(profit) AS Total_Profit
    FROM Sales
    GROUP BY YEAR(date), MONTH(date);
END //

CREATE TRIGGER AfterSaleInsert
AFTER INSERT ON Sales
FOR EACH ROW
BEGIN
    INSERT INTO Financials (date, amount, type, category, description, related_id)
    VALUES (NEW.date, NEW.sale_price, 'revenue', 'Vehicle Sale', CONCAT('Sale of Vehicle ID ', NEW.vehicle_id), NEW.sale_id);
END //

CREATE TRIGGER AfterPurchaseInsert
AFTER INSERT ON Purchases
FOR EACH ROW
BEGIN
    UPDATE Vehicle SET status = 'available' WHERE vehicle_id = NEW.vehicle_id;
END //

DELIMITER ;

-- Insert sample data into Vehicle table
INSERT INTO Vehicle (make, model, year, mileage, vehicle_condition, VIN, purchase_price, status)
VALUES ('Toyota', 'Camry', 2020, 15000, 'Excellent', '1HGBH41JXMN109186', 19000.00, 'available');

INSERT INTO Vehicle (make, model, year, mileage, vehicle_condition, VIN, purchase_price, status)
VALUES ('Honda', 'Civic', 2022, 5000, 'Good', '2HGFB2F50CH106786', 15000.00, 'available');

-- Insert sample data into Customer table
INSERT INTO Customer (name, contact_details, preferences) 
VALUES ('John Doe', 'john.doe@example.com', 'Prefers SUVs');

-- Insert sample data into Supplier table
INSERT INTO Supplier (name, contact_details) 
VALUES ('ABC Motors', 'contact@abcmotors.com');

-- Insert a sample purchase
INSERT INTO Purchases (date, vehicle_id, supplier_id, purchase_price, fees, transaction_cost) 
VALUES (CURDATE(), 1, 1, 20000.00, 500.00, 100.00);

-- Insert a sample sale using the stored procedure
CALL AddSale(CURDATE(), 1, 1, 101, 22000.00, 'Cash', 20000.00);

-- Insert another purchase
INSERT INTO Purchases (date, vehicle_id, supplier_id, purchase_price, fees, transaction_cost) 
VALUES (CURDATE(), 2, 1, 15000.00, 300.00, 50.00);

-- Insert another sale using the stored procedure
CALL AddSale(CURDATE(), 2, 1, 101, 22000.00, 'Cash', 20000.00);



CREATE USER 'sales_staff_user'@'%' IDENTIFIED BY 'password';
CREATE USER 'financial_team_user'@'%' IDENTIFIED BY 'password';
CREATE USER 'admin_user'@'%' IDENTIFIED BY 'password';

-- Granting permissions
GRANT SELECT, UPDATE ON UsedCarDealership.* TO 'sales_staff_user'@'%';
GRANT SELECT, INSERT, UPDATE ON Financials TO 'financial_team_user'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'admin_user'@'%' WITH GRANT OPTION;

-- Apply changes
FLUSH PRIVILEGES;

SHOW GRANTS FOR 'sales_staff_user'@'%';
SHOW GRANTS FOR 'financial_team_user'@'%';
SHOW GRANTS FOR 'admin_user'@'%';

-- Verify data in tables
SELECT * FROM Vehicle;
SELECT * FROM Customer;
SELECT * FROM Sales;
SELECT * FROM Purchases;
SELECT * FROM Supplier;
SELECT * FROM Financials;

SELECT 
    k.table_name AS 'Table',
    k.column_name AS 'Column',
    k.referenced_table_name AS 'Referenced Table',
    k.referenced_column_name AS 'Referenced Column'
FROM information_schema.key_column_usage k
WHERE k.table_schema = DATABASE()
  AND k.referenced_table_name IS NOT NULL;

CREATE INDEX idx_vehicle_status ON Vehicle(status);
CREATE INDEX idx_sales_date ON Sales(date);

CALL GenerateMonthlySalesReport();
