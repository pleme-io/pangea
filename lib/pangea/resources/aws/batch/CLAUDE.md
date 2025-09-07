# AWS Batch Resources

## Overview

AWS Batch resources enable scalable, containerized batch computing workloads with automatic scaling, job queuing, and resource management. These resources help organizations run large-scale data processing, machine learning training, simulation workloads, and other compute-intensive tasks efficiently.

## Key Concepts

### Batch Computing Architecture
- **Compute Environments**: Manage the underlying compute infrastructure (EC2, Spot, Fargate)
- **Job Queues**: Route jobs to appropriate compute environments based on priority
- **Job Definitions**: Templates defining job requirements and configuration
- **Jobs**: Individual units of work submitted to queues
- **Scheduling Policies**: Control job scheduling behavior and resource allocation

### Compute Environment Types
1. **Managed EC2**: AWS manages EC2 instances with automatic scaling
2. **Managed Spot**: Cost-optimized using EC2 Spot instances
3. **Managed Fargate**: Serverless container execution
4. **Unmanaged**: User manages compute resources directly

### Job Types and Patterns
- **Single-node Jobs**: Standard containerized workloads
- **Multi-node Jobs**: Parallel processing across multiple nodes (MPI workloads)
- **Array Jobs**: Parameter sweep jobs with multiple related tasks
- **GPU Jobs**: Machine learning and compute-intensive workloads

## Resources

### aws_batch_compute_environment
Manages the underlying compute infrastructure for batch jobs.

**Key Features:**
- Multiple compute types (EC2, Spot, Fargate)
- Automatic scaling based on job demand
- VPC and security group configuration
- Cost optimization through Spot instances

**Common Patterns:**
```ruby
# General-purpose EC2 compute environment
aws_batch_compute_environment(:general_purpose, {
  compute_environment_name: "general-purpose-compute",
  type: "MANAGED",
  state: "ENABLED",
  compute_resources: {
    type: "EC2",
    allocation_strategy: "BEST_FIT_PROGRESSIVE",
    min_vcpus: 0,
    max_vcpus: 1000,
    desired_vcpus: 10,
    instance_types: ["m5.large", "m5.xlarge", "m5.2xlarge"],
    subnets: [
      aws_subnet(:private_a).id,
      aws_subnet(:private_b).id,
      aws_subnet(:private_c).id
    ],
    security_group_ids: [
      aws_security_group(:batch_compute).id
    ],
    instance_role: aws_iam_instance_profile(:ecs_instance).arn,
    ec2_configuration: [
      {
        image_type: "ECS_AL2"
      }
    ],
    tags: {
      Environment: "production",
      Purpose: "batch-processing"
    }
  },
  service_role: aws_iam_role(:batch_service).arn,
  tags: {
    Environment: "production",
    Team: "data-engineering"
  }
})

# Cost-optimized Spot compute environment
aws_batch_compute_environment(:spot_processing, {
  compute_environment_name: "spot-processing",
  type: "MANAGED",
  compute_resources: {
    type: "SPOT",
    allocation_strategy: "SPOT_CAPACITY_OPTIMIZED",
    min_vcpus: 0,
    max_vcpus: 500,
    instance_types: ["m5.large", "m5.xlarge", "c5.large", "c5.xlarge"],
    spot_iam_fleet_request_role: aws_iam_role(:spot_fleet).arn,
    subnets: private_subnet_ids,
    security_group_ids: [aws_security_group(:batch_spot).id],
    instance_role: aws_iam_instance_profile(:ecs_instance).arn,
    tags: {
      SpotCompute: "true",
      CostOptimized: "true"
    }
  },
  service_role: aws_iam_role(:batch_service).arn,
  tags: {
    Environment: "development",
    CostOptimization: "spot"
  }
})

# Serverless Fargate compute environment
aws_batch_compute_environment(:serverless, {
  compute_environment_name: "serverless-fargate",
  type: "MANAGED",
  compute_resources: {
    type: "FARGATE",
    max_vcpus: 100,
    subnets: private_subnet_ids,
    security_group_ids: [aws_security_group(:batch_fargate).id]
  },
  tags: {
    Environment: "production",
    Type: "serverless"
  }
})

# GPU-enabled compute environment for ML workloads
aws_batch_compute_environment(:gpu_ml, {
  compute_environment_name: "gpu-ml-compute",
  type: "MANAGED",
  compute_resources: {
    type: "EC2",
    allocation_strategy: "BEST_FIT",
    min_vcpus: 0,
    max_vcpus: 100,
    instance_types: ["p3.2xlarge", "p3.8xlarge", "p4d.24xlarge"],
    subnets: private_subnet_ids,
    security_group_ids: [aws_security_group(:ml_compute).id],
    instance_role: aws_iam_instance_profile(:ecs_instance).arn,
    ec2_configuration: [
      {
        image_type: "ECS_AL2_NVIDIA"
      }
    ],
    tags: {
      WorkloadType: "machine-learning",
      GPU: "enabled"
    }
  },
  service_role: aws_iam_role(:batch_service).arn,
  tags: {
    Environment: "production",
    Purpose: "ml-training"
  }
})

# EKS-based compute environment
aws_batch_compute_environment(:eks_batch, {
  compute_environment_name: "eks-batch-compute",
  type: "MANAGED",
  eks_configuration: {
    eks_cluster_arn: aws_eks_cluster(:batch_cluster).arn,
    kubernetes_namespace: "batch-jobs"
  },
  tags: {
    Environment: "production",
    Platform: "kubernetes"
  }
})
```

