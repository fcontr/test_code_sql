# Enterprise Data Quality Standards and Metrics
## Research and Analysis Document

**Date:** January 5, 2026  
**Author:** Data Quality Platform Engineering Team  
**Target:** Define, Publish and Track Enterprise Data Quality Standards and Metrics for 2026

---

## Executive Summary

This document presents a comprehensive research analysis for establishing Enterprise Data Quality Standards across Inmar. Based on our existing Data Quality Platform Engineering (DQPE) capabilities, the Enterprise Data Architecture, and industry best practices, we propose a framework that aligns data quality dimensions with the five-layer enterprise architecture while enabling federated governance and domain ownership.

The goal is to evolve from our current project-specific approach to a standardized, enterprise-wide data quality program that supports the organization's vision of treating data as a product.

---

## 1. Data Quality Dimensions: Definition, Meaning, and Importance

### 1.1 Core Dimensions (Currently Implemented)

Based on our current Collector Engine capabilities and stakeholder needs, we recommend formalizing the following core dimensions as enterprise standards:

| Dimension | Definition | Why It Matters |
|-----------|------------|----------------|
| **Completeness** | Measures whether all expected data is present and recorded. Includes row counts, null value detection, and volume deviation analysis (comparing against 14-day rolling averages with a 20% threshold). | Incomplete data leads to flawed analysis and missed business opportunities. For example, missing basket data from a retailer impacts promotion effectiveness calculations. |
| **Timeliness** | Measures whether data arrives within established SLA/SLO windows and is available when needed for business processes. | Late data impacts downstream consumers who depend on timely information for daily operations, such as the ShopperSync export which stakeholders rely on by 6:00 AM EST. |
| **Freshness** | Calculates the number of days since data was last updated at its source, comparing against defined thresholds. | Stale data leads to outdated insights and poor business decisions. For real-time marketing campaigns, data that is days old may result in irrelevant offers. |
| **Uniqueness** | Ensures each record is distinct based on defined composite keys, detecting and quantifying duplicate records. | Duplicates inflate metrics, skew analysis, and waste storage. A duplicate basket transaction could double-count revenue figures. |
| **Accuracy** | Compares source and target datasets to ensure data integrity during transit. Verifies row counts and null counts match between origin and destination. | Data loss or corruption during ETL pipelines undermines trust in downstream analytics. If source has 1M records and target has 990K, we have a 1% data loss problem. |

### 1.2 Recommended Additional Dimensions for Enterprise Adoption

To mature our enterprise program, we recommend adding these dimensions over time:

| Dimension | Definition | Why It Matters | Implementation Approach |
|-----------|------------|----------------|------------------------|
| **Consistency** | Data values, formats, and definitions remain uniform across different sources, systems, and time periods. | Inconsistent data causes reconciliation issues between divisions. A customer ID formatted differently in MarTech vs Healthcare creates matching failures. | Cross-domain validation queries comparing attribute formats and value ranges |
| **Validity** | Data adheres to predefined rules, constraints, and business requirements (formats, ranges, data types). | Invalid data fails downstream processing. An email without @ symbol or a negative transaction amount indicates data entry or processing errors. | Rule-based validation collectors with configurable business rules |
| **Integrity** | Maintains referential integrity between related datasets and ensures parent-child relationships are preserved. | Broken relationships corrupt joins and produce incorrect aggregations. An offer without a valid campaign ID breaks reporting hierarchies. | Foreign key validation queries (already partially implemented in BudgetHub collectors) |

### 1.3 Dimension Priority Matrix

| Dimension | Business Impact | Implementation Complexity | Current Maturity | 2026 Priority |
|-----------|-----------------|---------------------------|------------------|---------------|
| Completeness | High | Low | Mature | Maintain/Expand |
| Timeliness | High | Medium | Mature | Maintain |
| Uniqueness | High | Low | Mature | Expand |
| Freshness | Medium | Low | Mature | Expand |
| Accuracy | High | Medium | Growing | Prioritize |
| Consistency | High | High | Not Started | Plan |
| Validity | Medium | Medium | Not Started | Pilot |
| Integrity | Medium | Low | Pilot | Expand |

