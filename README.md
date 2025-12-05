# firstdatabank_bulk_load_framework
Dynamic SQL Server bulk-load framework for FDB NDDF data using a driver table and directory scanning.

# FDB Bulk Load Framework for SQL Server

This repository provides a dynamic, automated bulk-load framework for loading First Databank (FDB) NDDF flat files into SQL Server. It eliminates the need to manually maintain or modify hundreds of `BULK INSERT` statements for each new FDB drop by using:

- A driver configuration table
- A dynamic bulk-load stored procedure
- Optional directory scanning using `xp_dirtree`
- Optional schema fix scripts for known vendor quirks

This framework makes FDB loading repeatable, maintainable, and drop-agnostic.

## Features

- **Dynamic BULK INSERT generation**  
  File paths are generated programmatically from configuration values.

- **Driver-table controlled**  
  Each file maps to its category, relative path, file name, and target table.

- **Load entire dataset or a single category**  
  Useful when troubleshooting or testing specific sections of the NDDF package.

- **Safe config re-runs**  
  The configuration insert script uses `NOT EXISTS`, preventing duplicates.

- **Schema fix support**  
  A dedicated script contains column adjustments for known FDB anomalies.

## Repository Structure

```
fdb-bulk-load-framework/
├─ README.md
├─ sql/
│  ├─ 01_FDB_BulkLoadConfig_Table.sql
│  ├─ 02_FDB_BulkLoad_Procedure.sql
│  ├─ 03_FDB_Scan_Directories_Preview.sql
│  ├─ 04_FDB_Insert_Config_From_Directories.sql
│  ├─ 05_sp_FDB_BulkLoad.sql
└─ docs/
   └─ FDB_Bulk_Load_Documentation.docx
```

## Script Overview

### 01_FDB_BulkLoadConfig_Table.sql

Creates the driver table:

```sql
CREATE TABLE dbo.FDB_BulkLoadConfig (
    ConfigID      int IDENTITY(1,1) PRIMARY KEY,
    Category      nvarchar(100) NOT NULL,
    RelativePath  nvarchar(500) NOT NULL,
    FileName      nvarchar(200) NOT NULL,
    TargetTable   sysname       NOT NULL,
    IsActive      bit           NOT NULL DEFAULT(1),
    CreatedOn     datetime2     NOT NULL DEFAULT(sysutcdatetime())
);
```

### 02_FDB_BulkLoad_Procedure.sql

Defines the main dynamic-load stored procedure.

Example usage:

```sql
EXEC dbo.usp_FDB_BulkLoad
    @DropFolderName = N'05NOV2025.TEL253540D';
```

Filter to a category:

```sql
EXEC dbo.usp_FDB_BulkLoad
    @DropFolderName = N'05NOV2025.TEL253540D',
    @Category       = N'NDDF Descriptive and Pricing';
```

### 03_FDB_Scan_Directories_Preview.sql

Uses `xp_dirtree` to preview FDB directories and verify SQL Server access.

### 04_FDB_Insert_Config_From_Directories.sql

Automatically populates the driver table with new file entries using `NOT EXISTS` to avoid duplicates.

### 05_FDB_PreLoad_SchemaFixes.sql

Contains known schema adjustments, such as:

```sql
ALTER TABLE dbo.RNDC14_NDC_MSTR ALTER COLUMN DESDTEC   varchar(max);
ALTER TABLE dbo.RNDC14_NDC_MSTR ALTER COLUMN DES2DTEC  varchar(max);
ALTER TABLE dbo.RNDC14_NDC_MSTR ALTER COLUMN HCFA_APPC varchar(max);
ALTER TABLE dbo.RNDC14_NDC_MSTR ALTER COLUMN HCFA_MRKC varchar(max);
```

## Workflow Summary

### One-time Setup
1. Create config table  
2. Create bulk load stored procedure  
3. Run schema fixes  
4. Populate config entries

### For Each New FDB Drop
1. Place drop into base path  
2. Optionally scan directories  
3. Update config table  
4. Run:

```sql
EXEC dbo.usp_FDB_BulkLoad @DropFolderName = 'YOUR_DROP';
```

## Disclaimer

This framework does not include FDB data or schemas. Users must comply with all licensing and security requirements.
