# DatabaseManagementMysql

- Database design: Planning the structure, tables, fields, and relationships between them.
- Database creation: Implementing the design using a database management system (DBMS).
- Data manipulation: Inserting, updating, deleting, and querying data using Structured Query Language (SQL) with MySQL.
- Database administration: Performing maintenance, backups, optimization, and security tasks.

## Database description:
Initially, we have 7 tables, but 3 of them can be merged into one, as they are 3 tables with the same user columns for Canadian, US, and UK nationalities.
Therefore, we have 4 tables: companies, users, credit_card, and transactions.
This is a relational database structured in a dimensional star model with the 'transactions' table as the fact table and the 'users,' credit_card, 'products,' and 'companies' tables as dimension tables that are related to the fact table 1 to N. There is also a relationship between the users and credit_cards tables 1 to N, which we consider unnecessary and will delete. We will also make the necessary modifications to optimize and organize the database: changing the birth_date and expiring_date types from VARCHAR to DATE.

![sales_EER_diagram](https://github.com/user-attachments/assets/bb2adef5-4422-44fd-9ff4-dacc6a28abf5)