---

## 2. Data Quality Dimensions by Enterprise Architecture Layer

Based on the Enterprise Data Architecture document, here is how each dimension applies to the five layers:

### Layer 1: Source Systems and Applications
*MarTech, Healthcare, Corporate, and 3rd Party applications*

| Dimension | Applicability | Rationale |
|-----------|--------------|-----------|
| **Validity** | Critical | Input sanitization and data type validation should occur at the point of entry. Invalid data caught here prevents downstream propagation. |
| **Consistency** | Important | Data normalization at entry ensures consistent formats across the organization. |
| **Integrity** | Important | Referential integrity enforcement (e.g., employee IDs validated against master HR data) prevents orphan records. |

**Governance Responsibility:** Application development teams via SDLC processes  
**DQ Team Role:** Consultative; provide standards and validation patterns

### Layer 2: Data Lake
*Raw, untransformed data storage in GCP*

| Dimension | Applicability | Rationale |
|-----------|--------------|-----------|
| **Timeliness** | Critical | Validation against SLAs ensures data arrives within expected windows. This is where our Timeliness Engine operates. |
| **Completeness** | Critical | Row count and basic file integrity validation detects ingestion failures early. |
| **Accuracy** | Important | Hash validation at ingestion detects tampering; source-to-lake row count matching confirms complete transit. |

**Governance Responsibility:** Data Engineering teams (pipelines), Data Quality team (monitoring)  
**DQ Team Role:** Active monitoring; Collector Engine executes completeness checks post-ingestion

### Layer 3: Independent Divisional Platforms
*MarTech Data Platform, Healthcare Data Platform, Corporate Data Platform*

| Dimension | Applicability | Rationale |
|-----------|--------------|-----------|
| **Accuracy** | Critical | Business logic validation against source data ensures transformations produce correct results. |
| **Uniqueness** | Critical | Curated data products must be de-duplicated based on domain-specific composite keys. |
| **Completeness** | Critical | Schema adherence for published data products; all required attributes present. |
| **Freshness** | Important | Transformed data must reflect recent source updates to remain valuable. |
| **Consistency** | Important | Standardization ensures downstream consumers receive uniform data regardless of source system variations. |

**Governance Responsibility:** Domain data teams (ownership), Data Quality team (measurement)  
**DQ Team Role:** Primary monitoring layer; most Collector Engine checks execute here

### Layer 4: Enterprise Capability Platform
*Central Data Catalog, Enterprise Tokenization Service, Audience Builder, MDM*

| Dimension | Applicability | Rationale |
|-----------|--------------|-----------|
| **Integrity** | Critical | Tokenization safeguards; metadata entries digitally signed; token mapping reconciliation in secure vault. |
| **Validity** | Critical | Schema enforcement validates incoming data feeds from Layer 3 match registered schemas in the catalog. |
| **Consistency** | Critical | Attribute Catalog requires consistent definitions across divisions for cross-domain queries. |
| **Completeness** | Important | Segment Metadata Catalog must have complete documentation for all published audiences. |

**Governance Responsibility:** Platform Engineering team (central services), Federated Governance body (standards)  
**DQ Team Role:** API uptime monitoring; schema validation; catalog completeness audits

### Layer 5: Activation and Consumption
*Enterprise BI, Campaign Tools, Personalized Healthcare Programs*

| Dimension | Applicability | Rationale |
|-----------|--------------|-----------|
| **Accuracy** | Critical | BI dashboard validation; reconciliation against authoritative source data ensures stakeholders see correct numbers. |
| **Timeliness** | Critical | Campaign audiences must be current; quarterly audits of campaign inputs vs outputs detect drift. |
| **Completeness** | Important | Pre-launch campaign audits ensure all required audience attributes are present. |

**Governance Responsibility:** Business stakeholders (validation), Platform team (delivery)  
**DQ Team Role:** Dashboard quality audits; campaign input validation

### Layer-by-Dimension Matrix Summary

