# AWS EMR Step - Architecture Notes

## Resource Purpose

AWS EMR Step provides the execution unit for big data processing workflows, enabling orchestrated execution of Spark jobs, Hive queries, Pig scripts, and custom applications with fine-grained control over resource allocation, failure handling, and dependency management within EMR clusters.

## Key Architectural Patterns

### Workflow Orchestration Pattern
- **Sequential Processing**: Steps execute in dependency order with configurable failure handling
- **Parallel Execution**: Multiple steps can run concurrently based on concurrency limits
- **Conditional Logic**: Steps can implement conditional execution based on previous step outcomes
- **Resource Awareness**: Step execution adapts to cluster resource availability and utilization

### Data Processing Pipeline Pattern
- **Extract-Transform-Load (ETL)**: Coordinated data movement and transformation steps
- **Validation-Process-Aggregate**: Data quality gates followed by processing and summarization
- **Branch-Merge Processing**: Parallel processing paths that reconverge for final aggregation
- **Incremental Processing**: Delta processing with checkpoint management and state recovery

### Multi-Engine Integration Pattern
- **Polyglot Analytics**: Different engines (Spark, Hive, Presto) for different workload characteristics
- **Format Transformation**: Steps that convert between data formats and storage optimizations
- **Cross-Platform Processing**: Integration with external systems and data sources
- **Hybrid Batch-Stream**: Steps that bridge batch and streaming processing paradigms

## Architecture Integration Points

