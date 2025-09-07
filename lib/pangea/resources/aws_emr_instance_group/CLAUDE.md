# AWS EMR Instance Group - Architecture Notes

## Resource Purpose

AWS EMR Instance Group enables dynamic cluster scaling and workload-specific resource allocation by providing fine-grained control over compute capacity, storage configuration, and auto-scaling behavior for different types of big data workloads within a single EMR cluster.

## Key Architectural Patterns

### Dynamic Resource Allocation Pattern
- **Workload-Specific Scaling**: Separate instance groups for different workload characteristics
- **Elastic Capacity Management**: Auto-scaling based on cluster utilization and workload demand
- **Cost-Performance Optimization**: Mix of spot and on-demand instances across different groups
- **Resource Isolation**: Independent scaling and configuration per workload type

### Tiered Storage Architecture Pattern  
- **Hot Storage Tiers**: High-IOPS EBS volumes for active data processing
- **Warm Storage Tiers**: General-purpose SSD for intermediate data
- **Cold Storage Tiers**: Throughput-optimized volumes for archival processing
- **Memory Hierarchy**: Instance types optimized for different memory access patterns

### Multi-Tenant Resource Pattern
- **Tenant-Specific Groups**: Dedicated instance groups per tenant or department
- **Resource Quotas**: Controlled capacity allocation through scaling constraints
- **Performance Isolation**: Independent scaling policies prevent resource contention
- **Cost Attribution**: Per-group cost tracking and billing allocation

## Architecture Integration Points

