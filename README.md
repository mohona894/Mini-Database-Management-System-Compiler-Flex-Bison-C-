# Mini-Database-Management-System-Compiler-Flex-Bison-C
A **mini SQL compiler and in-memory database engine** built using **Lex/Flex** and **Yacc/Bison** with **C**.
The project parses a subset of SQL syntax, generates tokens through lexical analysis, validates grammar using parsing rules, and executes commands on a custom in-memory database.

This project demonstrates the practical implementation of **Compiler Design concepts** applied to **Database Management System operations**.

## Project Overview
The system acts like a tiny DBMS that understands SQL-like commands such as:
* `CREATE DATABASE`
* `CREATE TABLE`
* `INSERT`
* `SELECT`
* `UPDATE`
* `DELETE`
* `JOIN (LEFT / RIGHT)`
* `COUNT / SUM / AVG`
* Conditional `WHERE` with `AND / OR`

Instead of using MySQL or any real DB, the data is stored and managed in **memory structures (arrays of structs)**, making it a true **compiler + execution engine** project.

## System Architecture

| Phase            | Tool          | Responsibility                                           |
| ---------------- | ------------- | -------------------------------------------------------- |
| Lexical Analysis | Flex          | Tokenizes SQL keywords, identifiers, literals, operators |
| Syntax Analysis  | Bison         | Validates grammar and builds parsing rules               |
| Execution Engine | C             | Performs DB operations using in-memory tables            |
| Storage          | Struct Arrays | Simulated tables, columns, and rows                      |

## Supported SQL Features

### Database & Table
* Create database
* Create table with columns and data types
* Drop table

### Data Manipulation
* Insert rows
* Update rows with conditions
* Delete rows with conditions

### Data Query
* Select all records
* Select with `WHERE` using `AND / OR`
* Aggregate functions: `COUNT`, `SUM`, `AVG`
* `LEFT JOIN` and `RIGHT JOIN`

### Data Types
* `INT`
* `FLOAT`
* `VARCHAR`

## Compiler Concepts Demonstrated
* Token definition using regular expressions (Flex)
* Grammar rules and parsing tree logic (Bison)
* Semantic actions for execution
* Symbol handling using `yylval`
* Error handling with `yyerror`
* Integration of lexer and parser

## In-Memory Storage Design
The database engine uses C structures:
* Tables
* Columns
* Rows
All records are stored in fixed-size arrays, simulating how a DB engine internally manages data.

## ⚙️ How to Build & Run

### Generate Lexer and Parser
flex db_lexer.l
bison -d db_parser.y
gcc lex.yy.c db_parser.tab.c -o mini_db

### Run the Program
./mini_db

Then write SQL-like commands in the terminal.
## Example Commands
sql
CREATE DATABASE test;
CREATE TABLE students (id INT, name VARCHAR, cgpa FLOAT);
INSERT INTO students VALUES (1, 'Asha', 3.75);
SELECT * FROM students;

## Learning Outcomes
* Practical understanding of **Compiler Design**
* How SQL is parsed and executed internally
* Building a mini DB engine without external libraries
* Integration of Flex, Bison, and C
* Implementing joins and aggregates programmatically

## 👩‍💻 Author
**Nahida Akter Mohona**



