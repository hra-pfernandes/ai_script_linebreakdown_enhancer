-- SQL Server Database Setup for Claude SQL Patch Pipeline
-- Database: Automation (VM-WT-DEV)
-- Authentication: Windows Authentication

USE [Automation];
GO

-- =====================================================
-- DROP TABLES (in reverse order due to foreign keys)
-- =====================================================
IF OBJECT_ID('dbo.SQL_Processing_Edits', 'U') IS NOT NULL
    DROP TABLE dbo.SQL_Processing_Edits;

IF OBJECT_ID('dbo.SQL_Processing_Files', 'U') IS NOT NULL
    DROP TABLE dbo.SQL_Processing_Files;

IF OBJECT_ID('dbo.SQL_Processing_Sessions', 'U') IS NOT NULL
    DROP TABLE dbo.SQL_Processing_Sessions;

-- =====================================================
-- CREATE TABLES
-- =====================================================

-- 1. SESSIONS TABLE - Track each batch processing run
CREATE TABLE dbo.SQL_Processing_Sessions (
    session_id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    start_time          DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    end_time            DATETIME2(3) NULL,
    script_version      NVARCHAR(50) NOT NULL,
    reference_file      NVARCHAR(255) NOT NULL,
    approach            NVARCHAR(100) NOT NULL,
    status              NVARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    total_files         INT NOT NULL DEFAULT 0,
    files_successful    INT NOT NULL DEFAULT 0,
    files_failed        INT NOT NULL DEFAULT 0,
    total_edits         INT NOT NULL DEFAULT 0,
    total_successful_edits INT NOT NULL DEFAULT 0,
    total_cost          DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
    total_savings       DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
    total_processing_seconds DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_by          NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    created_date        DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    modified_date       DATETIME2(3) NOT NULL DEFAULT GETDATE()
);

-- 2. FILES TABLE - Track each SQL file processed
CREATE TABLE dbo.SQL_Processing_Files (
    file_id             UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    session_id          UNIQUEIDENTIFIER NOT NULL,
    filename            NVARCHAR(255) NOT NULL,
    input_file_path     NVARCHAR(500) NOT NULL,
    output_file_path    NVARCHAR(500) NULL,
    file_size_bytes     BIGINT NULL,
    status              NVARCHAR(20) NOT NULL DEFAULT 'PROCESSING',
    start_time          DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    end_time            DATETIME2(3) NULL,
    edits_found         INT NOT NULL DEFAULT 0,
    edits_applied       INT NOT NULL DEFAULT 0,
    cost                DECIMAL(8,4) NOT NULL DEFAULT 0.0000,
    processing_seconds  DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    error_message       NVARCHAR(MAX) NULL,
    created_date        DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    modified_date       DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Files_Sessions 
        FOREIGN KEY (session_id) REFERENCES dbo.SQL_Processing_Sessions(session_id)
        ON DELETE CASCADE
);

-- 3. EDITS TABLE - Store complete edit details including full text
CREATE TABLE dbo.SQL_Processing_Edits (
    edit_id             UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    file_id             UNIQUEIDENTIFIER NOT NULL,
    edit_number         INT NOT NULL,
    timestamp           DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    description         NVARCHAR(1000) NOT NULL,
    position            INT NULL,
    match_type          NVARCHAR(20) NULL,
    success             BIT NOT NULL DEFAULT 0,
    old_snippet_full_text NVARCHAR(MAX) NULL,
    new_snippet_full_text NVARCHAR(MAX) NULL,
    snippet_old_length  INT NOT NULL DEFAULT 0,
    snippet_new_length  INT NOT NULL DEFAULT 0,
    lines_added         INT NOT NULL DEFAULT 0,
    characters_added    INT NOT NULL DEFAULT 0,
    processing_seconds  DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    error_message       NVARCHAR(MAX) NULL,
    created_date        DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Edits_Files 
        FOREIGN KEY (file_id) REFERENCES dbo.SQL_Processing_Files(file_id)
        ON DELETE CASCADE
);

-- =====================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Sessions indexes
CREATE INDEX IX_SQL_Processing_Sessions_StartTime 
    ON dbo.SQL_Processing_Sessions (start_time DESC);
CREATE INDEX IX_SQL_Processing_Sessions_Status 
    ON dbo.SQL_Processing_Sessions (status);
CREATE INDEX IX_SQL_Processing_Sessions_ScriptVersion 
    ON dbo.SQL_Processing_Sessions (script_version);

-- Files indexes
CREATE INDEX IX_SQL_Processing_Files_SessionId 
    ON dbo.SQL_Processing_Files (session_id);
CREATE INDEX IX_SQL_Processing_Files_Status 
    ON dbo.SQL_Processing_Files (status);
CREATE INDEX IX_SQL_Processing_Files_Filename 
    ON dbo.SQL_Processing_Files (filename);
CREATE INDEX IX_SQL_Processing_Files_StartTime 
    ON dbo.SQL_Processing_Files (start_time DESC);