### Workload-Optimized Cluster Architecture
```ruby
# Base cluster with core infrastructure
base_cluster = aws_emr_cluster(:multi_workload_cluster, {
  name: "enterprise-analytics-cluster",
  release_label: "emr-6.15.0",
  applications: ["Hadoop", "Spark", "Hive", "Presto"],
  master_instance_group: {
    instance_type: "r5.2xlarge"
  },
  core_instance_group: {
    instance_type: "r5.xlarge",
    instance_count: 6
  }
})

# Streaming workload group - low latency, consistent capacity
streaming_group = aws_emr_instance_group(:streaming_workload, {
  name: "real-time-streaming",
  cluster_id: base_cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "c5.2xlarge", # CPU-optimized for streaming
  instance_count: 8,
  # On-demand instances for predictable performance
  ebs_config: EmrInstanceGroupAttributes.create_ebs_config("gp3", 200, {
    iops: 8000,
    ebs_optimized: true,
    volumes_per_instance: 2
  }),
  # Conservative auto scaling for streaming stability
  auto_scaling_policy: {
    constraints: {
      min_capacity: 6,
      max_capacity: 16
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "StreamingLatencyScaleOut",
        "StreamingBatchProcessingTime",
        30.0, # 30 second processing time threshold
        2,
        {
          namespace: "AWS/ElasticMapReduce/Streaming",
          evaluation_periods: 2,
          cool_down: 300
        }
      ),
      EmrInstanceGroupAttributes.create_scale_in_rule(
        "StreamingLatencyScaleIn",
        "StreamingBatchProcessingTime",
        10.0,
        -1,
        {
          namespace: "AWS/ElasticMapReduce/Streaming",
          evaluation_periods: 5,
          cool_down: 900
        }
      )
    ]
  },
  configurations: [
    {
      classification: "spark-defaults",
      properties: {
        "spark.streaming.backpressure.enabled" => "true",
        "spark.streaming.receiver.writeAheadLog.enable" => "true",
        "spark.streaming.dynamicAllocation.enabled" => "false" # Fixed allocation for streaming
      }
    }
  ]
})

# Batch analytics group - cost-optimized, elastic capacity
batch_analytics_group = aws_emr_instance_group(:batch_analytics, {
  name: "batch-analytics-processing",
  cluster_id: base_cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "r5.large", # Memory-optimized for analytics
  instance_count: 4,
  bid_price: "0.06", # Spot instances for cost optimization
  ebs_config: EmrInstanceGroupAttributes.create_ebs_config("gp3", 300, {
    ebs_optimized: true,
    volumes_per_instance: 2
  }),
  # Aggressive auto scaling for batch workloads
  auto_scaling_policy: {
    constraints: {
      min_capacity: 2,
      max_capacity: 50
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "BatchQueueScaleOut",
        "ContainerPendingRatio",
        0.3,
        5, # Aggressive scale out
        {
          evaluation_periods: 1,
          cool_down: 180,
          market: "SPOT"
        }
      ),
      EmrInstanceGroupAttributes.create_scale_in_rule(
        "BatchUtilizationScaleIn",
        "YARNMemoryAvailablePercentage",
        75.0,
        -3, # Conservative scale in
        {
          evaluation_periods: 6,
          cool_down: 1200
        }
      )
    ]
  },
  configurations: [
    {
      classification: "spark-defaults",
      properties: {
        "spark.dynamicAllocation.enabled" => "true",
        "spark.dynamicAllocation.minExecutors" => "4",
        "spark.dynamicAllocation.maxExecutors" => "200",
        "spark.sql.adaptive.enabled" => "true"
      }
    }
  ]
})

# Machine learning workload group - GPU and high memory
ml_workload_group = aws_emr_instance_group(:ml_workload, {
  name: "machine-learning-training",
  cluster_id: base_cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "p3.2xlarge", # GPU instances
  instance_count: 2,
  # On-demand for expensive GPU instances
  ebs_config: EmrInstanceGroupAttributes.create_ebs_config("gp3", 1000, {
    iops: 16000,
    ebs_optimized: true
  }),
  # Manual scaling for expensive resources
  auto_scaling_policy: {
    constraints: {
      min_capacity: 1,
      max_capacity: 8
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "MLTrainingScaleOut",
        "GPUUtilization",
        85.0,
        1, # Scale one at a time for expensive instances
        {
          namespace: "CWAgent",
          evaluation_periods: 3,
          cool_down: 600
        }
      )
    ]
  },
  configurations: [
    {
      classification: "spark-defaults",
      properties: {
        "spark.rapids.sql.enabled" => "true",
        "spark.plugins" => "com.nvidia.spark.SQLPlugin",
        "spark.executor.resource.gpu.amount" => "1"
      }
    }
  ]
})

# I/O intensive workload group - high throughput storage
io_intensive_group = aws_emr_instance_group(:io_intensive, {
  name: "io-intensive-processing",
  cluster_id: base_cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "i3.4xlarge", # Local NVMe SSD instances
  instance_count: 6,
  bid_price: "0.30",
  ebs_config: EmrInstanceGroupAttributes.create_ebs_config("io2", 500, {
    iops: 32000, # Maximum IOPS
    ebs_optimized: true,
    volumes_per_instance: 4
  }),
  auto_scaling_policy: {
    constraints: {
      min_capacity: 3,
      max_capacity: 20
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "IOThroughputScaleOut",
        "DiskReadOps",
        1000.0,
        2,
        {
          namespace: "AWS/EC2",
          evaluation_periods: 2,
          cool_down: 300
        }
      ),
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "IOWaitScaleOut", 
        "CPUIowait",
        25.0,
        2,
        {
          namespace: "System/Linux",
          evaluation_periods: 3
        }
      )
    ]
  }
})
```