### Complex Data Processing Pipeline
```ruby
# Multi-stage data lake processing with sophisticated error handling
base_cluster = aws_emr_cluster(:pipeline_cluster, {
  name: "data-processing-pipeline",
  release_label: "emr-6.15.0",
  applications: ["Hadoop", "Spark", "Hive", "Pig"],
  step_concurrency_level: 5 # Allow multiple steps to run concurrently
})

# Step 1: Data Validation and Quality Assessment
validation_step = aws_emr_step(:data_validation,
  EmrStepAttributes.spark_step(
    "Data Quality Validation",
    "s3://pipeline-apps/data-validator.py",
    {
      deploy_mode: "cluster",
      driver_memory: "4g",
      driver_cores: "2",
      executor_memory: "8g",
      executor_cores: "4",
      num_executors: "15",
      spark_conf: "spark.sql.adaptive.enabled=true,spark.sql.adaptive.coalescePartitions.enabled=true",
      app_args: [
        "--input-path", "s3://raw-data/daily/#{Date.today}",
        "--schema-registry", "s3://schemas/",
        "--quality-rules", "s3://quality-rules/standard.json",
        "--validation-output", "s3://validation-results/#{Date.today}",
        "--failure-threshold", "0.05",
        "--detailed-report", "true"
      ],
      action_on_failure: "CANCEL_AND_WAIT" # Critical - must investigate data issues
    }
  ).merge({
    cluster_id: base_cluster.outputs[:id],
    description: "Comprehensive data quality validation with schema enforcement"
  })
)

# Step 2: Data Deduplication and Cleansing  
deduplication_step = aws_emr_step(:data_deduplication,
  EmrStepAttributes.spark_step(
    "Data Deduplication and Cleansing",
    "s3://pipeline-apps/deduplicator.jar",
    {
      deploy_mode: "cluster",
      driver_memory: "6g",
      executor_memory: "12g",
      executor_cores: "6",
      num_executors: "20",
      spark_conf: "spark.sql.adaptive.enabled=true,spark.sql.adaptive.skewJoin.enabled=true",
      app_args: [
        "--source", "s3://raw-data/daily/#{Date.today}",
        "--target", "s3://cleansed-data/daily/#{Date.today}",
        "--dedup-strategy", "latest_timestamp",
        "--partition-columns", "date,region",
        "--checkpoint-location", "s3://checkpoints/dedup/#{Date.today}"
      ],
      action_on_failure: "CONTINUE" # Can proceed with partial data if needed
    }
  ).merge({
    cluster_id: base_cluster.outputs[:id],
    description: "Remove duplicates and apply data cleansing rules"
  })
)

# Step 3: Business Logic Transformation
transformation_step = aws_emr_step(:business_transformation,
  EmrStepAttributes.hive_step(
    "Business Logic Transformation",
    "s3://hive-scripts/business-transforms.hql",
    {
      variables: {
        "processing_date" => Date.today.to_s,
        "source_database" => "cleansed_data",
        "target_database" => "business_data",
        "enrichment_tables" => "customer_profiles,product_catalog",
        "partition_spec" => "date='#{Date.today}'"
      },
      action_on_failure: "CONTINUE"
    }
  ).merge({
    cluster_id: base_cluster.outputs[:id],
    description: "Apply business rules and enrich data with reference information"
  })
)

# Step 4: Parallel Analytics Processing
customer_analytics_step = aws_emr_step(:customer_analytics,
  EmrStepAttributes.spark_step(
    "Customer Analytics Processing",
    "s3://analytics-apps/customer-insights.py",
    {
      driver_memory: "8g",
      executor_memory: "16g",
      executor_cores: "8",
      num_executors: "12",
      app_args: [
        "--source-table", "business_data.customer_interactions",
        "--target-path", "s3://analytics-results/customer-insights/#{Date.today}",
        "--analytics-types", "segmentation,churn_prediction,lifetime_value",
        "--model-registry", "s3://ml-models/customer/"
      ]
    }
  ).merge({
    cluster_id: base_cluster.outputs[:id],
    description: "Generate customer analytics and insights"
  })
)

product_analytics_step = aws_emr_step(:product_analytics,
  EmrStepAttributes.spark_step(
    "Product Analytics Processing", 
    "s3://analytics-apps/product-insights.py",
    {
      driver_memory: "6g",
      executor_memory: "12g",
      executor_cores: "6",
      num_executors: "10",
      app_args: [
        "--source-table", "business_data.product_interactions",
        "--target-path", "s3://analytics-results/product-insights/#{Date.today}",
        "--analytics-types", "recommendation,trend_analysis,inventory_optimization"
      ]
    }
  ).merge({
    cluster_id: base_cluster.outputs[:id],
    description: "Generate product analytics and recommendations"
  })
)

# Step 5: Data Quality Monitoring
quality_monitoring_step = aws_emr_step(:quality_monitoring,
  EmrStepAttributes.custom_jar_step(
    "Data Quality Monitoring",
    "s3://monitoring-apps/quality-monitor.jar",
    "com.company.QualityMonitor",
    {
      args: [
        "--processed-data", "s3://analytics-results/",
        "--quality-metrics", "completeness,accuracy,consistency,timeliness",
        "--alert-thresholds", "s3://configs/quality-thresholds.json",
        "--notification-topic", "arn:aws:sns:region:account:data-quality-alerts"
      ],
      properties: {
        "spark.sql.adaptive.enabled" => "true",
        "spark.dynamicAllocation.enabled" => "true"
      },
      action_on_failure: "CONTINUE"
    }
  ).merge({
    cluster_id: base_cluster.outputs[:id],
    description: "Monitor data quality metrics and generate alerts"
  })
)

# Step 6: Data Archive and Cleanup
archive_step = aws_emr_step(:data_archive,
  EmrStepAttributes.s3_copy_step(
    "Archive Processed Data",
    "s3://temp-processing/#{Date.today}",
    "s3://data-archive/#{Date.today.year}/#{Date.today.month}",
    {
      src_pattern: ".*\\.parquet$",
      output_codec: "gzip",
      target_size: "1024",
      action_on_failure: "CONTINUE"
    }
  ).merge({
    cluster_id: base_cluster.outputs[:id],
    description: "Archive processed data and clean up temporary files"
  })
)
```