### aws_batch_job_queue
Routes jobs to appropriate compute environments based on priority and availability.

**Key Features:**
- Priority-based job scheduling
- Multiple compute environment support
- State management (enabled/disabled)
- Job state time limits and actions

**Common Patterns:**
```ruby
# High-priority production queue
aws_batch_job_queue(:high_priority, {
  name: "high-priority-queue",
  priority: 100,
  state: "ENABLED",
  compute_environment_order: [
    {
      order: 1,
      compute_environment: aws_batch_compute_environment(:general_purpose).arn
    }
  ],
  job_state_time_limit_actions: [
    {
      reason: "Job timeout exceeded",
      state: "RUNNABLE",
      max_time_seconds: 3600,  # 1 hour timeout
      action: "CANCEL"
    }
  ],
  tags: {
    Priority: "high",
    Environment: "production"
  }
})

# Multi-environment queue with failover
aws_batch_job_queue(:multi_environment, {
  name: "multi-env-processing",
  priority: 50,
  compute_environment_order: [
    {
      order: 1,
      compute_environment: aws_batch_compute_environment(:general_purpose).arn
    },
    {
      order: 2,
      compute_environment: aws_batch_compute_environment(:spot_processing).arn
    }
  ],
  tags: {
    Pattern: "failover",
    CostOptimization: "enabled"
  }
})

# Development/testing queue with spot instances
aws_batch_job_queue(:development, {
  name: "dev-testing-queue", 
  priority: 10,
  compute_environment_order: [
    {
      order: 1,
      compute_environment: aws_batch_compute_environment(:spot_processing).arn
    }
  ],
  job_state_time_limit_actions: [
    {
      reason: "Development job timeout",
      state: "RUNNABLE",
      max_time_seconds: 1800,  # 30 minutes
      action: "CANCEL"
    }
  ],
  tags: {
    Environment: "development",
    Purpose: "testing"
  }
})

# ML training queue with GPU compute
aws_batch_job_queue(:ml_training, {
  name: "ml-training-queue",
  priority: 80,
  compute_environment_order: [
    {
      order: 1,
      compute_environment: aws_batch_compute_environment(:gpu_ml).arn
    }
  ],
  scheduling_policy_arn: aws_batch_scheduling_policy(:ml_fair_share).arn,
  tags: {
    WorkloadType: "ml-training",
    GPU: "required"
  }
})

# Serverless queue for lightweight jobs
aws_batch_job_queue(:serverless, {
  name: "serverless-queue",
  priority: 30,
  compute_environment_order: [
    {
      order: 1,
      compute_environment: aws_batch_compute_environment(:serverless).arn
    }
  ],
  tags: {
    Type: "serverless",
    Purpose: "lightweight-processing"
  }
})
```