### Multi-Tenant Cluster Architecture
```ruby
# Shared cluster for multiple business units
multi_tenant_cluster = aws_emr_cluster(:multi_tenant_platform, {
  name: "multi-tenant-analytics-platform",
  release_label: "emr-6.15.0",
  applications: ["Hadoop", "Spark", "Hive"],
  # Shared master and core capacity
  master_instance_group: { instance_type: "r5.2xlarge" },
  core_instance_group: { 
    instance_type: "r5.xlarge", 
    instance_count: 8 
  }
})

# Finance department instance group
finance_group = aws_emr_instance_group(:finance_dept, {
  name: "finance-analytics",
  cluster_id: multi_tenant_cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "r5.large",
  instance_count: 6,
  bid_price: "0.05",
  auto_scaling_policy: {
    constraints: {
      min_capacity: 2,  # Guaranteed minimum capacity
      max_capacity: 20  # Department quota
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "FinanceWorkloadScaleOut",
        "YARNMemoryAvailablePercentage",
        20.0,
        2,
        {
          dimensions: { 
            "JobFlowId" => multi_tenant_cluster.outputs[:id],
            "InstanceGroupName" => "finance-analytics"
          }
        }
      )
    ]
  },
  configurations: [
    {
      classification: "yarn-site",
      properties: {
        "yarn.scheduler.capacity.resource-calculator" => "org.apache.hadoop.yarn.util.resource.DominantResourceCalculator",
        "yarn.scheduler.fair.allocation.file" => "/etc/hadoop/conf/finance-fair-scheduler.xml"
      }
    }
  ]
})

# Marketing department instance group
marketing_group = aws_emr_instance_group(:marketing_dept, {
  name: "marketing-analytics",
  cluster_id: multi_tenant_cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "c5.xlarge", # CPU-optimized for web analytics
  instance_count: 4,
  bid_price: "0.08",
  auto_scaling_policy: {
    constraints: {
      min_capacity: 1,
      max_capacity: 15  # Smaller quota
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "MarketingWorkloadScaleOut",
        "CPUUtilization",
        70.0,
        2
      )
    ]
  }
})

# Data science team instance group
data_science_group = aws_emr_instance_group(:data_science_team, {
  name: "data-science-research",
  cluster_id: multi_tenant_cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "r5.2xlarge", # High memory for ML workloads
  instance_count: 3,
  # On-demand for interactive workloads
  ebs_config: EmrInstanceGroupAttributes.create_ebs_config("gp3", 500, {
    iops: 12000,
    ebs_optimized: true
  }),
  auto_scaling_policy: {
    constraints: {
      min_capacity: 2,
      max_capacity: 12
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "DataScienceMemoryScaleOut",
        "MemoryPercentage",
        75.0,
        1, # Conservative scaling for interactive work
        {
          evaluation_periods: 3,
          cool_down: 600
        }
      )
    ]
  },
  configurations: [
    {
      classification: "jupyter-s3-conf",
      properties: {
        "s3.persistence.enabled" => "true",
        "s3.persistence.bucket" => "data-science-notebooks"
      }
    }
  ]
})
```

### Time-Based Capacity Management
```ruby
# Business hours instance group - active during work hours
business_hours_group = aws_emr_instance_group(:business_hours, {
  name: "business-hours-processing",
  cluster_id: cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "m5.xlarge",
  instance_count: 8,
  bid_price: "0.08",
  auto_scaling_policy: {
    constraints: {
      min_capacity: 4,
      max_capacity: 40
    },
    rules: [
      # Aggressive scaling during business hours
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "BusinessHoursScaleOut",
        "YARNMemoryAvailablePercentage",
        30.0,
        4,
        {
          evaluation_periods: 1,
          cool_down: 180
        }
      ),
      # Conservative scale-in to maintain capacity
      EmrInstanceGroupAttributes.create_scale_in_rule(
        "BusinessHoursScaleIn",
        "YARNMemoryAvailablePercentage",
        80.0,
        -2,
        {
          evaluation_periods: 8,
          cool_down: 1800
        }
      )
    ]
  }
})

# Off-hours instance group - cost-optimized for batch processing
off_hours_group = aws_emr_instance_group(:off_hours_batch, {
  name: "off-hours-batch-processing",
  cluster_id: cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "r5.large",
  instance_count: 2,
  bid_price: "0.04", # Lower bid price for off-hours
  auto_scaling_policy: {
    constraints: {
      min_capacity: 0, # Can scale to zero
      max_capacity: 100 # Large capacity for batch jobs
    },
    rules: [
      # Very aggressive scaling for batch processing
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "BatchJobScaleOut",
        "ContainerPendingRatio",
        0.1, # Scale out quickly when jobs are queued
        10,
        {
          evaluation_periods: 1,
          cool_down: 120,
          market: "SPOT"
        }
      ),
      # Quick scale-in when no work
      EmrInstanceGroupAttributes.create_scale_in_rule(
        "BatchIdleScaleIn",
        "YARNMemoryAvailablePercentage",
        95.0,
        -5,
        {
          evaluation_periods: 2,
          cool_down: 300
        }
      )
    ]
  }
})
```