### Machine Learning Pipeline Architecture
```ruby
# ML pipeline with feature engineering, training, and model deployment
ml_cluster = aws_emr_cluster(:ml_pipeline_cluster, {
  name: "ml-training-pipeline",
  release_label: "emr-6.15.0",
  applications: ["Hadoop", "Spark", "JupyterHub"],
  step_concurrency_level: 3
})

# Feature engineering pipeline
feature_extraction_step = aws_emr_step(:feature_extraction,
  EmrStepAttributes.spark_step(
    "Feature Extraction and Engineering",
    "s3://ml-apps/feature-engineer.py",
    {
      deploy_mode: "cluster",
      driver_memory: "16g",
      driver_cores: "4",
      executor_memory: "32g", 
      executor_cores: "8",
      num_executors: "20",
      spark_conf: "spark.sql.adaptive.enabled=true,spark.sql.adaptive.localShuffleReader.enabled=true",
      app_args: [
        "--raw-data", "s3://ml-data/raw/",
        "--feature-output", "s3://ml-features/processed/",
        "--feature-definitions", "s3://ml-configs/features.yaml",
        "--time-windows", "1d,7d,30d",
        "--aggregation-functions", "sum,avg,count,stddev",
        "--categorical-encoding", "target_encoding",
        "--missing-value-strategy", "interpolation"
      ]
    }
  ).merge({
    cluster_id: ml_cluster.outputs[:id],
    description: "Extract and engineer features for ML training"
  })
)

# Data splitting for train/validation/test
data_split_step = aws_emr_step(:data_split,
  EmrStepAttributes.spark_step(
    "Train/Validation/Test Split",
    "s3://ml-apps/data-splitter.py",
    {
      driver_memory: "8g",
      executor_memory: "16g",
      num_executors: "10",
      app_args: [
        "--feature-data", "s3://ml-features/processed/",
        "--train-output", "s3://ml-features/train/",
        "--validation-output", "s3://ml-features/validation/",
        "--test-output", "s3://ml-features/test/",
        "--split-ratios", "0.7,0.15,0.15",
        "--stratify-column", "target",
        "--random-seed", "42"
      ]
    }
  ).merge({
    cluster_id: ml_cluster.outputs[:id],
    description: "Split data into train/validation/test sets"
  })
)

# Hyperparameter tuning
hyperparameter_tuning_step = aws_emr_step(:hyperparameter_tuning,
  EmrStepAttributes.spark_step(
    "Hyperparameter Tuning",
    "s3://ml-apps/hyperparameter-tuner.py",
    {
      deploy_mode: "cluster",
      driver_memory: "32g",
      driver_cores: "8", 
      executor_memory: "64g",
      executor_cores: "16",
      num_executors: "15",
      spark_conf: "spark.sql.adaptive.enabled=true,spark.dynamicAllocation.enabled=false",
      app_args: [
        "--train-data", "s3://ml-features/train/",
        "--validation-data", "s3://ml-features/validation/",
        "--algorithm", "gradient_boosting",
        "--tuning-strategy", "bayesian_optimization",
        "--max-trials", "100",
        "--parallel-trials", "10",
        "--early-stopping", "true",
        "--results-output", "s3://ml-results/tuning/"
      ]
    }
  ).merge({
    cluster_id: ml_cluster.outputs[:id],
    description: "Perform hyperparameter optimization"
  })
)

# Model training with best parameters
model_training_step = aws_emr_step(:model_training,
  EmrStepAttributes.spark_step(
    "Final Model Training",
    "s3://ml-apps/model-trainer.py",
    {
      driver_memory: "16g",
      executor_memory: "32g",
      num_executors: "20",
      app_args: [
        "--train-data", "s3://ml-features/train/",
        "--validation-data", "s3://ml-features/validation/",
        "--hyperparams", "s3://ml-results/tuning/best_params.json",
        "--model-output", "s3://ml-models/production/",
        "--model-metadata", "s3://ml-models/metadata/",
        "--feature-importance", "true",
        "--model-explainability", "true"
      ]
    }
  ).merge({
    cluster_id: ml_cluster.outputs[:id],
    description: "Train final production model"
  })
)

# Model validation and testing
model_validation_step = aws_emr_step(:model_validation,
  EmrStepAttributes.spark_step(
    "Model Validation and Testing",
    "s3://ml-apps/model-validator.py", 
    {
      driver_memory: "8g",
      executor_memory: "16g",
      num_executors: "8",
      app_args: [
        "--model-path", "s3://ml-models/production/",
        "--test-data", "s3://ml-features/test/",
        "--validation-metrics", "accuracy,precision,recall,f1,auc",
        "--performance-threshold", "0.85",
        "--fairness-checks", "true",
        "--drift-detection", "true",
        "--results-output", "s3://ml-results/validation/"
      ],
      action_on_failure: "CANCEL_AND_WAIT" # Critical - model must pass validation
    }
  ).merge({
    cluster_id: ml_cluster.outputs[:id],
    description: "Validate model performance and fairness"
  })
)
```

