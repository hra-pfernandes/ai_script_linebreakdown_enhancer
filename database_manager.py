# SQL Server Database Manager for Claude SQL Patch Pipeline
# Features: Connection management, transaction handling, real-time data logging

import os
import time
import uuid
from datetime import datetime
from pathlib import Path
import pyodbc
from contextlib import contextmanager
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DatabaseManager:
    """Manages SQL Server database operations for the Claude SQL Patch Pipeline"""
    
    def __init__(self, server=None, database=None, username=None, password=None, driver=None):
        """Initialize database manager with connection parameters"""
        self.server = server or os.getenv('DB_SERVER', 'VM-WT-DEV')
        self.database = database or os.getenv('DB_NAME', 'Automation')
        self.username = username or os.getenv('DB_USERNAME', '')
        self.password = password or os.getenv('DB_PASSWORD', '')
        self.driver = driver or os.getenv('DB_DRIVER', 'ODBC Driver 17 for SQL Server')
        
        self.connection = None
        self.current_session_id = None
        self.current_file_id = None
        
    def get_connection_string(self):
        """Build SQL Server connection string with Windows Authentication"""
        if self.username and self.password:
            # SQL Server Authentication
            return (f"DRIVER={{{self.driver}}};"
                   f"SERVER={self.server};"
                   f"DATABASE={self.database};"
                   f"UID={self.username};"
                   f"PWD={self.password};")
        else:
            # Windows Authentication
            return (f"DRIVER={{{self.driver}}};"
                   f"SERVER={self.server};"
                   f"DATABASE={self.database};"
                   f"Trusted_Connection=yes;")
    
    def connect(self, max_retries=3):
        """Establish database connection with retry logic"""
        connection_string = self.get_connection_string()
        
        for attempt in range(max_retries + 1):
            try:
                logger.info(f"Attempting database connection (attempt {attempt + 1}/{max_retries + 1})")
                self.connection = pyodbc.connect(connection_string, timeout=30)
                logger.info("Database connection established successfully")
                return self.connection
                
            except pyodbc.Error as e:
                logger.error(f"Database connection failed (attempt {attempt + 1}): {e}")
                if attempt < max_retries:
                    time.sleep(2 ** attempt)  # Exponential backoff
                else:
                    raise Exception(f"Failed to connect to database after {max_retries + 1} attempts: {e}")
    
    def disconnect(self):
        """Close database connection"""
        if self.connection:
            try:
                self.connection.close()
                logger.info("Database connection closed")
            except Exception as e:
                logger.error(f"Error closing database connection: {e}")
            finally:
                self.connection = None
    
    @contextmanager
    def transaction(self):
        """Context manager for database transactions"""
        if not self.connection:
            self.connect()
            
        cursor = self.connection.cursor()
        try:
            yield cursor
            self.connection.commit()
            logger.debug("Transaction committed successfully")
        except Exception as e:
            self.connection.rollback()
            logger.error(f"Transaction rolled back due to error: {e}")
            raise
        finally:
            cursor.close()
    
    def execute_query(self, query, params=None, fetch_one=False, fetch_all=False):
        """Execute a query with error handling"""
        if not self.connection:
            self.connect()
            
        try:
            with self.transaction() as cursor:
                cursor.execute(query, params or [])
                
                if fetch_one:
                    return cursor.fetchone()
                elif fetch_all:
                    return cursor.fetchall()
                else:
                    return cursor.rowcount
                    
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            logger.error(f"Query: {query}")
            logger.error(f"Params: {params}")
            raise
    
    # =====================================================
    # SESSION MANAGEMENT
    # =====================================================
    
    def start_session(self, script_version, reference_file, approach):
        """Start a new processing session"""
        try:
            session_id = str(uuid.uuid4())
            
            query = """
                INSERT INTO dbo.SQL_Processing_Sessions 
                (session_id, script_version, reference_file, approach, status, start_time)
                VALUES (?, ?, ?, ?, 'IN_PROGRESS', GETDATE())
            """
            
            self.execute_query(query, [session_id, script_version, reference_file, approach])
            self.current_session_id = session_id
            
            logger.info(f"Started new session: {session_id}")
            return session_id
            
        except Exception as e:
            logger.error(f"Failed to start session: {e}")
            raise
    
    def end_session(self, session_id, status, total_files, files_successful, files_failed, 
                   total_edits, total_successful_edits, total_cost, total_savings, processing_seconds):
        """End a processing session with final metrics"""
        try:
            query = """
                UPDATE dbo.SQL_Processing_Sessions 
                SET end_time = GETDATE(),
                    status = ?,
                    total_files = ?,
                    files_successful = ?,
                    files_failed = ?,
                    total_edits = ?,
                    total_successful_edits = ?,
                    total_cost = ?,
                    total_savings = ?,
                    total_processing_seconds = ?,
                    modified_date = GETDATE()
                WHERE session_id = ?
            """
            
            params = [status, total_files, files_successful, files_failed, 
                     total_edits, total_successful_edits, total_cost, total_savings, 
                     processing_seconds, session_id]
            
            rows_affected = self.execute_query(query, params)
            
            if rows_affected > 0:
                logger.info(f"Session {session_id} ended with status: {status}")
            else:
                logger.warning(f"No session found with ID: {session_id}")
                
        except Exception as e:
            logger.error(f"Failed to end session {session_id}: {e}")
            raise
    
    # =====================================================
    # FILE MANAGEMENT
    # =====================================================
    
    def start_file(self, session_id, filename, input_file_path, file_size_bytes=None):
        """Start processing a file"""
        try:
            file_id = str(uuid.uuid4())
            
            query = """
                INSERT INTO dbo.SQL_Processing_Files 
                (file_id, session_id, filename, input_file_path, file_size_bytes, status, start_time)
                VALUES (?, ?, ?, ?, ?, 'PROCESSING', GETDATE())
            """
            
            self.execute_query(query, [file_id, session_id, filename, input_file_path, file_size_bytes])
            self.current_file_id = file_id
            
            logger.info(f"Started processing file: {filename} (ID: {file_id})")
            return file_id
            
        except Exception as e:
            logger.error(f"Failed to start file processing: {e}")
            raise
    
    def end_file(self, file_id, status, output_file_path, edits_found, edits_applied, 
                cost, processing_seconds, error_message=None):
        """End file processing with results"""
        try:
            query = """
                UPDATE dbo.SQL_Processing_Files 
                SET end_time = GETDATE(),
                    status = ?,
                    output_file_path = ?,
                    edits_found = ?,
                    edits_applied = ?,
                    cost = ?,
                    processing_seconds = ?,
                    error_message = ?,
                    modified_date = GETDATE()
                WHERE file_id = ?
            """
            
            params = [status, output_file_path, edits_found, edits_applied, 
                     cost, processing_seconds, error_message, file_id]
            
            rows_affected = self.execute_query(query, params)
            
            if rows_affected > 0:
                logger.info(f"File {file_id} processing ended with status: {status}")
            else:
                logger.warning(f"No file found with ID: {file_id}")
                
        except Exception as e:
            logger.error(f"Failed to end file processing {file_id}: {e}")
            raise
    
    # =====================================================
    # EDIT MANAGEMENT
    # =====================================================

    def log_edit(self, file_id, edit_number, description, position, match_type, success,
                 old_snippet_full_text, new_snippet_full_text, lines_added, characters_added,
                 processing_seconds, error_message=None,
                 anchor_line_number=None,         # line in patched SQL where anchor ends
                 insertion_ends_at_line=None):     # anchor_line + lines_added
        """
        Log an insertion operation with full text and line number tracking.

        DB schema required for anchor_line_number / insertion_ends_at_line:

            -- Run once before first use if columns don't exist yet:
            ALTER TABLE dbo.SQL_Processing_Edits
                ALTER COLUMN position NVARCHAR(500);
            ALTER TABLE dbo.SQL_Processing_Edits
                ADD anchor_line_number     INT NULL,
                    insertion_ends_at_line INT NULL;
        """
        try:
            edit_id = str(uuid.uuid4())

            snippet_old_length = len(old_snippet_full_text) if old_snippet_full_text else 0
            snippet_new_length = len(new_snippet_full_text) if new_snippet_full_text else 0

            query = """
                INSERT INTO dbo.SQL_Processing_Edits
                (edit_id, file_id, edit_number, description, position, match_type, success,
                 old_snippet_full_text, new_snippet_full_text, snippet_old_length, snippet_new_length,
                 lines_added, characters_added, processing_seconds, error_message,
                 anchor_line_number, insertion_ends_at_line)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

            params = [
                edit_id, file_id, edit_number, description,
                position,           # NVARCHAR(500) — anchor text, not integer offset
                match_type, success,
                old_snippet_full_text, new_snippet_full_text,
                snippet_old_length, snippet_new_length,
                lines_added, characters_added, processing_seconds, error_message,
                anchor_line_number,        # INT NULL
                insertion_ends_at_line,    # INT NULL
            ]

            self.execute_query(query, params)

            logger.info(
                f"Logged edit {edit_number} for file {file_id}: "
                f"{'SUCCESS' if success else 'FAILED'} | "
                f"lines {anchor_line_number}→{insertion_ends_at_line}"
            )
            return edit_id

        except Exception as e:
            logger.error(f"Failed to log edit: {e}")
            raise

    # =====================================================
    # QUERY METHODS
    # =====================================================
    
    def get_session_summary(self, session_id):
        """Get session summary information"""
        query = """
            SELECT * FROM dbo.vw_SQL_Processing_Session_Summary 
            WHERE session_id = ?
        """
        return self.execute_query(query, [session_id], fetch_one=True)
    
    def get_recent_sessions(self, days=30):
        """Get recent session activity"""
        query = """
            SELECT * FROM dbo.vw_SQL_Processing_Recent_Activity 
            ORDER BY start_time DESC
        """
        return self.execute_query(query, fetch_all=True)
    
    def get_file_details(self, file_id):
        """Get detailed file processing information"""
        query = """
            SELECT * FROM dbo.vw_SQL_Processing_File_Details 
            WHERE file_id = ?
        """
        return self.execute_query(query, [file_id], fetch_one=True)
    
    def get_file_edits(self, file_id):
        """Get all edits for a specific file"""
        query = """
            SELECT edit_id, edit_number, description, success, position, match_type,
                   snippet_old_length, snippet_new_length, lines_added, characters_added,
                   processing_seconds, error_message,
                   anchor_line_number, insertion_ends_at_line,
                   timestamp
            FROM dbo.SQL_Processing_Edits 
            WHERE file_id = ?
            ORDER BY edit_number
        """
        return self.execute_query(query, [file_id], fetch_all=True)
    
    def get_edit_full_text(self, edit_id):
        """Get full text snippets for a specific edit"""
        query = """
            SELECT edit_id, old_snippet_full_text, new_snippet_full_text
            FROM dbo.SQL_Processing_Edits 
            WHERE edit_id = ?
        """
        return self.execute_query(query, [edit_id], fetch_one=True)
    
    # =====================================================
    # HEALTH CHECK AND UTILITIES
    # =====================================================
    
    def test_connection(self):
        """Test database connectivity and table existence"""
        try:
            # Test connection
            if not self.connection:
                self.connect()
            
            # Test table existence
            query = """
                SELECT COUNT(*) as table_count
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_NAME IN ('SQL_Processing_Sessions', 'SQL_Processing_Files', 'SQL_Processing_Edits')
            """
            
            result = self.execute_query(query, fetch_one=True)
            table_count = result[0] if result else 0
            
            if table_count == 3:
                logger.info("Database connection and tables verified successfully")
                return True
            else:
                logger.error(f"Expected 3 tables, found {table_count}. Please run database_setup.sql")
                return False
                
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            return False
    
    def get_database_stats(self):
        """Get database statistics"""
        try:
            query = """
                SELECT 
                    'Sessions' as table_name, COUNT(*) as record_count
                FROM dbo.SQL_Processing_Sessions
                UNION ALL
                SELECT 
                    'Files' as table_name, COUNT(*) as record_count  
                FROM dbo.SQL_Processing_Files
                UNION ALL
                SELECT 
                    'Edits' as table_name, COUNT(*) as record_count
                FROM dbo.SQL_Processing_Edits
            """
            
            return self.execute_query(query, fetch_all=True)
            
        except Exception as e:
            logger.error(f"Failed to get database stats: {e}")
            return []
    
    def cleanup_old_sessions(self, days_old=90):
        """Clean up sessions older than specified days"""
        try:
            query = """
                DELETE FROM dbo.SQL_Processing_Sessions 
                WHERE start_time < DATEADD(DAY, -?, GETDATE())
                  AND status IN ('COMPLETED', 'FAILED')
            """
            
            rows_deleted = self.execute_query(query, [days_old])
            logger.info(f"Cleaned up {rows_deleted} sessions older than {days_old} days")
            return rows_deleted
            
        except Exception as e:
            logger.error(f"Failed to cleanup old sessions: {e}")
            raise


# =====================================================
# CONVENIENCE FUNCTIONS
# =====================================================

def create_database_manager():
    """Create a database manager instance with environment variables"""
    return DatabaseManager()


def test_database_setup():
    """Test database setup and connectivity"""
    db = create_database_manager()
    try:
        success = db.test_connection()
        if success:
            stats = db.get_database_stats()
            print("Database Statistics:")
            for stat in stats:
                print(f"  {stat[0]}: {stat[1]} records")
        return success
    finally:
        db.disconnect()


if __name__ == "__main__":
    print("Testing database connection and setup...")
    if test_database_setup():
        print("✅ Database setup verified successfully!")
    else:
        print("❌ Database setup verification failed!")
        print("Please ensure:")
        print("1. SQL Server is accessible at VM-WT-DEV")
        print("2. Database 'Automation' exists")
        print("3. Windows Authentication is configured")
        print("4. Tables were created using database_setup.sql")