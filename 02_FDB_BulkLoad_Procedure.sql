/* 01_FDB_BulkLoad_Procedure.sql
   Uses FDB_BulkLoadConfig to BULK INSERT all active files
   for a given drop folder. Optional @Category to restrict load.
*/

IF OBJECT_ID('dbo.usp_FDB_BulkLoad','P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FDB_BulkLoad;
GO

CREATE PROCEDURE dbo.usp_FDB_BulkLoad
    @DropFolderName nvarchar(255),          -- e.g. '05NOV2025.TEL253540D'
    @Category       nvarchar(100) = NULL    -- e.g. 'Counseling Messages'; NULL = all
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @RootPath        nvarchar(4000),
        @FullPath        nvarchar(4000),
        @Sql             nvarchar(max),
        @RelativePath    nvarchar(400),
        @FileName        nvarchar(255),
        @TargetSchema    sysname,
        @TargetTable     sysname,
        @FieldTerminator nvarchar(50),
        @RowTerminator   nvarchar(50);

    -- Base path that changes per drop
    SET @RootPath = 
          N'G:\backups\FDB Staging\'
        + @DropFolderName
        + N'\NDDF Plus DB\NDDF Plus DB\';

    DECLARE curFDB CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            RelativePath,
            FileName,
            TargetSchema,
            TargetTable,
            FieldTerminator,
            RowTerminator
        FROM dbo.FDB_BulkLoadConfig
        WHERE IsActive = 1
          AND (@Category IS NULL OR Category = @Category);

    OPEN curFDB;

    FETCH NEXT FROM curFDB INTO
        @RelativePath,
        @FileName,
        @TargetSchema,
        @TargetTable,
        @FieldTerminator,
        @RowTerminator;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Ensure RelativePath ends with a backslash
        IF RIGHT(@RelativePath,1) NOT IN ('\','/')
            SET @RelativePath = @RelativePath + N'\';

        SET @FullPath = @RootPath + @RelativePath + @FileName;

        SET @Sql = N'
BULK INSERT ' + QUOTENAME(@TargetSchema) + N'.' + QUOTENAME(@TargetTable) + N'
FROM ''' + @FullPath + N'''
WITH (
    FIELDTERMINATOR = ''' + @FieldTerminator + N''',
    ROWTERMINATOR   = ''' + @RowTerminator   + N'''
);';

        PRINT 'Running: ' + @FullPath + ' -> ' 
              + @TargetSchema + '.' + @TargetTable;

        EXEC sys.sp_executesql @Sql;

        FETCH NEXT FROM curFDB INTO
            @RelativePath,
            @FileName,
            @TargetSchema,
            @TargetTable,
            @FieldTerminator,
            @RowTerminator;
    END

    CLOSE curFDB;
    DEALLOCATE curFDB;
END;
GO
