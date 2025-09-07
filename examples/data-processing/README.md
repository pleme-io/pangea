# Data Processing Pipeline Infrastructure

This example demonstrates a comprehensive data processing pipeline using Pangea, showcasing real-time streaming, batch processing, and data lake architecture with AWS services.

## Overview

The data processing pipeline includes:

- **Data Lake Architecture**: Multi-zone S3 storage with lifecycle management
- **Real-Time Streaming**: Kinesis Data Streams and Analytics for live data
- **Batch Processing**: AWS Glue ETL and EMR for large-scale analytics
- **Workflow Orchestration**: Step Functions for pipeline automation
- **Data Catalog**: Glue Data Catalog for metadata management
- **Security**: End-to-end encryption with KMS
- **Cost Optimization**: Lifecycle policies and auto-scaling

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Data Sources                                  │
│              (Applications, IoT, Logs, APIs)                        │
└────────────────────┬───────────────────────────┬────────────────────┘
                     │                           │
              Stream │                           │ Batch
                     ▼                           ▼
         ┌──────────────────┐         ┌──────────────────┐
         │ Kinesis Streams  │         │   S3 Raw Data    │
         │ (Real-time)      │         │   (Data Lake)    │
         └─────────┬────────┘         └─────────┬────────┘
                   │                             │
         ┌─────────▼────────┐                   │
         │ Kinesis Analytics│                   │
         │ (Stream Process) │                   │
         └─────────┬────────┘                   │
                   │                             │
         ┌─────────▼────────┐         ┌─────────▼────────┐
         │ Lambda Transform │         │  Glue Crawler    │
         │ (Enrichment)     │         │ (Schema Discovery)│
         └─────────┬────────┘         └─────────┬────────┘
                   │                             │
         ┌─────────▼────────┐         ┌─────────▼────────┐
         │ Kinesis Firehose │         │   Glue ETL Job   │
         │ (S3 Delivery)    │         │ (Transformation) │
         └─────────┬────────┘         └─────────┬────────┘
                   │                             │
                   └──────────┬──────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        S3 Data Lake                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  Raw Zone   │─▶│ Processed    │─▶│ Curated Zone │              │
│  │ (Original)  │  │    Zone      │  │ (Analytics)  │              │
│  └─────────────┘  └──────────────┘  └──────┬───────┘              │
└─────────────────────────────────────────────┼───────────────────────┘
                                              │
                              ┌───────────────┴────────────────┐
                              │                                │
                    ┌─────────▼────────┐          ┌────────────▼────────┐
                    │   EMR Cluster    │          │   Analytics Tools   │
                    │ (Big Data)       │          │ (Athena, QuickSight)│
                    └──────────────────┘          └─────────────────────┘
```

## Templates

### 1. Data Lake Foundation (`data_lake_foundation`)

Core data storage and networking:
- S3 buckets for raw, processed, curated, and results data
- KMS encryption key for data at rest
- S3 lifecycle policies for cost optimization
- VPC with private subnets for compute resources
- Glue Data Catalog database
- CloudWatch log groups

### 2. Streaming Infrastructure (`streaming_infrastructure`)

Real-time data processing:
- Kinesis Data Streams for ingestion
- Kinesis Analytics for SQL-based stream processing
- Lambda functions for data transformation
- Kinesis Firehose for S3 delivery
- Automatic partitioning by date/time
- Parquet conversion for analytics

### 3. Batch Processing (`batch_processing`)

Large-scale data processing:
- Glue crawlers for schema discovery
- Glue ETL jobs for transformation
- EMR cluster for advanced analytics (production)
- Step Functions for workflow orchestration
- Scheduled processing with CloudWatch Events
- Auto-scaling for cost efficiency

## Deployment

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. S3 buckets for Terraform state (if using remote backend)
3. Sufficient IAM permissions for all services

### Development Environment

```bash
# Deploy all templates
pangea apply infrastructure.rb

# Deploy individual templates in order
pangea apply infrastructure.rb --template data_lake_foundation
pangea apply infrastructure.rb --template streaming_infrastructure
pangea apply infrastructure.rb --template batch_processing
```

### Production Environment

```bash
# Enable EMR cluster for production
export ENABLE_EMR=true
export KINESIS_SHARD_COUNT=10

