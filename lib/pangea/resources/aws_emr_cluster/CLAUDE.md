# AWS EMR Cluster - Architecture Notes

## Resource Purpose

AWS EMR Cluster provides managed big data processing infrastructure that scales from single-node development environments to massive production clusters, supporting Hadoop ecosystem applications, Spark analytics, machine learning workloads, and interactive data science with built-in auto-scaling, fault tolerance, and cost optimization.

## Key Architectural Patterns

### Elastic Computing Pattern
- **Dynamic Resource Allocation**: Auto-scaling task instance groups based on workload demand
- **Mixed Instance Types**: Master, core, and task nodes optimized for different workload characteristics
- **Spot Instance Integration**: Cost optimization through intelligent spot instance management
- **Multi-AZ Resilience**: Geographic distribution for fault tolerance and availability

### Data Lake Processing Pattern
- **Storage-Compute Separation**: HDFS on cluster with S3 as persistent data lake storage
- **Catalog Integration**: Seamless integration with Glue Data Catalog for metadata management
- **Format Optimization**: Native support for columnar formats (Parquet, ORC) and compression
- **Partition-Aware Processing**: Intelligent partition pruning and predicate pushdown

### Stream-Batch Hybrid Pattern
- **Unified Processing Model**: Same cluster handling both batch and streaming workloads
- **Lambda Architecture Support**: Speed layer (streaming) and batch layer on same infrastructure
- **Checkpoint Management**: Persistent state management for fault-tolerant stream processing
- **Real-time Analytics**: Sub-second latency capabilities with Spark Streaming

## Architecture Integration Points