### Stream Processing Integration Architecture  
```ruby
# Real-time and batch processing coordination
streaming_cluster = aws_emr_cluster(:stream_batch_cluster, {
  name: "streaming-batch-coordinator",
  applications: ["Hadoop", "Spark", "Flink"],
  keep_job_flow_alive_when_no_steps: true
})

# Streaming checkpoint reconciliation
checkpoint_reconciliation_step = aws_emr_step(:checkpoint_reconciliation,
  EmrStepAttributes.spark_step(
    "Streaming Checkpoint Reconciliation",
    "s3://streaming-apps/checkpoint-reconciler.py",
    {
      driver_memory: "4g",
      executor_memory: "8g",
      num_executors: "6",
      app_args: [
        "--checkpoint-location", "s3://streaming-checkpoints/",
        "--batch-results", "s3://batch-results/daily/",
        "--reconciliation-window", "24h",
        "--tolerance-threshold", "0.001",
        "--correction-output", "s3://reconciliation-corrections/"
      ]
    }
  ).merge({
    cluster_id: streaming_cluster.outputs[:id],
    description: "Reconcile streaming results with batch processing"
  })
)

# Late data processing
late_data_processing_step = aws_emr_step(:late_data_processing,
  EmrStepAttributes.spark_step(
    "Late Arriving Data Processing",
    "s3://streaming-apps/late-data-processor.py",
    {
      driver_memory: "6g",
      executor_memory: "12g",
      num_executors: "10",
      spark_conf: "spark.sql.adaptive.enabled=true,spark.streaming.backpressure.enabled=true",
      app_args: [
        "--late-data-path", "s3://late-arrivals/",
        "--watermark-delay", "2 hours",
        "--output-mode", "update",
        "--trigger-interval", "10 minutes",
        "--state-store", "s3://stream-state/"
      ]
    }
  ).merge({
    cluster_id: streaming_cluster.outputs[:id],
    description: "Process late-arriving streaming data"
  })
)

# Stream-batch join processing
stream_batch_join_step = aws_emr_step(:stream_batch_join,
  EmrStepAttributes.spark_step(
    "Stream-Batch Data Join",
    "s3://analytics-apps/stream-batch-joiner.py",
    {
      driver_memory: "8g",
      executor_memory: "16g",
      num_executors: "15",
      app_args: [
        "--streaming-data", "s3://streaming-results/",
        "--batch-data", "s3://batch-results/",
        "--join-keys", "customer_id,timestamp",
        "--join-window", "1 hour",
        "--output-path", "s3://unified-analytics/"
      ]
    }
  ).merge({
    cluster_id: streaming_cluster.outputs[:id],
    description: "Join streaming and batch data for unified analytics"
  })
)
```