### aws_batch_job_definition
Defines job templates with container configuration and resource requirements.

**Key Features:**
- Container and multi-node job types
- Resource requirements (CPU, memory, GPU)
- Environment variable and secrets management
- Retry strategies and timeouts
- Platform capabilities (EC2, Fargate)

**Common Patterns:**
```ruby
# Data processing job definition
aws_batch_job_definition(:data_processing, {
  job_definition_name: "data-processing-job",
  type: "container",
  platform_capabilities: ["EC2"],
  container_properties: {
    image: "your-account.dkr.ecr.us-east-1.amazonaws.com/data-processor:latest",
    vcpus: 2,
    memory: 4096,
    job_role_arn: aws_iam_role(:batch_job).arn,
    execution_role_arn: aws_iam_role(:batch_execution).arn,
    environment: [
      {
        name: "AWS_DEFAULT_REGION",
        value: "us-east-1"
      },
      {
        name: "S3_BUCKET",
        value: aws_s3_bucket(:data_processing).id
      },
      {
        name: "LOG_LEVEL", 
        value: "INFO"
      }
    ],
    mount_points: [
      {
        source_volume: "tmp",
        container_path: "/tmp",
        read_only: false
      }
    ],
    volumes: [
      {
        name: "tmp",
        host: {
          source_path: "/tmp"
        }
      }
    ],
    log_configuration: {
      log_driver: "awslogs",
      options: {
        "awslogs-group" => aws_cloudwatch_log_group(:batch_logs).name,
        "awslogs-region" => "us-east-1",
        "awslogs-stream-prefix" => "data-processing"
      }
    },
    secrets: [
      {
        name: "DB_PASSWORD",
        value_from: aws_secretsmanager_secret(:db_password).arn
      }
    ]
  },
  retry_strategy: {
    attempts: 3
  },
  timeout: {
    attempt_duration_seconds: 7200  # 2 hours
  },
  tags: {
    JobType: "data-processing",
    Team: "data-engineering"
  }
})

# ML training job with GPU requirements
aws_batch_job_definition(:ml_training, {
  job_definition_name: "ml-training-job",
  type: "container",
  platform_capabilities: ["EC2"],
  container_properties: {
    image: "your-account.dkr.ecr.us-east-1.amazonaws.com/ml-trainer:latest",
    job_role_arn: aws_iam_role(:ml_batch_job).arn,
    execution_role_arn: aws_iam_role(:batch_execution).arn,
    resource_requirements: [
      {
        type: "GPU",
        value: "1"
      },
      {
        type: "VCPU", 
        value: "8"
      },
      {
        type: "MEMORY",
        value: "32768"
      }
    ],
    environment: [
      {
        name: "MODEL_S3_PATH",
        value: "s3://#{aws_s3_bucket(:ml_models).id}/models/"
      },
      {
        name: "TRAINING_DATA_PATH",
        value: "s3://#{aws_s3_bucket(:training_data).id}/datasets/"
      },
      {
        name: "CUDA_VISIBLE_DEVICES",
        value: "0"
      }
    ],
    mount_points: [
      {
        source_volume: "model_cache",
        container_path: "/opt/ml/model",
        read_only: false
      }
    ],
    volumes: [
      {
        name: "model_cache",
        efs_volume_configuration: {
          file_system_id: aws_efs_file_system(:ml_cache).id,
          root_directory: "/models",
          transit_encryption: "ENABLED"
        }
      }
    ],
    log_configuration: {
      log_driver: "awslogs",
      options: {
        "awslogs-group" => aws_cloudwatch_log_group(:ml_training_logs).name,
        "awslogs-region" => "us-east-1"
      }
    }
  },
  retry_strategy: {
    attempts: 2
  },
  timeout: {
    attempt_duration_seconds: 28800  # 8 hours
  },
  tags: {
    JobType: "ml-training",
    GPU: "required"
  }
})

# Fargate job definition for lightweight processing
aws_batch_job_definition(:lightweight_processing, {
  job_definition_name: "lightweight-processor",
  type: "container",
  platform_capabilities: ["FARGATE"],
  container_properties: {
    image: "your-account.dkr.ecr.us-east-1.amazonaws.com/lightweight-processor:latest",
    execution_role_arn: aws_iam_role(:fargate_execution).arn,
    resource_requirements: [
      {
        type: "VCPU",
        value: "0.25"
      },
      {
        type: "MEMORY", 
        value: "512"
      }
    ],
    environment: [
      {
        name: "PROCESSING_MODE",
        value: "lightweight"
      }
    ],
    log_configuration: {
      log_driver: "awslogs",
      options: {
        "awslogs-group" => aws_cloudwatch_log_group(:fargate_logs).name,
        "awslogs-region" => "us-east-1",
        "awslogs-stream-prefix" => "lightweight"
      }
    },
    network_configuration: {
      assign_public_ip: "DISABLED"
    },
    fargate_platform_configuration: {
      platform_version: "LATEST"
    }
  },
  tags: {
    Platform: "fargate",
    JobType: "lightweight"
  }
})

# Multi-node parallel job for HPC workloads
aws_batch_job_definition(:parallel_hpc, {
  job_definition_name: "parallel-hpc-job",
  type: "multinode",
  node_properties: {
    main_node: 0,
    num_nodes: 4,
    node_range_properties: [
      {
        target_nodes: "0:3",
        container: {
          image: "your-account.dkr.ecr.us-east-1.amazonaws.com/mpi-app:latest",
          vcpus: 8,
          memory: 16384,
          job_role_arn: aws_iam_role(:hpc_job_role).arn,
          environment: [
            {
              name: "MPI_RANKS",
              value: "4"
            },
            {
              name: "OMP_NUM_THREADS",
              value: "8"
            }
          ]
        }
      }
    ]
  },
  retry_strategy: {
    attempts: 1  # HPC jobs typically don't retry
  },
  timeout: {
    attempt_duration_seconds: 14400  # 4 hours
  },
  tags: {
    JobType: "hpc-parallel",
    Nodes: "multi"
  }
})
```