| Dimension | L1: Source | L2: Lake | L3: Platforms | L4: Enterprise | L5: Activation |
|-----------|------------|----------|---------------|----------------|----------------|
| Completeness | - | Critical | Critical | Important | Important |
| Timeliness | - | Critical | - | - | Critical |
| Freshness | - | - | Important | - | - |
| Uniqueness | - | - | Critical | - | - |
| Accuracy | - | Important | Critical | - | Critical |
| Validity | Critical | - | - | Critical | - |
| Consistency | Important | - | Important | Critical | - |
| Integrity | Important | - | - | Critical | - |

---

## 3. Data Quality Checks by Layer: Within Pipeline vs. Outside Pipeline

### 3.1 Within-Pipeline Checks (Inline/Embedded)

These checks execute as part of the data pipeline itself, blocking or alerting before data moves forward.

#### Layer 1: Source Systems
| Check Type | Example | Implementation |
|------------|---------|----------------|
| Input Validation | Reject records where email format is invalid | Application code regex validation |
| Type Enforcement | Ensure transaction_amount is numeric, not string | Database constraints |
| Required Fields | Block inserts where customer_id is NULL | NOT NULL constraints |
| Range Validation | Quantity must be between 0 and 10000 | CHECK constraints |

#### Layer 2: Data Lake Ingestion
| Check Type | Example | Implementation |
|------------|---------|----------------|
| File Integrity | Validate file checksum matches manifest | Pipeline pre-processing step |
| Row Count Threshold | Fail if incoming file has < 100 rows (expect 10000+) | Airflow task with conditional logic |
| Schema Validation | Reject files with missing required columns | BigQuery schema auto-detection with strict mode |
| Duplicate Detection | Check for duplicate file deliveries | GCS object metadata comparison |

**Example Airflow Inline Check:**
```python
def validate_row_count(**context):
    expected_min = 10000
    actual_count = get_source_row_count()
    if actual_count < expected_min:
        raise AirflowException(f"Row count {actual_count} below threshold {expected_min}")
```

#### Layer 3: Transformation Pipelines
| Check Type | Example | Implementation |
|------------|---------|----------------|
| Business Rule Validation | Total basket amount must equal sum of item amounts | SQL assertion in transformation |
| Referential Integrity | All offer_ids must exist in offer_master | JOIN validation before load |
| Deduplication | Remove exact duplicates before loading | SQL DISTINCT or window functions |
| Null Propagation Check | Critical business keys cannot become NULL after transformation | CASE statement with error handling |

**Example dbt Test (Recommendation for Engineering Teams):**
```yaml
# schema.yml
models:
  - name: basket_transformed
    tests:
      - unique:
          column_name: basket_id
      - not_null:
          column_name: retailer_source
      - relationships:
          to: ref('retailer_master')
          field: retailer_id
```

### 3.2 Outside-Pipeline Checks (Post-Processing/Monitoring)

These checks execute after data has been loaded, measuring quality and alerting on issues. This is where our Collector Engine operates.

#### Layer 2: Data Lake (Post-Ingestion)
| Check Type | Example | Current Implementation |
|------------|---------|----------------------|
| Timeliness Monitoring | Did ShopperSync data arrive by 6 AM SLO? | Timeliness Engine with Google Chat webhooks |
| Volume Deviation | Is today's row count within 20% of 14-day average? | `target_completeness_*.sql` collectors |
| Source Comparison | Do source and lake row counts match? | `source_completeness_*.sql` collectors |

**Example Collector Query (Target Completeness):**
```sql
-- Compares daily row counts against 14-day rolling average
SELECT source, child_id, parent_id, data_date, value,
       AVG(value) OVER (PARTITION BY source ORDER BY data_date 
                        ROWS BETWEEN 14 PRECEDING AND 1 PRECEDING) as avg_14_days,
       CASE WHEN value < avg_14_days * 0.8 OR value > avg_14_days * 1.2 
            THEN 'SUSPICIOUS' ELSE 'OK' END as status
FROM completeness_results
```

