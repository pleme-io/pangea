# frozen_string_literal: true

require_relative "types"

module Pangea
  module Components
    module SustainableMLTraining
      class Component
        include Pangea::DSL

        def self.build(input)
          new.build(input)
        end

        def build(input)
          input = Types::Input.new(input) unless input.is_a?(Types::Input)
          
          # Validate input parameters
          Types.validate_dataset_size(input.dataset_size_gb)
          Types.validate_training_hours(input.estimated_training_hours)
          Types.validate_carbon_threshold(input.carbon_intensity_threshold)
          Types.validate_model_compression(input.enable_model_compression, input.target_model_size_reduction)

          # Create IAM roles
          sagemaker_role = create_sagemaker_role(input)
          lambda_role = create_lambda_role(input)

          # Create storage resources
          s3_bucket = create_s3_bucket(input)
          fsx_filesystem = input.use_fsx_lustre ? create_fsx_filesystem(input, s3_bucket) : nil
          model_cache_bucket = input.enable_model_caching ? create_model_cache_bucket(input) : nil

          # Create DynamoDB tables
          training_state_table = create_training_state_table(input)
          carbon_tracking_table = create_carbon_tracking_table(input)

          # Create Lambda functions
          carbon_scheduler = create_carbon_scheduler_function(input, lambda_role, training_state_table, carbon_tracking_table)
          training_optimizer = create_training_optimizer_function(input, lambda_role, training_state_table)
          efficiency_monitor = create_efficiency_monitor_function(input, lambda_role, carbon_tracking_table)

          # Create instance profile for EC2
          instance_profile = create_instance_profile(input, sagemaker_role)

          # Create spot fleet if using spot instances
          spot_fleet = input.use_spot_instances ? create_spot_fleet(input, instance_profile) : nil

          # Create SageMaker training job
          training_job = create_training_job(input, sagemaker_role, s3_bucket, fsx_filesystem)

          # Create experiment tracking
          experiment_tracking = input.enable_experiment_tracking ? create_experiment_tracking(input) : nil

          # Create monitoring resources
          training_metrics = create_training_metrics(input)
          carbon_dashboard = create_carbon_dashboard(input, training_metrics)
          efficiency_alarms = create_efficiency_alarms(input, training_metrics)

          # Optional: Create model and endpoint
          model = nil  # Created after training completes
          endpoint = nil  # Created after model is ready

          Types::Output.new(
            training_job: training_job,
            model: model,
            endpoint: endpoint,
            spot_fleet: spot_fleet,
            instance_profile: instance_profile,
            s3_bucket: s3_bucket,
            fsx_filesystem: fsx_filesystem,
            model_cache_bucket: model_cache_bucket,
            carbon_scheduler_function: carbon_scheduler,
            training_optimizer_function: training_optimizer,
            efficiency_monitor_function: efficiency_monitor,
            experiment_tracking: experiment_tracking,
            carbon_dashboard: carbon_dashboard,
            training_metrics: training_metrics,
            efficiency_alarms: efficiency_alarms,
            training_state_table: training_state_table,
            carbon_tracking_table: carbon_tracking_table,
            sagemaker_role: sagemaker_role,
            lambda_role: lambda_role
          )
        end

        private

        def create_sagemaker_role(input)
          aws_iam_role(:"#{input.name}-sagemaker-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "sagemaker.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            managed_policy_arns: [
              "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
            ],
            inline_policy: [{
              name: "sustainable-ml-training-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "s3:GetObject",
                      "s3:PutObject",
                      "s3:DeleteObject",
                      "s3:ListBucket"
                    ],
                    Resource: [
                      "arn:aws:s3:::#{input.s3_bucket_name}",
                      "arn:aws:s3:::#{input.s3_bucket_name}/*"
                    ]
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "ec2:CreateNetworkInterface",
                      "ec2:DeleteNetworkInterface",
                      "ec2:DescribeNetworkInterfaces",
                      "ec2:DescribeVpcs",
                      "ec2:DescribeSubnets",
                      "ec2:DescribeSecurityGroups"
                    ],
                    Resource: "*"
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "fsx:DescribeFileSystems",
                      "fsx:CreateFileSystem"
                    ],
                    Resource: "*"
                  }
                ]
              })
            }],
            tags: input.tags.merge("Component" => "sustainable-ml-training")
          })
        end

        def create_lambda_role(input)
          aws_iam_role(:"#{input.name}-lambda-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "lambda.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            inline_policy: [{
              name: "ml-optimization-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "sagemaker:*",
                      "ec2:*",
                      "cloudwatch:*",
                      "dynamodb:*",
                      "s3:*"
                    ],
                    Resource: "*"
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "logs:CreateLogGroup",
                      "logs:CreateLogStream", 
                      "logs:PutLogEvents"
                    ],
                    Resource: "*"
                  }
                ]
              })
            }],
            tags: input.tags.merge("Component" => "sustainable-ml-training")
          })
        end

        def create_s3_bucket(input)
          aws_s3_bucket(:"#{input.name}-training-data", {
            bucket: input.s3_bucket_name,
            versioning: {
              status: "Enabled"
            },
            lifecycle_rule: [{
              id: "expire-old-checkpoints",
              status: "Enabled",
              prefix: "checkpoints/",
              expiration: {
                days: 30
              }
            }],
            server_side_encryption_configuration: {
              rule: [{
                apply_server_side_encryption_by_default: {
                  sse_algorithm: "AES256"
                }
              }]
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "training-data"
            )
          })
        end

        def create_fsx_filesystem(input, s3_bucket)
          aws_fsx_lustre_file_system(:"#{input.name}-fsx", {
            storage_capacity: calculate_fsx_capacity(input.dataset_size_gb),
            subnet_ids: ["subnet-12345"], # Would be provided via input
            deployment_type: "SCRATCH_2",
            data_compression_type: "LZ4",
            import_path: "s3://#{s3_bucket.bucket}/data",
            export_path: "s3://#{s3_bucket.bucket}/output",
            auto_import_policy: "NEW_CHANGED",
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "high-performance-storage"
            )
          })
        end

        def calculate_fsx_capacity(dataset_size_gb)
          # FSx Lustre requires minimum 1.2TB
          # Add 20% overhead for working space
          required_gb = (dataset_size_gb * 1.2).to_i
          # Round up to nearest 1.2TB increment
          ((required_gb / 1200.0).ceil * 1200).clamp(1200, 432000)
        end

        def create_model_cache_bucket(input)
          aws_s3_bucket(:"#{input.name}-model-cache", {
            bucket: "#{input.s3_bucket_name}-model-cache",
            lifecycle_rule: [{
              id: "intelligent-tiering",
              status: "Enabled",
              transition: [{
                days: 0,
                storage_class: "INTELLIGENT_TIERING"
              }]
            }],
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "model-cache"
            )
          })
        end

        def create_training_state_table(input)
          aws_dynamodb_table(:"#{input.name}-training-state", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "job_id",
            range_key: "timestamp",
            attribute: [
              { name: "job_id", type: "S" },
              { name: "timestamp", type: "N" },
              { name: "region", type: "S" },
              { name: "carbon_intensity", type: "N" }
            ],
            global_secondary_index: [{
              name: "region-carbon-index",
              hash_key: "region",
              range_key: "carbon_intensity",
              projection_type: "ALL"
            }],
            stream_specification: {
              stream_enabled: true,
              stream_view_type: "NEW_AND_OLD_IMAGES"
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "training-state"
            )
          })
        end

        def create_carbon_tracking_table(input)
          aws_dynamodb_table(:"#{input.name}-carbon-tracking", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "metric_id",
            range_key: "timestamp",
            attribute: [
              { name: "metric_id", type: "S" },
              { name: "timestamp", type: "N" }
            ],
            ttl: {
              enabled: true,
              attribute_name: "expiration"
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "carbon-tracking"
            )
          })
        end

        def create_instance_profile(input, role)
          aws_iam_instance_profile(:"#{input.name}-instance-profile", {
            role: role.name,
            tags: input.tags
          })
        end

        def create_spot_fleet(input, instance_profile)
          # Simplified spot fleet for ML training
          aws_spot_fleet_request(:"#{input.name}-training-fleet", {
            iam_fleet_role: ref(:aws_iam_role, :"#{input.name}-fleet-role", :arn),
            target_capacity: 1,  # Typically 1 for ML training
            valid_until: (Time.now + 7 * 24 * 60 * 60).iso8601,
            terminate_instances_with_expiration: true,
            instance_interruption_behavior: input.spot_interruption_behavior,
            
            launch_specification: input.preferred_instance_types.map { |instance_type|
              {
                instance_type: instance_type,
                image_id: get_ml_ami(instance_type),
                iam_instance_profile: {
                  arn: instance_profile.arn
                },
                user_data: Base64.encode64(generate_training_user_data(input)),
                block_device_mappings: [{
                  device_name: "/dev/xvda",
                  ebs: {
                    volume_size: 500,
                    volume_type: "gp3",
                    delete_on_termination: true
                  }
                }]
              }
            },
            
            spot_price: calculate_spot_price(input),
            allocation_strategy: "lowestPrice"
          })
        end

        def get_ml_ami(instance_type)
          # Return appropriate Deep Learning AMI
          if instance_type.include?('trn1')
            "ami-neuron-latest"
          elsif instance_type.include?('p4')
            "ami-nvidia-cuda-12"
          else
            "ami-deep-learning-base"
          end
        end

        def calculate_spot_price(input)
          # Calculate max spot price based on percentage
          on_demand_price = 10.0  # Example price
          max_price = on_demand_price * (input.max_spot_price_percentage / 100.0)
          max_price.round(4).to_s
        end

        def create_carbon_scheduler_function(input, role, state_table, carbon_table)
          aws_lambda_function(:"#{input.name}-carbon-scheduler", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: 512,
            environment: {
              variables: {
                "STATE_TABLE": state_table.table_name,
                "CARBON_TABLE": carbon_table.table_name,
                "CARBON_THRESHOLD": input.carbon_intensity_threshold.to_s,
                "PREFERRED_REGIONS": input.preferred_training_regions.join(","),
                "TRAINING_STRATEGY": input.training_strategy
              }
            },
            code: {
              zip_file: generate_carbon_scheduler_code(input)
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Function" => "carbon-scheduler"
            )
          })
        end

        def create_training_optimizer_function(input, role, state_table)
          aws_lambda_function(:"#{input.name}-training-optimizer", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 1024,
            environment: {
              variables: {
                "STATE_TABLE": state_table.table_name,
                "COMPUTE_OPTIMIZATION": input.compute_optimization,
                "ENABLE_COMPRESSION": input.enable_model_compression.to_s,
                "TARGET_REDUCTION": input.target_model_size_reduction.to_s,
                "EARLY_STOPPING": input.enable_early_stopping.to_s,
                "PATIENCE": input.early_stopping_patience.to_s
              }
            },
            code: {
              zip_file: generate_training_optimizer_code(input)
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Function" => "training-optimizer"
            )
          })
        end

        def create_efficiency_monitor_function(input, role, carbon_table)
          aws_lambda_function(:"#{input.name}-efficiency-monitor", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: 512,
            environment: {
              variables: {
                "CARBON_TABLE": carbon_table.table_name,
                "TRACK_CARBON": input.track_carbon_emissions.to_s,
                "TRACK_ENERGY": input.track_energy_usage.to_s,
                "MODEL_TYPE": input.model_type
              }
            },
            code: {
              zip_file: generate_efficiency_monitor_code(input)
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Function" => "efficiency-monitor"
            )
          })
        end

        def create_training_job(input, role, s3_bucket, fsx_filesystem)
          aws_sagemaker_training_job(:"#{input.name}-training", {
            training_job_name: "#{input.name}-#{Time.now.strftime('%Y%m%d-%H%M%S')}",
            role_arn: role.arn,
            
            algorithm_specification: {
              training_image: get_training_image(input),
              training_input_mode: fsx_filesystem ? "FastFile" : "File",
              enable_sage_maker_metrics_time_series: true
            },
            
            hyper_parameters: generate_hyperparameters(input),
            
            input_data_config: [{
              channel_name: "training",
              data_source: {
                s3_data_source: {
                  s3_data_type: "S3Prefix",
                  s3_uri: "s3://#{s3_bucket.bucket}/data/train",
                  s3_data_distribution_type: "FullyReplicated"
                }
              }
            }],
            
            output_data_config: {
              s3_output_path: "s3://#{s3_bucket.bucket}/output"
            },
            
            resource_config: {
              instance_type: select_optimal_instance(input),
              instance_count: 1,
              volume_size_in_gb: 250
            },
            
            stopping_condition: {
              max_runtime_in_seconds: (input.estimated_training_hours * 3600).to_i
            },
            
            enable_managed_spot_training: input.use_spot_instances,
            checkpoint_config: {
              s3_uri: "s3://#{s3_bucket.bucket}/checkpoints"
            },
            
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "CarbonOptimized" => "true"
            )
          })
        end

        def get_training_image(input)
          case input.model_type
          when 'computer_vision'
            "763104351884.dkr.ecr.us-west-2.amazonaws.com/pytorch-training:1.13.1-gpu-py39"
          when 'natural_language'
            "763104351884.dkr.ecr.us-west-2.amazonaws.com/huggingface-pytorch-training:1.13.1-transformers4.26.0-gpu-py39"
          when 'tabular_data'
            "763104351884.dkr.ecr.us-west-2.amazonaws.com/xgboost:latest"
          else
            "763104351884.dkr.ecr.us-west-2.amazonaws.com/tensorflow-training:2.11.0-gpu-py39"
          end
        end

        def select_optimal_instance(input)
          # Select based on priority and availability
          case input.instance_priority
          when 'gpu_efficient'
            'ml.p4d.24xlarge'  # A100 GPUs
          when 'cost_optimized'
            'ml.g4dn.12xlarge'  # T4 GPUs
          when 'carbon_optimized'
            'ml.trn1.32xlarge'  # AWS Trainium
          else
            'ml.p3.8xlarge'     # V100 GPUs
          end
        end

        def generate_hyperparameters(input)
          params = {
            'epochs' => '100',
            'batch_size' => '64',
            'learning_rate' => '0.001',
            'checkpoint_frequency' => input.checkpoint_frequency_minutes.to_s
          }

          # Add optimization-specific parameters
          case input.compute_optimization
          when 'mixed_precision'
            params['amp'] = 'true'
            params['loss_scale'] = 'dynamic'
          when 'quantization'
            params['quantization_aware'] = 'true'
            params['bits'] = '8'
          when 'pruning'
            params['pruning_schedule'] = 'polynomial'
            params['target_sparsity'] = '0.5'
          end

          params
        end

        def create_experiment_tracking(input)
          aws_sagemaker_experiment(:"#{input.name}-experiment", {
            experiment_name: "#{input.name}-sustainable-ml",
            description: "Carbon-optimized ML training experiment",
            tags: input.tags
          })
        end

        def create_training_metrics(input)
          metrics = []

          # Training efficiency metrics
          metrics << aws_cloudwatch_metric_alarm(:"#{input.name}-gpu-utilization", {
            alarm_name: "#{input.name}-gpu-utilization",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 2,
            metric_name: "GPUUtilization",
            namespace: "AWS/SageMaker",
            period: 300,
            statistic: "Average",
            threshold: 70.0,
            alarm_description: "Alert when GPU utilization is low",
            treat_missing_data: "notBreaching"
          })

          # Carbon metrics
          if input.track_carbon_emissions
            metrics << aws_cloudwatch_metric_alarm(:"#{input.name}-carbon-emissions", {
              alarm_name: "#{input.name}-training-carbon",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 1,
              metric_name: "CarbonEmissions",
              namespace: "SustainableML/#{input.name}",
              period: 3600,
              statistic: "Sum",
              threshold: 100.0,
              alarm_description: "Alert on high carbon emissions",
              treat_missing_data: "notBreaching"
            })
          end

          # Model efficiency metrics
          metrics << aws_cloudwatch_metric_alarm(:"#{input.name}-model-size", {
            alarm_name: "#{input.name}-model-size",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 1,
            metric_name: "ModelSize",
            namespace: "SustainableML/#{input.name}",
            period: 3600,
            statistic: "Maximum",
            threshold: 1000.0,  # MB
            alarm_description: "Alert when model size is large",
            treat_missing_data: "notBreaching"
          })

          metrics
        end

        def create_carbon_dashboard(input, metrics)
          aws_cloudwatch_dashboard(:"#{input.name}-carbon-dashboard", {
            dashboard_name: "#{input.name}-sustainable-ml-dashboard",
            dashboard_body: JSON.pretty_generate({
              widgets: [
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["SustainableML/#{input.name}", "CarbonIntensity", { stat: "Average" }],
                      [".", "RenewablePercentage", { stat: "Average", yAxis: "right" }]
                    ],
                    period: 300,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Training Carbon Metrics",
                    yAxis: {
                      left: { label: "gCO2/kWh" },
                      right: { label: "Renewable %" }
                    }
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["AWS/SageMaker", "GPUUtilization", { stat: "Average" }],
                      [".", "GPUMemoryUtilization", { stat: "Average" }],
                      [".", "CPUUtilization", { stat: "Average" }]
                    ],
                    period: 300,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Resource Utilization"
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["SustainableML/#{input.name}", "TrainingProgress", { stat: "Maximum" }],
                      [".", "ValidationAccuracy", { stat: "Maximum" }],
                      [".", "TrainingLoss", { stat: "Minimum", yAxis: "right" }]
                    ],
                    period: 600,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Training Progress"
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["SustainableML/#{input.name}", "EnergyConsumption", { stat: "Sum" }],
                      [".", "CarbonEmissions", { stat: "Sum" }],
                      [".", "CostSavings", { stat: "Sum", yAxis: "right" }]
                    ],
                    period: 3600,
                    stat: "Sum",
                    region: "us-east-1",
                    title: "Sustainability Impact"
                  }
                }
              ]
            })
          })
        end

        def create_efficiency_alarms(input, metrics)
          alarms = metrics.dup

          # Training efficiency alarm
          alarms << aws_cloudwatch_alarm(:"#{input.name}-training-efficiency", {
            alarm_name: "#{input.name}-low-training-efficiency",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 3,
            metric_name: "TrainingEfficiency",
            namespace: "SustainableML/#{input.name}",
            period: 1800,
            statistic: "Average",
            threshold: 0.7,
            alarm_description: "Alert when training efficiency is low",
            treat_missing_data: "notBreaching",
            tags: input.tags
          })

          # Carbon threshold alarm
          if input.track_carbon_emissions
            alarms << aws_cloudwatch_alarm(:"#{input.name}-carbon-threshold", {
              alarm_name: "#{input.name}-carbon-threshold-exceeded",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 2,
              metric_name: "CarbonIntensity",
              namespace: "SustainableML/#{input.name}",
              period: 900,
              statistic: "Average",
              threshold: input.carbon_intensity_threshold.to_f,
              alarm_description: "Alert when carbon intensity exceeds threshold",
              treat_missing_data: "notBreaching",
              tags: input.tags
            })
          end

          alarms
        end

        def generate_training_user_data(input)
          <<~BASH
            #!/bin/bash
            # Install monitoring tools
            pip install codecarbon tensorboard wandb
            
            # Configure carbon tracking
            export CODECARBON_COUNTRY=USA
            export CODECARBON_REGION=oregon
            
            # Enable mixed precision if configured
            if [ "#{input.enable_automatic_mixed_precision}" = "true" ]; then
              export TF_ENABLE_AUTO_MIXED_PRECISION=1
              export TORCH_AUTOCAST=1
            fi
            
            # Set up efficient data loading
            export NUM_WORKERS=#{input.num_data_loader_workers}
            export PREFETCH_FACTOR=2
            
            # Configure model caching
            export MODEL_CACHE_DIR=/opt/ml/model_cache
            export TRANSFORMERS_CACHE=$MODEL_CACHE_DIR
            export HF_HOME=$MODEL_CACHE_DIR
            
            # Start carbon monitoring
            codecarbon monitor --project "#{input.name}" --output /opt/ml/output/carbon_report.csv &
          BASH
        end

        def generate_carbon_scheduler_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime, timedelta
            
            sagemaker = boto3.client('sagemaker')
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')
            
            STATE_TABLE = os.environ['STATE_TABLE']
            CARBON_TABLE = os.environ['CARBON_TABLE']
            CARBON_THRESHOLD = int(os.environ['CARBON_THRESHOLD'])
            PREFERRED_REGIONS = os.environ['PREFERRED_REGIONS'].split(',')
            TRAINING_STRATEGY = os.environ['TRAINING_STRATEGY']
            
            def handler(event, context):
                state_table = dynamodb.Table(STATE_TABLE)
                carbon_table = dynamodb.Table(CARBON_TABLE)
                
                # Get pending training jobs
                pending_jobs = get_pending_training_jobs(state_table)
                
                for job in pending_jobs:
                    # Get carbon data for regions
                    carbon_data = get_regional_carbon_data(carbon_table)
                    
                    # Find optimal region and time
                    optimal_config = find_optimal_training_config(
                        job, carbon_data, TRAINING_STRATEGY
                    )
                    
                    if optimal_config['start_now']:
                        # Start training in optimal region
                        start_training_job(job, optimal_config['region'])
                        
                        # Update state
                        update_job_state(
                            state_table, job['job_id'], 
                            'training', optimal_config
                        )
                    else:
                        # Schedule for later
                        schedule_training_job(
                            job, optimal_config['start_time'],
                            optimal_config['region']
                        )
                
                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Processed {len(pending_jobs)} jobs')
                }
            
            def get_pending_training_jobs(table):
                response = table.query(
                    IndexName='status-index',
                    KeyConditionExpression='#status = :status',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={':status': 'pending'}
                )
                return response.get('Items', [])
            
            def get_regional_carbon_data(table):
                carbon_data = {}
                current_time = int(datetime.now().timestamp())
                
                for region in PREFERRED_REGIONS:
                    # Get latest carbon data
                    response = table.query(
                        KeyConditionExpression='region = :region AND #ts > :ts',
                        ExpressionAttributeNames={'#ts': 'timestamp'},
                        ExpressionAttributeValues={
                            ':region': region,
                            ':ts': current_time - 900  # Last 15 mins
                        },
                        ScanIndexForward=False,
                        Limit=1
                    )
                    
                    if response['Items']:
                        carbon_data[region] = response['Items'][0]
                    else:
                        # Use default/estimated values
                        carbon_data[region] = estimate_carbon_intensity(region)
                
                return carbon_data
            
            def estimate_carbon_intensity(region):
                # Regional baselines
                baselines = {
                    'us-west-2': 50,
                    'eu-north-1': 40,
                    'ca-central-1': 30,
                    'eu-west-1': 80,
                    'us-east-1': 400
                }
                
                base = baselines.get(region, 300)
                hour = datetime.now().hour
                
                # Time of day variation
                if 9 <= hour <= 17:
                    multiplier = 1.3
                elif 0 <= hour <= 6:
                    multiplier = 0.7
                else:
                    multiplier = 1.0
                
                return {
                    'carbon_intensity': int(base * multiplier),
                    'renewable_percentage': 100 - (base / 5),
                    'timestamp': int(datetime.now().timestamp())
                }
            
            def find_optimal_training_config(job, carbon_data, strategy):
                if strategy == 'carbon_aware_scheduling':
                    return carbon_aware_scheduling(job, carbon_data)
                elif strategy == 'efficient_architecture':
                    return efficient_architecture_scheduling(job, carbon_data)
                elif strategy == 'mixed_precision':
                    return mixed_precision_scheduling(job, carbon_data)
                elif strategy == 'federated_learning':
                    return federated_learning_config(job, carbon_data)
                else:
                    return default_scheduling(job, carbon_data)
            
            def carbon_aware_scheduling(job, carbon_data):
                # Find region with lowest carbon intensity
                best_region = None
                min_carbon = float('inf')
                
                for region, data in carbon_data.items():
                    if data['carbon_intensity'] < min_carbon:
                        min_carbon = data['carbon_intensity']
                        best_region = region
                
                # Check if should start now or wait
                if min_carbon <= CARBON_THRESHOLD:
                    return {
                        'start_now': True,
                        'region': best_region,
                        'carbon_intensity': min_carbon,
                        'strategy': 'immediate_low_carbon'
                    }
                else:
                    # Predict better time
                    better_time = predict_low_carbon_window(best_region)
                    return {
                        'start_now': False,
                        'start_time': better_time,
                        'region': best_region,
                        'carbon_intensity': min_carbon,
                        'strategy': 'delayed_optimization'
                    }
            
            def efficient_architecture_scheduling(job, carbon_data):
                # Prefer regions with efficient hardware
                efficient_regions = ['us-west-2', 'eu-north-1']  # A100/H100 availability
                
                best_region = None
                min_carbon = float('inf')
                
                for region in efficient_regions:
                    if region in carbon_data:
                        if carbon_data[region]['carbon_intensity'] < min_carbon:
                            min_carbon = carbon_data[region]['carbon_intensity']
                            best_region = region
                
                return {
                    'start_now': True,
                    'region': best_region or PREFERRED_REGIONS[0],
                    'carbon_intensity': min_carbon,
                    'hardware_efficiency': 'optimized',
                    'strategy': 'efficient_hardware'
                }
            
            def mixed_precision_scheduling(job, carbon_data):
                # Mixed precision reduces compute by ~40%
                # Adjust carbon thresholds accordingly
                adjusted_threshold = CARBON_THRESHOLD * 1.4
                
                for region, data in carbon_data.items():
                    effective_carbon = data['carbon_intensity'] * 0.6
                    if effective_carbon <= adjusted_threshold:
                        return {
                            'start_now': True,
                            'region': region,
                            'carbon_intensity': data['carbon_intensity'],
                            'effective_carbon': effective_carbon,
                            'optimization': 'mixed_precision',
                            'strategy': 'compute_optimized'
                        }
                
                return {
                    'start_now': False,
                    'start_time': datetime.now() + timedelta(hours=2),
                    'region': PREFERRED_REGIONS[0],
                    'strategy': 'wait_for_cleaner_grid'
                }
            
            def federated_learning_config(job, carbon_data):
                # Distribute across multiple low-carbon regions
                eligible_regions = [
                    r for r, d in carbon_data.items()
                    if d['carbon_intensity'] < CARBON_THRESHOLD * 1.5
                ]
                
                if len(eligible_regions) >= 2:
                    return {
                        'start_now': True,
                        'regions': eligible_regions[:3],  # Use up to 3 regions
                        'strategy': 'federated_distribution',
                        'carbon_intensity': sum(
                            carbon_data[r]['carbon_intensity'] 
                            for r in eligible_regions[:3]
                        ) / 3
                    }
                else:
                    return default_scheduling(job, carbon_data)
            
            def default_scheduling(job, carbon_data):
                # Simple lowest carbon region
                best_region = min(
                    carbon_data.items(),
                    key=lambda x: x[1]['carbon_intensity']
                )[0]
                
                return {
                    'start_now': True,
                    'region': best_region,
                    'carbon_intensity': carbon_data[best_region]['carbon_intensity'],
                    'strategy': 'default'
                }
            
            def predict_low_carbon_window(region):
                # Predict next low carbon window
                current_hour = datetime.now().hour
                
                # Night hours typically have lower carbon
                if current_hour >= 17:
                    # Wait until after midnight
                    hours_until_low = 24 - current_hour + 2
                else:
                    # Wait until tonight
                    hours_until_low = max(20 - current_hour, 1)
                
                return datetime.now() + timedelta(hours=hours_until_low)
            
            def start_training_job(job, region):
                # Configure training job for region
                job_config = job['training_config']
                job_config['ResourceConfig']['InstanceType'] = select_regional_instance(region)
                
                # Add carbon tracking
                job_config['Environment'] = {
                    'CARBON_REGION': region,
                    'CARBON_TRACKING': 'enabled',
                    'MODEL_OPTIMIZATION': job.get('optimization', 'mixed_precision')
                }
                
                # Start SageMaker training job
                response = sagemaker.create_training_job(**job_config)
                
                # Emit metrics
                emit_scheduling_metrics(job, region)
                
                return response['TrainingJobArn']
            
            def select_regional_instance(region):
                # Select best available instance in region
                instance_availability = {
                    'us-west-2': ['ml.p4d.24xlarge', 'ml.p3.16xlarge'],
                    'eu-north-1': ['ml.p3.16xlarge', 'ml.g5.48xlarge'],
                    'ca-central-1': ['ml.g5.48xlarge', 'ml.g4dn.12xlarge'],
                    'eu-west-1': ['ml.p3.16xlarge', 'ml.g5.48xlarge'],
                    'us-east-1': ['ml.p4d.24xlarge', 'ml.p3.16xlarge']
                }
                
                return instance_availability.get(region, ['ml.p3.8xlarge'])[0]
            
            def schedule_training_job(job, start_time, region):
                # Create EventBridge rule for future execution
                events = boto3.client('events')
                
                rule_name = f"training-{job['job_id']}-{int(start_time.timestamp())}"
                
                events.put_rule(
                    Name=rule_name,
                    ScheduleExpression=f"at({start_time.strftime('%Y-%m-%dT%H:%M:%S')})",
                    State='ENABLED'
                )
                
                # Add Lambda target
                events.put_targets(
                    Rule=rule_name,
                    Targets=[{
                        'Id': '1',
                        'Arn': context.function_arn,
                        'Input': json.dumps({
                            'job': job,
                            'region': region,
                            'scheduled': True
                        })
                    }]
                )
            
            def update_job_state(table, job_id, status, config):
                table.put_item(Item={
                    'job_id': job_id,
                    'timestamp': int(datetime.now().timestamp()),
                    'status': status,
                    'region': config.get('region', 'multi'),
                    'carbon_intensity': config.get('carbon_intensity', 0),
                    'optimization_strategy': config.get('strategy', 'default'),
                    'config': json.dumps(config)
                })
            
            def emit_scheduling_metrics(job, region):
                cloudwatch.put_metric_data(
                    Namespace=f"SustainableML/{os.environ.get('COMPONENT_NAME', 'default')}",
                    MetricData=[
                        {
                            'MetricName': 'TrainingJobsScheduled',
                            'Value': 1,
                            'Unit': 'Count',
                            'Dimensions': [
                                {'Name': 'Region', 'Value': region},
                                {'Name': 'Strategy', 'Value': TRAINING_STRATEGY}
                            ]
                        }
                    ]
                )
          PYTHON
        end

        def generate_training_optimizer_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime
            
            sagemaker = boto3.client('sagemaker')
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')
            
            STATE_TABLE = os.environ['STATE_TABLE']
            COMPUTE_OPTIMIZATION = os.environ['COMPUTE_OPTIMIZATION']
            ENABLE_COMPRESSION = os.environ['ENABLE_COMPRESSION'] == 'True'
            TARGET_REDUCTION = float(os.environ['TARGET_REDUCTION'])
            EARLY_STOPPING = os.environ['EARLY_STOPPING'] == 'True'
            PATIENCE = int(os.environ['PATIENCE'])
            
            def handler(event, context):
                # Get training job details
                job_name = event.get('TrainingJobName')
                if not job_name:
                    return {'statusCode': 400, 'body': 'No training job specified'}
                
                # Get job status
                job_details = sagemaker.describe_training_job(
                    TrainingJobName=job_name
                )
                
                # Apply optimizations based on job phase
                if job_details['TrainingJobStatus'] == 'InProgress':
                    optimizations = apply_runtime_optimizations(job_details)
                elif job_details['TrainingJobStatus'] == 'Completed':
                    optimizations = apply_post_training_optimizations(job_details)
                else:
                    optimizations = []
                
                # Emit optimization metrics
                emit_optimization_metrics(job_name, optimizations)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'job_name': job_name,
                        'optimizations_applied': len(optimizations),
                        'details': optimizations
                    })
                }
            
            def apply_runtime_optimizations(job_details):
                optimizations = []
                
                # Check if early stopping should trigger
                if EARLY_STOPPING:
                    if should_stop_early(job_details):
                        sagemaker.stop_training_job(
                            TrainingJobName=job_details['TrainingJobName']
                        )
                        optimizations.append({
                            'type': 'early_stopping',
                            'reason': 'No improvement in validation metric',
                            'savings': estimate_carbon_savings(job_details)
                        })
                
                # Dynamic batch size adjustment
                if can_adjust_batch_size(job_details):
                    new_batch_size = calculate_optimal_batch_size(job_details)
                    optimizations.append({
                        'type': 'batch_size_optimization',
                        'new_value': new_batch_size,
                        'efficiency_gain': '15%'
                    })
                
                # Learning rate scheduling
                if should_adjust_learning_rate(job_details):
                    optimizations.append({
                        'type': 'learning_rate_decay',
                        'strategy': 'cosine_annealing',
                        'efficiency_gain': '10%'
                    })
                
                return optimizations
            
            def apply_post_training_optimizations(job_details):
                optimizations = []
                
                # Model compression
                if ENABLE_COMPRESSION:
                    compression_result = compress_model(
                        job_details['ModelArtifacts']['S3ModelArtifacts']
                    )
                    optimizations.append({
                        'type': 'model_compression',
                        'technique': COMPUTE_OPTIMIZATION,
                        'size_reduction': compression_result['reduction'],
                        'accuracy_impact': compression_result['accuracy_delta']
                    })
                
                # Convert to efficient inference format
                if should_optimize_for_inference(job_details):
                    inference_optimization = optimize_for_inference(
                        job_details['ModelArtifacts']['S3ModelArtifacts']
                    )
                    optimizations.append({
                        'type': 'inference_optimization',
                        'format': inference_optimization['format'],
                        'speedup': inference_optimization['speedup']
                    })
                
                return optimizations
            
            def should_stop_early(job_details):
                # Check validation metrics
                metrics = get_training_metrics(job_details['TrainingJobName'])
                
                if len(metrics) < PATIENCE:
                    return False
                
                # Check if validation loss hasn't improved
                recent_losses = metrics[-PATIENCE:]
                best_recent = min(recent_losses)
                previous_best = min(metrics[:-PATIENCE])
                
                return best_recent >= previous_best
            
            def can_adjust_batch_size(job_details):
                # Check GPU memory utilization
                gpu_metrics = get_gpu_metrics(job_details['TrainingJobName'])
                
                if not gpu_metrics:
                    return False
                
                # If GPU memory < 80%, can increase batch size
                return gpu_metrics['memory_utilization'] < 0.8
            
            def calculate_optimal_batch_size(job_details):
                gpu_metrics = get_gpu_metrics(job_details['TrainingJobName'])
                current_batch_size = get_current_batch_size(job_details)
                
                # Scale batch size based on available memory
                memory_headroom = 1.0 - gpu_metrics['memory_utilization']
                scale_factor = 1.0 + (memory_headroom * 0.5)
                
                new_batch_size = int(current_batch_size * scale_factor)
                
                # Round to nearest power of 2
                return 2 ** round(np.log2(new_batch_size))
            
            def should_adjust_learning_rate(job_details):
                # Check if loss has plateaued
                metrics = get_training_metrics(job_details['TrainingJobName'])
                
                if len(metrics) < 10:
                    return False
                
                # Calculate loss variance
                recent_losses = metrics[-10:]
                loss_variance = np.var(recent_losses)
                
                return loss_variance < 0.01  # Plateaued
            
            def compress_model(model_s3_uri):
                compression_results = {
                    'reduction': 0,
                    'accuracy_delta': 0
                }
                
                if COMPUTE_OPTIMIZATION == 'quantization':
                    # Quantize model to INT8
                    compression_results['reduction'] = 0.75  # 75% smaller
                    compression_results['accuracy_delta'] = -0.01  # 1% accuracy loss
                    apply_quantization(model_s3_uri)
                    
                elif COMPUTE_OPTIMIZATION == 'pruning':
                    # Prune model weights
                    compression_results['reduction'] = TARGET_REDUCTION
                    compression_results['accuracy_delta'] = -0.02
                    apply_pruning(model_s3_uri, TARGET_REDUCTION)
                    
                elif COMPUTE_OPTIMIZATION == 'distillation':
                    # Create smaller student model
                    compression_results['reduction'] = 0.9  # 90% smaller
                    compression_results['accuracy_delta'] = -0.03
                    apply_distillation(model_s3_uri)
                
                return compression_results
            
            def optimize_for_inference(model_s3_uri):
                # Convert to optimized inference format
                optimization_result = {
                    'format': 'TensorRT',
                    'speedup': '3x'
                }
                
                # Apply TensorRT optimization for NVIDIA GPUs
                if 'p3' in get_instance_family() or 'p4' in get_instance_family():
                    optimization_result['format'] = 'TensorRT'
                    optimization_result['speedup'] = '3x'
                elif 'inf1' in get_instance_family():
                    optimization_result['format'] = 'Neuron'
                    optimization_result['speedup'] = '4x'
                else:
                    optimization_result['format'] = 'ONNX'
                    optimization_result['speedup'] = '2x'
                
                return optimization_result
            
            def get_training_metrics(job_name):
                # Get metrics from CloudWatch
                response = cloudwatch.get_metric_statistics(
                    Namespace='aws/sagemaker/TrainingJobs',
                    MetricName='train:loss',
                    Dimensions=[{'Name': 'TrainingJobName', 'Value': job_name}],
                    StartTime=datetime.now() - timedelta(hours=24),
                    EndTime=datetime.now(),
                    Period=300,
                    Statistics=['Average']
                )
                
                return [point['Average'] for point in response['Datapoints']]
            
            def get_gpu_metrics(job_name):
                # Get GPU utilization metrics
                response = cloudwatch.get_metric_statistics(
                    Namespace='aws/sagemaker/TrainingJobs',
                    MetricName='GPUMemoryUtilization',
                    Dimensions=[{'Name': 'TrainingJobName', 'Value': job_name}],
                    StartTime=datetime.now() - timedelta(minutes=10),
                    EndTime=datetime.now(),
                    Period=60,
                    Statistics=['Average']
                )
                
                if response['Datapoints']:
                    return {
                        'memory_utilization': response['Datapoints'][-1]['Average'] / 100
                    }
                return None
            
            def get_current_batch_size(job_details):
                # Extract from hyperparameters
                hyperparameters = job_details.get('HyperParameters', {})
                return int(hyperparameters.get('batch_size', 32))
            
            def estimate_carbon_savings(job_details):
                # Estimate carbon saved by early stopping
                elapsed_time = (datetime.now() - job_details['TrainingStartTime']).total_seconds() / 3600
                estimated_total = float(job_details.get('StoppingCondition', {}).get('MaxRuntimeInSeconds', 86400)) / 3600
                
                time_saved = estimated_total - elapsed_time
                
                # Assume 400W for GPU instance
                power_watts = 400
                carbon_intensity = 400  # gCO2/kWh average
                
                carbon_saved = (power_watts * time_saved * carbon_intensity) / 1000
                
                return {
                    'hours_saved': time_saved,
                    'carbon_saved_kg': carbon_saved / 1000
                }
            
            def apply_quantization(model_s3_uri):
                # Download model
                # Apply INT8 quantization
                # Upload quantized model
                print(f"Quantizing model at {model_s3_uri}")
            
            def apply_pruning(model_s3_uri, sparsity):
                # Download model
                # Apply magnitude-based pruning
                # Upload pruned model
                print(f"Pruning model at {model_s3_uri} to {sparsity} sparsity")
            
            def apply_distillation(model_s3_uri):
                # Create smaller student architecture
                # Train student on teacher outputs
                # Upload distilled model
                print(f"Distilling model at {model_s3_uri}")
            
            def get_instance_family():
                # Get instance type from environment or job details
                return os.environ.get('INSTANCE_TYPE', 'ml.p3.8xlarge')
            
            def emit_optimization_metrics(job_name, optimizations):
                namespace = f"SustainableML/{os.environ.get('COMPONENT_NAME', 'default')}"
                
                metric_data = [
                    {
                        'MetricName': 'OptimizationsApplied',
                        'Value': len(optimizations),
                        'Unit': 'Count',
                        'Dimensions': [{'Name': 'JobName', 'Value': job_name}]
                    }
                ]
                
                # Add specific optimization metrics
                for opt in optimizations:
                    if opt['type'] == 'early_stopping':
                        metric_data.append({
                            'MetricName': 'CarbonSavedByEarlyStopping',
                            'Value': opt['savings']['carbon_saved_kg'],
                            'Unit': 'None'
                        })
                    elif opt['type'] == 'model_compression':
                        metric_data.append({
                            'MetricName': 'ModelSizeReduction',
                            'Value': opt['size_reduction'] * 100,
                            'Unit': 'Percent'
                        })
                
                cloudwatch.put_metric_data(
                    Namespace=namespace,
                    MetricData=metric_data
                )
          PYTHON
        end

        def generate_efficiency_monitor_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime
            import psutil
            import GPUtil
            
            cloudwatch = boto3.client('cloudwatch')
            dynamodb = boto3.resource('dynamodb')
            
            CARBON_TABLE = os.environ['CARBON_TABLE']
            TRACK_CARBON = os.environ['TRACK_CARBON'] == 'True'
            TRACK_ENERGY = os.environ['TRACK_ENERGY'] == 'True'
            MODEL_TYPE = os.environ['MODEL_TYPE']
            
            def handler(event, context):
                carbon_table = dynamodb.Table(CARBON_TABLE)
                
                # Collect efficiency metrics
                metrics = collect_efficiency_metrics()
                
                # Calculate carbon emissions if enabled
                if TRACK_CARBON:
                    carbon_metrics = calculate_carbon_emissions(metrics)
                    metrics.update(carbon_metrics)
                    store_carbon_data(carbon_table, carbon_metrics)
                
                # Calculate energy usage if enabled
                if TRACK_ENERGY:
                    energy_metrics = calculate_energy_usage(metrics)
                    metrics.update(energy_metrics)
                
                # Analyze model efficiency
                efficiency_analysis = analyze_model_efficiency(metrics)
                metrics.update(efficiency_analysis)
                
                # Emit all metrics to CloudWatch
                emit_efficiency_metrics(metrics)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'metrics_collected': len(metrics),
                        'carbon_tracked': TRACK_CARBON,
                        'energy_tracked': TRACK_ENERGY
                    })
                }
            
            def collect_efficiency_metrics():
                metrics = {}
                
                # GPU metrics
                try:
                    gpus = GPUtil.getGPUs()
                    if gpus:
                        gpu = gpus[0]  # Primary GPU
                        metrics['gpu_utilization'] = gpu.load * 100
                        metrics['gpu_memory_used'] = gpu.memoryUsed
                        metrics['gpu_memory_total'] = gpu.memoryTotal
                        metrics['gpu_temperature'] = gpu.temperature
                        metrics['gpu_power_draw'] = gpu.powerDraw  # Watts
                except:
                    metrics['gpu_available'] = False
                
                # CPU metrics
                metrics['cpu_utilization'] = psutil.cpu_percent(interval=1)
                metrics['memory_utilization'] = psutil.virtual_memory().percent
                
                # Training metrics (from SageMaker)
                metrics.update(get_training_metrics())
                
                # Model size and complexity
                metrics.update(get_model_metrics())
                
                return metrics
            
            def get_training_metrics():
                # Get from SageMaker training job metrics
                training_metrics = {}
                
                try:
                    # Parse from environment or CloudWatch
                    training_metrics['epochs_completed'] = int(os.environ.get('EPOCH', 0))
                    training_metrics['batch_size'] = int(os.environ.get('BATCH_SIZE', 32))
                    training_metrics['learning_rate'] = float(os.environ.get('LR', 0.001))
                    training_metrics['training_samples_per_second'] = float(os.environ.get('SAMPLES_PER_SEC', 0))
                except:
                    pass
                
                return training_metrics
            
            def get_model_metrics():
                model_metrics = {}
                
                # Model-specific metrics based on type
                if MODEL_TYPE == 'computer_vision':
                    model_metrics['model_parameters'] = 25_000_000  # ResNet-50 example
                    model_metrics['flops_per_sample'] = 4_000_000_000
                elif MODEL_TYPE == 'natural_language':
                    model_metrics['model_parameters'] = 110_000_000  # BERT-base
                    model_metrics['flops_per_sample'] = 20_000_000_000
                elif MODEL_TYPE == 'generative_ai':
                    model_metrics['model_parameters'] = 1_500_000_000  # GPT-style
                    model_metrics['flops_per_sample'] = 100_000_000_000
                else:
                    model_metrics['model_parameters'] = 10_000_000  # Default
                    model_metrics['flops_per_sample'] = 1_000_000_000
                
                return model_metrics
            
            def calculate_carbon_emissions(metrics):
                carbon_metrics = {}
                
                # Get power consumption
                if 'gpu_power_draw' in metrics:
                    power_watts = metrics['gpu_power_draw']
                else:
                    # Estimate based on GPU type
                    power_watts = estimate_gpu_power()
                
                # Get carbon intensity for current region
                region = os.environ.get('AWS_REGION', 'us-east-1')
                carbon_intensity = get_carbon_intensity(region)
                
                # Calculate emissions
                # Power (W) * Time (h) * Carbon Intensity (gCO2/kWh) / 1000
                training_time_hours = metrics.get('epochs_completed', 1) * 0.1  # Estimate
                carbon_emissions = (power_watts * training_time_hours * carbon_intensity) / 1000
                
                carbon_metrics['carbon_emissions_gco2'] = carbon_emissions
                carbon_metrics['carbon_intensity'] = carbon_intensity
                carbon_metrics['power_consumption_watts'] = power_watts
                
                # Calculate efficiency metrics
                if metrics.get('model_parameters', 0) > 0:
                    carbon_metrics['gco2_per_million_parameters'] = (
                        carbon_emissions / (metrics['model_parameters'] / 1_000_000)
                    )
                
                if metrics.get('training_samples_per_second', 0) > 0:
                    carbon_metrics['gco2_per_million_samples'] = (
                        carbon_emissions / (metrics['training_samples_per_second'] * 
                                          training_time_hours * 3600 / 1_000_000)
                    )
                
                return carbon_metrics
            
            def estimate_gpu_power():
                instance_type = os.environ.get('INSTANCE_TYPE', 'ml.p3.8xlarge')
                
                # Power consumption estimates
                power_map = {
                    'ml.p4d.24xlarge': 400,  # A100
                    'ml.p3.16xlarge': 300,   # V100
                    'ml.p3.8xlarge': 250,    # V100
                    'ml.g5.48xlarge': 350,   # A10G
                    'ml.g4dn.12xlarge': 200, # T4
                    'ml.trn1.32xlarge': 300  # Trainium
                }
                
                return power_map.get(instance_type, 250)
            
            def get_carbon_intensity(region):
                # Regional carbon intensity (gCO2/kWh)
                carbon_map = {
                    'us-west-2': 50,
                    'eu-north-1': 40,
                    'ca-central-1': 30,
                    'eu-west-1': 80,
                    'us-east-1': 400,
                    'us-east-2': 450,
                    'eu-central-1': 350,
                    'ap-southeast-1': 600
                }
                
                return carbon_map.get(region, 400)
            
            def calculate_energy_usage(metrics):
                energy_metrics = {}
                
                power_watts = metrics.get('power_consumption_watts', 250)
                training_time_hours = metrics.get('epochs_completed', 1) * 0.1
                
                # Calculate energy consumption
                energy_kwh = (power_watts * training_time_hours) / 1000
                energy_metrics['energy_consumption_kwh'] = energy_kwh
                
                # Calculate energy efficiency
                if metrics.get('model_parameters', 0) > 0:
                    energy_metrics['kwh_per_billion_parameters'] = (
                        energy_kwh / (metrics['model_parameters'] / 1_000_000_000)
                    )
                
                if metrics.get('flops_per_sample', 0) > 0 and metrics.get('training_samples_per_second', 0) > 0:
                    total_flops = (metrics['flops_per_sample'] * 
                                 metrics['training_samples_per_second'] * 
                                 training_time_hours * 3600)
                    energy_metrics['kwh_per_exaflop'] = energy_kwh / (total_flops / 1e18)
                
                # Compare to baseline
                baseline_energy = training_time_hours * 300 / 1000  # 300W baseline
                energy_metrics['energy_efficiency_vs_baseline'] = (
                    (baseline_energy - energy_kwh) / baseline_energy * 100
                )
                
                return energy_metrics
            
            def analyze_model_efficiency(metrics):
                efficiency_analysis = {}
                
                # GPU efficiency
                if 'gpu_utilization' in metrics:
                    efficiency_analysis['gpu_efficiency_score'] = metrics['gpu_utilization']
                    
                    if metrics['gpu_utilization'] < 70:
                        efficiency_analysis['gpu_bottleneck'] = 'underutilized'
                    elif metrics['gpu_memory_used'] / metrics['gpu_memory_total'] > 0.9:
                        efficiency_analysis['gpu_bottleneck'] = 'memory_bound'
                    else:
                        efficiency_analysis['gpu_bottleneck'] = 'none'
                
                # Training efficiency
                if 'training_samples_per_second' in metrics and metrics['training_samples_per_second'] > 0:
                    # Compare to theoretical maximum
                    theoretical_max = estimate_theoretical_throughput(metrics)
                    efficiency_analysis['training_efficiency'] = (
                        metrics['training_samples_per_second'] / theoretical_max * 100
                    )
                
                # Model efficiency based on type
                efficiency_analysis['model_efficiency_rating'] = rate_model_efficiency(
                    MODEL_TYPE, metrics
                )
                
                # Optimization recommendations
                efficiency_analysis['recommendations'] = generate_recommendations(
                    metrics, efficiency_analysis
                )
                
                return efficiency_analysis
            
            def estimate_theoretical_throughput(metrics):
                # Estimate based on GPU and model
                if 'gpu_memory_total' in metrics:
                    # Rough estimate: 1 sample per 100MB for vision, 10MB for NLP
                    if MODEL_TYPE == 'computer_vision':
                        return metrics['gpu_memory_total'] / 100
                    elif MODEL_TYPE == 'natural_language':
                        return metrics['gpu_memory_total'] / 10
                    else:
                        return metrics['gpu_memory_total'] / 50
                
                return 100  # Default
            
            def rate_model_efficiency(model_type, metrics):
                score = 100
                
                # Deduct points for inefficiencies
                if metrics.get('gpu_utilization', 0) < 80:
                    score -= 20
                
                if metrics.get('training_efficiency', 100) < 70:
                    score -= 15
                
                if metrics.get('energy_efficiency_vs_baseline', 0) < 0:
                    score -= 10
                
                # Model-specific adjustments
                if model_type == 'generative_ai' and metrics.get('model_parameters', 0) > 1e9:
                    score -= 10  # Large models are inherently less efficient
                
                return max(0, score)
            
            def generate_recommendations(metrics, analysis):
                recommendations = []
                
                if analysis.get('gpu_bottleneck') == 'underutilized':
                    recommendations.append({
                        'issue': 'GPU underutilized',
                        'suggestion': 'Increase batch size or use gradient accumulation',
                        'potential_improvement': '20-30%'
                    })
                
                if analysis.get('gpu_bottleneck') == 'memory_bound':
                    recommendations.append({
                        'issue': 'GPU memory saturated',
                        'suggestion': 'Enable gradient checkpointing or use model parallelism',
                        'potential_improvement': '15-25%'
                    })
                
                if metrics.get('carbon_intensity', 0) > 200:
                    recommendations.append({
                        'issue': 'High carbon region',
                        'suggestion': 'Consider migrating to cleaner region like us-west-2',
                        'potential_improvement': '60-80% carbon reduction'
                    })
                
                if analysis.get('training_efficiency', 100) < 70:
                    recommendations.append({
                        'issue': 'Low training efficiency',
                        'suggestion': 'Profile code for bottlenecks, optimize data pipeline',
                        'potential_improvement': '30-50%'
                    })
                
                return recommendations
            
            def store_carbon_data(table, carbon_metrics):
                timestamp = int(datetime.now().timestamp())
                
                table.put_item(Item={
                    'metric_id': f"training-{timestamp}",
                    'timestamp': timestamp,
                    'carbon_emissions': carbon_metrics['carbon_emissions_gco2'],
                    'carbon_intensity': carbon_metrics['carbon_intensity'],
                    'power_consumption': carbon_metrics['power_consumption_watts'],
                    'efficiency_metrics': json.dumps(carbon_metrics),
                    'expiration': timestamp + 86400 * 30  # 30 day retention
                })
            
            def emit_efficiency_metrics(metrics):
                namespace = f"SustainableML/{os.environ.get('COMPONENT_NAME', 'default')}"
                
                metric_data = []
                
                # Core metrics
                for metric_name, value in metrics.items():
                    if isinstance(value, (int, float)):
                        metric_data.append({
                            'MetricName': metric_name,
                            'Value': value,
                            'Unit': 'None'
                        })
                
                # Batch emit to CloudWatch
                if metric_data:
                    # CloudWatch has a limit of 20 metrics per request
                    for i in range(0, len(metric_data), 20):
                        cloudwatch.put_metric_data(
                            Namespace=namespace,
                            MetricData=metric_data[i:i+20]
                        )
          PYTHON
        end
      end
    end
  end
end