### aws_batch_job
Submits individual jobs to job queues for processing.

**Key Features:**
- Job parameter customization
- Container and node overrides
- Job dependencies
- Retry and timeout configuration

**Common Patterns:**
```ruby
# Data processing job with parameters
aws_batch_job(:daily_data_processing, {
  job_name: "daily-data-processing-#{Time.now.strftime('%Y%m%d')}",
  job_queue: aws_batch_job_queue(:high_priority).arn,
  job_definition: aws_batch_job_definition(:data_processing).arn,
  parameters: {
    "inputPath" => "s3://#{aws_s3_bucket(:raw_data).id}/daily/#{Date.today}",
    "outputPath" => "s3://#{aws_s3_bucket(:processed_data).id}/daily/#{Date.today}",
    "processingDate" => Date.today.to_s
  },
  container_overrides: {
    environment: [
      {
        name: "BATCH_SIZE",
        value: "1000"
      },
      {
        name: "PARALLEL_WORKERS",
        value: "4"
      }
    ]
  },
  retry_strategy: {
    attempts: 3
  },
  timeout: {
    attempt_duration_seconds: 7200
  },
  tags: {
    JobType: "daily-processing",
    Date: Date.today.to_s
  }
})

# ML training job with specific resource overrides
aws_batch_job(:model_training, {
  job_name: "model-training-#{SecureRandom.hex(4)}",
  job_queue: aws_batch_job_queue(:ml_training).arn,
  job_definition: aws_batch_job_definition(:ml_training).arn,
  parameters: {
    "modelType" => "transformer",
    "datasetPath" => "s3://training-data/latest/",
    "epochs" => "100",
    "learningRate" => "0.001"
  },
  container_overrides: {
    vcpus: 16,
    memory: 65536,  # 64GB
    environment: [
      {
        name: "MODEL_NAME",
        value: "custom-transformer-v1"
      },
      {
        name: "CHECKPOINT_INTERVAL",
        value: "10"
      }
    ],
    resource_requirements: [
      {
        type: "GPU",
        value: "4"  # Override to use 4 GPUs
      }
    ]
  },
  tags: {
    JobType: "ml-training",
    Model: "transformer"
  }
})

# Job with dependencies on other jobs
aws_batch_job(:data_validation, {
  job_name: "data-validation-#{Time.now.to_i}",
  job_queue: aws_batch_job_queue(:high_priority).arn,
  job_definition: aws_batch_job_definition(:data_processing).arn,
  depends_on_jobs: [
    {
      job_id: aws_batch_job(:daily_data_processing).job_id,
      type: "N_TO_N"
    }
  ],
  parameters: {
    "validationRules" => "strict",
    "inputPath" => "s3://processed-data/daily/#{Date.today}"
  },
  tags: {
    JobType: "validation",
    DependsOn: "data-processing"
  }
})

# Parallel array job pattern
(1..10).each do |i|
  aws_batch_job(:"batch_job_#{i}", {
    job_name: "parallel-processing-#{i}",
    job_queue: aws_batch_job_queue(:multi_environment).arn,
    job_definition: aws_batch_job_definition(:data_processing).arn,
    parameters: {
      "partitionId" => i.to_s,
      "totalPartitions" => "10",
      "inputPath" => "s3://large-dataset/partition-#{i}/"
    },
    container_overrides: {
      environment: [
        {
          name: "PARTITION_ID",
          value: i.to_s
        }
      ]
    },
    tags: {
      JobType: "parallel-processing",
      Partition: i.to_s
    }
  })
end
```

