# SAP ABAP Portfolio

This repository contains my portfolio of SAP ABAP development projects. These projects demonstrate my proficiency in ABAP programming, including Data Dictionary objects, ALV reports, performance tuning, Dialog Programming, data integration interfaces, and Object-Oriented ABAP.

## Projects Included

### 1. Employee Report Generator (ALV Report)
An end-to-end ABAP report utilizing the ALV Grid (cl_salv_table) to display employee master data.
- Custom Database Table creation in ADT (Data Dictionary)
- Dynamic selection screen for data filtering
- Modern Open SQL integration (ABAP 7.40+)

### 2. Sales Data Analysis (Performance Tuning)
A comparative project demonstrating the impact of proper database query design.
- Multi-table relatioships (Sales Order Header and Item)
- Comparison between nested SELECT statements (anti-pattern) and INNER JOIN
- Focused on minimizing database roundtrips and improving response times

### 3. Employee Data Entry Screen (Dialog Programming)
A complete Module Pool Program for performing CRUD operations on employee data.
- Screen Painter (SE51) design and implementation
- Flow logic involving Process Before Output (PBO) and Process After Input (PAI) modules
- Custom Transaction Code (T-Code) integration
- Simple print-preview simulation using WRITE statements

### 4. Mass Upload Tool and Integration (BDC, RFC, BAPI)
A set of tools for data integration and migration.
- Batch Data Communication (BDC) upload program simulating manual input via CALL TRANSACTION.
- Custom Remote-Enabled Function Module (RFC) for cross-system data retrieval.
- Example program to consume standard SAP BAPI (BAPI_USER_GET_DETAIL).

### 5. Object-Oriented ABAP Refactoring (OO ALV)
Refactoring procedural reports into Object-Oriented paradigms.
- Implementation of Local Classes and Methods.
- Custom Exception handling using TRY/CATCH blocks.
- Transitioning to OO-ALV grids for data display.

## Technologies Used
- SAP ABAP (7.40+)
- ABAP Development Tools (ADT) / Eclipse
- SAP GUI
