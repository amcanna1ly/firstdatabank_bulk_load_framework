/* 00_FDB_BulkLoadConfig_Table.sql
   Creates driver/config table for FDB bulk loads
*/

IF OBJECT_ID('dbo.FDB_BulkLoadConfig','U') IS NOT NULL
    DROP TABLE dbo.FDB_BulkLoadConfig;
GO

CREATE TABLE dbo.FDB_BulkLoadConfig (
    ConfigID          int IDENTITY(1,1) PRIMARY KEY,
    IsActive          bit            NOT NULL DEFAULT (1),

    Category          nvarchar(100)  NULL,         -- top-level folder (Counseling Messages, MinMax, etc.)
    RelativePath      nvarchar(400)  NOT NULL,     -- path under "NDDF Plus DB\NDDF Plus DB\"
    FileName          nvarchar(255)  NOT NULL,     -- file name only

    TargetSchema      sysname        NOT NULL DEFAULT 'dbo',
    TargetTable       sysname        NOT NULL,     -- usually same as FileName

    FieldTerminator   nvarchar(50)   NOT NULL DEFAULT N'|',
    RowTerminator     nvarchar(50)   NOT NULL DEFAULT N'\n'
);
GO