-- Edits indexes
CREATE INDEX IX_SQL_Processing_Edits_FileId 
    ON dbo.SQL_Processing_Edits (file_id);
CREATE INDEX IX_SQL_Processing_Edits_Success 
    ON dbo.SQL_Processing_Edits (success);
CREATE INDEX IX_SQL_Processing_Edits_EditNumber 
    ON dbo.SQL_Processing_Edits (file_id, edit_number);
CREATE INDEX IX_SQL_Processing_Edits_Timestamp 
    ON dbo.SQL_Processing_Edits (timestamp DESC);

-- =====================================================
-- CREATE VIEWS FOR COMMON QUERIES
-- =====================================================
GO

-- Session Summary View
CREATE VIEW dbo.vw_SQL_Processing_Session_Summary AS
SELECT 
    s.session_id,
    s.start_time,
    s.end_time,
    s.script_version,
    s.status,
    s.total_files,
    s.files_successful,
    s.files_failed,
    CASE 
        WHEN s.total_files > 0 THEN CAST((s.files_successful * 100.0 / s.total_files) AS DECIMAL(5,2))
        ELSE 0 
    END AS success_rate_percent,
    s.total_edits,
    s.total_successful_edits,
    CASE 
        WHEN s.total_edits > 0 THEN CAST((s.total_successful_edits * 100.0 / s.total_edits) AS DECIMAL(5,2))
        ELSE 0 
    END AS edit_success_rate_percent,
    s.total_cost,
    s.total_savings,
    s.total_processing_seconds,
    CASE 
        WHEN s.total_files > 0 THEN CAST((s.total_processing_seconds / s.total_files) AS DECIMAL(8,2))
        ELSE 0 
    END AS avg_seconds_per_file
FROM dbo.SQL_Processing_Sessions s;
GO

-- File Details View
CREATE VIEW dbo.vw_SQL_Processing_File_Details AS
SELECT 
    f.file_id,
    f.session_id,
    s.start_time AS session_start,
    f.filename,
    f.status,
    f.edits_found,
    f.edits_applied,
    CASE 
        WHEN f.edits_found > 0 THEN CAST((f.edits_applied * 100.0 / f.edits_found) AS DECIMAL(5,2))
        ELSE 0 
    END AS edit_success_rate_percent,
    f.cost,
    f.processing_seconds,
    f.start_time,
    f.end_time,
    f.error_message,
    s.script_version
FROM dbo.SQL_Processing_Files f
INNER JOIN dbo.SQL_Processing_Sessions s ON f.session_id = s.session_id;
GO

-- Recent Activity View (Last 30 days)
CREATE VIEW dbo.vw_SQL_Processing_Recent_Activity AS
SELECT 
    s.session_id,
    s.start_time,
    s.script_version,
    s.status AS session_status,
    s.total_files,
    s.files_successful,
    s.files_failed,
    s.total_cost,
    COUNT(f.file_id) AS files_in_db,
    SUM(CASE WHEN f.status = 'SUCCESS' THEN 1 ELSE 0 END) AS files_successful_detail,
    SUM(CASE WHEN f.status = 'FAILED' THEN 1 ELSE 0 END) AS files_failed_detail
FROM dbo.SQL_Processing_Sessions s
LEFT JOIN dbo.SQL_Processing_Files f ON s.session_id = f.session_id
WHERE s.start_time >= DATEADD(DAY, -30, GETDATE())
GROUP BY s.session_id, s.start_time, s.script_version, s.status, 
         s.total_files, s.files_successful, s.files_failed, s.total_cost;
GO

-- =====================================================
-- PERMISSIONS (Adjust as needed for your environment)
-- =====================================================

-- Grant permissions to appropriate users/roles
-- GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.SQL_Processing_Sessions TO [YourAppRole];
-- GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.SQL_Processing_Files TO [YourAppRole];
-- GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.SQL_Processing_Edits TO [YourAppRole];
-- GRANT SELECT ON dbo.vw_SQL_Processing_Session_Summary TO [YourReportingRole];
-- GRANT SELECT ON dbo.vw_SQL_Processing_File_Details TO [YourReportingRole];
-- GRANT SELECT ON dbo.vw_SQL_Processing_Recent_Activity TO [YourReportingRole];

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify tables were created
SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name LIKE 'SQL_Processing_%'
ORDER BY t.name, c.column_id;

-- Verify indexes were created
SELECT 
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name LIKE 'SQL_Processing_%'
    AND i.name IS NOT NULL
ORDER BY t.name, i.name;

-- Verify views were created
SELECT name AS view_name
FROM sys.views
WHERE name LIKE 'vw_SQL_Processing_%'
ORDER BY name;

PRINT 'Database setup completed successfully!';
PRINT 'Tables created: SQL_Processing_Sessions, SQL_Processing_Files, SQL_Processing_Edits';
PRINT 'Views created: vw_SQL_Processing_Session_Summary, vw_SQL_Processing_File_Details, vw_SQL_Processing_Recent_Activity';