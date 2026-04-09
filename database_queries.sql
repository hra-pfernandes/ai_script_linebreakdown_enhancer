-- Useful SQL Queries for Claude SQL Patch Pipeline Monitoring and Reporting
-- Database: Automation (VM-WT-DEV)
-- Tables: SQL_Processing_Sessions, SQL_Processing_Files, SQL_Processing_Edits

-- =====================================================
-- SESSION MONITORING QUERIES
-- =====================================================

-- 1. Recent Processing Sessions (Last 7 days)
SELECT 
    s.session_id,
    s.start_time,
    s.end_time,
    s.script_version,
    s.status,
    s.total_files,
    s.files_successful,
    s.files_failed,
    CAST((s.files_successful * 100.0 / NULLIF(s.total_files, 0)) AS DECIMAL(5,1)) AS success_rate_percent,
    s.total_edits,
    s.total_successful_edits,
    CAST((s.total_successful_edits * 100.0 / NULLIF(s.total_edits, 0)) AS DECIMAL(5,1)) AS edit_success_rate_percent,
    s.total_cost,
    s.total_processing_seconds,
    CAST((s.total_processing_seconds / NULLIF(s.total_files, 0)) AS DECIMAL(8,2)) AS avg_seconds_per_file
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time >= DATEADD(DAY, -7, GETDATE())
ORDER BY s.start_time DESC;

-- 2. Session Performance Summary
SELECT 
    s.script_version,
    COUNT(*) AS total_sessions,
    SUM(s.total_files) AS total_files_processed,
    SUM(s.files_successful) AS total_files_successful,
    SUM(s.files_failed) AS total_files_failed,
    SUM(s.total_edits) AS total_edits,
    SUM(s.total_successful_edits) AS total_successful_edits,
    SUM(s.total_cost) AS total_cost,
    AVG(s.total_processing_seconds) AS avg_session_time,
    CAST(AVG(s.files_successful * 100.0 / NULLIF(s.total_files, 0)) AS DECIMAL(5,1)) AS avg_file_success_rate,
    CAST(AVG(s.total_successful_edits * 100.0 / NULLIF(s.total_edits, 0)) AS DECIMAL(5,1)) AS avg_edit_success_rate
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time >= DATEADD(DAY, -30, GETDATE())
GROUP BY s.script_version
ORDER BY total_sessions DESC;

-- 3. Daily Processing Volume (Last 30 days)
SELECT 
    CAST(s.start_time AS DATE) AS processing_date,
    COUNT(*) AS sessions_count,
    SUM(s.total_files) AS files_processed,
    SUM(s.files_successful) AS files_successful,
    SUM(s.total_edits) AS total_edits,
    SUM(s.total_successful_edits) AS successful_edits,
    SUM(s.total_cost) AS daily_cost,
    SUM(s.total_processing_seconds) / 60.0 AS total_minutes
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(s.start_time AS DATE)
ORDER BY processing_date DESC;

-- =====================================================
-- FILE PROCESSING ANALYSIS
-- =====================================================

