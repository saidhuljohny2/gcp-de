-- =============================================================================
-- RetailPulse | 01_create_datasets.sql
-- Purpose: Create Medallion Architecture datasets in BigQuery
-- Author: RetailPulse Data Engineering Team
-- =============================================================================
-- Prerequisites:
--   1. Replace `gcp-evening-batch-501811` with your GCP Project ID
--   2. Enable BigQuery API in GCP Console
--   3. Ensure billing is enabled on the project
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CONFIGURATION: Update project ID before execution
-- -----------------------------------------------------------------------------
-- Option A: Set default project in bq CLI: bq mk --project_id=YOUR_PROJECT
-- Option B: Replace gcp-evening-batch-501811 below with your project ID

-- =============================================================================
-- RAW LAYER
-- Dataset: retail_raw
-- Purpose: Landing zone for external tables pointing to Cloud Storage (GCS)
-- Retention: 90 days (configurable) — raw files remain in GCS
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS `gcp-evening-batch-501811.retail_raw`
OPTIONS (
  description = 'Raw layer: external tables over GCS CSV landing zone',
  location = 'US'
);

-- =============================================================================
-- BRONZE LAYER
-- Dataset: retail_bronze
-- Purpose: Immutable copy of raw data loaded into native BigQuery tables
-- Partitioning: Applied at table level (see 03_bronze_tables.sql)
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS `gcp-evening-batch-501811.retail_bronze`
OPTIONS (
  description = 'Bronze layer: native tables with raw schema, minimal transformation',
  location = 'US'
);

-- =============================================================================
-- SILVER LAYER
-- Dataset: retail_silver
-- Purpose: Cleaned, validated, conformed dimensional model
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS `gcp-evening-batch-501811.retail_silver`
OPTIONS (
  description = 'Silver layer: cleaned facts and dimensions with business rules applied',
  location = 'US'
);

-- =============================================================================
-- GOLD LAYER
-- Dataset: retail_gold
-- Purpose: Business-ready aggregates and KPI tables for analytics & BI
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS `gcp-evening-batch-501811.retail_gold`
OPTIONS (
  description = 'Gold layer: curated business aggregates for dashboards and reporting',
  location = 'US'
);

-- =============================================================================
-- VERIFICATION QUERY
-- Run after creation to confirm all datasets exist
-- =============================================================================
/*
SELECT schema_name, location, creation_time
FROM `gcp-evening-batch-501811.INFORMATION_SCHEMA.SCHEMATA`
WHERE schema_name IN ('retail_raw', 'retail_bronze', 'retail_silver', 'retail_gold')
ORDER BY schema_name;
*/