#### Layer 3: Divisional Platforms (Post-Transformation)
| Check Type | Example | Current Implementation |
|------------|---------|----------------------|
| Completeness (Row/Null) | Count rows and nulls per column in basket table | `completeness_shoppersyncdatamart_basket.sql` |
| Uniqueness | Detect duplicates based on composite key (retailerSource, retailerId, basketId) | `uniqueness_shoppersync-shoppersyncdatamart_basket.sql` |
| Freshness | Days since offer table was last updated | `freshness_shoppersync_offerhub_offer.sql` |
| Accuracy | Compare row counts between Informix source and BigQuery target | `completeness_informix_*.sql` vs BigQuery counts |

#### Layer 4: Enterprise Platform
| Check Type | Example | Recommended Implementation |
|------------|---------|---------------------------|
| Catalog Completeness | All published datasets have descriptions and owners | Metadata query against catalog tables |
| Token Reconciliation | Validate token mappings periodically | Secure vault audit job |
| Schema Drift Detection | Alert when incoming schema differs from registered schema | Schema comparison collector |

#### Layer 5: Activation
| Check Type | Example | Recommended Implementation |
|------------|---------|---------------------------|
| Dashboard Reconciliation | BI totals match authoritative source | Scheduled comparison queries |
| Campaign Audience Validation | Audience size reasonable for targeting criteria | Pre-campaign size checks |
| Historical Drift | Compare this week's metrics to last week's baseline | Trend analysis collectors |

### 3.3 Pipeline vs. Post-Processing Decision Matrix

| Factor | Within Pipeline | Outside Pipeline (Collector Engine) |
|--------|-----------------|-------------------------------------|
| **Blocking** | Yes - stops bad data from flowing | No - alerts but doesn't block |
| **Latency** | Adds processing time | Runs asynchronously after load |
| **Ownership** | Engineering team maintains | DQ team maintains |
| **Flexibility** | Requires code changes to modify | SQL-based, easily configurable |
| **Coverage** | Limited to owned pipelines | Can check any accessible data source |
| **Best For** | Critical business rules that must never be violated | Monitoring, trending, anomaly detection |

**Recommendation:** Use a layered approach where inline checks catch critical violations and our Collector Engine provides comprehensive monitoring across all data sources.

---

## 4. Tracking Data Quality on External Engineering Team Pipelines

### 4.1 Current Challenges

External engineering teams (DEG, DataOps, divisional teams) build pipelines that produce data our stakeholders consume. We need visibility into data quality without requiring code changes to their pipelines.

### 4.2 Recommended Approach: Sensor-Based Monitoring

Our Collector Engine already supports this through various sensor types:

| Sensor Type | Use Case | How It Works |
|-------------|----------|--------------|
| **Logging Sensor** | BigQuery tables refreshed by external Airflow DAGs | Monitor GCP logs for task completion messages; trigger DQ checks when data is fresh |
| **Time Sensor** | On-premises databases with known refresh schedules | Execute checks at fixed times when data is expected to be available |
| **GCS Sensor** | Files landing in GCS buckets from external sources | Detect file arrival and trigger validation |
| **BigQuery SQL Sensor** | Custom conditions (e.g., new partition available) | Run a probe query until condition is met, then execute DQ checks |

### 4.3 Implementation Pattern for External Pipelines

**Step 1: Identify Critical External Datasets**
- Maintain the Critical Datasets inventory (currently documented in Confluence)
- Prioritize based on business impact and consumer count

**Step 2: Establish Observability Without Code Changes**
```
External Pipeline                         Our Monitoring
      |                                        |
      v                                        |
[Load Data to BigQuery] ---> [GCP Logs] ----> [Logging Sensor]
      |                                        |
      v                                        v
[Data Available]                    [Trigger Collector Engine]
                                              |
                                              v
                                    [Execute DQ Queries]
                                              |
                                              v
                                    [Store Results in BQ]
                                              |
                                              v
                                    [Dashboard + Alerts]
```

**Step 3: Configure Appropriate Sensors**