### Performance-Optimized Architecture Patterns
```ruby
# Memory-intensive analytics group
memory_optimized_group = aws_emr_instance_group(:memory_analytics, {
  name: "memory-intensive-analytics",
  cluster_id: cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "r5.4xlarge", # High memory instances
  instance_count: 10,
  ebs_config: EmrInstanceGroupAttributes.create_ebs_config("gp3", 400, {
    iops: 12000,
    ebs_optimized: true,
    volumes_per_instance: 2
  }),
  auto_scaling_policy: {
    constraints: {
      min_capacity: 6,
      max_capacity: 30
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "MemoryUtilizationScaleOut",
        "MemoryPercentage",
        70.0,
        2,
        { evaluation_periods: 2 }
      ),
      EmrInstanceGroupAttributes.create_scale_in_rule(
        "MemoryUtilizationScaleIn",
        "MemoryPercentage",
        30.0,
        -1,
        { evaluation_periods: 5, cool_down: 900 }
      )
    ]
  },
  configurations: [
    {
      classification: "spark-defaults",
      properties: {
        "spark.executor.memory" => "24g",
        "spark.driver.memory" => "16g",
        "spark.executor.memoryFraction" => "0.8",
        "spark.sql.adaptive.coalescePartitions.enabled" => "true"
      }
    }
  ]
})

# Compute-intensive group for CPU-bound workloads
compute_optimized_group = aws_emr_instance_group(:compute_intensive, {
  name: "cpu-intensive-processing",
  cluster_id: cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "c5.9xlarge", # High CPU instances
  instance_count: 6,
  bid_price: "0.50",
  ebs_config: EmrInstanceGroupAttributes.create_ebs_config("gp3", 200, {
    iops: 6000,
    ebs_optimized: true
  }),
  auto_scaling_policy: {
    constraints: {
      min_capacity: 3,
      max_capacity: 24
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "CPUUtilizationScaleOut",
        "CPUUtilization",
        75.0,
        3,
        { evaluation_periods: 2, cool_down: 300 }
      ),
      EmrInstanceGroupAttributes.create_scale_in_rule(
        "CPUUtilizationScaleIn",
        "CPUUtilization",
        20.0,
        -2,
        { evaluation_periods: 4, cool_down: 600 }
      )
    ]
  },
  configurations: [
    {
      classification: "spark-defaults",
      properties: {
        "spark.executor.cores" => "16",
        "spark.executor.instances" => "2",
        "spark.default.parallelism" => "192"
      }
    }
  ]
})
```

## Cost Optimization Patterns

### Spot Instance Management
```ruby
# Cost-aware spot instance group with diverse instance types
spot_fleet_group = aws_emr_instance_group(:spot_fleet, {
  name: "cost-optimized-spot-fleet",
  cluster_id: cluster.outputs[:id],
  instance_role: "TASK",
  instance_type: "m5.large", # Primary instance type
  instance_count: 8,
  bid_price: "0.06", # Aggressive bid price
  auto_scaling_policy: {
    constraints: {
      min_capacity: 2,
      max_capacity: 100
    },
    rules: [
      EmrInstanceGroupAttributes.create_scale_out_rule(
        "SpotAvailabilityScaleOut",
        "ContainerPendingRatio",
        0.2,
        10, # Aggressive scaling when spot is available
        {
          evaluation_periods: 1,
          cool_down: 60,
          market: "SPOT"
        }
      ),
      EmrInstanceGroupAttributes.create_scale_in_rule(
        "SpotCostScaleIn",
        "YARNMemoryAvailablePercentage",
        85.0,
        -5,
        { evaluation_periods: 2, cool_down: 180 }
      )
    ]
  }
})
```

This instance group resource enables sophisticated cluster resource management that adapts to different workload patterns, cost constraints, and performance requirements while maintaining fine-grained control over capacity allocation and scaling behavior.