### aws_batch_scheduling_policy
Manages job scheduling policies for fair resource allocation and priority handling.

**Key Features:**
- Fair share scheduling
- Compute reservation management  
- Share decay configuration
- Weight-based resource allocation

**Common Patterns:**
```ruby
# Fair share policy for multi-tenant environment
aws_batch_scheduling_policy(:multi_tenant_fair_share, {
  name: "multi-tenant-fair-share",
  fair_share_policy: {
    compute_reservation: 10,  # Reserve 10% for high priority
    share_decay_seconds: 3600,  # 1 hour decay
    share_distribution: [
      {
        share_identifier: "team-data-engineering",
        weight_factor: 0.4
      },
      {
        share_identifier: "team-ml-research", 
        weight_factor: 0.3
      },
      {
        share_identifier: "team-analytics",
        weight_factor: 0.2
      },
      {
        share_identifier: "team-other",
        weight_factor: 0.1
      }
    ]
  },
  tags: {
    Purpose: "fair-share",
    Environment: "production"
  }
})

# ML training fair share with longer decay
aws_batch_scheduling_policy(:ml_fair_share, {
  name: "ml-training-fair-share",
  fair_share_policy: {
    compute_reservation: 20,  # Reserve more for high priority ML jobs
    share_decay_seconds: 7200,  # 2 hours decay for longer jobs
    share_distribution: [
      {
        share_identifier: "research-team",
        weight_factor: 0.5
      },
      {
        share_identifier: "production-ml",
        weight_factor: 0.3
      },
      {
        share_identifier: "experimentation",
        weight_factor: 0.2
      }
    ]
  },
  tags: {
    WorkloadType: "ml-training",
    GPU: "optimized"
  }
})

# Development environment scheduling
aws_batch_scheduling_policy(:dev_scheduling, {
  name: "development-scheduling",
  fair_share_policy: {
    compute_reservation: 5,  # Lower reservation for dev
    share_decay_seconds: 1800,  # 30 minutes decay
    share_distribution: [
      {
        share_identifier: "dev-team-1",
        weight_factor: 0.33
      },
      {
        share_identifier: "dev-team-2", 
        weight_factor: 0.33
      },
      {
        share_identifier: "dev-testing",
        weight_factor: 0.34
      }
    ]
  },
  tags: {
    Environment: "development",
    Purpose: "testing"
  }
})
```

