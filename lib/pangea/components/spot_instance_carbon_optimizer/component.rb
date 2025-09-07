# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require_relative "types"

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      class Component
        include Pangea::DSL

        def self.build(input)
          new.build(input)
        end

        def build(input)
          input = Types::Input.new(input) unless input.is_a?(Types::Input)
          
          # Validate input parameters
          Types.validate_capacity(input.target_capacity)
          Types.validate_carbon_threshold(input.carbon_intensity_threshold)
          Types.validate_regions(input.allowed_regions, input.preferred_regions)
          Types.validate_spot_block_duration(input.use_spot_blocks, input.spot_block_duration_hours)

          # Create IAM roles
          fleet_role = create_fleet_role(input)
          lambda_role = create_lambda_role(input)

          # Create DynamoDB tables
          fleet_state_table = create_fleet_state_table(input)
          carbon_data_table = create_carbon_data_table(input)
          migration_history_table = create_migration_history_table(input)

          # Create Spot fleet requests in each region
          spot_fleets = create_regional_spot_fleets(input, fleet_role, fleet_state_table)

          # Create Lambda functions
          carbon_monitor = create_carbon_monitor_function(input, lambda_role, carbon_data_table)
          fleet_optimizer = create_fleet_optimizer_function(input, lambda_role, fleet_state_table, carbon_data_table)
          migration_orchestrator = create_migration_orchestrator_function(input, lambda_role, fleet_state_table, migration_history_table)

          # Create EventBridge schedules
          optimization_schedule = create_optimization_schedule(input, fleet_optimizer)
          carbon_check_schedule = create_carbon_check_schedule(input, carbon_monitor)
          spot_interruption_rule = create_spot_interruption_rule(input, migration_orchestrator)

          # Create CloudWatch monitoring
          efficiency_metrics = create_efficiency_metrics(input)
          carbon_dashboard = create_carbon_dashboard(input, spot_fleets, efficiency_metrics)
          carbon_alarms = create_carbon_alarms(input, efficiency_metrics)

          Types::Output.new(
            spot_fleets: spot_fleets,
            carbon_monitor_function: carbon_monitor,
            fleet_optimizer_function: fleet_optimizer,
            migration_orchestrator_function: migration_orchestrator,
            fleet_state_table: fleet_state_table,
            carbon_data_table: carbon_data_table,
            migration_history_table: migration_history_table,
            optimization_schedule: optimization_schedule,
            carbon_check_schedule: carbon_check_schedule,
            spot_interruption_rule: spot_interruption_rule,
            carbon_dashboard: carbon_dashboard,
            efficiency_metrics: efficiency_metrics,
            carbon_alarms: carbon_alarms,
            fleet_role: fleet_role,
            lambda_role: lambda_role
          )
        end

        private

        def create_fleet_role(input)
          aws_iam_role(:"#{input.name}-fleet-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "spotfleet.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            managed_policy_arns: [
              "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
            ],
            inline_policy: [{
              name: "spot-fleet-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "ec2:*",
                      "iam:PassRole",
                      "sns:Publish"
                    ],
                    Resource: "*"
                  }
                ]
              })
            }],
            tags: input.tags.merge("Component" => "spot-carbon-optimizer")
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
              name: "carbon-optimizer-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "ec2:*SpotFleet*",
                      "ec2:*SpotInstance*",
                      "ec2:Describe*",
                      "ec2:CreateTags",
                      "ec2:ModifyInstanceAttribute"
                    ],
                    Resource: "*"
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "dynamodb:*"
                    ],
                    Resource: "*"
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "cloudwatch:PutMetricData",
                      "cloudwatch:GetMetricStatistics"
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
            tags: input.tags.merge("Component" => "spot-carbon-optimizer")
          })
        end

        def create_fleet_state_table(input)
          aws_dynamodb_table(:"#{input.name}-fleet-state", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "fleet_id",
            range_key: "region",
            attribute: [
              { name: "fleet_id", type: "S" },
              { name: "region", type: "S" },
              { name: "carbon_intensity", type: "N" },
              { name: "last_migration", type: "N" }
            ],
            global_secondary_index: [
              {
                name: "carbon-intensity-index",
                hash_key: "region",
                range_key: "carbon_intensity",
                projection_type: "ALL"
              }
            ],
            stream_specification: {
              stream_enabled: true,
              stream_view_type: "NEW_AND_OLD_IMAGES"
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Purpose" => "fleet-state"
            )
          })
        end

        def create_carbon_data_table(input)
          aws_dynamodb_table(:"#{input.name}-carbon-data", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "region",
            range_key: "timestamp",
            attribute: [
              { name: "region", type: "S" },
              { name: "timestamp", type: "N" }
            ],
            ttl: {
              enabled: true,
              attribute_name: "expiration"
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Purpose" => "carbon-data"
            )
          })
        end

        def create_migration_history_table(input)
          aws_dynamodb_table(:"#{input.name}-migration-history", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "migration_id",
            range_key: "timestamp",
            attribute: [
              { name: "migration_id", type: "S" },
              { name: "timestamp", type: "N" },
              { name: "source_region", type: "S" },
              { name: "target_region", type: "S" }
            ],
            global_secondary_index: [
              {
                name: "region-time-index",
                hash_key: "source_region",
                range_key: "timestamp",
                projection_type: "ALL"
              }
            ],
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Purpose" => "migration-history"
            )
          })
        end

        def create_regional_spot_fleets(input, fleet_role, state_table)
          spot_fleets = {}
          
          # Only create fleets in regions with VPC configuration
          configured_regions = input.vpc_configs.keys & input.allowed_regions
          
          configured_regions.each do |region|
            vpc_config = input.vpc_configs[region]
            
            spot_fleets[region] = aws_spot_fleet_request(:"#{input.name}-fleet-#{region}", {
              iam_fleet_role: fleet_role.arn,
              target_capacity: calculate_regional_capacity(input, region),
              valid_until: (Time.now + 365 * 24 * 60 * 60).iso8601, # 1 year
              terminate_instances_with_expiration: true,
              instance_interruption_behavior: input.interruption_behavior,
              fleet_type: "maintain",
              replace_unhealthy_instances: true,
              
              launch_specification: create_launch_specifications(input, region, vpc_config),
              
              spot_price: calculate_spot_price(input, region),
              allocation_strategy: "lowestPrice",
              instance_pools_to_use_count: 2,
              
              tag_specification: [{
                resource_type: "spot-fleet-request",
                tags: input.tags.merge(
                  "Component" => "spot-carbon-optimizer",
                  "Region" => region,
                  "CarbonOptimized" => "true"
                )
              }]
            })
          end
          
          spot_fleets
        end

        def calculate_regional_capacity(input, region)
          # Distribute capacity based on carbon intensity
          if input.optimization_strategy == 'renewable_only'
            input.preferred_regions.include?(region) ? input.target_capacity : 0
          else
            # Weight by inverse carbon intensity
            carbon_intensity = Types::REGIONAL_CARBON_BASELINE[region] || 400
            weight = 1000.0 / carbon_intensity
            (input.target_capacity * weight / 10).to_i.clamp(1, input.target_capacity)
          end
        end

        def create_launch_specifications(input, region, vpc_config)
          input.instance_types.map do |instance_type|
            {
              instance_type: instance_type,
              image_id: get_latest_ami(region, instance_type),
              subnet_id: vpc_config[:subnet_ids].split(',').first,
              security_groups: [{ group_id: create_security_group(input, region, vpc_config[:vpc_id]) }],
              
              user_data: Base64.encode64(generate_user_data(input, region)),
              
              block_device_mappings: [{
                device_name: "/dev/xvda",
                ebs: {
                  volume_size: 30,
                  volume_type: "gp3",
                  delete_on_termination: true
                }
              }],
              
              instance_market_options: {
                market_type: "spot",
                spot_options: {
                  spot_instance_type: input.use_spot_blocks ? "persistent" : "one-time",
                  block_duration_minutes: input.spot_block_duration_hours ? input.spot_block_duration_hours * 60 : nil
                }
              },
              
              tag_specifications: [{
                resource_type: "instance",
                tags: input.tags.merge(
                  "Component" => "spot-carbon-optimizer",
                  "Region" => region,
                  "WorkloadType" => input.workload_type
                )
              }]
            }
          end
        end

        def get_latest_ami(region, instance_type)
          # Return appropriate AMI based on instance architecture
          if instance_type.include?('g.') # Graviton
            "ami-0123456789abcdef0" # Amazon Linux 2 ARM
          else
            "ami-0987654321fedcba9" # Amazon Linux 2 x86
          end
        end

        def create_security_group(input, region, vpc_id)
          # In practice, this would create or reference an existing security group
          "sg-#{region}-#{vpc_id}-carbon"
        end

        def calculate_spot_price(input, region)
          # Calculate max spot price with buffer
          # In practice, this would query current spot prices
          base_price = 0.10 # Example base price
          buffer = 1 + (input.spot_price_buffer_percentage / 100.0)
          (base_price * buffer).round(4).to_s
        end

        def create_carbon_monitor_function(input, role, carbon_table)
          aws_lambda_function(:"#{input.name}-carbon-monitor", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: 512,
            environment: {
              variables: {
                "CARBON_TABLE": carbon_table.table_name,
                "ALLOWED_REGIONS": input.allowed_regions.join(","),
                "RENEWABLE_MINIMUM": input.renewable_percentage_minimum.to_s,
                "REPORTING_INTERVAL": input.carbon_reporting_interval_minutes.to_s
              }
            },
            code: {
              zip_file: generate_carbon_monitor_code(input)
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Function" => "carbon-monitor"
            )
          })
        end

        def create_fleet_optimizer_function(input, role, state_table, carbon_table)
          aws_lambda_function(:"#{input.name}-fleet-optimizer", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 1024,
            environment: {
              variables: {
                "FLEET_STATE_TABLE": state_table.table_name,
                "CARBON_TABLE": carbon_table.table_name,
                "OPTIMIZATION_STRATEGY": input.optimization_strategy,
                "CARBON_THRESHOLD": input.carbon_intensity_threshold.to_s,
                "TARGET_CAPACITY": input.target_capacity.to_s,
                "ALLOWED_REGIONS": input.allowed_regions.join(","),
                "PREFERRED_REGIONS": input.preferred_regions.join(",")
              }
            },
            code: {
              zip_file: generate_fleet_optimizer_code(input)
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Function" => "fleet-optimizer"
            )
          })
        end

        def create_migration_orchestrator_function(input, role, state_table, history_table)
          aws_lambda_function(:"#{input.name}-migration-orchestrator", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 512,
            environment: {
              variables: {
                "FLEET_STATE_TABLE": state_table.table_name,
                "MIGRATION_HISTORY_TABLE": history_table.table_name,
                "MIGRATION_STRATEGY": input.migration_strategy,
                "MIGRATION_THRESHOLD": input.migration_threshold_minutes.to_s,
                "WORKLOAD_TYPE": input.workload_type,
                "ENABLE_CROSS_REGION": input.enable_cross_region_migration.to_s
              }
            },
            code: {
              zip_file: generate_migration_orchestrator_code(input)
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Function" => "migration-orchestrator"
            )
          })
        end

        def create_optimization_schedule(input, optimizer_function)
          aws_eventbridge_scheduler_schedule(:"#{input.name}-optimization-schedule", {
            flexible_time_window: {
              mode: "FLEXIBLE",
              maximum_window_in_minutes: 5
            },
            schedule_expression: "rate(#{input.carbon_reporting_interval_minutes} minutes)",
            target: {
              arn: optimizer_function.arn,
              role_arn: ref(:aws_iam_role, :"#{input.name}-scheduler-role", :arn)
            },
            tags: input.tags.merge("Component" => "spot-carbon-optimizer")
          })
        end

        def create_carbon_check_schedule(input, monitor_function)
          aws_eventbridge_scheduler_schedule(:"#{input.name}-carbon-check-schedule", {
            flexible_time_window: {
              mode: "OFF"
            },
            schedule_expression: "rate(5 minutes)",
            target: {
              arn: monitor_function.arn,
              role_arn: ref(:aws_iam_role, :"#{input.name}-scheduler-role", :arn)
            },
            tags: input.tags.merge("Component" => "spot-carbon-optimizer")
          })
        end

        def create_spot_interruption_rule(input, migration_function)
          aws_cloudwatch_event_rule(:"#{input.name}-spot-interruption-rule", {
            name: "#{input.name}-spot-interruption",
            description: "Trigger migration on spot interruption",
            event_pattern: JSON.pretty_generate({
              source: ["aws.ec2"],
              "detail-type": ["EC2 Spot Instance Interruption Warning"]
            }),
            targets: [{
              arn: migration_function.arn,
              id: "1"
            }],
            tags: input.tags
          })
        end

        def create_efficiency_metrics(input)
          [
            aws_cloudwatch_metric_alarm(:"#{input.name}-carbon-intensity-metric", {
              alarm_name: "#{input.name}-average-carbon-intensity",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 2,
              metric_name: "AverageCarbonIntensity",
              namespace: "SpotCarbonOptimizer/#{input.name}",
              period: 300,
              statistic: "Average",
              threshold: input.carbon_intensity_threshold.to_f,
              treat_missing_data: "notBreaching"
            }),
            aws_cloudwatch_metric_alarm(:"#{input.name}-renewable-percentage-metric", {
              alarm_name: "#{input.name}-renewable-percentage",
              comparison_operator: "LessThanThreshold",
              evaluation_periods: 2,
              metric_name: "RenewablePercentage",
              namespace: "SpotCarbonOptimizer/#{input.name}",
              period: 300,
              statistic: "Average",
              threshold: input.renewable_percentage_minimum.to_f,
              treat_missing_data: "notBreaching"
            }),
            aws_cloudwatch_metric_alarm(:"#{input.name}-migration-frequency-metric", {
              alarm_name: "#{input.name}-migration-frequency",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 1,
              metric_name: "MigrationCount",
              namespace: "SpotCarbonOptimizer/#{input.name}",
              period: 3600,
              statistic: "Sum",
              threshold: 10.0,
              treat_missing_data: "notBreaching"
            })
          ]
        end

        def create_carbon_dashboard(input, spot_fleets, metrics)
          aws_cloudwatch_dashboard(:"#{input.name}-carbon-dashboard", {
            dashboard_name: "#{input.name}-spot-carbon-dashboard",
            dashboard_body: JSON.pretty_generate({
              widgets: [
                {
                  type: "metric",
                  properties: {
                    metrics: input.allowed_regions.map { |region|
                      ["SpotCarbonOptimizer/#{input.name}", "RegionalCarbonIntensity", 
                       { "Region": region }]
                    },
                    period: 300,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Regional Carbon Intensity",
                    yAxis: {
                      left: { min: 0, label: "gCO2/kWh" }
                    }
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["SpotCarbonOptimizer/#{input.name}", "TotalFleetCapacity", { stat: "Average" }],
                      [".", "ActiveInstances", { stat: "Sum" }],
                      [".", "SpotSavings", { stat: "Sum", yAxis: "right" }]
                    ],
                    period: 300,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Fleet Capacity and Savings",
                    yAxis: {
                      left: { label: "Instances" },
                      right: { label: "Savings ($)" }
                    }
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["SpotCarbonOptimizer/#{input.name}", "CarbonEmissionsAvoided", { stat: "Sum" }],
                      [".", "RenewableEnergyUsage", { stat: "Average", yAxis: "right" }]
                    ],
                    period: 3600,
                    stat: "Sum",
                    region: "us-east-1",
                    title: "Carbon Impact",
                    yAxis: {
                      left: { label: "gCO2 Avoided" },
                      right: { label: "Renewable %" }
                    }
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["SpotCarbonOptimizer/#{input.name}", "MigrationCount", { stat: "Sum" }],
                      [".", "MigrationDuration", { stat: "Average" }],
                      [".", "MigrationSuccess", { stat: "Average", yAxis: "right" }]
                    ],
                    period: 3600,
                    stat: "Sum",
                    region: "us-east-1",
                    title: "Migration Activity"
                  }
                }
              ]
            })
          })
        end

        def create_carbon_alarms(input, metrics)
          alarms = metrics.dup
          
          if input.alert_on_high_carbon
            alarms << aws_cloudwatch_alarm(:"#{input.name}-high-carbon-alarm", {
              alarm_name: "#{input.name}-high-carbon-usage",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 3,
              metric_name: "HighCarbonInstancePercentage",
              namespace: "SpotCarbonOptimizer/#{input.name}",
              period: 900,
              statistic: "Average",
              threshold: 25.0,
              alarm_description: "Alert when >25% instances in high-carbon regions",
              treat_missing_data: "notBreaching",
              tags: input.tags
            })
          end
          
          alarms
        end

        def generate_user_data(input, region)
          <<~BASH
            #!/bin/bash
            # Install CloudWatch agent
            wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
            sudo rpm -U ./amazon-cloudwatch-agent.rpm
            
            # Configure for carbon monitoring
            cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
            {
              "metrics": {
                "namespace": "SpotCarbonOptimizer/#{input.name}",
                "metrics_collected": {
                  "cpu": {
                    "measurement": [
                      "cpu_usage_idle",
                      "cpu_usage_iowait"
                    ],
                    "metrics_collection_interval": 60
                  },
                  "disk": {
                    "measurement": [
                      "used_percent"
                    ],
                    "metrics_collection_interval": 60,
                    "resources": [
                      "*"
                    ]
                  },
                  "mem": {
                    "measurement": [
                      "mem_used_percent"
                    ],
                    "metrics_collection_interval": 60
                  }
                }
              }
            }
            EOF
            
            # Start CloudWatch agent
            sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
              -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
            
            # Tag instance with carbon data
            INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
            REGION=#{region}
            aws ec2 create-tags --region $REGION --resources $INSTANCE_ID \
              --tags Key=CarbonRegion,Value=$REGION Key=WorkloadType,Value=#{input.workload_type}
          BASH
        end

        def generate_carbon_monitor_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            import time
            from datetime import datetime
            import requests
            
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')
            ec2 = boto3.client('ec2')
            
            CARBON_TABLE = os.environ['CARBON_TABLE']
            ALLOWED_REGIONS = os.environ['ALLOWED_REGIONS'].split(',')
            RENEWABLE_MINIMUM = int(os.environ['RENEWABLE_MINIMUM'])
            
            # Regional carbon data (gCO2/kWh)
            CARBON_BASELINE = {
                'us-east-1': 400,
                'us-east-2': 450,
                'us-west-1': 250,
                'us-west-2': 50,
                'eu-central-1': 350,
                'eu-west-1': 80,
                'eu-north-1': 40,
                'ca-central-1': 30,
                'ap-southeast-1': 600,
                'ap-southeast-2': 700,
                'sa-east-1': 100
            }
            
            def handler(event, context):
                carbon_table = dynamodb.Table(CARBON_TABLE)
                
                # Collect carbon data for all regions
                carbon_data = collect_regional_carbon_data()
                
                # Store in DynamoDB
                store_carbon_data(carbon_table, carbon_data)
                
                # Calculate fleet carbon metrics
                fleet_metrics = calculate_fleet_carbon_metrics(carbon_data)
                
                # Emit CloudWatch metrics
                emit_carbon_metrics(fleet_metrics)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'regions_monitored': len(carbon_data),
                        'average_carbon_intensity': fleet_metrics['average_intensity'],
                        'renewable_percentage': fleet_metrics['renewable_percentage']
                    })
                }
            
            def collect_regional_carbon_data():
                carbon_data = {}
                current_time = int(time.time())
                
                for region in ALLOWED_REGIONS:
                    # Get real-time carbon intensity
                    intensity = get_carbon_intensity(region)
                    renewable_pct = get_renewable_percentage(region, intensity)
                    
                    carbon_data[region] = {
                        'carbon_intensity': intensity,
                        'renewable_percentage': renewable_pct,
                        'timestamp': current_time,
                        'spot_price': get_spot_price(region),
                        'instance_count': count_instances(region)
                    }
                
                return carbon_data
            
            def get_carbon_intensity(region):
                # Simulate time-of-day variations
                hour = datetime.now().hour
                base = CARBON_BASELINE.get(region, 400)
                
                # Peak hours (higher intensity)
                if 9 <= hour <= 17:
                    multiplier = 1.3
                # Night hours (lower intensity)  
                elif 0 <= hour <= 6:
                    multiplier = 0.7
                else:
                    multiplier = 1.0
                
                # Add seasonal variation
                month = datetime.now().month
                if month in [12, 1, 2]:  # Winter
                    seasonal = 1.2
                elif month in [6, 7, 8]:  # Summer
                    seasonal = 1.1
                else:
                    seasonal = 1.0
                
                return int(base * multiplier * seasonal)
            
            def get_renewable_percentage(region, intensity):
                # Estimate renewable percentage from carbon intensity
                if intensity < 100:
                    return 85 + (100 - intensity) / 10
                elif intensity < 200:
                    return 60 + (200 - intensity) / 5
                elif intensity < 400:
                    return 30 + (400 - intensity) / 10
                else:
                    return max(5, 30 - (intensity - 400) / 20)
            
            def get_spot_price(region):
                try:
                    ec2_regional = boto3.client('ec2', region_name=region)
                    response = ec2_regional.describe_spot_price_history(
                        InstanceTypes=['t3.large'],
                        MaxResults=1,
                        ProductDescriptions=['Linux/UNIX']
                    )
                    
                    if response['SpotPriceHistory']:
                        return float(response['SpotPriceHistory'][0]['SpotPrice'])
                except:
                    pass
                
                return 0.05  # Default price
            
            def count_instances(region):
                try:
                    ec2_regional = boto3.client('ec2', region_name=region)
                    response = ec2_regional.describe_instances(
                        Filters=[
                            {'Name': 'instance-state-name', 'Values': ['running']},
                            {'Name': 'tag:Component', 'Values': ['spot-carbon-optimizer']}
                        ]
                    )
                    
                    count = sum(len(r['Instances']) for r in response['Reservations'])
                    return count
                except:
                    return 0
            
            def store_carbon_data(table, carbon_data):
                current_time = int(time.time())
                expiration = current_time + 86400  # 24 hour TTL
                
                for region, data in carbon_data.items():
                    table.put_item(Item={
                        'region': region,
                        'timestamp': current_time,
                        'carbon_intensity': data['carbon_intensity'],
                        'renewable_percentage': data['renewable_percentage'],
                        'spot_price': str(data['spot_price']),
                        'instance_count': data['instance_count'],
                        'expiration': expiration
                    })
            
            def calculate_fleet_carbon_metrics(carbon_data):
                total_instances = sum(d['instance_count'] for d in carbon_data.values())
                
                if total_instances == 0:
                    return {
                        'average_intensity': 0,
                        'renewable_percentage': 0,
                        'carbon_emissions': 0,
                        'low_carbon_instances': 0
                    }
                
                # Weighted average by instance count
                weighted_intensity = sum(
                    d['carbon_intensity'] * d['instance_count'] 
                    for d in carbon_data.values()
                ) / total_instances
                
                weighted_renewable = sum(
                    d['renewable_percentage'] * d['instance_count']
                    for d in carbon_data.values()
                ) / total_instances
                
                # Count instances in low-carbon regions
                low_carbon_instances = sum(
                    d['instance_count'] for d in carbon_data.values()
                    if d['carbon_intensity'] < 200
                )
                
                # Estimate hourly emissions (simplified)
                # Assume t3.large = 2 vCPU = ~50W
                power_watts = 50
                hours = 1
                carbon_emissions = (power_watts * hours * weighted_intensity) / 1000
                
                return {
                    'average_intensity': weighted_intensity,
                    'renewable_percentage': weighted_renewable,
                    'carbon_emissions': carbon_emissions,
                    'low_carbon_instances': low_carbon_instances,
                    'total_instances': total_instances
                }
            
            def emit_carbon_metrics(metrics):
                namespace = f"SpotCarbonOptimizer/{os.environ.get('COMPONENT_NAME', 'default')}"
                
                metric_data = [
                    {
                        'MetricName': 'AverageCarbonIntensity',
                        'Value': metrics['average_intensity'],
                        'Unit': 'None'
                    },
                    {
                        'MetricName': 'RenewablePercentage', 
                        'Value': metrics['renewable_percentage'],
                        'Unit': 'Percent'
                    },
                    {
                        'MetricName': 'CarbonEmissions',
                        'Value': metrics['carbon_emissions'],
                        'Unit': 'None'
                    },
                    {
                        'MetricName': 'LowCarbonInstances',
                        'Value': metrics['low_carbon_instances'],
                        'Unit': 'Count'
                    },
                    {
                        'MetricName': 'TotalFleetCapacity',
                        'Value': metrics['total_instances'],
                        'Unit': 'Count'
                    }
                ]
                
                # Regional metrics
                carbon_data = collect_regional_carbon_data()
                for region, data in carbon_data.items():
                    metric_data.extend([
                        {
                            'MetricName': 'RegionalCarbonIntensity',
                            'Value': data['carbon_intensity'],
                            'Unit': 'None',
                            'Dimensions': [{'Name': 'Region', 'Value': region}]
                        },
                        {
                            'MetricName': 'RegionalInstanceCount',
                            'Value': data['instance_count'],
                            'Unit': 'Count',
                            'Dimensions': [{'Name': 'Region', 'Value': region}]
                        }
                    ])
                
                cloudwatch.put_metric_data(
                    Namespace=namespace,
                    MetricData=metric_data
                )
          PYTHON
        end

        def generate_fleet_optimizer_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime, timedelta
            
            ec2 = boto3.client('ec2')
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')
            
            FLEET_STATE_TABLE = os.environ['FLEET_STATE_TABLE']
            CARBON_TABLE = os.environ['CARBON_TABLE']
            OPTIMIZATION_STRATEGY = os.environ['OPTIMIZATION_STRATEGY']
            CARBON_THRESHOLD = int(os.environ['CARBON_THRESHOLD'])
            TARGET_CAPACITY = int(os.environ['TARGET_CAPACITY'])
            ALLOWED_REGIONS = os.environ['ALLOWED_REGIONS'].split(',')
            PREFERRED_REGIONS = os.environ['PREFERRED_REGIONS'].split(',')
            
            def handler(event, context):
                fleet_table = dynamodb.Table(FLEET_STATE_TABLE)
                carbon_table = dynamodb.Table(CARBON_TABLE)
                
                # Get current fleet state
                fleet_state = get_fleet_state(fleet_table)
                
                # Get latest carbon data
                carbon_data = get_latest_carbon_data(carbon_table)
                
                # Calculate optimal distribution
                optimal_distribution = calculate_optimal_distribution(
                    fleet_state, carbon_data
                )
                
                # Apply optimizations
                applied_changes = apply_fleet_optimizations(
                    fleet_state, optimal_distribution
                )
                
                # Update fleet state
                update_fleet_state(fleet_table, applied_changes)
                
                # Emit optimization metrics
                emit_optimization_metrics(applied_changes)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'optimizations_applied': len(applied_changes),
                        'new_distribution': optimal_distribution
                    })
                }
            
            def get_fleet_state(table):
                fleet_state = {}
                
                for region in ALLOWED_REGIONS:
                    try:
                        # Get fleet info from EC2
                        ec2_regional = boto3.client('ec2', region_name=region)
                        response = ec2_regional.describe_spot_fleet_requests(
                            Filters=[
                                {'Name': 'tag:Component', 'Values': ['spot-carbon-optimizer']}
                            ]
                        )
                        
                        for fleet in response['SpotFleetRequestConfigs']:
                            if fleet['SpotFleetRequestState'] == 'active':
                                fleet_state[region] = {
                                    'fleet_id': fleet['SpotFleetRequestId'],
                                    'current_capacity': fleet['SpotFleetRequestConfig']['TargetCapacity'],
                                    'fulfilled_capacity': fleet.get('FulfilledCapacity', 0),
                                    'instances': get_fleet_instances(ec2_regional, fleet['SpotFleetRequestId'])
                                }
                    except Exception as e:
                        print(f"Error getting fleet state for {region}: {str(e)}")
                
                return fleet_state
            
            def get_fleet_instances(ec2_client, fleet_id):
                try:
                    response = ec2_client.describe_spot_fleet_instances(
                        SpotFleetRequestId=fleet_id
                    )
                    return response.get('ActiveInstances', [])
                except:
                    return []
            
            def get_latest_carbon_data(table):
                carbon_data = {}
                current_time = int(datetime.now().timestamp())
                lookback = current_time - 900  # 15 minutes
                
                for region in ALLOWED_REGIONS:
                    try:
                        response = table.query(
                            KeyConditionExpression='region = :region AND #ts > :ts',
                            ExpressionAttributeNames={'#ts': 'timestamp'},
                            ExpressionAttributeValues={
                                ':region': region,
                                ':ts': lookback
                            },
                            ScanIndexForward=False,
                            Limit=1
                        )
                        
                        if response['Items']:
                            item = response['Items'][0]
                            carbon_data[region] = {
                                'carbon_intensity': item['carbon_intensity'],
                                'renewable_percentage': item['renewable_percentage'],
                                'spot_price': float(item.get('spot_price', 0.05))
                            }
                    except Exception as e:
                        print(f"Error getting carbon data for {region}: {str(e)}")
                        # Use defaults
                        carbon_data[region] = {
                            'carbon_intensity': 400,
                            'renewable_percentage': 30,
                            'spot_price': 0.05
                        }
                
                return carbon_data
            
            def calculate_optimal_distribution(fleet_state, carbon_data):
                if OPTIMIZATION_STRATEGY == 'carbon_first':
                    return optimize_for_carbon(carbon_data)
                elif OPTIMIZATION_STRATEGY == 'cost_first':
                    return optimize_for_cost(carbon_data)
                elif OPTIMIZATION_STRATEGY == 'renewable_only':
                    return optimize_for_renewable(carbon_data)
                elif OPTIMIZATION_STRATEGY == 'follow_the_sun':
                    return optimize_follow_sun(carbon_data)
                else:  # balanced
                    return optimize_balanced(carbon_data)
            
            def optimize_for_carbon(carbon_data):
                # Sort regions by carbon intensity
                sorted_regions = sorted(
                    carbon_data.items(),
                    key=lambda x: x[1]['carbon_intensity']
                )
                
                distribution = {}
                remaining_capacity = TARGET_CAPACITY
                
                for region, data in sorted_regions:
                    if data['carbon_intensity'] <= CARBON_THRESHOLD:
                        # Allocate proportionally to inverse carbon intensity
                        weight = 1000 / data['carbon_intensity']
                        allocation = min(
                            int(TARGET_CAPACITY * weight / 100),
                            remaining_capacity
                        )
                        distribution[region] = allocation
                        remaining_capacity -= allocation
                
                # Distribute remaining to preferred regions
                if remaining_capacity > 0:
                    for region in PREFERRED_REGIONS:
                        if region in distribution:
                            distribution[region] += remaining_capacity
                            break
                
                return distribution
            
            def optimize_for_cost(carbon_data):
                # Sort by spot price
                sorted_regions = sorted(
                    carbon_data.items(),
                    key=lambda x: x[1]['spot_price']
                )
                
                distribution = {}
                remaining_capacity = TARGET_CAPACITY
                
                for region, data in sorted_regions:
                    # Only use regions under carbon threshold
                    if data['carbon_intensity'] <= CARBON_THRESHOLD * 2:
                        allocation = min(
                            int(TARGET_CAPACITY / len(ALLOWED_REGIONS)),
                            remaining_capacity
                        )
                        distribution[region] = allocation
                        remaining_capacity -= allocation
                
                return distribution
            
            def optimize_for_renewable(carbon_data):
                distribution = {}
                
                for region, data in carbon_data.items():
                    if data['renewable_percentage'] >= 70:
                        distribution[region] = int(TARGET_CAPACITY / 3)
                
                return distribution
            
            def optimize_follow_sun(carbon_data):
                # Follow renewable energy availability by timezone
                current_hour = datetime.now().hour
                
                # Map regions to timezones (simplified)
                timezone_offset = {
                    'us-west-2': -8,
                    'us-west-1': -8,
                    'us-east-1': -5,
                    'us-east-2': -5,
                    'eu-west-1': 0,
                    'eu-central-1': 1,
                    'eu-north-1': 1,
                    'ap-southeast-1': 8,
                    'ap-southeast-2': 10,
                    'sa-east-1': -3,
                    'ca-central-1': -5
                }
                
                distribution = {}
                
                for region, data in carbon_data.items():
                    offset = timezone_offset.get(region, 0)
                    local_hour = (current_hour + offset) % 24
                    
                    # Prefer regions during daylight hours (more solar)
                    if 8 <= local_hour <= 18:
                        weight = 2
                    else:
                        weight = 1
                    
                    if data['renewable_percentage'] > 40:
                        distribution[region] = int(TARGET_CAPACITY * weight / 10)
                
                return distribution
            
            def optimize_balanced(carbon_data):
                distribution = {}
                
                for region, data in carbon_data.items():
                    # Score based on carbon and cost
                    carbon_score = 1000 / data['carbon_intensity']
                    cost_score = 1 / data['spot_price']
                    renewable_score = data['renewable_percentage'] / 100
                    
                    # Weighted combination
                    total_score = (carbon_score * 0.5 + 
                                 cost_score * 0.3 + 
                                 renewable_score * 0.2)
                    
                    # Prefer regions with good combined score
                    if total_score > 5:
                        distribution[region] = int(TARGET_CAPACITY * total_score / 50)
                
                # Ensure we meet target capacity
                total_allocated = sum(distribution.values())
                if total_allocated < TARGET_CAPACITY:
                    # Add to preferred regions
                    for region in PREFERRED_REGIONS:
                        if region in distribution:
                            distribution[region] += TARGET_CAPACITY - total_allocated
                            break
                
                return distribution
            
            def apply_fleet_optimizations(fleet_state, optimal_distribution):
                changes = []
                
                for region, target_capacity in optimal_distribution.items():
                    current_capacity = fleet_state.get(region, {}).get('current_capacity', 0)
                    
                    if target_capacity != current_capacity:
                        try:
                            ec2_regional = boto3.client('ec2', region_name=region)
                            
                            if region in fleet_state and fleet_state[region]['fleet_id']:
                                # Modify existing fleet
                                fleet_id = fleet_state[region]['fleet_id']
                                
                                response = ec2_regional.modify_spot_fleet_request(
                                    SpotFleetRequestId=fleet_id,
                                    TargetCapacity=target_capacity
                                )
                                
                                changes.append({
                                    'region': region,
                                    'action': 'modified',
                                    'fleet_id': fleet_id,
                                    'old_capacity': current_capacity,
                                    'new_capacity': target_capacity
                                })
                            else:
                                # Would create new fleet (simplified for this example)
                                changes.append({
                                    'region': region,
                                    'action': 'would_create',
                                    'new_capacity': target_capacity
                                })
                        
                        except Exception as e:
                            print(f"Error optimizing fleet in {region}: {str(e)}")
                
                return changes
            
            def update_fleet_state(table, changes):
                for change in changes:
                    if change['action'] in ['modified', 'created']:
                        table.put_item(Item={
                            'fleet_id': change.get('fleet_id', f"pending-{change['region']}"),
                            'region': change['region'],
                            'capacity': change['new_capacity'],
                            'last_updated': int(datetime.now().timestamp()),
                            'optimization_strategy': OPTIMIZATION_STRATEGY
                        })
            
            def emit_optimization_metrics(changes):
                namespace = f"SpotCarbonOptimizer/{os.environ.get('COMPONENT_NAME', 'default')}"
                
                # Calculate capacity changes
                capacity_added = sum(
                    c['new_capacity'] - c.get('old_capacity', 0)
                    for c in changes if c['new_capacity'] > c.get('old_capacity', 0)
                )
                
                capacity_removed = sum(
                    c.get('old_capacity', 0) - c['new_capacity']
                    for c in changes if c.get('old_capacity', 0) > c['new_capacity']
                )
                
                cloudwatch.put_metric_data(
                    Namespace=namespace,
                    MetricData=[
                        {
                            'MetricName': 'OptimizationRuns',
                            'Value': 1,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'FleetModifications',
                            'Value': len(changes),
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'CapacityAdded',
                            'Value': capacity_added,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'CapacityRemoved',
                            'Value': capacity_removed,
                            'Unit': 'Count'
                        }
                    ]
                )
          PYTHON
        end

        def generate_migration_orchestrator_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            import time
            from datetime import datetime
            import uuid
            
            ec2 = boto3.client('ec2')
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')
            
            FLEET_STATE_TABLE = os.environ['FLEET_STATE_TABLE']
            MIGRATION_HISTORY_TABLE = os.environ['MIGRATION_HISTORY_TABLE']
            MIGRATION_STRATEGY = os.environ['MIGRATION_STRATEGY']
            MIGRATION_THRESHOLD = int(os.environ['MIGRATION_THRESHOLD'])
            WORKLOAD_TYPE = os.environ['WORKLOAD_TYPE']
            ENABLE_CROSS_REGION = os.environ['ENABLE_CROSS_REGION'] == 'True'
            
            def handler(event, context):
                # Handle spot interruption or optimization trigger
                if 'detail-type' in event and event['detail-type'] == 'EC2 Spot Instance Interruption Warning':
                    return handle_spot_interruption(event)
                else:
                    return handle_optimization_trigger(event)
            
            def handle_spot_interruption(event):
                instance_id = event['detail']['instance-id']
                region = event['region']
                
                print(f"Handling spot interruption for {instance_id} in {region}")
                
                # Get instance details
                instance_info = get_instance_info(instance_id, region)
                
                if not instance_info:
                    return {'statusCode': 404, 'body': 'Instance not found'}
                
                # Find target region with lowest carbon
                target_region = find_migration_target(region)
                
                if not target_region:
                    return {'statusCode': 400, 'body': 'No suitable migration target'}
                
                # Execute migration
                migration_id = execute_migration(
                    instance_info, region, target_region
                )
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'migration_id': migration_id,
                        'source': region,
                        'target': target_region
                    })
                }
            
            def handle_optimization_trigger(event):
                fleet_table = dynamodb.Table(FLEET_STATE_TABLE)
                history_table = dynamodb.Table(MIGRATION_HISTORY_TABLE)
                
                # Check for migration opportunities
                migration_candidates = find_migration_candidates(fleet_table)
                
                migrations_executed = []
                
                for candidate in migration_candidates:
                    if should_migrate(candidate):
                        migration_id = execute_fleet_migration(
                            candidate['source_region'],
                            candidate['target_region'],
                            candidate['instances']
                        )
                        
                        migrations_executed.append({
                            'migration_id': migration_id,
                            'source': candidate['source_region'],
                            'target': candidate['target_region'],
                            'instance_count': len(candidate['instances'])
                        })
                        
                        # Record in history
                        record_migration(history_table, migration_id, candidate)
                
                # Emit metrics
                emit_migration_metrics(migrations_executed)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'migrations_executed': len(migrations_executed),
                        'details': migrations_executed
                    })
                }
            
            def get_instance_info(instance_id, region):
                try:
                    ec2_regional = boto3.client('ec2', region_name=region)
                    response = ec2_regional.describe_instances(
                        InstanceIds=[instance_id]
                    )
                    
                    if response['Reservations']:
                        instance = response['Reservations'][0]['Instances'][0]
                        return {
                            'instance_id': instance_id,
                            'instance_type': instance['InstanceType'],
                            'launch_time': instance['LaunchTime'],
                            'tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                        }
                except Exception as e:
                    print(f"Error getting instance info: {str(e)}")
                
                return None
            
            def find_migration_target(source_region):
                # Get latest carbon data
                carbon_data = get_regional_carbon_data()
                
                # Sort by carbon intensity
                sorted_regions = sorted(
                    carbon_data.items(),
                    key=lambda x: x[1]['carbon_intensity']
                )
                
                # Find best target (not source)
                for region, data in sorted_regions:
                    if region != source_region and data['carbon_intensity'] < carbon_data[source_region]['carbon_intensity']:
                        return region
                
                return None
            
            def get_regional_carbon_data():
                # Simplified - in production would query carbon table
                return {
                    'us-east-1': {'carbon_intensity': 400},
                    'us-west-2': {'carbon_intensity': 50},
                    'eu-north-1': {'carbon_intensity': 40},
                    'ca-central-1': {'carbon_intensity': 30}
                }
            
            def find_migration_candidates(fleet_table):
                candidates = []
                
                # Query fleet state for high carbon regions
                response = fleet_table.scan()
                
                carbon_data = get_regional_carbon_data()
                
                for item in response.get('Items', []):
                    region = item['region']
                    carbon_intensity = carbon_data.get(region, {}).get('carbon_intensity', 400)
                    
                    if carbon_intensity > 200:  # High carbon threshold
                        # Find lower carbon alternative
                        target = find_migration_target(region)
                        
                        if target:
                            candidates.append({
                                'source_region': region,
                                'target_region': target,
                                'carbon_reduction': carbon_intensity - carbon_data[target]['carbon_intensity'],
                                'instances': get_region_instances(region),
                                'fleet_id': item.get('fleet_id')
                            })
                
                return candidates
            
            def get_region_instances(region):
                try:
                    ec2_regional = boto3.client('ec2', region_name=region)
                    response = ec2_regional.describe_instances(
                        Filters=[
                            {'Name': 'instance-state-name', 'Values': ['running']},
                            {'Name': 'tag:Component', 'Values': ['spot-carbon-optimizer']}
                        ]
                    )
                    
                    instances = []
                    for reservation in response['Reservations']:
                        instances.extend([i['InstanceId'] for i in reservation['Instances']])
                    
                    return instances
                except:
                    return []
            
            def should_migrate(candidate):
                # Check migration criteria
                if not ENABLE_CROSS_REGION:
                    return False
                
                # Significant carbon reduction
                if candidate['carbon_reduction'] < 100:
                    return False
                
                # Not too many instances
                if len(candidate['instances']) > 50:
                    return False
                
                # Workload type supports migration
                if WORKLOAD_TYPE not in ['stateless', 'batch', 'distributed']:
                    return False
                
                return True
            
            def execute_migration(instance_info, source_region, target_region):
                migration_id = str(uuid.uuid4())
                
                if MIGRATION_STRATEGY == 'checkpoint_restore':
                    execute_checkpoint_restore(instance_info, source_region, target_region, migration_id)
                elif MIGRATION_STRATEGY == 'blue_green':
                    execute_blue_green(instance_info, source_region, target_region, migration_id)
                elif MIGRATION_STRATEGY == 'drain_and_shift':
                    execute_drain_and_shift(instance_info, source_region, target_region, migration_id)
                else:  # live_migration
                    execute_live_migration(instance_info, source_region, target_region, migration_id)
                
                return migration_id
            
            def execute_checkpoint_restore(instance_info, source_region, target_region, migration_id):
                print(f"Executing checkpoint/restore migration {migration_id}")
                
                # 1. Create snapshot of instance
                ec2_source = boto3.client('ec2', region_name=source_region)
                
                # 2. Stop instance (checkpoint)
                ec2_source.stop_instances(InstanceIds=[instance_info['instance_id']])
                
                # 3. Create AMI from instance
                ami_response = ec2_source.create_image(
                    InstanceId=instance_info['instance_id'],
                    Name=f"migration-{migration_id}",
                    Description=f"Carbon migration from {source_region} to {target_region}"
                )
                
                # 4. Copy AMI to target region
                ec2_target = boto3.client('ec2', region_name=target_region)
                
                # 5. Launch instance in target region
                # (Simplified - would wait for AMI and copy)
                
                # 6. Terminate source instance
                ec2_source.terminate_instances(InstanceIds=[instance_info['instance_id']])
            
            def execute_blue_green(instance_info, source_region, target_region, migration_id):
                print(f"Executing blue/green migration {migration_id}")
                
                # 1. Launch instance in target region
                ec2_target = boto3.client('ec2', region_name=target_region)
                
                # 2. Configure and test new instance
                
                # 3. Switch traffic to new instance
                
                # 4. Terminate old instance
                ec2_source = boto3.client('ec2', region_name=source_region)
                ec2_source.terminate_instances(InstanceIds=[instance_info['instance_id']])
            
            def execute_drain_and_shift(instance_info, source_region, target_region, migration_id):
                print(f"Executing drain and shift migration {migration_id}")
                
                # 1. Mark instance for draining
                ec2_source = boto3.client('ec2', region_name=source_region)
                ec2_source.create_tags(
                    Resources=[instance_info['instance_id']],
                    Tags=[{'Key': 'Migration', 'Value': 'draining'}]
                )
                
                # 2. Wait for connections to drain
                time.sleep(MIGRATION_THRESHOLD * 60)
                
                # 3. Launch replacement in target
                
                # 4. Terminate source
                ec2_source.terminate_instances(InstanceIds=[instance_info['instance_id']])
            
            def execute_live_migration(instance_info, source_region, target_region, migration_id):
                print(f"Executing live migration {migration_id}")
                # Live migration is complex and would require:
                # - Network tunneling between regions
                # - State synchronization
                # - Atomic cutover
                # Simplified here
                pass
            
            def execute_fleet_migration(source_region, target_region, instances):
                migration_id = str(uuid.uuid4())
                
                print(f"Migrating {len(instances)} instances from {source_region} to {target_region}")
                
                # Execute appropriate migration strategy
                if MIGRATION_STRATEGY == 'checkpoint_restore':
                    for instance_id in instances[:5]:  # Limit to 5 at a time
                        instance_info = get_instance_info(instance_id, source_region)
                        if instance_info:
                            execute_checkpoint_restore(
                                instance_info, source_region, target_region, migration_id
                            )
                
                return migration_id
            
            def record_migration(table, migration_id, candidate):
                table.put_item(Item={
                    'migration_id': migration_id,
                    'timestamp': int(time.time()),
                    'source_region': candidate['source_region'],
                    'target_region': candidate['target_region'],
                    'instance_count': len(candidate['instances']),
                    'carbon_reduction': candidate['carbon_reduction'],
                    'migration_strategy': MIGRATION_STRATEGY,
                    'workload_type': WORKLOAD_TYPE
                })
            
            def emit_migration_metrics(migrations):
                namespace = f"SpotCarbonOptimizer/{os.environ.get('COMPONENT_NAME', 'default')}"
                
                total_carbon_saved = sum(
                    m.get('carbon_reduction', 0) * m.get('instance_count', 0)
                    for m in migrations
                )
                
                cloudwatch.put_metric_data(
                    Namespace=namespace,
                    MetricData=[
                        {
                            'MetricName': 'MigrationCount',
                            'Value': len(migrations),
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'InstancesMigrated',
                            'Value': sum(m.get('instance_count', 0) for m in migrations),
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'CarbonSavedByMigration',
                            'Value': total_carbon_saved,
                            'Unit': 'None'
                        },
                        {
                            'MetricName': 'MigrationSuccess',
                            'Value': 100 if migrations else 0,
                            'Unit': 'Percent'
                        }
                    ]
                )
          PYTHON
        end
      end
    end
  end
end