### Data Lake Analytics Architecture
```ruby
# Multi-purpose analytics cluster with comprehensive data lake integration
analytics_platform = aws_emr_cluster(:analytics_platform, {
  name: "unified-analytics-platform",
  release_label: "emr-6.15.0",
  description: "Unified platform for batch and streaming analytics",
  **EmrClusterAttributes.workload_configurations[:data_engineering],
  service_role: "arn:aws:iam::123456789012:role/EMRServiceRole",
  ec2_attributes: {
    instance_profile: "arn:aws:iam::123456789012:instance-profile/EMRDataLakeProfile",
    key_name: "analytics-platform-key",
    subnet_ids: ["subnet-analytics-a", "subnet-analytics-b", "subnet-analytics-c"],
    emr_managed_master_security_group: "sg-emr-master-analytics",
    emr_managed_slave_security_group: "sg-emr-worker-analytics",
    additional_master_security_groups: ["sg-notebook-access", "sg-monitoring"],
    additional_slave_security_groups: ["sg-data-access"]
  },
  master_instance_group: {
    instance_type: "r5.2xlarge" # Memory-optimized for Spark driver
  },
  core_instance_group: {
    instance_type: "r5.xlarge",
    instance_count: 6,
    ebs_config: {
      ebs_optimized: true,
      ebs_block_device_config: [
        {
          volume_specification: {
            volume_type: "gp3",
            size_in_gb: 200,
            iops: 8000
          },
          volumes_per_instance: 2
        }
      ]
    }
  },
  task_instance_groups: [
    # Spot instances for batch processing
    {
      name: "batch-processing-spot",
      instance_role: "TASK",
      instance_type: "m5.2xlarge",
      instance_count: 8,
      bid_price: "0.15",
      auto_scaling_policy: {
        constraints: {
          min_capacity: 4,
          max_capacity: 50
        },
        rules: [
          {
            name: "ScaleOutOnContainerPending",
            description: "Scale out when containers are pending",
            action: {
              market: "SPOT",
              simple_scaling_policy_configuration: {
                adjustment_type: "CHANGE_IN_CAPACITY",
                scaling_adjustment: 4,
                cool_down: 300
              }
            },
            trigger: {
              cloud_watch_alarm_definition: {
                comparison_operator: "GREATER_THAN",
                evaluation_periods: 2,
                metric_name: "ContainerPendingRatio",
                namespace: "AWS/ElasticMapReduce",
                period: 300,
                statistic: "AVERAGE",
                threshold: 0.3
              }
            }
          },
          {
            name: "ScaleInOnLowUtilization",
            description: "Scale in when cluster utilization is low",
            action: {
              simple_scaling_policy_configuration: {
                adjustment_type: "CHANGE_IN_CAPACITY",
                scaling_adjustment: -2,
                cool_down: 600
              }
            },
            trigger: {
              cloud_watch_alarm_definition: {
                comparison_operator: "LESS_THAN",
                evaluation_periods: 3,
                metric_name: "YARNMemoryAvailablePercentage",
                namespace: "AWS/ElasticMapReduce",
                period: 600,
                statistic: "AVERAGE",
                threshold: 80.0
              }
            }
          }
        ]
      }
    },
    # On-demand instances for streaming workloads
    {
      name: "streaming-processing-ondemand",
      instance_role: "TASK",
      instance_type: "c5.xlarge",
      instance_count: 4,
      ebs_config: {
        ebs_optimized: true,
        ebs_block_device_config: [
          {
            volume_specification: {
              volume_type: "gp3",
              size_in_gb: 100
            }
          }
        ]
      }
    }
  ],
  configurations: [
    # Spark configuration optimized for data lake workloads
    EmrClusterAttributes.spark_configuration({
      min_executors: 8,
      max_executors: 200,
      additional_properties: {
        "spark.sql.adaptive.enabled" => "true",
        "spark.sql.adaptive.coalescePartitions.enabled" => "true",
        "spark.sql.adaptive.skewJoin.enabled" => "true",
        "spark.hadoop.fs.s3a.fast.upload" => "true",
        "spark.hadoop.fs.s3a.multipart.size" => "134217728", # 128MB
        "spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version" => "2",
        "spark.speculation" => "true",
        "spark.sql.parquet.filterPushdown" => "true",
        "spark.sql.parquet.mergeSchema" => "false"
      }
    }),
    # Hive integration with Glue Catalog
    EmrClusterAttributes.hive_configuration({
      connection_url: "glue_catalog",
      additional_properties: {
        "hive.metastore.glue.catalogid" => "123456789012",
        "hive.exec.parallel" => "true",
        "hive.exec.parallel.thread.number" => "8",
        "hive.vectorized.execution.enabled" => "true",
        "hive.vectorized.execution.reduce.enabled" => "true"
      }
    }),
    # HDFS optimizations
    EmrClusterAttributes.hadoop_configuration({
      datanode_heap: "4096",
      namenode_heap: "4096"
    }),
    # Additional optimizations
    {
      classification: "yarn-site",
      properties: {
        "yarn.resourcemanager.decommissioning.timeout" => "3600",
        "yarn.resourcemanager.node-removal-untracked.timeout" => "60000",
        "yarn.log-aggregation.retain-seconds" => "86400"
      }
    }
  ],
  bootstrap_action: [
    EmrClusterAttributes.bootstrap_action(
      "install-monitoring-agents",
      "s3://platform-bootstrap/install-monitoring.sh",
      ["--datadog-api-key", "${datadog_api_key}"]
    ),
    EmrClusterAttributes.bootstrap_action(
      "configure-data-lake-access",
      "s3://platform-bootstrap/configure-data-access.sh",
      ["--data-lake-bucket", "s3://company-data-lake"]
    )
  ],
  log_uri: "s3://emr-platform-logs/analytics-cluster/",
  log_encryption_kms_key_id: "arn:aws:kms:region:account:key/analytics-kms-key",
  termination_protection: true,
  keep_job_flow_alive_when_no_steps: true,
  step_concurrency_level: 5
})

# Integration with Glue Jobs for ETL orchestration
etl_trigger = aws_glue_trigger(:emr_analytics_trigger, {
  name: "emr-analytics-orchestrator",
  type: "SCHEDULED",
  schedule: GlueTriggerAttributes.schedule_expressions[:daily_at_2am],
  actions: [
    GlueTriggerAttributes.action_for_job("submit-emr-steps", {
      arguments: {
        "--emr-cluster-id" => analytics_platform.outputs[:id],
        "--step-definitions" => "s3://etl-configs/daily-processing-steps.json"
      }
    })
  ]
})
```