## Best Practices

### Compute Environment Design
1. **Resource Optimization**
   - Use Spot instances for fault-tolerant workloads
   - Choose appropriate instance types for workload characteristics
   - Configure auto-scaling based on job demand patterns

2. **Network Configuration**
   - Place compute in private subnets for security
   - Use appropriate security groups with minimal required access
   - Consider placement groups for HPC workloads

3. **Cost Management**
   - Mix On-Demand and Spot instances appropriately
   - Use Fargate for variable, lightweight workloads
   - Monitor and optimize instance type selection

### Job Definition Best Practices
1. **Container Optimization**
   - Use multi-stage builds for smaller images
   - Implement proper health checks and monitoring
   - Secure container configurations

2. **Resource Requirements**
   - Right-size CPU, memory, and GPU requirements
   - Use resource requirements for Fargate jobs
   - Implement appropriate retry and timeout strategies

3. **Environment Management**
   - Use secrets management for sensitive data
   - Implement proper logging configuration
   - Pass configuration via environment variables

### Queue and Scheduling
1. **Queue Design**
   - Separate queues by priority and resource requirements
   - Implement appropriate job timeouts
   - Use multiple compute environments for redundancy

2. **Fair Share Scheduling**
   - Configure appropriate weight factors for teams/workloads
   - Set reasonable share decay periods
   - Monitor resource utilization and adjust policies

## Integration Examples

