# DatabaseManagementMysql

- Database design: Planning the structure, tables, fields, and relationships between them.
- Database creation: Implementing the design using a database management system (DBMS).
- Data manipulation: Inserting, updating, deleting, and querying data using Structured Query Language (SQL) with MySQL.
- Database administration: Performing maintenance, backups, optimization, and security tasks.

## Database description:
This (sweet, cute, miny tiny, little thing) is a relational database structured in a dimensional snowflake schema with the 'transactions' table as the fact table and the 'users', 'credit_card', 'card_status', 'products', 'orders' and 'companies' tables as dimension tables that are related to the fact table 1 to N. 
Necessary modifications were made to optimize and organize the database.
To integrate the data from products.csv into the database and relate it to transactions.product_ids, we needed an intermediate table to manage the relationship between transactions and products, since product_ids can contain multiple values ​​per transaction in the same field.
We have also created an extra table to reflect the status of credit_cards eather active or blocked based on whether the last 3 transactions have been declined or not.

![sales_EER_diagram](https://github.com/user-attachments/assets/bb2adef5-4422-44fd-9ff4-dacc6a28abf5)