For BigQuery tables refreshed by external Airflow DAGs:
```json
{
  "trigger": "logging_sensor",
  "collectionParameters": {
    "sensor_log_payload": "TaskInstance Finished: dag_id=external_dag_name, task_id=final_load_task",
    "sensor_log_project": "external-project-id",
    "sensor_log_token": "sm://secret-id-for-credentials",
    "sensor_timeout_minutes": 600
  }
}
```

For on-premises databases with no log visibility:
```json
{
  "trigger": "time_sensor",
  "cronSchedule": "0 6 * * *",
  "collectionParameters": {
    "sensor_timeout_minutes": 120
  }
}
```

### 4.4 Integration with DataOps

We currently publish Pub/Sub messages to the DataOps project with collector metrics. This enables:

- **Unified Alerting:** DataOps receives quality signals alongside operational metrics
- **Cross-Team Visibility:** Engineering teams can subscribe to quality events for their datasets
- **Automated Remediation:** Future state could trigger pipeline reruns on quality failures

**Current alertParameters Configuration:**
```json
{
  "alertParameters": {
    "pubsub_topic": "projects/dataops-project/topics/dq-alerts",
    "alert_on_error": true,
    "alert_on_warning": true
  }
}
```

### 4.5 Recommended Enhancements

1. **Self-Service Registration:** Allow engineering teams to register their datasets for DQ monitoring through a form or API
2. **Automatic Discovery:** Scan for new tables in monitored datasets and suggest DQ checks
3. **Pipeline Metadata Integration:** Ingest pipeline lineage to understand data flow and identify upstream issues
4. **Federated Dashboards:** Provide team-specific dashboard views filtered to their owned datasets

---

## 5. Helping Teams Drive Better Data Quality

### 5.1 Current Services Offered

Based on our process documentation, we provide:

| Service | Description | Access |
|---------|-------------|--------|
| **Customized Dashboards** | Quality metrics visualization by business unit | Superset (superset.inmar.com) |
| **Automated Alerts** | Email and Google Chat notifications on quality issues | Configured per collector |
| **Scorecard Views** | High-level health indicators (Timeliness, Completeness, Uniqueness) | Scorecard Landing Page dashboard |
| **On-Demand Checks** | Request new DQ checks through Jira or email | gcp-dataquality-engineers@inmar.com |

### 5.2 Proposed Data Quality Enablement Program

To scale our impact, we recommend a structured enablement program:

#### Tier 1: Self-Service Resources
| Resource | Description | Timeline |
|----------|-------------|----------|
| **DQ Standards Documentation** | Published dimensions, thresholds, and best practices | Q1 2026 |
| **Query Templates** | Pre-built SQL patterns for each dimension that teams can customize | Q1 2026 |
| **Dashboard Templates** | Superset dashboard templates teams can clone and configure | Q2 2026 |
| **Office Hours** | Weekly drop-in sessions for DQ questions and guidance | Ongoing |

#### Tier 2: Guided Implementation
| Service | Description | Engagement Model |
|---------|-------------|------------------|
| **Critical Dataset Onboarding** | Full implementation of DQ checks for priority datasets | Annual prioritization process |
| **Composite Key Workshops** | Collaborate with stakeholders to define uniqueness keys | Per-project basis |
| **Alert Configuration** | Set up appropriate notification channels and thresholds | Part of onboarding |
| **Dashboard Buildout** | Create custom dashboards for business unit needs | Quarterly capacity planning |

#### Tier 3: Embedded Partnership
| Service | Description | Engagement Model |
|---------|-------------|------------------|
| **Pipeline Design Review** | Consult on inline DQ checks for new pipelines | On-request |
| **Issue Investigation** | Deep-dive analysis of quality problems with root cause identification | Escalation from Tier 2 |
| **Quality Improvement Projects** | Partner with teams to remediate systemic issues | Quarterly planning |

### 5.3 Data Quality Champions Program

**Concept:** Designate DQ Champions within each major data domain who serve as the first line of contact and promote quality practices within their teams.

**Responsibilities:**
- Attend monthly DQ sync meetings
- Triage quality alerts for their domain
- Advocate for quality improvements in sprint planning
- Provide business context for threshold definitions