### Machine Learning Platform Architecture
```ruby
# Specialized ML cluster with GPU instances and ML frameworks
ml_platform = aws_emr_cluster(:ml_platform, {
  name: "ml-research-and-training-platform",
  release_label: "emr-6.15.0",
  **EmrClusterAttributes.workload_configurations[:machine_learning],
  service_role: "arn:aws:iam::123456789012:role/EMRMLServiceRole",
  ec2_attributes: {
    instance_profile: "arn:aws:iam::123456789012:instance-profile/EMRMLInstanceProfile",
    key_name: "ml-platform-key",
    subnet_id: "subnet-ml-private", # Single AZ for GPU instance availability
    additional_master_security_groups: ["sg-jupyter-access", "sg-tensorboard-access"],
    additional_slave_security_groups: ["sg-distributed-training"]
  },
  master_instance_group: {
    instance_type: "r5.4xlarge" # Large memory for feature engineering
  },
  core_instance_group: {
    instance_type: "r5.2xlarge",
    instance_count: 4,
    ebs_config: {
      ebs_optimized: true,
      ebs_block_device_config: [
        {
          volume_specification: {
            volume_type: "gp3",
            size_in_gb: 500
          }
        }
      ]
    }
  },
  task_instance_groups: [
    # GPU instances for model training
    {
      name: "gpu-training-group",
      instance_role: "TASK",
      instance_type: "p3.2xlarge",
      instance_count: 2,
      ebs_config: {
        ebs_optimized: true,
        ebs_block_device_config: [
          {
            volume_specification: {
              volume_type: "gp3",
              size_in_gb: 1000
            }
          }
        ]
      }
    },
    # CPU instances for data preprocessing
    {
      name: "preprocessing-group",
      instance_role: "TASK", 
      instance_type: "c5.4xlarge",
      instance_count: 6,
      bid_price: "0.30",
      auto_scaling_policy: {
        constraints: {
          min_capacity: 2,
          max_capacity: 20
        },
        rules: [
          {
            name: "ScaleForPreprocessing",
            action: {
              simple_scaling_policy_configuration: {
                scaling_adjustment: 3,
                cool_down: 300
              }
            },
            trigger: {
              cloud_watch_alarm_definition: {
                comparison_operator: "GREATER_THAN",
                evaluation_periods: 2,
                metric_name: "CPUUtilization",
                namespace: "AWS/ElasticMapReduce",
                period: 300,
                threshold: 70.0
              }
            }
          }
        ]
      }
    }
  ],
  configurations: [
    # Spark optimized for ML workloads
    EmrClusterAttributes.spark_configuration({
      min_executors: 4,
      max_executors: 40,
      additional_properties: {
        "spark.sql.execution.arrow.pyspark.enabled" => "true",
        "spark.python.worker.memory" => "4g",
        "spark.driver.maxResultSize" => "4g",
        "spark.kryoserializer.buffer.max" => "2000m",
        "spark.sql.adaptive.localShuffleReader.enabled" => "true"
      }
    }),
    # JupyterHub configuration
    {
      classification: "jupyter-s3-conf",
      properties: {
        "s3.persistence.enabled" => "true",
        "s3.persistence.bucket" => "ml-platform-notebooks"
      }
    }
  ],
  bootstrap_action: [
    EmrClusterAttributes.bootstrap_action(
      "install-cuda-drivers",
      "s3://ml-bootstrap/install-cuda.sh"
    ),
    EmrClusterAttributes.bootstrap_action(
      "install-ml-libraries",
      "s3://ml-bootstrap/install-ml-packages.sh",
      ["--tensorflow-version", "2.12.0", "--pytorch-version", "2.0.1"]
    )
  ],
  keep_job_flow_alive_when_no_steps: true,
  step_concurrency_level: 3
})
```

