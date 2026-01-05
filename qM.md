# Enterprise Data Quality Standards and Metrics
## Research Document - DQPE Target 2026

**Author:** Data Quality Platform Engineering Team  
**Date:** January 2026  
**Status:** Research and Analysis Phase

---

## Executive Summary

This document presents the research and analysis conducted to establish Enterprise Data Quality Standards across Inmar. The objective is to define, publish, and track data quality standards and metrics that can be applied uniformly across the organization, leveraging the existing Data Quality Collector Engine framework while extending its reach to encompass the broader enterprise data architecture.

The research draws from our current implementations, processes documented in our repository, and the Enterprise Data Architecture reference document to propose a comprehensive approach for organization-wide data quality governance.

---

## Table of Contents

1. [Data Quality Dimensions](#1-data-quality-dimensions)
2. [Data Quality by Data Layer](#2-data-quality-by-data-layer)
3. [Data Quality Checks at Each Layer](#3-data-quality-checks-at-each-layer)
4. [Monitoring External Pipeline Data Quality](#4-monitoring-external-pipeline-data-quality)
5. [Helping Teams Improve Data Quality](#5-helping-teams-improve-data-quality)
6. [Success Criteria](#6-success-criteria)
7. [Recommendations](#7-recommendations)

---

## 1. Data Quality Dimensions

### 1.1 Core Dimensions Currently Implemented at Inmar

Based on our existing Collector Engine framework and operational experience, we have established the following core data quality dimensions:

| Dimension | Definition | Why It Matters | Current Implementation |
|-----------|------------|----------------|------------------------|
| **Completeness** | Measures whether all expected data is present and no critical data points are missing | Incomplete data leads to flawed analysis, missed business insights, and incorrect decision-making | Row counts, null counts per column, target completeness (14-day rolling average comparison with 20% tolerance) |
| **Uniqueness** | Ensures that each data record is distinct based on defined composite keys, with no duplications | Duplicates skew metrics, inflate counts, and violate data integrity. They can cause billing errors, incorrect reporting, and system failures | Duplicate detection using stakeholder-defined composite keys, 7-day lookback for incremental tables, full scan for static tables |
| **Freshness** | Measures how current the data is by calculating days since the last update | Stale data leads to outdated insights and poor business outcomes. Real-time or near-real-time decisions require fresh data | Days between last data update and current date, compared against expected freshness thresholds |
| **Timeliness** | Tracks whether data arrives within established SLA/SLO windows | Late data disrupts downstream processes, reports, and stakeholder expectations. SLA breaches have business and contractual implications | Airflow task monitoring, stage completion tracking, automated alerts at 6am EST for ShopperSync exports |
| **Accuracy** | Validates that data correctly represents the real-world objects or events it captures | Inaccurate data leads to wrong conclusions, compliance risks, and loss of trust in data-driven decisions | Source-to-target row count and null count comparison during ETL transit |

### 1.2 Additional Dimensions to Consider for Enterprise Adoption

Drawing from industry standards and our scorecard framework, the following dimensions should be evaluated for enterprise-wide implementation:

| Dimension | Definition | Business Value | Recommended Priority |
|-----------|------------|----------------|---------------------|
| **Consistency** | Data values, formats, and definitions remain uniform across systems and time | Enables reliable cross-system analytics and prevents conflicting reports | High - Critical for enterprise reporting |
| **Validity** | Data conforms to predefined rules, formats, ranges, and business constraints | Prevents garbage-in-garbage-out scenarios and ensures data meets business rules | High - Foundation for trusted data |
| **Integrity** | Referential integrity is maintained across related datasets | Ensures foreign keys link correctly and entity relationships are preserved | Medium - Important for data lake environments |
| **Relevance** | Data is meaningful and applicable to the intended purpose | Avoids collecting and processing data that provides no business value | Low - More of a governance concern |

### 1.3 How We Define and Measure Each Dimension

Our current implementation uses standardized SQL patterns and output types:

**Completeness Collectors:**
- Script prefix: `completeness_`, `target_completeness_`
- Output types: `row_count`, `null_count`
- Pattern: Counts rows and null values per column, flags deviations greater than 20% from 14-day average

**Uniqueness Collectors:**
- Script prefix: `uniqueness_`
- Output types: `duplicate_count`, `row_count`, `unique_duplicates`, `percentage`
- Pattern: GROUP BY on composite key columns, COUNT(*) > 1 identifies duplicates

**Freshness Collectors:**
- Script prefix: `freshness_`
- Output types: `freshness`, `expected_freshness`, `last_update`, `result` (OK/ERR)
- Pattern: `DATE_DIFF(current_date, MAX(update_column), DAY)` compared against threshold

**Timeliness Collectors:**
- Engine: Timeliness Engine (maintained by DataOps)
- Output types: Stage completion times, SLA breach indicators
- Pattern: Task timestamp capture, comparison against established SLOs

**Accuracy Collectors:**
- Script prefix: `source_completeness_`
- Output types: Row counts and null counts from both source and target
- Pattern: Parallel queries comparing source database against target BigQuery tables

---

## 2. Data Quality by Data Layer

### 2.1 Enterprise Data Architecture Layers

Based on the Enterprise Data Architecture reference, data flows through multiple layers, each with distinct data quality requirements:

```
+------------------+     +------------------+     +------------------+     +------------------+
|  SOURCE LAYER    | --> |  INGESTION       | --> |  TRANSFORMATION  | --> |  CONSUMPTION     |
|                  |     |  LAYER           |     |  LAYER           |     |  LAYER           |
+------------------+     +------------------+     +------------------+     +------------------+
| Operational DBs  |     | Raw/Landing Zone |     | Curated/Refined  |     | Data Products    |
| SaaS APIs        |     | GCS Buckets      |     | BigQuery Tables  |     | Reports/Dashboards|
| Files (S3, SFTP) |     | Staging Tables   |     | Data Marts       |     | ML Models        |
| On-prem Systems  |     | Message Queues   |     | Aggregations     |     | APIs             |
+------------------+     +------------------+     +------------------+     +------------------+
```

### 2.2 Applicable Dimensions per Layer

| Data Layer | Completeness | Uniqueness | Freshness | Timeliness | Accuracy | Validity | Consistency |
|------------|:------------:|:----------:|:---------:|:----------:|:--------:|:--------:|:-----------:|
| **Source Layer** | Medium | Low | High | High | N/A (baseline) | Medium | Low |
| **Ingestion Layer** | High | Medium | High | High | High | High | Medium |
| **Transformation Layer** | High | High | Medium | Medium | High | High | High |
| **Consumption Layer** | High | High | Low | Low | Medium | Medium | High |

### 2.3 Rationale for Each Layer

**Source Layer:**
- Focus on detecting missing data and monitoring source system health
- Freshness and timeliness are critical to know when upstream data was last updated
- Limited control over source data quality, primarily observational

**Ingestion Layer (Raw/Landing Zone):**
- Most critical layer for accuracy checks (source-to-target validation)
- Detect data loss during transit (ETL failures, network issues)
- Schema validation and format checks
- Examples from our repo: `completeness_informix_*.sql`, `completeness_mti_*.sql`

**Transformation Layer (Curated/Refined):**
- Uniqueness becomes paramount as data is joined and aggregated
- Business rule validation and cross-table consistency
- Referential integrity between dimension and fact tables
- Examples from our repo: `uniqueness_shoppersync-shoppersyncdatamart_*.sql`

**Consumption Layer (Data Products):**
- Data should already be clean; focus on monitoring and alerting
- Consistency across different consumption views
- User-facing data quality dashboards
- Examples: Superset dashboards like "ShopperSync Data Completeness", "Data Quality Scorecard"

---

## 3. Data Quality Checks at Each Layer

### 3.1 Check Types: Pipeline-Embedded vs External Monitoring

Data quality checks can be implemented in two ways:

| Approach | Description | Pros | Cons | When to Use |
|----------|-------------|------|------|-------------|
| **In-Pipeline** | Checks embedded within the ETL/ELT pipeline code | Immediate feedback, can halt bad data, no latency | Adds pipeline complexity, harder to modify, distributed ownership | Critical business data, compliance requirements, when bad data must be blocked |
| **External Monitoring** | Checks run independently after data lands (our Collector Engine approach) | Centralized, flexible, easy to modify, consolidated reporting | Post-hoc detection, bad data may already be used, requires cleanup processes | Observational quality metrics, trend analysis, non-blocking validation |

### 3.2 Recommended Checks by Layer

#### Source Layer

| Check Type | In-Pipeline | External | Example |
|------------|:-----------:|:--------:|---------|
| Source availability monitoring | - | Yes | GCS sensor detecting file arrival |
| Data extraction validation | Yes | - | Count records extracted vs expected |
| Schema drift detection | Yes | Yes | Column addition/removal alerts |

**Current Implementation Example:**
```sql
-- GCS Sensor for file arrival (timeliness_prcm_previous_day_client_batch_numbers.sql)
SELECT DISTINCT * FROM `collector_engine.view_timeliness_prcm`
WHERE bucket_name = '--parameters'
AND snapshot_date = CASE
    WHEN EXTRACT(DAYOFWEEK FROM current_date) BETWEEN 3 AND 6 THEN current_date - 1
    WHEN EXTRACT(DAYOFWEEK FROM current_date) = 2 THEN current_date - 3
END
```

#### Ingestion Layer

| Check Type | In-Pipeline | External | Example |
|------------|:-----------:|:--------:|---------|
| Row count validation (source vs target) | Yes | Yes | Compare Informix count to BQ count |
| Null count validation | - | Yes | Column-level null tracking |
| Data type validation | Yes | - | Cast failures during load |
| Duplicate detection on primary keys | Yes | Yes | Pre-insert deduplication |

**Current Implementation Example:**
```sql
-- Source-to-target accuracy (source_completeness_shoppersync-offerhub_offer.sql)
SELECT
    SUM(row_count) AS row_count__offer,
    sum(id) as null_count__id,
    -- ... additional columns
FROM (
    SELECT 1 AS row_count,
        case when id is null then 1 else 0 end as id,
        -- ... additional columns
    FROM --parameters
) AS offerhub_offer
```

#### Transformation Layer

| Check Type | In-Pipeline | External | Example |
|------------|:-----------:|:--------:|---------|
| Business rule validation | Yes | Yes | Negative amounts where prohibited |
| Referential integrity | - | Yes | FK relationships maintained |
| Composite key uniqueness | - | Yes | No duplicates on business keys |
| Volume anomaly detection | - | Yes | 20% deviation from 14-day average |
| Cross-table consistency | - | Yes | Totals match between related tables |

**Current Implementation Example:**
```sql
-- Uniqueness check (uniqueness_shoppersync-shoppersyncdatamart_basket.sql)
SELECT sum(duplicate_count) as duplicate_count__basket,
       sum(row_count) as row_count__basket,
       dup_date, total_dups, retailer_source 
FROM (
    SELECT case when dup_count > 1 then 1 else 0 end as duplicate_count,
           1 as row_count,
           dup_date, retailer_source,
           sum(dup_count) as total_dups
    FROM (
        SELECT concat(retailersource,'-',coalesce(retailerId,0),'-',
                      coalesce(retailerFamilyId, 0),'-',basketid) pk,
               transactionDate as dup_date,
               retailersource as retailer_source,
               count(*) as dup_count
        FROM `shoppersync.shoppersyncdatamart.basket`
        WHERE retailersource = '--parameters'
          AND lastExportDate >= current_date - 7
        GROUP BY 1,2,3
    )
    GROUP BY 1,2,3,4
)
GROUP BY dup_date, total_dups, retailer_source
```

#### Consumption Layer

| Check Type | In-Pipeline | External | Example |
|------------|:-----------:|:--------:|---------|
| Dashboard data freshness | - | Yes | Last refresh timestamp display |
| Report completeness | - | Yes | All expected dimensions present |
| API response validation | Yes | - | Schema and data validation |
| User-reported issue tracking | - | Yes | Feedback loop integration |

**Current Implementation Example:**
```sql
-- Freshness for consumption layer (freshness_shoppersync_offerhub_offer.sql)
SELECT cast(last_update as string) last_update,
       cast(current_date as string) metric_date,
       date_diff(current_date, last_update, DAY) freshness, 
       case when date_diff(current_date, last_update, DAY) <= --parameters
            then 'OK' else 'ERR' end result,
       --parameters expected_freshness
FROM (
    SELECT max(cast(updated as date)) last_update
    FROM shoppersync.offerhubdatamart.offer
    WHERE cast(updated as date) >= current_date - (--parameters + 5)
) fresh
```

### 3.3 Check Execution Patterns

Based on our Collector Engine DAG, we support multiple sensor types for triggering checks:

| Sensor Type | Use Case | Configuration |
|-------------|----------|---------------|
| `logging_sensor` | BigQuery tables refreshed by Airflow | Monitors Cloud Logging for specific DAG completion messages |
| `time_sensor` | On-prem databases, fixed schedules | Executes at specified cron time |
| `gcs_sensor` | Files landing in GCS buckets | Monitors bucket for new objects |
| `bigQuery_sql_sensor` | Custom SQL condition checks | Runs SQL query until condition is met |

---

## 4. Monitoring External Pipeline Data Quality

### 4.1 The Challenge

External engineering teams build and maintain their own data pipelines (ETL/ELT processes) that produce datasets consumed across the organization. These teams may not have data quality expertise or tooling, creating blind spots in our overall data quality posture.

### 4.2 Current Approach

We currently monitor external team datasets through our Collector Engine by:

1. **Requesting access** via ENTDEVOPS Jira tickets for service account permissions
2. **Registering data sources** in `tblDimDataSource` with appropriate connection credentials stored in Secret Manager
3. **Creating collectors** that run SQL queries against their datasets
4. **Publishing results** to our BigQuery output tables for dashboarding and alerting

This model works but has limitations:
- Reactive rather than proactive
- Limited visibility into pipeline internals
- Delayed detection (post-landing only)
- Manual onboarding process

### 4.3 Recommended Enterprise Model

To scale data quality monitoring across pipelines built by external teams, we recommend a three-tier approach:

#### Tier 1: Self-Service Data Quality Registration

Create a self-service portal or streamlined process where engineering teams can:
- Register their datasets for monitoring
- Define their own composite keys for uniqueness checks
- Specify expected freshness thresholds
- Configure alerting preferences

**Implementation:**
- Expand `gbq_scripts/` to include templated INSERT scripts for common patterns
- Create documentation and examples for each dimension type
- Develop a Jira intake form that auto-generates collector configurations

#### Tier 2: Pipeline Integration SDK

Provide lightweight libraries or code patterns that engineering teams can embed in their pipelines:

```python
# Proposed: dq_sdk module
from inmar_dq_sdk import DataQualityReporter

dq = DataQualityReporter(
    project="inm-data-governance",
    dataset="collector_engine"
)

# Report metrics directly from pipeline
dq.report_completeness(
    table="my_dataset.my_table",
    row_count=df.count(),
    null_counts={"column_a": df.filter(col("column_a").isNull()).count()}
)
```

This allows teams to:
- Push metrics in real-time during pipeline execution
- Leverage their existing pipeline orchestration (Airflow, Dataflow, etc.)
- Maintain ownership while contributing to central visibility

#### Tier 3: Pub/Sub Event Integration

Leverage our existing Pub/Sub integration with DataOps to:
- Receive pipeline completion events from external teams
- Trigger our collectors based on their pipeline events
- Publish data quality results back to team-specific topics

**Current Capability:**
We already publish Pub/Sub messages with collector metadata to DataOps team topics via `alertParameters` in `tblDimCollector`. This pattern can be extended for bidirectional communication.

### 4.4 Governance Model for External Pipelines

| Responsibility | Data Quality Team | External Engineering Team | Shared |
|----------------|:------------------:|:--------------------------:|:------:|
| Define quality thresholds | - | Yes | - |
| Implement collectors | Yes | - | - |
| Monitor alerts | Yes | Yes | - |
| Investigate root cause | - | Yes | - |
| Remediate data issues | - | Yes | - |
| Update composite keys | - | - | Yes |
| Dashboard access | Yes | Yes | - |
| SLA definition | - | - | Yes |

---

## 5. Helping Teams Improve Data Quality

### 5.1 Current Offerings

Based on our documented processes, we currently offer:

1. **Quality Metrics by Dimension**
   - Completeness, Freshness, Timeliness, Uniqueness dashboards
   - Accessible via Apache Superset at `superset.inmar.com`

2. **Customized Dashboards**
   - Business unit-specific views (ShopperSync, Finance Datalake, Healthcare/PRCM)
   - Scorecard landing pages with gauge indicators

3. **Automated Alerts**
   - Email notifications via SendGrid
   - Google Chat webhooks to relevant team spaces
   - Pub/Sub messages for DataOps integration

4. **Request Process**
   - Email to `gcp-dataquality-engineers@inmar.com`
   - Jira ticket creation on Data Quality - Platform Engineering board

### 5.2 Recommended Enhancements

#### Data Quality Playbooks

Create standardized remediation guides for common data quality issues:

| Issue Type | Playbook Content |
|------------|------------------|
| Missing Data | Root cause checklist, upstream contact matrix, backfill procedures |
| Duplicates | Deduplication strategies, composite key validation, cleanup scripts |
| Stale Data | Pipeline health checks, dependency mapping, escalation paths |
| Schema Changes | Change detection, downstream impact analysis, communication templates |

#### Proactive Quality Reviews

Establish a cadence for proactive engagement:

- **Quarterly Data Quality Reviews**: Meet with each business unit to review trends, discuss upcoming changes, and identify new monitoring needs
- **New Dataset Onboarding**: Include data quality requirements in the data platform onboarding checklist
- **Incident Post-Mortems**: After data quality incidents, conduct reviews and update monitoring

#### Training and Education

Develop training materials for engineering teams:

1. **Data Quality 101**: What are the dimensions, why they matter
2. **Self-Service Collector Creation**: How to add new collectors to the engine
3. **Dashboard Interpretation**: How to read and act on scorecard data
4. **Best Practices Guide**: SQL patterns, naming conventions, testing approaches

#### Quality Gates

Work with data platform teams to implement quality gates:

- Block dataset publication if uniqueness score falls below threshold
- Require freshness certification before downstream pipeline execution
- Automated Slack/Chat notifications when new tables are created without quality coverage

### 5.3 Data Quality Ownership Model

We recommend a federated model where:

| Component | Owner | Responsibilities |
|-----------|-------|------------------|
| Collector Engine | DQ Platform Team | Infrastructure, framework, enhancements |
| Collector Configuration | Dataset Owner | Thresholds, composite keys, alert recipients |
| Remediation | Dataset Owner | Fixing root causes, cleaning data |
| Dashboards | DQ Platform Team | Building, maintaining, access management |
| Standards Definition | DQ Platform Team + Data Governance | Cross-org standards, dimension definitions |

---

## 6. Success Criteria

### 6.1 Quantitative Metrics

| Metric | Current State | 2026 Target | Measurement Method |
|--------|---------------|-------------|-------------------|
| **Dataset Coverage** | ~50 tables across 3 data sources | 200+ tables across 10+ data sources | Count of active collectors in `tblDimCollector` |
| **Average Completeness Score** | ~95% (ShopperSync) | 98% across all monitored datasets | Weighted average from scorecard |
| **Duplicate Rate** | <0.1% (monitored tables) | <0.05% across all monitored datasets | Aggregate duplicate_count / row_count |
| **Freshness SLA Compliance** | ~90% | 95% | Freshness result = 'OK' percentage |
| **Timeliness SLA Compliance** | ~85% (ShopperSync 6am) | 95% across all SLAs | Stage completion within threshold |
| **Mean Time to Detect (MTTD)** | Not measured | <30 minutes for critical datasets | Alert timestamp - data landing timestamp |
| **Alert Resolution Rate** | Not measured | 90% within SLA | Closed tickets / Total alerts |

### 6.2 Qualitative Outcomes

| Outcome | Description | Validation Method |
|---------|-------------|-------------------|
| **Published Standards Document** | Official enterprise data quality standards adopted by Data Governance Council | Confluence publication, executive sign-off |
| **Self-Service Adoption** | Engineering teams actively using self-service tools | Collector creation requests, portal usage stats |
| **Stakeholder Satisfaction** | Business users trust the data they consume | Survey results, incident reduction |
| **Cross-Team Visibility** | Any team can view data quality for datasets they consume | Dashboard access logs, support tickets |
| **Reduced Incident Impact** | Data quality issues caught before downstream impact | Incident post-mortem classification |

### 6.3 Program Milestones

| Quarter | Milestone | Deliverable |
|---------|-----------|-------------|
| Q1 2026 | Standards Definition | Published Enterprise Data Quality Standards document |
| Q1 2026 | Baseline Measurement | Current state assessment across all critical datasets |
| Q2 2026 | Platform Expansion | Collector Engine extended to 3 additional data sources |
| Q2 2026 | Self-Service MVP | Basic self-service collector registration process |
| Q3 2026 | Training Rollout | Data Quality training delivered to all engineering teams |
| Q3 2026 | Alert Optimization | Reduced false positives, improved MTTD |
| Q4 2026 | Full Coverage | All critical datasets (per 2025 list) under monitoring |
| Q4 2026 | Program Review | Success metrics evaluated, 2027 roadmap defined |

---

## 7. Recommendations

### 7.1 Immediate Actions (Q1 2026)

1. **Formalize Dimension Definitions**
   - Draft official definitions for each dimension
   - Get sign-off from Data Governance Council
   - Publish to Confluence as the authoritative source

2. **Extend Critical Dataset Coverage**
   - Review the "Shortlisted Critical Datasets - 2025" list
   - Prioritize datasets without any coverage
   - Begin collector implementation for top 20 uncovered datasets

3. **Improve Documentation**
   - Update `copilot-instructions.md` with enterprise standards
   - Create step-by-step guides for each collector type
   - Document alerting configuration options

### 7.2 Medium-Term Actions (Q2-Q3 2026)

4. **Build Self-Service Capabilities**
   - Create Jira intake templates for each dimension
   - Develop a configuration generator tool
   - Establish SLA for collector implementation (e.g., 5 business days)

5. **Enhance Alerting Intelligence**
   - Implement alert correlation to reduce noise
   - Add severity classification (Critical, Major, Minor)
   - Create escalation paths based on SLA breach duration

6. **Develop Quality Gates**
   - Partner with Data Platform team on publication controls
   - Define minimum quality thresholds per data tier
   - Implement blocking vs. warning modes

### 7.3 Long-Term Vision (Q4 2026 and Beyond)

7. **Machine Learning for Anomaly Detection**
   - Move beyond fixed thresholds (20% deviation)
   - Implement statistical anomaly detection for volume patterns
   - Predict data quality issues before they occur

8. **Data Quality as Code**
   - Version control all quality rules alongside data pipeline code
   - Enable PR-based review for threshold changes
   - Integrate with CI/CD for automated testing

9. **Enterprise Data Quality Portal**
   - Single pane of glass for all data quality metrics
   - Role-based views (executive, data engineer, analyst)
   - Integration with data catalog for discoverability

### 7.4 Technical Recommendations

Based on repository analysis, I recommend the following technical improvements:

1. **Standardize Collector Naming**
   - Enforce the `<dimension>_<dataset>_<table>` pattern via validation
   - Add naming validation to the collector configuration process

2. **Improve Sensor Efficiency**
   - Evaluate sensor timeout configurations across collectors
   - Implement adaptive poke intervals based on historical patterns

3. **Expand Output Type Library**
   - Add new output types for Validity dimension (e.g., `format_error_count`, `range_violation_count`)
   - Create output types for Consistency dimension (e.g., `mismatch_count`)

4. **Dashboard Consolidation**
   - Create a unified "Enterprise Data Quality" dashboard
   - Implement drill-down from enterprise view to business unit to individual collector

---

## Appendix A: Current Collector Inventory Summary

Based on the `scripts/` directory analysis:

| Dimension | Count | Example Scripts |
|-----------|-------|-----------------|
| Completeness | ~150+ | `completeness_shoppersyncdatamart_basket.sql`, `completeness_mti_usfret_dbo_box.sql` |
| Target Completeness | ~25 | `target_completeness_basket.sql`, `target_completeness_offer.sql` |
| Uniqueness | ~50+ | `uniqueness_shoppersync-shoppersyncdatamart_basket.sql`, `uniqueness_finance-datalake_ar_invoice_header.sql` |
| Freshness | ~10 | `freshness_shoppersync_offerhub_offer.sql`, `freshness_shoppersync_katana_impressions.sql` |
| Source Accuracy | ~8 | `source_completeness_shoppersync-offerhub_offer.sql` |
| Timeliness | 1 | `timeliness_prcm_previous_day_client_batch_numbers.sql` |
| Integrity | 2 | `integrity_budgethubdatamart_budget_activity_data_deadletter_table.sql` |

---

## Appendix B: Data Sources Currently Monitored

| Data Source Type | Platform | Example |
|------------------|----------|---------|
| BigQuery | Google Cloud | shoppersync.shoppersyncdatamart |
| MSSQL | On-premises | MTI USFRET, USFPIMS databases |
| Informix | On-premises | RxReturns operational data |
| PostgreSQL | Cloud SQL | Finance Datalake sources |
| MySQL | On-premises / Cloud | Legacy promotional data |
| GCS Buckets | Google Cloud | PRCM file arrivals |

---

## Appendix C: Alerting Channels

| Channel | Use Case | Configuration |
|---------|----------|---------------|
| Email (SendGrid) | Formal notifications, escalations | `gcp-dataquality-engineers@inmar.com` |
| Google Chat Webhook | Real-time team alerts | Space-specific webhooks in Airflow connections |
| Pub/Sub | System-to-system integration | DataOps project topics for completeness metrics |

---

## Appendix D: Reference Documents

- Enterprise Data Architecture: [Google Doc Link](https://docs.google.com/document/d/1BNrb4hAJnk3tl3JB5kktp1Cfe1nqOZdrG90oiYRpirs/)
- Collector Engine Technical Documentation: `docs/` folder in this repository
- Critical Datasets - 2025: Internal Confluence page
- Data Quality Scorecard: `superset.inmar.com/superset/dashboard/Scorecard-Landing-Page/`

---

*This document represents initial research and analysis. It should be reviewed with stakeholders and refined based on feedback before finalizing the Enterprise Data Quality Standards.*