**Domains to Target:**
- MarTech (ShopperSync, OfferHub, Katana)
- Healthcare (PRCM, RxReturns)
- Finance (AR/AP, Salesforce)
- Corporate (Workday, ERP)

### 5.4 Quality Metrics Ownership Model

Aligned with the Enterprise Architecture principle of "Domain Ownership," we recommend:

| Role | Responsibility |
|------|----------------|
| **Domain Team** | Define what quality means for their data (thresholds, composite keys, freshness expectations) |
| **DQ Platform Team** | Implement measurement, provide tooling, maintain infrastructure |
| **Data Governance** | Set enterprise standards, arbitrate cross-domain issues |
| **DataOps** | Respond to quality alerts, triage issues, coordinate remediation |

---

## 6. Success Criteria for the Enterprise DQ Program

### 6.1 Quantitative Metrics

| Metric | Baseline (Current) | 2026 Target | Measurement Method |
|--------|-------------------|-------------|-------------------|
| **Critical Datasets Covered** | ~50 tables (ShopperSync, Finance, MTI) | 150+ tables across all divisions | Count of active collectors |
| **Timeliness SLO Achievement** | 85% (estimated) | 95% | Timeliness scorecard |
| **Completeness Score** | 90% (ShopperSync only) | 95% enterprise-wide | Completeness scorecard |
| **Uniqueness Score** | 98% (ShopperSync only) | 99.5% enterprise-wide | Uniqueness scorecard |
| **Mean Time to Detect (MTTD)** | Variable (some issues found by consumers) | < 2 hours from data availability | Alert timestamp vs. data load timestamp |
| **Mean Time to Notify (MTTN)** | < 30 minutes (for monitored datasets) | < 15 minutes | Alert delivery timestamp |
| **Dashboard Adoption** | ~20 active users | 100+ active users | Superset analytics |

### 6.2 Qualitative Outcomes

| Outcome | How We'll Know |
|---------|----------------|
| **Increased Trust in Data** | Stakeholders cite DQ dashboards in decision-making; fewer ad-hoc data validation requests |
| **Proactive Issue Detection** | DQ team identifies issues before consumers report them (shift from reactive to proactive) |
| **Cross-Division Visibility** | Single pane of glass showing quality across MarTech, Healthcare, and Corporate data |
| **Reduced Data Incidents** | Decrease in production incidents caused by data quality problems |
| **Engineering Integration** | Engineering teams proactively request DQ checks for new pipelines |

### 6.3 Program Milestones

| Milestone | Target Date | Deliverables |
|-----------|-------------|--------------|
| **Standards Published** | Q1 2026 | This document approved; dimension definitions published to Confluence |
| **Layer 3 Coverage Expanded** | Q2 2026 | Healthcare and Corporate platforms added to Collector Engine |
| **Self-Service Tools Launched** | Q2 2026 | Query templates and dashboard templates available |
| **Champions Program Active** | Q3 2026 | Champions identified for 4 major domains; monthly syncs established |
| **Enterprise Dashboard Live** | Q3 2026 | Unified scorecard showing all divisions on single view |
| **Layer 4 Monitoring Initiated** | Q4 2026 | Catalog completeness and schema validation checks in production |
| **Year-End Review** | Q4 2026 | Program assessment; 2027 roadmap defined |

### 6.4 Risk Factors and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Stakeholder Engagement** | Medium | High | Executive sponsorship; demonstrate quick wins |
| **Resource Constraints** | High | Medium | Prioritize critical datasets; leverage self-service |
| **Cross-Team Coordination** | Medium | Medium | Champions program; regular sync meetings |
| **Alert Fatigue** | Medium | Medium | Tune thresholds carefully; categorize severity levels |
| **Scope Creep** | Medium | Low | Clear prioritization criteria; quarterly capacity reviews |

---

## 7. Recommendations and Next Steps

### 7.1 Immediate Actions (Q1 2026)

1. **Formalize Dimension Definitions:** Publish the five core dimensions (Completeness, Timeliness, Freshness, Uniqueness, Accuracy) as official enterprise standards.