### Stream Processing Architecture
```ruby
# Real-time streaming cluster with Kafka and Spark Streaming
streaming_cluster = aws_emr_cluster(:streaming_cluster, {
  name: "real-time-streaming-platform",
  release_label: "emr-6.15.0",
  applications: ["Hadoop", "Spark", "Flink", "Zeppelin"],
  service_role: "arn:aws:iam::123456789012:role/EMRStreamingRole",
  ec2_attributes: {
    instance_profile: "arn:aws:iam::123456789012:instance-profile/EMRStreamingProfile",
    subnet_ids: ["subnet-streaming-a", "subnet-streaming-b"],
    additional_master_security_groups: ["sg-kafka-access", "sg-kinesis-access"]
  },
  master_instance_group: {
    instance_type: "m5.xlarge"
  },
  core_instance_group: {
    instance_type: "r5.large",
    instance_count: 6,
    ebs_config: {
      ebs_optimized: true,
      ebs_block_device_config: [
        {
          volume_specification: {
            volume_type: "gp3",
            size_in_gb: 200
          }
        }
      ]
    }
  },
  task_instance_groups: [
    # Dedicated streaming processing nodes
    {
      name: "streaming-processors",
      instance_role: "TASK",
      instance_type: "c5.2xlarge",
      instance_count: 8,
      auto_scaling_policy: {
        constraints: {
          min_capacity: 4,
          max_capacity: 32
        },
        rules: [
          {
            name: "ScaleOnStreamingLag",
            description: "Scale based on streaming lag",
            action: {
              simple_scaling_policy_configuration: {
                adjustment_type: "CHANGE_IN_CAPACITY",
                scaling_adjustment: 2,
                cool_down: 180
              }
            },
            trigger: {
              cloud_watch_alarm_definition: {
                comparison_operator: "GREATER_THAN",
                evaluation_periods: 2,
                metric_name: "StreamingBatchProcessingTime",
                namespace: "AWS/ElasticMapReduce",
                period: 60,
                threshold: 30.0,
                dimensions: {
                  "JobFlowId" => streaming_cluster.outputs[:id]
                }
              }
            }
          }
        ]
      }
    }
  ],
  configurations: [
    # Spark Streaming optimizations
    EmrClusterAttributes.spark_configuration({
      min_executors: 6,
      max_executors: 60,
      additional_properties: {
        "spark.streaming.backpressure.enabled" => "true",
        "spark.streaming.receiver.writeAheadLog.enable" => "true",
        "spark.streaming.kafka.consumer.cache.enabled" => "true",
        "spark.streaming.dynamicAllocation.enabled" => "true",
        "spark.streaming.dynamicAllocation.minExecutors" => "6",
        "spark.streaming.dynamicAllocation.maxExecutors" => "60",
        "spark.serializer" => "org.apache.spark.serializer.KryoSerializer"
      }
    }),
    # Flink configuration for complex event processing
    {
      classification: "flink-conf",
      properties: {
        "taskmanager.memory.process.size" => "4g",
        "jobmanager.memory.process.size" => "2g",
        "state.backend" => "rocksdb",
        "state.checkpoints.dir" => "s3://streaming-checkpoints/flink/",
        "execution.checkpointing.interval" => "60000"
      }
    }
  ],
  bootstrap_action: [
    EmrClusterAttributes.bootstrap_action(
      "configure-kafka-clients",
      "s3://streaming-bootstrap/configure-kafka.sh",
      ["--kafka-brokers", "kafka1:9092,kafka2:9092,kafka3:9092"]
    )
  ],
  keep_job_flow_alive_when_no_steps: true,
  step_concurrency_level: 8,
  auto_termination_policy: {
    idle_timeout: 7200 # 2 hours idle timeout for cost control
  }
})
```