-- 4. File Processing Success/Failure Analysis
SELECT 
    f.filename,
    COUNT(*) AS times_processed,
    SUM(CASE WHEN f.status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful_runs,
    SUM(CASE WHEN f.status = 'FAILED' THEN 1 ELSE 0 END) AS failed_runs,
    SUM(CASE WHEN f.status = 'PARTIAL' THEN 1 ELSE 0 END) AS partial_runs,
    AVG(f.edits_found) AS avg_edits_found,
    AVG(f.edits_applied) AS avg_edits_applied,
    AVG(f.cost) AS avg_cost,
    AVG(f.processing_seconds) AS avg_processing_time,
    MAX(f.start_time) AS last_processed
FROM dbo.SQL_Processing_Files f
WHERE f.start_time >= DATEADD(DAY, -30, GETDATE())
GROUP BY f.filename
ORDER BY times_processed DESC, avg_cost DESC;

-- 5. Files with Consistent Processing Issues
SELECT 
    f.filename,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN f.status = 'FAILED' THEN 1 ELSE 0 END) AS failed_attempts,
    CAST((SUM(CASE WHEN f.status = 'FAILED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DECIMAL(5,1)) AS failure_rate,
    STRING_AGG(DISTINCT f.error_message, ' | ') AS common_errors,
    MAX(f.start_time) AS last_attempt
FROM dbo.SQL_Processing_Files f
WHERE f.start_time >= DATEADD(DAY, -30, GETDATE())
GROUP BY f.filename
HAVING SUM(CASE WHEN f.status = 'FAILED' THEN 1 ELSE 0 END) > 0
ORDER BY failure_rate DESC, failed_attempts DESC;

-- 6. File Size vs Processing Time Analysis
SELECT 
    CASE 
        WHEN f.file_size_bytes < 50000 THEN 'Small (<50KB)'
        WHEN f.file_size_bytes < 200000 THEN 'Medium (50-200KB)'
        WHEN f.file_size_bytes < 500000 THEN 'Large (200-500KB)'
        ELSE 'Very Large (>500KB)'
    END AS file_size_category,
    COUNT(*) AS file_count,
    AVG(f.processing_seconds) AS avg_processing_time,
    AVG(f.cost) AS avg_cost,
    AVG(f.edits_found) AS avg_edits_found,
    AVG(f.edits_applied) AS avg_edits_applied
FROM dbo.SQL_Processing_Files f
WHERE f.start_time >= DATEADD(DAY, -30, GETDATE())
    AND f.file_size_bytes IS NOT NULL
GROUP BY 
    CASE 
        WHEN f.file_size_bytes < 50000 THEN 'Small (<50KB)'
        WHEN f.file_size_bytes < 200000 THEN 'Medium (50-200KB)'
        WHEN f.file_size_bytes < 500000 THEN 'Large (200-500KB)'
        ELSE 'Very Large (>500KB)'
    END
ORDER BY avg_processing_time DESC;

-- =====================================================
-- EDIT PATTERN ANALYSIS
-- =====================================================

-- 7. Most Common Edit Types
SELECT 
    e.description,
    COUNT(*) AS occurrence_count,
    SUM(CASE WHEN e.success = 1 THEN 1 ELSE 0 END) AS successful_count,
    SUM(CASE WHEN e.success = 0 THEN 1 ELSE 0 END) AS failed_count,
    CAST((SUM(CASE WHEN e.success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DECIMAL(5,1)) AS success_rate,
    AVG(e.processing_seconds) AS avg_processing_time,
    AVG(e.snippet_new_length - e.snippet_old_length) AS avg_size_change,
    AVG(e.lines_added) AS avg_lines_added
FROM dbo.SQL_Processing_Edits e
INNER JOIN dbo.SQL_Processing_Files f ON e.file_id = f.file_id
WHERE f.start_time >= DATEADD(DAY, -30, GETDATE())
GROUP BY e.description
HAVING COUNT(*) >= 5  -- Only show edits that appear at least 5 times
ORDER BY occurrence_count DESC;

-- 8. Edit Success Rate by Match Type
SELECT 
    e.match_type,
    COUNT(*) AS total_edits,
    SUM(CASE WHEN e.success = 1 THEN 1 ELSE 0 END) AS successful_edits,
    SUM(CASE WHEN e.success = 0 THEN 1 ELSE 0 END) AS failed_edits,
    CAST((SUM(CASE WHEN e.success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DECIMAL(5,1)) AS success_rate,
    AVG(e.processing_seconds) AS avg_processing_time
FROM dbo.SQL_Processing_Edits e
INNER JOIN dbo.SQL_Processing_Files f ON e.file_id = f.file_id
WHERE f.start_time >= DATEADD(DAY, -30, GETDATE())
    AND e.match_type IS NOT NULL
GROUP BY e.match_type
ORDER BY success_rate DESC;

-- 9. Failed Edits Analysis
SELECT 
    e.edit_number,
    e.description,
    e.match_type,
    e.error_message,
    f.filename,
    f.start_time,
    e.processing_seconds,
    LEFT(e.old_snippet_full_text, 100) + '...' AS snippet_preview
FROM dbo.SQL_Processing_Edits e
INNER JOIN dbo.SQL_Processing_Files f ON e.file_id = f.file_id
WHERE e.success = 0
    AND f.start_time >= DATEADD(DAY, -7, GETDATE())
ORDER BY f.start_time DESC, e.edit_number;

-- =====================================================
-- COST AND PERFORMANCE ANALYSIS
-- =====================================================

-- 10. Cost Analysis by Script Version
SELECT 
    s.script_version,
    COUNT(*) AS session_count,
    SUM(s.total_cost) AS total_cost,
    AVG(s.total_cost) AS avg_cost_per_session,
    SUM(s.total_savings) AS total_savings,
    AVG(s.total_savings) AS avg_savings_per_session,
    AVG(s.total_processing_seconds) AS avg_processing_seconds,
    SUM(s.total_files) AS total_files_processed,
    AVG(s.total_cost / NULLIF(s.total_files, 0)) AS avg_cost_per_file
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time >= DATEADD(DAY, -30, GETDATE())
GROUP BY s.script_version
ORDER BY total_cost DESC;

-- 11. Hourly Processing Patterns
SELECT 
    DATEPART(HOUR, s.start_time) AS processing_hour,
    COUNT(*) AS session_count,
    AVG(s.total_processing_seconds) AS avg_processing_time,
    AVG(s.total_cost) AS avg_cost,
    AVG(s.files_successful * 100.0 / NULLIF(s.total_files, 0)) AS avg_success_rate
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time >= DATEADD(DAY, -14, GETDATE())
GROUP BY DATEPART(HOUR, s.start_time)
ORDER BY processing_hour;

-- =====================================================
-- OPERATIONAL MONITORING QUERIES
-- =====================================================

-- 12. Current Processing Status (Real-time monitoring)
SELECT 
    s.session_id,
    s.start_time,
    s.script_version,
    s.status AS session_status,
    s.total_files,
    COUNT(f.file_id) AS files_in_progress,
    SUM(CASE WHEN f.status = 'SUCCESS' THEN 1 ELSE 0 END) AS files_completed,
    SUM(CASE WHEN f.status = 'FAILED' THEN 1 ELSE 0 END) AS files_failed,
    SUM(CASE WHEN f.status = 'PROCESSING' THEN 1 ELSE 0 END) AS files_still_processing,
    DATEDIFF(MINUTE, s.start_time, GETDATE()) AS minutes_elapsed
FROM dbo.SQL_Processing_Sessions s
LEFT JOIN dbo.SQL_Processing_Files f ON s.session_id = f.session_id
WHERE s.status = 'IN_PROGRESS' 
    OR s.start_time >= DATEADD(HOUR, -2, GETDATE())
GROUP BY s.session_id, s.start_time, s.script_version, s.status, s.total_files
ORDER BY s.start_time DESC;

-- 13. System Performance Health Check
SELECT 
    'Last 24 Hours' AS time_period,
    COUNT(DISTINCT s.session_id) AS sessions_count,
    SUM(s.total_files) AS files_processed,
    AVG(s.total_processing_seconds / NULLIF(s.total_files, 0)) AS avg_seconds_per_file,
    SUM(s.total_cost) AS total_cost,
    CAST(AVG(s.files_successful * 100.0 / NULLIF(s.total_files, 0)) AS DECIMAL(5,1)) AS avg_success_rate,
    CAST(AVG(s.total_successful_edits * 100.0 / NULLIF(s.total_edits, 0)) AS DECIMAL(5,1)) AS avg_edit_success_rate
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time >= DATEADD(DAY, -1, GETDATE())

UNION ALL

SELECT 
    'Last 7 Days' AS time_period,
    COUNT(DISTINCT s.session_id) AS sessions_count,
    SUM(s.total_files) AS files_processed,
    AVG(s.total_processing_seconds / NULLIF(s.total_files, 0)) AS avg_seconds_per_file,
    SUM(s.total_cost) AS total_cost,
    CAST(AVG(s.files_successful * 100.0 / NULLIF(s.total_files, 0)) AS DECIMAL(5,1)) AS avg_success_rate,
    CAST(AVG(s.total_successful_edits * 100.0 / NULLIF(s.total_edits, 0)) AS DECIMAL(5,1)) AS avg_edit_success_rate
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time >= DATEADD(DAY, -7, GETDATE())

UNION ALL

SELECT 
    'Last 30 Days' AS time_period,
    COUNT(DISTINCT s.session_id) AS sessions_count,
    SUM(s.total_files) AS files_processed,
    AVG(s.total_processing_seconds / NULLIF(s.total_files, 0)) AS avg_seconds_per_file,
    SUM(s.total_cost) AS total_cost,
    CAST(AVG(s.files_successful * 100.0 / NULLIF(s.total_files, 0)) AS DECIMAL(5,1)) AS avg_success_rate,
    CAST(AVG(s.total_successful_edits * 100.0 / NULLIF(s.total_edits, 0)) AS DECIMAL(5,1)) AS avg_edit_success_rate
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time >= DATEADD(DAY, -30, GETDATE());

-- =====================================================
-- DETAILED INVESTIGATION QUERIES
-- =====================================================

-- 14. Get Full Edit Details for a Specific Session
-- Usage: Replace @SessionID with actual session ID
DECLARE @SessionID UNIQUEIDENTIFIER = 'YOUR-SESSION-ID-HERE';

SELECT 
    s.session_id,
    s.start_time AS session_start,
    f.filename,
    f.status AS file_status,
    e.edit_number,
    e.description,
    e.success AS edit_success,
    e.match_type,
    e.position,
    e.snippet_old_length,
    e.snippet_new_length,
    e.lines_added,
    e.characters_added,
    e.processing_seconds,
    e.error_message
FROM dbo.SQL_Processing_Sessions s
INNER JOIN dbo.SQL_Processing_Files f ON s.session_id = f.session_id
INNER JOIN dbo.SQL_Processing_Edits e ON f.file_id = e.file_id
WHERE s.session_id = @SessionID
ORDER BY f.filename, e.edit_number;

-- 15. Get Full Snippet Text for a Specific Edit
-- Usage: Replace @EditID with actual edit ID
DECLARE @EditID UNIQUEIDENTIFIER = 'YOUR-EDIT-ID-HERE';

SELECT 
    e.edit_id,
    e.edit_number,
    e.description,
    e.success,
    f.filename,
    e.old_snippet_full_text,
    '-- REPLACED WITH --' AS separator,
    e.new_snippet_full_text
FROM dbo.SQL_Processing_Edits e
INNER JOIN dbo.SQL_Processing_Files f ON e.file_id = f.file_id
WHERE e.edit_id = @EditID;

-- =====================================================
-- DATA CLEANUP QUERIES
-- =====================================================

-- 16. Clean up old completed sessions (older than 90 days)
-- USE WITH CAUTION - This will permanently delete data
/*
DELETE FROM dbo.SQL_Processing_Sessions 
WHERE start_time < DATEADD(DAY, -90, GETDATE())
    AND status IN ('COMPLETED', 'FAILED');
*/

-- 17. Identify sessions that can be cleaned up
SELECT 
    s.session_id,
    s.start_time,
    s.status,
    s.total_files,
    DATEDIFF(DAY, s.start_time, GETDATE()) AS days_old,
    'Can be cleaned up' AS cleanup_status
FROM dbo.SQL_Processing_Sessions s
WHERE s.start_time < DATEADD(DAY, -90, GETDATE())
    AND s.status IN ('COMPLETED', 'FAILED')
ORDER BY s.start_time;

-- =====================================================
-- REPORTING VIEWS USAGE EXAMPLES
-- =====================================================

-- 18. Using the built-in views for quick reports
SELECT * FROM dbo.vw_SQL_Processing_Session_Summary
WHERE start_time >= DATEADD(DAY, -7, GETDATE())
ORDER BY start_time DESC;

SELECT * FROM dbo.vw_SQL_Processing_File_Details
WHERE session_start >= DATEADD(DAY, -7, GETDATE())
    AND status = 'FAILED'
ORDER BY session_start DESC;

SELECT * FROM dbo.vw_SQL_Processing_Recent_Activity
ORDER BY start_time DESC;

-- =====================================================
-- NOTES
-- =====================================================
/*
PERFORMANCE TIPS:
1. These queries are optimized for the last 30 days of data
2. For older data analysis, adjust the date filters accordingly
3. The views (vw_*) provide pre-calculated metrics for common reports
4. Use the cleanup queries periodically to maintain performance
5. Monitor the avg_seconds_per_file metric to detect performance degradation

MONITORING RECOMMENDATIONS:
1. Run query #12 (Current Processing Status) for real-time monitoring
2. Run query #13 (System Performance Health Check) daily
3. Run query #5 (Files with Consistent Processing Issues) weekly
4. Set up alerts for failure rates > 10% or processing times > 5 minutes per file

TROUBLESHOOTING:
1. Use query #9 (Failed Edits Analysis) to identify common failure patterns
2. Use queries #14 and #15 to investigate specific failed sessions/edits
3. Use query #6 (File Size vs Processing Time) to identify performance bottlenecks
*/