-- Creación base de datos
-- Creamos el esquema de las tablas
CREATE DATABASE IF NOT EXISTS sales;
USE sales;

-- Creamos las tbalas
CREATE TABLE IF NOT EXISTS credit_cards (
	id VARCHAR(20) PRIMARY KEY,
    user_id INT NOT NULL,
    iban VARCHAR(50) UNIQUE NOT NULL,
    pan VARCHAR(50) UNIQUE NOT NULL,
    pin VARCHAR(50) NOT NULL,
    cvv INT NOT NULL,
    track1 VARCHAR(50),
    track2 VARCHAR(50),
    expiring_date VARCHAR(10) NOT NULL);
    
CREATE TABLE IF NOT EXISTS companies (
	company_id VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(50),
    country VARCHAR(20),
    website VARCHAR(100));
    
CREATE TABLE IF NOT EXISTS users (
	id INT PRIMARY KEY,
    name VARCHAR(50),
    surname VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(255),
    birth_date VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(50),
    adress VARCHAR(255));
    
CREATE TABLE IF NOT EXISTS transactions (
	id VARCHAR(100) PRIMARY KEY,
    card_id VARCHAR(20) NOT NULL,
    business_id VARCHAR(20) NOT NULL,
    timestamp TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    declined boolean,
    product_ids VARCHAR(50) NOT NULL,
    user_id INT NOT NULL,
    lat FLOAT,
    longitude FLOAT);
    
-- Comprobamos y habilitamos la inserción de archivos locales
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = TRUE;

-- Insertamos de datos
LOAD DATA LOCAL INFILE 'C:/Users/Nicola Korff/Desktop/SQL/da/sprint_04/credit_cards.csv' 
INTO TABLE credit_cards 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

SELECT * FROM credit_cards;

LOAD DATA LOCAL INFILE 'C:/Users/Nicola Korff/Desktop/SQL/da/sprint_04/companies.csv' 
INTO TABLE companies 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

SELECT * FROM companies;

LOAD DATA LOCAL INFILE 'C:/Users/Nicola Korff/Desktop/SQL/da/sprint_04/users_ca.csv' 
INTO TABLE users 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/Nicola Korff/Desktop/SQL/da/sprint_04/users_uk.csv' 
INTO TABLE users 
FIELDS TERMINATED BY ','
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/Nicola Korff/Desktop/SQL/da/sprint_04/users_usa.csv' 
INTO TABLE users 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

SELECT * FROM users;

LOAD DATA LOCAL INFILE 'C:/Users/Nicola Korff/Desktop/SQL/da/sprint_04/transactions.csv' 
INTO TABLE transactions 
FIELDS TERMINATED BY ';'
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

SELECT * FROM transactions;

-- Cambios en las tablas
-- Eliminamos id_user de la tabla credit_cards
ALTER TABLE credit_cards DROP COLUMN user_id;

-- Modificamos el tipo de dato de la columna expiring_date:
ALTER TABLE credit_cards ADD COLUMN expiring_date_temp DATE; 
UPDATE credit_cards SET expiring_date_temp = STR_TO_DATE(expiring_date, '%m/%d/%y');
ALTER TABLE credit_cards DROP expiring_date;
ALTER TABLE credit_cards CHANGE expiring_date_temp expiring_date DATE NOT NULL;

SHOW COLUMNS FROM credit_cards;

-- En user modificamos el tipo de datos de la columna birth_date: 
ALTER TABLE users ADD COLUMN birth_date_temp DATE; 
UPDATE users SET birth_date_temp = STR_TO_DATE(birth_date, '%b %d, %Y');
ALTER TABLE users DROP birth_date;
ALTER TABLE users CHANGE birth_date_temp birth_date DATE NOT NULL;

SHOW COLUMNS FROM users;

-- Comprobamos que todo se ha creado correctamente
SHOW TABLES FROM sales;

SHOW COLUMNS FROM credit_cards;
SHOW COLUMNS FROM companies;
SHOW COLUMNS FROM users;
SHOW COLUMNS FROM transactions;

-- Creamos las relaciones de Foreign keys entre las tablas
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_credit_cards FOREIGN KEY (card_id) REFERENCES credit_cards (id),
ADD CONSTRAINT fk_transactions_companies FOREIGN KEY (business_id) REFERENCES companies (company_id),
ADD CONSTRAINT fk_transactions_users FOREIGN KEY (user_id) REFERENCES users (id);

-- Comprobamos que se han creado correctamente
SHOW INDEXES FROM transactions;


-- Creamos un tabla que muestre el estado de las tarjetas de credito dependiendo si han sido declinadas sus ultimas 3 transacciones
CREATE TABLE credit_status (
    card_id VARCHAR(20) PRIMARY KEY,
    status ENUM('activa', 'bloqueada') NOT NULL);
   
   -- Comprobamos que se ha creado correctamente
    SHOW TABLES FROM sales;

-- Insertar en la tabla los datos filtrados
INSERT INTO credit_status (card_id, status)
SELECT card_id,
CASE WHEN sum(declined) < 3
	THEN 'activa'
    ELSE 'bloqueada'