### Multi-Tenant Analytics Architecture
```ruby
# Shared analytics cluster with tenant isolation
multi_tenant_cluster = aws_emr_cluster(:multi_tenant, {
  name: "multi-tenant-analytics-cluster",
  release_label: "emr-6.15.0",
  applications: ["Hadoop", "Spark", "Hive", "Presto"],
  service_role: "arn:aws:iam::123456789012:role/EMRMultiTenantRole",
  ec2_attributes: {
    instance_profile: "arn:aws:iam::123456789012:instance-profile/EMRMultiTenantProfile",
    subnet_ids: ["subnet-tenant-a", "subnet-tenant-b"],
    additional_master_security_groups: ["sg-tenant-isolation"]
  },
  master_instance_group: {
    instance_type: "r5.2xlarge"
  },
  core_instance_group: {
    instance_type: "r5.xlarge",
    instance_count: 8
  },
  task_instance_groups: [
    # Separate instance groups per tenant for resource isolation
    {
      name: "tenant-a-processing",
      instance_role: "TASK",
      instance_type: "m5.xlarge",
      instance_count: 6,
      auto_scaling_policy: {
        constraints: { min_capacity: 2, max_capacity: 20 },
        rules: [
          {
            name: "TenantAScaling",
            action: {
              simple_scaling_policy_configuration: {
                scaling_adjustment: 2,
                cool_down: 300
              }
            },
            trigger: {
              cloud_watch_alarm_definition: {
                comparison_operator: "GREATER_THAN",
                evaluation_periods: 2,
                metric_name: "YARNMemoryAvailablePercentage",
                namespace: "AWS/ElasticMapReduce",
                period: 300,
                threshold: 20.0,
                dimensions: {
                  "JobFlowId" => multi_tenant_cluster.outputs[:id],
                  "InstanceGroupName" => "tenant-a-processing"
                }
              }
            }
          }
        ]
      }
    },
    {
      name: "tenant-b-processing",
      instance_role: "TASK",
      instance_type: "m5.xlarge", 
      instance_count: 4,
      auto_scaling_policy: {
        constraints: { min_capacity: 2, max_capacity: 15 },
        rules: [
          {
            name: "TenantBScaling",
            action: {
              simple_scaling_policy_configuration: {
                scaling_adjustment: 2,
                cool_down: 300
              }
            },
            trigger: {
              cloud_watch_alarm_definition: {
                comparison_operator: "GREATER_THAN",
                evaluation_periods: 2,
                metric_name: "YARNMemoryAvailablePercentage",
                namespace: "AWS/ElasticMapReduce",
                period: 300,
                threshold: 20.0,
                dimensions: {
                  "JobFlowId" => multi_tenant_cluster.outputs[:id],
                  "InstanceGroupName" => "tenant-b-processing"
                }
              }
            }
          }
        ]
      }
    }
  ],
  configurations: [
    # YARN configuration for multi-tenancy
    {
      classification: "yarn-site",
      properties: {
        "yarn.resourcemanager.scheduler.class" => "org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler",
        "yarn.scheduler.fair.allocation.file" => "/etc/hadoop/conf/fair-scheduler.xml",
        "yarn.scheduler.fair.preemption" => "true",
        "yarn.scheduler.fair.user-as-default-queue" => "false"
      }
    },
    # Spark configuration with dynamic allocation
    EmrClusterAttributes.spark_configuration({
      min_executors: 4,
      max_executors: 80,
      additional_properties: {
        "spark.sql.adaptive.enabled" => "true",
        "spark.dynamicAllocation.enabled" => "true",
        "spark.shuffle.service.enabled" => "true"
      }
    })
  ],
  bootstrap_action: [
    EmrClusterAttributes.bootstrap_action(
      "configure-multi-tenant-queues",
      "s3://multi-tenant-bootstrap/configure-queues.sh",
      ["--tenant-list", "tenant-a,tenant-b", "--queue-config", "s3://configs/fair-scheduler.xml"]
    )
  ],
  placement_group_configs: [
    {
      instance_role: "CORE",
      placement_strategy: "CLUSTER"
    }
  ]
})
```

## Performance Optimization Patterns

### Memory-Optimized Configuration
```ruby
memory_optimized_cluster = aws_emr_cluster(:memory_optimized, {
  name: "memory-intensive-analytics",
  release_label: "emr-6.15.0",
  applications: ["Hadoop", "Spark"],
  master_instance_group: {
    instance_type: "r5.4xlarge"
  },
  core_instance_group: {
    instance_type: "r5.8xlarge",
    instance_count: 6
  },
  configurations: [
    EmrClusterAttributes.spark_configuration({
      additional_properties: {
        "spark.executor.memory" => "24g",
        "spark.executor.cores" => "8",
        "spark.driver.memory" => "16g",
        "spark.driver.maxResultSize" => "8g",
        "spark.sql.adaptive.coalescePartitions.enabled" => "true",
        "spark.sql.adaptive.coalescePartitions.minPartitionNum" => "1",
        "spark.sql.adaptive.advisoryPartitionSizeInBytes" => "268435456" # 256MB
      }
    })
  ]
})
```

### I/O Optimized Configuration
```ruby
io_optimized_cluster = aws_emr_cluster(:io_optimized, {
  name: "io-intensive-processing",
  core_instance_group: {
    instance_type: "i3.2xlarge", # NVMe SSD storage
    instance_count: 8,
    ebs_config: {
      ebs_optimized: true,
      ebs_block_device_config: [
        {
          volume_specification: {
            volume_type: "io2",
            size_in_gb: 1000,
            iops: 32000
          },
          volumes_per_instance: 4
        }
      ]
    }
  },
  configurations: [
    {
      classification: "hdfs-site",
      properties: {
        "dfs.datanode.max.transfer.threads" => "16384",
        "dfs.datanode.handler.count" => "100",
        "dfs.namenode.handler.count" => "100"
      }
    }
  ]
})
```

This cluster resource enables sophisticated big data processing architectures that scale from development environments to massive production workloads with intelligent resource management, cost optimization, and performance tuning capabilities.