### Complete Data Processing Pipeline
```ruby
# End-to-end data processing with AWS Batch
template :batch_data_pipeline do
  # Compute environments for different workload types
  spot_compute = aws_batch_compute_environment(:spot_processing, {
    compute_environment_name: "data-processing-spot",
    type: "MANAGED",
    compute_resources: {
      type: "SPOT",
      allocation_strategy: "SPOT_CAPACITY_OPTIMIZED",
      min_vcpus: 0,
      max_vcpus: 500,
      instance_types: ["m5.large", "m5.xlarge", "c5.large"],
      spot_iam_fleet_request_role: aws_iam_role(:spot_fleet).arn,
      subnets: private_subnet_ids,
      security_group_ids: [aws_security_group(:batch_compute).id],
      instance_role: aws_iam_instance_profile(:ecs_instance).arn
    },
    service_role: aws_iam_role(:batch_service).arn,
    tags: processing_tags
  })

  ondemand_compute = aws_batch_compute_environment(:ondemand_processing, {
    compute_environment_name: "data-processing-ondemand",
    type: "MANAGED",
    compute_resources: {
      type: "EC2",
      allocation_strategy: "BEST_FIT_PROGRESSIVE",
      min_vcpus: 0,
      max_vcpus: 100,
      instance_types: ["m5.large", "m5.xlarge"],
      subnets: private_subnet_ids,
      security_group_ids: [aws_security_group(:batch_compute).id],
      instance_role: aws_iam_instance_profile(:ecs_instance).arn
    },
    service_role: aws_iam_role(:batch_service).arn,
    tags: processing_tags
  })

  # Job queues with different priorities
  critical_queue = aws_batch_job_queue(:critical_processing, {
    name: "critical-data-processing",
    priority: 100,
    compute_environment_order: [
      {
        order: 1,
        compute_environment: ondemand_compute.arn
      }
    ],
    tags: { Priority: "critical" }
  })

  standard_queue = aws_batch_job_queue(:standard_processing, {
    name: "standard-data-processing", 
    priority: 50,
    compute_environment_order: [
      {
        order: 1,
        compute_environment: ondemand_compute.arn
      },
      {
        order: 2, 
        compute_environment: spot_compute.arn
      }
    ],
    tags: { Priority: "standard" }
  })

  # Job definitions for different processing stages
  data_ingestion_job = aws_batch_job_definition(:data_ingestion, {
    job_definition_name: "data-ingestion",
    type: "container",
    platform_capabilities: ["EC2"],
    container_properties: {
      image: "#{ecr_repository_url}/data-ingestion:latest",
      vcpus: 2,
      memory: 4096,
      job_role_arn: aws_iam_role(:data_ingestion_job).arn,
      environment: [
        {
          name: "S3_RAW_BUCKET",
          value: aws_s3_bucket(:raw_data).id
        },
        {
          name: "S3_PROCESSED_BUCKET", 
          value: aws_s3_bucket(:processed_data).id
        }
      ],
      log_configuration: log_config("data-ingestion")
    },
    retry_strategy: { attempts: 3 },
    timeout: { attempt_duration_seconds: 3600 }
  })

  data_transformation_job = aws_batch_job_definition(:data_transformation, {
    job_definition_name: "data-transformation",
    type: "container",
    platform_capabilities: ["EC2"],
    container_properties: {
      image: "#{ecr_repository_url}/data-transformation:latest",
      vcpus: 4,
      memory: 8192,
      job_role_arn: aws_iam_role(:data_transformation_job).arn,
      environment: common_environment_vars,
      log_configuration: log_config("data-transformation")
    },
    retry_strategy: { attempts: 2 },
    timeout: { attempt_duration_seconds: 7200 }
  })

  data_validation_job = aws_batch_job_definition(:data_validation, {
    job_definition_name: "data-validation",
    type: "container", 
    platform_capabilities: ["EC2"],
    container_properties: {
      image: "#{ecr_repository_url}/data-validation:latest",
      vcpus: 1,
      memory: 2048,
      job_role_arn: aws_iam_role(:data_validation_job).arn,
      environment: common_environment_vars,
      log_configuration: log_config("data-validation")
    },
    retry_strategy: { attempts: 3 },
    timeout: { attempt_duration_seconds: 1800 }
  })

  # Fair share scheduling for different teams
  aws_batch_scheduling_policy(:data_teams_fair_share, {
    name: "data-teams-fair-share",
    fair_share_policy: {
      compute_reservation: 15,
      share_decay_seconds: 3600,
      share_distribution: [
        { share_identifier: "data-engineering", weight_factor: 0.5 },
        { share_identifier: "analytics", weight_factor: 0.3 },
        { share_identifier: "data-science", weight_factor: 0.2 }
      ]
    }
  })
end
```

## Common Pitfalls and Solutions

### Resource Sizing Issues
**Problem**: Jobs failing due to insufficient memory or CPU
**Solution**:
- Monitor CloudWatch metrics for resource utilization
- Use job definition resource requirements appropriately
- Implement proper retry strategies with backoff

### Cost Optimization Challenges
**Problem**: High compute costs due to inefficient resource usage
**Solution**:
- Use Spot instances for fault-tolerant workloads
- Right-size compute environments based on actual usage
- Implement auto-scaling policies appropriately

### Job Dependency Complexity
**Problem**: Complex job workflows difficult to manage
**Solution**:
- Use Step Functions for complex workflows
- Implement proper job naming and tagging strategies
- Consider AWS Batch array jobs for parallel processing

### Queue Management Issues
**Problem**: Jobs stuck in queues or uneven resource allocation
**Solution**:
- Configure multiple compute environments per queue
- Use fair share scheduling policies appropriately
- Monitor queue metrics and adjust priorities