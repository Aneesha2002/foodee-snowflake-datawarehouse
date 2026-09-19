# FOODEE — Snowflake Food Delivery Data Warehouse

FOODEE is an end-to-end **Snowflake data engineering and data warehousing project** built around a food delivery business.

The project transforms raw CSV source data into analytics-ready datasets through a layered warehouse architecture, dimensional modeling, incremental processing, data quality validation, audit tracking, and business reporting.

## Architecture

![FOODEE Architecture](docs/architecture.png)

**RAW → STAGE → DM → PREPUB → PUB → Reports**

## Tech Stack

- Snowflake
- SQL
- Git / GitHub
- CSV
- Snowflake Internal Stage

## Data Sources

- Customers
- Restaurants
- Menu Items
- Orders
- Order Items

## Warehouse Layers

### RAW

Stores source data with minimal transformation while preserving the source structure.

### STAGE

Cleans and prepares source data for downstream processing, including:

- Data-quality filtering
- Deduplication using `ROW_NUMBER()`
- Latest-record selection using `LAST_UPDATED_TIMESTAMP`
- Incremental `MERGE` processing

### DM — Data Mart

Contains the core dimensional model:

- `DIM_CUSTOMER`
- `DIM_RESTAURANT`
- `DIM_MENU_ITEM`
- `FACT_ORDER_ITEM`

`DIM_CUSTOMER` uses **SCD Type 2** to preserve historical customer changes.

`FACT_ORDER_ITEM` is maintained at **order-item grain** and uses surrogate keys to link to dimensions.

### PREPUB

Provides an intermediate, business-ready representation of the dimensional data before final publication.

### PUB

Contains business-facing data prepared for reporting and downstream consumption.

## Incremental Data Processing

FOODEE includes incremental processing for Orders and Order Items using **watermark-based change tracking**.

The pipeline:

1. Identifies new or changed records using `LAST_UPDATED_TIMESTAMP`.
2. Loads affected records into STAGE.
3. Updates required dimensions.
4. Loads the fact table.
5. Processes PREPUB and PUB.
6. Runs data-quality validation.
7. Records batch and audit information.
8. Advances the watermark only after successful processing.

If processing fails, the batch is marked as failed and the watermark is not advanced.

Restaurant and Menu Item processing uses idempotent snapshot-based `MERGE` logic because the source data does not provide a reliable change timestamp.

## Automated Pipeline

FOODEE includes the stored procedure:

`FOODEE_DB.RAW.SP_ORDERS_INCREMENTAL_PIPELINE()`

Pipeline flow:

**Batch Start → STAGE → Dimensions → Fact → PREPUB → PUB → DQ → Audit → Watermark**

Run the pipeline with:

    CALL FOODEE_DB.RAW.SP_ORDERS_INCREMENTAL_PIPELINE();

When no new data is available, the pipeline exits without advancing the watermark.

## Data Modeling

The project uses dimensional modeling with:

- Dimension tables for descriptive business entities
- A fact table at **order-item grain**
- Natural keys from source systems
- Surrogate keys for warehouse dimensions
- SCD Type 2 customer history

`FACT_ORDER_ITEM` contains:

- Quantity
- Unit price
- Discount amount
- Gross amount
- Net amount

## Idempotent Loading

FOODEE uses `MERGE` logic across multiple layers to support **idempotent processing**.

Rerunning an already-processed load does not create duplicate fact or business-facing records.

## Control and Audit Framework

The project includes control and audit tables for pipeline execution tracking.

The framework records:

- Batch/run identifiers
- Processing status
- Start and completion timestamps
- Rows processed / loaded
- Error information
- Watermark progression

## Data Quality

FOODEE includes **18 data-quality checks** covering:

- Duplicate surrogate keys
- Duplicate fact records
- Critical NULL values
- Orphaned dimension keys
- Invalid fact calculations
- SCD Type 2 date validity
- Multiple current customer records
- Duplicate natural keys
- Overlapping SCD Type 2 records
- Invalid fact values
- PREPUB/PUB reconciliation
- Layer-level reconciliation

## Testing

The repository includes tests for:

- Stage deduplication
- SCD Type 2 customer changes
- Customer update simulation
- SCD Type 2 validation
- Audit logging
- Incremental Order Item processing
- Incremental Order processing
- Watermark and batch behavior

## Business KPIs

FOODEE includes SQL reports for:

1. Most ordered food item
2. Most popular cuisine
3. Most ordered restaurant
4. Popular food combinations
5. Top customers by order activity
6. Revenue by restaurant
7. Customer cancellation rate

## Repository Structure

    foodee-snowflake-datawarehouse/
    │
    ├── data/
    ├── docs/
    │
    ├── sql/
    │   ├── setup/
    │   ├── raw/
    │   ├── stage/
    │   ├── dm/
    │   ├── prepub/
    │   ├── pub/
    │   ├── control/
    │   ├── procedures/
    │   ├── reports/
    │   └── tests/
    │
    ├── .gitignore
    └── README.md

## Fresh Snowflake Setup

Run the SQL scripts in the following order:

1. `sql/setup/`
2. `sql/raw/`
3. `sql/stage/`
4. `sql/dm/`
5. `sql/prepub/`
6. `sql/pub/`
7. `sql/reports/`
8. `sql/procedures/`

Upload the source CSV files to the Snowflake internal stage before running the RAW initial-load scripts.

For a fresh account, `sql/pub/04_alter_pub_surrogate_keys.sql` is not required because the current PUB create script already contains the surrogate-key columns.

After deployment, run:

    CALL FOODEE_DB.RAW.SP_ORDERS_INCREMENTAL_PIPELINE();

## Project Objective

FOODEE demonstrates practical Snowflake data engineering concepts including:

- Layered data warehouse architecture
- SQL ETL/ELT
- Dimensional modeling
- Fact and dimension design
- SCD Type 2
- Surrogate and natural keys
- Incremental processing
- Watermark-based change tracking
- Idempotent `MERGE` operations
- Batch and audit tracking
- Data-quality validation
- Stored-procedure orchestration
- Testing
- Business reporting