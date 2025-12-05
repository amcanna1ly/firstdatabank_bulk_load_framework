/* 02_FDB_Scan_Directories_Preview.sql
   Scans all known FDB folders and lists files found, without inserting.
   Change @DropFolderName if you point at a different sample drop.
*/

DECLARE @DropFolderName nvarchar(255) = N'05NOV2025.TEL253540D';

DECLARE @BaseRoot nvarchar(4000) = 
      N'G:\backups\FDB Staging\'
    + @DropFolderName
    + N'\NDDF Plus DB\NDDF Plus DB\';

PRINT 'Scanning base root: ' + @BaseRoot;

CREATE TABLE #DirRoots (
    Category     nvarchar(100),
    RelativePath nvarchar(400)
);

INSERT INTO #DirRoots (Category, RelativePath)
VALUES
    (N'Counseling Messages',        N'Counseling Messages\CMM 1.0\'),
    (N'Drug Allergy',               N'Drug Allergy\DAM 4.0\'),
    (N'Drug-Drug Interaction',      N'Drug-Drug Interaction\DDIM 3.3\'),
    (N'Drug-Food Interaction',      N'Drug-Food Interaction\DFIM 1.0\'),
    (N'Drug-Lab Interference',      N'Drug-Lab Interference\DLIM 2.0\'),
    (N'Duplicate Therapy',          N'Duplicate Therapy\DPT 1.0\'),
    (N'Introp',                     N'Introp\INTROP 1.0\'),

    (N'MinMax',                     N'MinMax\MINMAX 2.1\MinMax Adult Daily Dose\'),
    (N'MinMax',                     N'MinMax\MINMAX 2.1\MinMax Adult Daily Range\'),
    (N'MinMax',                     N'MinMax\MINMAX 2.1\MinMax Geriatric Daily Dose\'),
    (N'MinMax',                     N'MinMax\MINMAX 2.1\MinMax Geriatric Daily Range\'),
    (N'MinMax',                     N'MinMax\MINMAX 2.1\Pediatric Dosing\'),

    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\NDDF BASICS 3.0\Generic Formulation and Ingredient\'),
    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\NDDF BASICS 3.0\Miscellaneous Therapeutic Class\'),
    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\NDDF BASICS 3.0\Packaged Product\'),
    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\NDDF BASICS 3.0\Pricing\'),
    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\NDDF ETC 1.0\'),
    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\NDDF MEDNAMES 3.0\'),
    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\NDDF MTL 1.0\'),
    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\NDDF XRF 1.0\'),
    (N'NDDF Descriptive and Pricing', N'NDDF Descriptive and Pricing\TALL MAN PLUS 2.0\'),

    (N'Patient Education',          N'Patient Education\PEM 2.0\'),
    (N'Prioritized Label Warnings', N'Prioritized Label Warnings\LBLW 1.0\'),
    (N'Rxnorm',                     N'Rxnorm\RXNORM 1.0\');

CREATE TABLE #Files (
    Category     nvarchar(100),
    RelativePath nvarchar(400),
    FileName     nvarchar(512)
);

DECLARE 
    @Category     nvarchar(100),
    @RelPath      nvarchar(400),
    @ScanPath     nvarchar(4000);

DECLARE curRoots CURSOR LOCAL FAST_FORWARD FOR
    SELECT Category, RelativePath
    FROM #DirRoots;

OPEN curRoots;

FETCH NEXT FROM curRoots INTO @Category, @RelPath;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @ScanPath = @BaseRoot + @RelPath;

    PRINT 'Scanning: ' + @ScanPath;

    CREATE TABLE #DirTree (
        Subdirectory nvarchar(512),
        Depth        int,
        FileFlag     int
    );

    INSERT INTO #DirTree (Subdirectory, Depth, FileFlag)
    EXEC master.sys.xp_dirtree @ScanPath, 1, 1;  -- depth 1, include files

    INSERT INTO #Files (Category, RelativePath, FileName)
    SELECT @Category, @RelPath, Subdirectory
    FROM #DirTree
    WHERE FileFlag = 1;

    DROP TABLE #DirTree;

    FETCH NEXT FROM curRoots INTO @Category, @RelPath;
END

CLOSE curRoots;
DEALLOCATE curRoots;

SELECT Category, RelativePath, FileName
FROM #Files
ORDER BY Category, RelativePath, FileName;
GO