### Multi-Tenant Processing Architecture
```ruby
# Multi-tenant data processing with resource isolation
multi_tenant_cluster = aws_emr_cluster(:multi_tenant_processing, {
  name: "multi-tenant-data-platform",
  step_concurrency_level: 10 # Support multiple tenant processing
})

# Tenant-specific processing steps
%w[tenant_a tenant_b tenant_c].each do |tenant|
  tenant_etl_step = aws_emr_step(:"#{tenant}_etl",
    EmrStepAttributes.spark_step(
      "#{tenant.upcase} ETL Processing",
      "s3://tenant-apps/etl-processor.py",
      {
        driver_memory: "4g",
        executor_memory: "8g",
        num_executors: "8",
        spark_conf: "spark.sql.adaptive.enabled=true,spark.scheduler.pool=#{tenant}",
        app_args: [
          "--tenant-id", tenant,
          "--source-path", "s3://tenant-data/#{tenant}/raw/",
          "--target-path", "s3://tenant-data/#{tenant}/processed/",
          "--processing-rules", "s3://tenant-configs/#{tenant}/rules.json",
          "--quality-threshold", "0.95",
          "--resource-pool", tenant
        ]
      }
    ).merge({
      cluster_id: multi_tenant_cluster.outputs[:id],
      description: "Process data for #{tenant}"
    })
  )
  
  # Tenant-specific analytics
  tenant_analytics_step = aws_emr_step(:"#{tenant}_analytics",
    EmrStepAttributes.hive_step(
      "#{tenant.upcase} Analytics",
      "s3://analytics-scripts/tenant-analytics.hql",
      {
        variables: {
          "tenant_id" => tenant,
          "source_database" => "#{tenant}_processed",
          "target_database" => "#{tenant}_analytics",
          "processing_date" => Date.today.to_s
        }
      }
    ).merge({
      cluster_id: multi_tenant_cluster.outputs[:id],
      description: "Generate analytics for #{tenant}"
    })
  )
end

# Cross-tenant aggregation (privacy-preserving)
cross_tenant_aggregation_step = aws_emr_step(:cross_tenant_aggregation,
  EmrStepAttributes.spark_step(
    "Cross-Tenant Aggregated Analytics",
    "s3://platform-apps/cross-tenant-aggregator.py",
    {
      driver_memory: "8g",
      executor_memory: "16g",
      num_executors: "12",
      app_args: [
        "--tenant-data-paths", "s3://tenant-data/*/processed/",
        "--aggregation-level", "platform",
        "--privacy-mode", "differential_privacy",
        "--epsilon", "1.0",
        "--output-path", "s3://platform-analytics/aggregated/"
      ]
    }
  ).merge({
    cluster_id: multi_tenant_cluster.outputs[:id],
    description: "Generate privacy-preserving cross-tenant analytics"
  })
)
```

## Performance Optimization Patterns

### Resource-Aware Step Orchestration
```ruby
# Dynamic resource allocation based on cluster capacity
resource_aware_step = aws_emr_step(:adaptive_processing,
  EmrStepAttributes.spark_step(
    "Adaptive Resource Processing",
    "s3://adaptive-apps/resource-aware-processor.py",
    {
      # Dynamic configuration based on cluster state
      driver_memory: "#{cluster_memory_per_node * 0.1}g",
      executor_memory: "#{cluster_memory_per_node * 0.7}g",
      num_executors: "#{cluster_core_instances * cores_per_instance - 2}",
      spark_conf: "spark.dynamicAllocation.enabled=true,spark.dynamicAllocation.maxExecutors=#{cluster_max_capacity}",
      app_args: [
        "--auto-tune", "true",
        "--resource-monitoring", "enabled",
        "--adaptive-partitioning", "true"
      ]
    }
  ).merge({
    cluster_id: cluster.outputs[:id]
  })
)
```

### Cost-Optimized Processing
```ruby
# Spot instance aware processing
spot_optimized_step = aws_emr_step(:spot_processing,
  EmrStepAttributes.spark_step(
    "Spot-Optimized Processing",
    "s3://spot-apps/fault-tolerant-processor.py",
    {
      driver_memory: "4g",
      executor_memory: "6g", # Smaller executors for faster recovery
      num_executors: "30",   # More executors for fault tolerance
      spark_conf: "spark.sql.adaptive.enabled=true,spark.speculation=true,spark.task.maxAttempts=5",
      app_args: [
        "--checkpoint-interval", "30s",
        "--failure-recovery", "aggressive",
        "--spot-instance-handling", "enabled"
      ]
    }
  ).merge({
    cluster_id: cluster.outputs[:id],
    action_on_failure: "CONTINUE" # Continue despite spot interruptions
  })
)
```

This step resource enables sophisticated data processing workflows that coordinate complex multi-stage pipelines with intelligent resource management, failure handling, and performance optimization across diverse big data processing engines.