2. **Expand Layer 2/3 Coverage:** Prioritize Healthcare and Corporate data platforms for Collector Engine onboarding.

3. **Document Threshold Guidelines:** Create guidance for teams on how to set appropriate thresholds (e.g., what constitutes acceptable freshness for different use cases).

4. **Launch Champions Program:** Identify and onboard DQ Champions for MarTech and Healthcare domains.

### 7.2 Medium-Term Initiatives (Q2-Q3 2026)

1. **Self-Service Toolkit:** Develop and publish query templates, dashboard templates, and onboarding guides.

2. **Enterprise Dashboard:** Build unified scorecard view aggregating quality metrics across all monitored datasets.

3. **Pipeline Integration Guidance:** Create best practices documentation for inline DQ checks that engineering teams can adopt.

4. **Automated Discovery:** Pilot automatic detection of new tables in monitored datasets with suggested DQ checks.

### 7.3 Long-Term Vision (Q4 2026 and Beyond)

1. **Layer 4 Integration:** Extend monitoring to Enterprise Capability Platform (Catalog, Tokenization, MDM).

2. **Predictive Quality:** Use historical data to predict quality issues before they occur (e.g., trending toward threshold violation).

3. **Quality-as-Code:** Enable teams to define DQ checks in their pipeline repositories with automatic deployment.

4. **Cross-Division Lineage:** Integrate with data lineage tools to trace quality issues to root causes across system boundaries.

---

## 8. Alignment with Enterprise Architecture Principles

| Architecture Principle | How DQ Program Supports It |
|----------------------|---------------------------|
| **Domain Ownership** | Domains define their quality requirements; DQ team provides measurement infrastructure |
| **Data as a Product** | Quality metrics are part of the product specification; published alongside data documentation |
| **Security by Design** | DQ checks validate tokenization integrity and access controls without exposing sensitive data |
| **Self-Serve Platform** | Self-service tools empower teams to monitor their own data quality |
| **Federated Governance** | Central DQ team sets standards; domains execute compliance through their pipelines |

---

## Appendix A: Current Collector Engine Inventory Summary

| Dimension | Script Prefix | Active Collectors (approx.) |
|-----------|--------------|---------------------------|
| Completeness | `completeness_` | 150+ |
| Target Completeness | `target_completeness_` | 30+ |
| Uniqueness | `uniqueness_` | 60+ |
| Freshness | `freshness_` | 10+ |
| Accuracy (Source Comparison) | `source_completeness_` | 10+ |
| Integrity | `integrity_` | 2 |
| Timeliness | `timeliness_` | 5+ |

## Appendix B: Superset Dashboard Inventory

| Dashboard | Focus | Audience |
|-----------|-------|----------|
| Scorecard Landing Page | Enterprise-wide health overview | All stakeholders |
| ShopperSync Data Completeness | MarTech completeness metrics | Analytics, DO, DEG |
| ShopperSync Data Uniqueness | Duplicate detection for ShopperSync | Analytics, DO |
| Offerhub Data Freshness | Freshness metrics for Offer data | Marketing Ops |
| RxReturns Data Accuracy | Source-target comparison for Healthcare | HC Data Team |
| Today's Export Status | Real-time timeliness for ShopperSync | DO, DEG |
| Exports Over Time | Historical timeliness trends | Analytics |

## Appendix C: Contact and Resources

| Resource | Location |
|----------|----------|
| DQ Team Email | gcp-dataquality-engineers@inmar.com |
| Jira Board | Data Quality - Platform Engineering |
| Confluence Space | [Data Quality Platform Engineering](https://inmardigital.atlassian.net/wiki/spaces/DQPE/overview) |
| GitHub Repository | inmar/data_governance_dq |
| Terraform Infrastructure | inmar/inm-data-governance-terraform |
| Superset Production | superset.inmar.com |

---

*This document serves as the foundation for establishing Enterprise Data Quality Standards at Inmar. It should be reviewed and approved by Data Governance leadership before formal publication.*