# Deploy with production configurations
pangea apply infrastructure.rb --namespace production --no-auto-approve
```

## Data Flow

### Real-Time Processing

1. **Data Ingestion**: Applications send events to Kinesis Data Streams
2. **Stream Analytics**: Kinesis Analytics processes and enriches data
3. **Transformation**: Lambda functions apply business logic
4. **Storage**: Firehose delivers to S3 in Parquet format

### Batch Processing

1. **Raw Data**: Files land in S3 raw zone
2. **Discovery**: Glue Crawler discovers schema
3. **ETL**: Glue jobs transform and aggregate data
4. **Analytics**: EMR runs complex analytics jobs
5. **Results**: Output stored in curated zone

## Sample Data Producer

Create a Python script to send sample data:

```python
import boto3
import json
import random
import time
from datetime import datetime

kinesis = boto3.client('kinesis', region_name='us-east-1')
stream_name = 'data-processing-main-stream-development'

event_types = ['page_view', 'button_click', 'form_submit', 'api_call']
user_ids = [f'user_{i}' for i in range(1000)]

while True:
    event = {
        'event_time': datetime.utcnow().isoformat() + 'Z',
        'user_id': random.choice(user_ids),
        'event_type': random.choice(event_types),
        'event_data': {
            'page': f'/page_{random.randint(1, 100)}',
            'duration': random.randint(100, 5000),
            'success': random.choice([True, False])
        }
    }
    
    kinesis.put_record(
        StreamName=stream_name,
        Data=json.dumps(event),
        PartitionKey=event['user_id']
    )
    
    print(f"Sent event: {event['event_type']} for {event['user_id']}")
    time.sleep(0.1)
```

## Querying Data with Athena

Once data is processed, query it using Athena:

```sql
-- Create external table for processed data
CREATE EXTERNAL TABLE processed_events (
    event_time timestamp,
    user_id string,
    event_type string,
    event_data string,
    processed_timestamp timestamp,
    hour_of_day int,
    day_of_week int
)
STORED AS PARQUET
LOCATION 's3://data-lake-processed-{namespace}-{random}/processed/detailed/'
PARTITIONED BY (event_date date);

-- Query hourly aggregates
SELECT 
    event_date,
    event_hour,
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM hourly_aggregates
WHERE event_date >= current_date - interval '7' day
GROUP BY event_date, event_hour, event_type
ORDER BY event_date DESC, event_hour DESC;
```

## Monitoring and Observability

### CloudWatch Dashboards

Monitor pipeline health:
- Kinesis stream metrics (records, throughput)
- Glue job success/failure rates
- EMR cluster utilization
- S3 storage growth

### Alarms

Set up alerts for:
- Kinesis stream throttling
- Glue job failures
- EMR cluster issues
- Step Functions execution failures

## Cost Optimization

### Storage Lifecycle

- **Raw Data**: Transitions to Glacier after 90 days
- **Processed Data**: Moves to Infrequent Access after 60 days
- **Old Data**: Expires after retention period

### Compute Optimization

- **Kinesis**: On-demand mode for development
- **EMR**: Auto-scaling based on workload
- **Glue**: DPU allocation based on job size

## Security Best Practices

1. **Encryption**: KMS keys for all data at rest
2. **Network Isolation**: Private subnets for compute
3. **IAM Roles**: Least privilege access
4. **Audit Trail**: CloudTrail for all API calls
5. **Data Classification**: Tag-based access control

## Troubleshooting

### Common Issues

1. **Kinesis Throttling**
   - Increase shard count
   - Implement exponential backoff
   - Use Kinesis Scaling Utility

2. **Glue Job Failures**
   - Check CloudWatch logs
   - Verify IAM permissions
   - Validate data schema

3. **EMR Performance**
   - Review Spark configurations
   - Check instance types
   - Monitor YARN metrics

## Advanced Features

### Custom Processing

Add custom Glue jobs by creating new scripts:

```python
# custom_aggregation.py
from pyspark.sql import functions as F

# Custom aggregation logic
daily_summary = df.groupBy(
    F.date_trunc('day', 'event_time').alias('day')
).agg(
    F.count('*').alias('total_events'),
    F.countDistinct('user_id').alias('unique_users'),
    F.avg('duration').alias('avg_duration')
)
```

### Machine Learning Integration

Use processed data for ML:
1. Export curated data to SageMaker
2. Train models on historical patterns
3. Deploy models for real-time scoring
4. Store predictions back to data lake

## Clean Up

Remove infrastructure in reverse order:

```bash
# Stop streaming data first
pangea destroy infrastructure.rb --template batch_processing
pangea destroy infrastructure.rb --template streaming_infrastructure
pangea destroy infrastructure.rb --template data_lake_foundation
```

## Next Steps

1. Implement data quality checks
2. Add data lineage tracking
3. Set up cross-region replication
4. Implement GDPR compliance features
5. Add real-time alerting for anomalies