END AS status
FROM (SELECT transactions.card_id, transactions.timestamp, declined,
	DENSE_RANK() OVER (PARTITION BY transactions.card_id
					  ORDER BY transactions.timestamp DESC) AS rango 
FROM transactions) AS consulta_rango
WHERE rango <= 3
GROUP BY card_id
ORDER BY card_id;

SELECT * FROM credit_status;
Select COUNT(id) FROM credit_cards; # para mostrar la cantidad de credit_cards que hay

-- Añadimos el Foreign Key
ALTER TABLE credit_status
ADD CONSTRAINT fk_credit_status_credit_cards FOREIGN KEY (card_id) REFERENCES credit_cards (id);

SHOW INDEXES FROM credit_status;


-- Crea una tabla intermedia para poder crear, insertar y relacionar la tabla products teniendo en cuenta que transactions tiene varios productos en un mismo campo
-- Primero crearemos la tabla products:
CREATE TABLE IF NOT EXISTS products (
	id INT PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    price VARCHAR(10) NOT NULL,
    color VARCHAR(20),
    weight FLOAT,
    warehouse_id VARCHAR(10));

-- Insertamos los datos en la tabla products:
LOAD DATA LOCAL INFILE 'C:/Users/Nicola Korff/Desktop/SQL/da/sprint_04/products.csv' 
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM products;

-- comprobamos que se ha creado correctamente
SHOW TABLES FROM sales;
SHOW COLUMNS FROM products;

-- Cambios en la tabla:
-- En la columna price separamos el simbolo de dolar a una nueva columna denominada currency:
ALTER TABLE products ADD COLUMN currency VARCHAR(1); 
UPDATE products 
SET currency = LEFT(price, 1),
    price = CAST(SUBSTRING(price, 2) AS DECIMAL(10,2));
    
-- Comprobamos como ha quedado:
SELECT * FROM products;

-- Creamos la tabla intermedia a la que denominamos orders a partir de las columnas id y product_ids de transactions:
CREATE TABLE orders SELECT id, product_ids FROM transactions;

SELECT * FROM orders;


-- creamos la tabla temporal:
CREATE TABLE temp_orders (
	id VARCHAR (100),
	product_id1 INT,
	product_id2 INT,
	product_id3 INT,
   	product_id4 INT);

-- insertamos los productos_id de la tabla
INSERT INTO temp_orders (id, product_id1, product_id2, product_id3, product_id4)
SELECT id,
    CAST(NULLIF(SUBSTRING_INDEX(product_ids, ',', 1), '') AS UNSIGNED) AS product_id1,
    CAST(NULLIF(IF(LENGTH(product_ids) - LENGTH(REPLACE(product_ids, ',', '')) >= 1, 
           SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ',', 2), ',', -1), NULL), '') 
           AS UNSIGNED) AS product_id2,
    CAST(NULLIF(IF(LENGTH(product_ids) - LENGTH(REPLACE(product_ids, ',', '')) >= 2, 
           SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ',', 3), ',', -1), NULL), '') 
           AS UNSIGNED) AS product_id3,
    CAST(NULLIF(IF(LENGTH(product_ids) - LENGTH(REPLACE(product_ids, ',', '')) >= 3, 
           SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ',', 4), ',', -1), NULL), '') 
           AS UNSIGNED) AS product_id4
FROM orders;

SELECT * FROM temp_orders;

-- Una vez resuelta la separación de los valores, traspasamos los datos de la tabla temp_orders a  trasp_order respetando sus ids. 
-- Creamo una tabla auxiliar a la que denominamos trasp_order para traspasar los valores:
CREATE TABLE trasp_order (
	id VARCHAR(100),
    product_id INT);

-- Insertamos los valores:
INSERT INTO trasp_order (id, product_id)
SELECT id, product_id1 
FROM temp_orders
WHERE product_id1 IS NOT NULL 
UNION ALL
SELECT id, product_id2 
FROM temp_orders 
WHERE product_id2 IS NOT NULL
UNION ALL
SELECT id, product_id3 
FROM temp_orders
WHERE product_id3 IS NOT NULL
UNION ALL
SELECT id, product_id4 
FROM temp_orders
WHERE product_id4 IS NOT NULL;

SELECT * FROM trasp_order;

-- Borrar la tabla original "orders" la cual será reemplazada con "trasp_order"
DROP table orders;

-- Renombrar la tabla "trasp_order" a su valor final "orders".
ALTER TABLE trasp_order RENAME orders;

-- Borrar tabla temporal "temp_orders"
DROP TABLE temp_orders;

-- Comprobamos como han quedado las columnas en la tabla:
SHOW TABLES FROM sales;

SELECT * FROM orders ORDER BY id;

-- Añadimos los Foreign Key
-- Tabla orders
-- Creamos un índice de id en orders para vincular con la Foreign Key de la tabla transactions.
ALTER TABLE orders
ADD CONSTRAINT fk_orders_products FOREIGN KEY (product_id) REFERENCES products (id),
ADD CONSTRAINT fk_orders_transactions FOREIGN KEY (id) REFERENCES transactions (id);

-- Comprobamos
SHOW INDEXES FROM orders;





    











