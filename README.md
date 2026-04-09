# AI Script Line Breakdown Enhancer

This project is designed to enhance and optimize SQL scripts for healthcare insurance claims processing. It provides tools for batch processing, database management, and script optimization.

## Project Overview

This system processes and optimizes SQL scripts for various insurance providers including Aetna, UHC, Cigna, GHI, HIP, and others. The project includes:

- Database management utilities
- Batch processing scripts
- SQL script optimization tools
- Analysis and reporting capabilities

## Installation

### Prerequisites
- Python 3.8 or higher
- Required Python packages (see requirements.txt)

### Setup Instructions
1. Clone the repository
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Configure environment variables (see .env file)
4. Set up the database (see database_setup.sql)

## Usage

### Running Batch Processing
The main batch processing script is `optimized_main_batch_v27.py`. To run it:

```bash
python optimized_main_batch_v27.py
```

### Database Management
Use the database manager utilities in `database_manager.py` for:
- Database connection management
- Query execution
- Data validation

### Script Optimization
The optimization script `optimized_main_batch_db_fixed_new9_indicator_flag_rn_fix.py` provides advanced optimization features including:
- Indicator flag processing
- Row number fixes
- Database optimization

## File Structure

```
AI_Script_Enhancer/
├── database_manager.py          # Database connection and management utilities
├── database_queries.sql         # SQL queries for database operations
├── database_setup.sql           # Database schema and setup scripts
├── optimized_main_batch_v27.py  # Main batch processing script
├── optimized_main_batch_db_fixed_new9_indicator_flag_rn_fix.py  # Advanced optimization script
├── requirements.txt             # Python dependencies
├── test.py                      # Test scripts
├── .gitignore                   # Git ignore rules
├── .env                         # Environment variables
└── batch_output/                # Directory for batch output files
    ├── NYP_COL_Aetna_Commercial_OP_Complete/
    ├── NYP_COL_UHC_CHP_OP_Complete/
    ├── NYP_COL_Magnacare_OP_Complete/
    └── ...                      # Other provider-specific output directories
```

## Dependencies

- Python 3.8+
- Required packages listed in requirements.txt
- Database system (configured in .env)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please refer to the documentation in the data/ directory or contact the development team.