# frozen_string_literal: true

require_relative "types"

module Pangea
  module Components
    module CarbonAwareCompute
      class Component
        include Pangea::DSL

        def self.build(input)
          new.build(input)
        end

        def build(input)
          input = Types::Input.new(input) unless input.is_a?(Types::Input)
          
          # Validate input parameters
          Types.validate_carbon_threshold(input.carbon_intensity_threshold)
          Types.validate_execution_window(input.min_execution_window_hours, input.max_execution_window_hours)
          Types.validate_deadline(input.deadline_hours, input.max_execution_window_hours)

          # Create IAM roles
          execution_role = create_execution_role(input)
          scheduler_role = create_scheduler_role(input)

          # Create DynamoDB tables
          workload_table = create_workload_table(input)
          carbon_data_table = create_carbon_data_table(input)

          # Create Lambda functions
          scheduler_function = create_scheduler_function(input, execution_role, workload_table, carbon_data_table)
          executor_function = create_executor_function(input, execution_role, workload_table)
          monitor_function = create_monitor_function(input, execution_role, carbon_data_table)

          # Create EventBridge rules
          scheduler_rule = create_scheduler_rule(input, scheduler_function, scheduler_role)
          carbon_check_rule = create_carbon_check_rule(input, monitor_function, scheduler_role)

          # Create CloudWatch metrics and dashboard
          carbon_metric = create_carbon_metric(input)
          efficiency_metric = create_efficiency_metric(input)
          dashboard = create_monitoring_dashboard(input, carbon_metric, efficiency_metric)

          # Create optional alarms
          high_carbon_alarm = input.alert_on_high_carbon ? create_high_carbon_alarm(input, carbon_metric) : nil
          efficiency_alarm = input.enable_cost_optimization ? create_efficiency_alarm(input, efficiency_metric) : nil

          Types::Output.new(
            scheduler_function: scheduler_function,
            executor_function: executor_function,
            monitor_function: monitor_function,
            scheduler_rule: scheduler_rule,
            carbon_check_rule: carbon_check_rule,
            workload_table: workload_table,
            carbon_data_table: carbon_data_table,
            carbon_metric: carbon_metric,
            efficiency_metric: efficiency_metric,
            dashboard: dashboard,
            high_carbon_alarm: high_carbon_alarm,
            efficiency_alarm: efficiency_alarm,
            execution_role: execution_role,
            scheduler_role: scheduler_role
          )
        end

        private

        def create_execution_role(input)
          aws_iam_role(:"#{input.name}-execution-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "lambda.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            inline_policy: [{
              name: "carbon-aware-execution-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "dynamodb:GetItem",
                      "dynamodb:PutItem",
                      "dynamodb:UpdateItem",
                      "dynamodb:Query",
                      "dynamodb:Scan"
                    ],
                    Resource: ["*"]
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "cloudwatch:PutMetricData",
                      "cloudwatch:GetMetricStatistics"
                    ],
                    Resource: ["*"]
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "ec2:DescribeRegions",
                      "ec2:DescribeInstances",
                      "ec2:DescribeSpotPriceHistory"
                    ],
                    Resource: ["*"]
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "logs:CreateLogGroup",
                      "logs:CreateLogStream",
                      "logs:PutLogEvents"
                    ],
                    Resource: ["*"]
                  }
                ]
              })
            }],
            tags: input.tags.merge("Component" => "carbon-aware-compute")
          })
        end

        def create_scheduler_role(input)
          aws_iam_role(:"#{input.name}-scheduler-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "scheduler.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            inline_policy: [{
              name: "invoke-lambda-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [{
                  Effect: "Allow",
                  Action: "lambda:InvokeFunction",
                  Resource: "*"
                }]
              })
            }],
            tags: input.tags.merge("Component" => "carbon-aware-compute")
          })
        end

        def create_workload_table(input)
          aws_dynamodb_table(:"#{input.name}-workloads", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "workload_id",
            range_key: "scheduled_time",
            attribute: [
              { name: "workload_id", type: "S" },
              { name: "scheduled_time", type: "N" },
              { name: "region", type: "S" },
              { name: "status", type: "S" }
            ],
            global_secondary_index: [
              {
                name: "region-status-index",
                hash_key: "region",
                range_key: "status",
                projection_type: "ALL"
              }
            ],
            ttl: {
              enabled: true,
              attribute_name: "expiration_time"
            },
            tags: input.tags.merge(
              "Component" => "carbon-aware-compute",
              "Purpose" => "workload-queue"
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
              "Component" => "carbon-aware-compute",
              "Purpose" => "carbon-intensity-cache"
            )
          })
        end

        def create_scheduler_function(input, role, workload_table, carbon_table)
          aws_lambda_function(:"#{input.name}-scheduler", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: input.memory_mb,
            architecture: input.use_graviton ? ["arm64"] : ["x86_64"],
            environment: {
              variables: {
                "WORKLOAD_TABLE": workload_table.table_name,
                "CARBON_TABLE": carbon_table.table_name,
                "OPTIMIZATION_STRATEGY": input.optimization_strategy,
                "CARBON_THRESHOLD": input.carbon_intensity_threshold.to_s,
                "PREFERRED_REGIONS": input.preferred_regions.join(","),
                "MIN_WINDOW_HOURS": input.min_execution_window_hours.to_s,
                "MAX_WINDOW_HOURS": input.max_execution_window_hours.to_s,
                "CARBON_DATA_SOURCE": input.carbon_data_source
              }
            },
            code: {
              zip_file: generate_scheduler_code(input)
            },
            tags: input.tags.merge(
              "Component" => "carbon-aware-compute",
              "Function" => "scheduler"
            )
          })
        end

        def create_executor_function(input, role, workload_table)
          aws_lambda_function(:"#{input.name}-executor", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: input.memory_mb,
            ephemeral_storage: {
              size: input.ephemeral_storage_gb
            },
            architecture: input.use_graviton ? ["arm64"] : ["x86_64"],
            environment: {
              variables: {
                "WORKLOAD_TABLE": workload_table.table_name,
                "WORKLOAD_TYPE": input.workload_type,
                "USE_SPOT": input.use_spot_instances.to_s,
                "ENABLE_CARBON_REPORTING": input.enable_carbon_reporting.to_s
              }
            },
            code: {
              zip_file: generate_executor_code(input)
            },
            tags: input.tags.merge(
              "Component" => "carbon-aware-compute",
              "Function" => "executor"
            )
          })
        end

        def create_monitor_function(input, role, carbon_table)
          aws_lambda_function(:"#{input.name}-monitor", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 60,
            memory_size: 256,
            architecture: input.use_graviton ? ["arm64"] : ["x86_64"],
            environment: {
              variables: {
                "CARBON_TABLE": carbon_table.table_name,
                "CARBON_DATA_SOURCE": input.carbon_data_source,
                "PREFERRED_REGIONS": input.preferred_regions.join(","),
                "ENABLE_REPORTING": input.enable_carbon_reporting.to_s
              }
            },
            code: {
              zip_file: generate_monitor_code(input)
            },
            tags: input.tags.merge(
              "Component" => "carbon-aware-compute",
              "Function" => "monitor"
            )
          })
        end

        def create_scheduler_rule(input, function, role)
          aws_eventbridge_scheduler_schedule(:"#{input.name}-scheduler-rule", {
            flexible_time_window: {
              mode: "FLEXIBLE",
              maximum_window_in_minutes: 15
            },
            schedule_expression: "rate(5 minutes)",
            target: {
              arn: function.arn,
              role_arn: role.arn,
              retry_policy: {
                maximum_retry_attempts: 2
              }
            },
            tags: input.tags.merge("Component" => "carbon-aware-compute")
          })
        end

        def create_carbon_check_rule(input, function, role)
          aws_eventbridge_scheduler_schedule(:"#{input.name}-carbon-check-rule", {
            flexible_time_window: {
              mode: "OFF"
            },
            schedule_expression: "rate(15 minutes)",
            target: {
              arn: function.arn,
              role_arn: role.arn
            },
            tags: input.tags.merge("Component" => "carbon-aware-compute")
          })
        end

        def create_carbon_metric(input)
          aws_cloudwatch_metric_alarm(:"#{input.name}-carbon-metric", {
            alarm_name: "#{input.name}-carbon-emissions",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 1,
            metric_name: "CarbonEmissions",
            namespace: "CarbonAwareCompute/#{input.name}",
            period: 300,
            statistic: "Average",
            threshold: input.carbon_intensity_threshold.to_f,
            alarm_description: "Carbon emissions metric for #{input.name}",
            treat_missing_data: "notBreaching"
          })
        end

        def create_efficiency_metric(input)
          aws_cloudwatch_metric_alarm(:"#{input.name}-efficiency-metric", {
            alarm_name: "#{input.name}-compute-efficiency",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 2,
            metric_name: "ComputeEfficiency",
            namespace: "CarbonAwareCompute/#{input.name}",
            period: 300,
            statistic: "Average",
            threshold: 80.0,
            alarm_description: "Compute efficiency metric for #{input.name}",
            treat_missing_data: "notBreaching"
          })
        end

        def create_monitoring_dashboard(input, carbon_metric, efficiency_metric)
          aws_cloudwatch_dashboard(:"#{input.name}-dashboard", {
            dashboard_name: "#{input.name}-carbon-aware-dashboard",
            dashboard_body: JSON.pretty_generate({
              widgets: [
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["CarbonAwareCompute/#{input.name}", "CarbonEmissions", { stat: "Average" }],
                      [".", "CarbonIntensity", { stat: "Average", yAxis: "right" }]
                    ],
                    period: 300,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Carbon Emissions & Intensity",
                    yAxis: {
                      left: { label: "gCO2eq" },
                      right: { label: "gCO2/kWh" }
                    }
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["CarbonAwareCompute/#{input.name}", "WorkloadsScheduled", { stat: "Sum" }],
                      [".", "WorkloadsShifted", { stat: "Sum" }],
                      [".", "WorkloadsExecuted", { stat: "Sum" }]
                    ],
                    period: 3600,
                    stat: "Sum",
                    region: "us-east-1",
                    title: "Workload Execution Metrics"
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: input.preferred_regions.map { |region|
                      ["CarbonAwareCompute/#{input.name}", "RegionCarbonIntensity", { "RegionName": region }]
                    },
                    period: 900,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Regional Carbon Intensity"
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["CarbonAwareCompute/#{input.name}", "ComputeEfficiency", { stat: "Average" }],
                      [".", "CostSavings", { stat: "Sum", yAxis: "right" }]
                    ],
                    period: 3600,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Efficiency & Cost Optimization"
                  }
                }
              ]
            })
          })
        end

        def create_high_carbon_alarm(input, metric)
          aws_cloudwatch_alarm(:"#{input.name}-high-carbon-alarm", {
            alarm_name: "#{input.name}-high-carbon-intensity",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 2,
            metric_name: "CarbonIntensity",
            namespace: "CarbonAwareCompute/#{input.name}",
            period: 900,
            statistic: "Average",
            threshold: input.carbon_intensity_threshold.to_f,
            alarm_description: "Alert when carbon intensity exceeds threshold",
            alarm_actions: [], # SNS topic would go here
            treat_missing_data: "notBreaching",
            tags: input.tags
          })
        end

        def create_efficiency_alarm(input, metric)
          aws_cloudwatch_alarm(:"#{input.name}-low-efficiency-alarm", {
            alarm_name: "#{input.name}-low-compute-efficiency",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 3,
            metric_name: "ComputeEfficiency",
            namespace: "CarbonAwareCompute/#{input.name}",
            period: 1800,
            statistic: "Average",
            threshold: 70.0,
            alarm_description: "Alert when compute efficiency is low",
            alarm_actions: [], # SNS topic would go here
            treat_missing_data: "notBreaching",
            tags: input.tags
          })
        end

        def generate_scheduler_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            import time
            from datetime import datetime, timedelta
            import requests
            
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')
            
            WORKLOAD_TABLE = os.environ['WORKLOAD_TABLE']
            CARBON_TABLE = os.environ['CARBON_TABLE']
            OPTIMIZATION_STRATEGY = os.environ['OPTIMIZATION_STRATEGY']
            CARBON_THRESHOLD = int(os.environ['CARBON_THRESHOLD'])
            PREFERRED_REGIONS = os.environ['PREFERRED_REGIONS'].split(',')
            MIN_WINDOW = int(os.environ['MIN_WINDOW_HOURS'])
            MAX_WINDOW = int(os.environ['MAX_WINDOW_HOURS'])
            
            def handler(event, context):
                workload_table = dynamodb.Table(WORKLOAD_TABLE)
                carbon_table = dynamodb.Table(CARBON_TABLE)
                
                # Get pending workloads
                pending_workloads = get_pending_workloads(workload_table)
                
                for workload in pending_workloads:
                    # Get carbon intensity for regions
                    carbon_data = get_carbon_intensity(carbon_table, PREFERRED_REGIONS)
                    
                    # Determine optimal execution time and location
                    optimal_schedule = optimize_schedule(
                        workload,
                        carbon_data,
                        OPTIMIZATION_STRATEGY,
                        CARBON_THRESHOLD
                    )
                    
                    # Update workload with optimal schedule
                    update_workload_schedule(
                        workload_table,
                        workload['workload_id'],
                        optimal_schedule
                    )
                    
                    # Emit metrics
                    emit_scheduling_metrics(
                        workload,
                        optimal_schedule,
                        carbon_data
                    )
                
                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Scheduled {len(pending_workloads)} workloads')
                }
            
            def get_pending_workloads(table):
                response = table.query(
                    IndexName='region-status-index',
                    KeyConditionExpression='#status = :status',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={':status': 'pending'}
                )
                return response.get('Items', [])
            
            def get_carbon_intensity(table, regions):
                carbon_data = {}
                current_time = int(time.time())
                
                for region in regions:
                    # Check cache first
                    response = table.query(
                        KeyConditionExpression='region = :region AND #ts > :ts',
                        ExpressionAttributeNames={'#ts': 'timestamp'},
                        ExpressionAttributeValues={
                            ':region': region,
                            ':ts': current_time - 900  # 15 min cache
                        },
                        ScanIndexForward=False,
                        Limit=1
                    )
                    
                    if response['Items']:
                        carbon_data[region] = response['Items'][0]['carbon_intensity']
                    else:
                        # Fetch from API (simulated here)
                        intensity = fetch_carbon_intensity(region)
                        carbon_data[region] = intensity
                        
                        # Cache the data
                        table.put_item(Item={
                            'region': region,
                            'timestamp': current_time,
                            'carbon_intensity': intensity,
                            'expiration': current_time + 3600
                        })
                
                return carbon_data
            
            def fetch_carbon_intensity(region):
                # Simulated carbon intensity data
                # In production, this would call electricity maps API
                region_base_intensity = {
                    'us-west-2': 50,    # Oregon - hydro
                    'eu-north-1': 40,   # Stockholm - renewable
                    'eu-west-1': 80,    # Ireland - mixed
                    'ca-central-1': 30, # Canada - hydro
                    'us-east-1': 400,   # Virginia - coal/gas
                    'ap-southeast-1': 600  # Singapore - gas
                }
                
                # Add time-of-day variation
                hour = datetime.now().hour
                if 9 <= hour <= 17:  # Peak hours
                    multiplier = 1.3
                elif 0 <= hour <= 6:  # Off-peak
                    multiplier = 0.7
                else:
                    multiplier = 1.0
                
                base = region_base_intensity.get(region, 300)
                return int(base * multiplier)
            
            def optimize_schedule(workload, carbon_data, strategy, threshold):
                best_region = None
                best_time = None
                min_carbon = float('inf')
                
                if strategy in ['time_shifting', 'combined']:
                    # Analyze different time windows
                    for hours_ahead in range(MIN_WINDOW, MAX_WINDOW + 1):
                        future_time = datetime.now() + timedelta(hours=hours_ahead)
                        
                        # Estimate future carbon intensity
                        for region, current_intensity in carbon_data.items():
                            estimated_intensity = estimate_future_intensity(
                                region, current_intensity, future_time
                            )
                            
                            if estimated_intensity < min_carbon:
                                min_carbon = estimated_intensity
                                best_region = region
                                best_time = future_time
                
                if strategy in ['location_shifting', 'combined']:
                    # Find lowest carbon region right now
                    for region, intensity in carbon_data.items():
                        if intensity < min_carbon:
                            min_carbon = intensity
                            best_region = region
                            best_time = datetime.now()
                
                # Fallback to preferred region if no good option
                if min_carbon > threshold and best_region is None:
                    best_region = PREFERRED_REGIONS[0]
                    best_time = datetime.now() + timedelta(hours=MIN_WINDOW)
                
                return {
                    'region': best_region,
                    'scheduled_time': int(best_time.timestamp()),
                    'estimated_carbon_intensity': min_carbon,
                    'optimization_type': 'time_shift' if best_time > datetime.now() else 'location_shift'
                }
            
            def estimate_future_intensity(region, current, future_time):
                # Simple estimation based on time of day
                hour = future_time.hour
                
                # Off-peak bonus
                if 0 <= hour <= 6:
                    return current * 0.7
                # Peak penalty
                elif 9 <= hour <= 17:
                    return current * 1.3
                # Standard
                else:
                    return current
            
            def update_workload_schedule(table, workload_id, schedule):
                table.update_item(
                    Key={
                        'workload_id': workload_id,
                        'scheduled_time': schedule['scheduled_time']
                    },
                    UpdateExpression='SET #region = :region, #status = :status, optimization_type = :opt_type, estimated_carbon = :carbon',
                    ExpressionAttributeNames={
                        '#region': 'region',
                        '#status': 'status'
                    },
                    ExpressionAttributeValues={
                        ':region': schedule['region'],
                        ':status': 'scheduled',
                        ':opt_type': schedule['optimization_type'],
                        ':carbon': schedule['estimated_carbon_intensity']
                    }
                )
            
            def emit_scheduling_metrics(workload, schedule, carbon_data):
                cloudwatch.put_metric_data(
                    Namespace=f"CarbonAwareCompute/{os.environ.get('COMPONENT_NAME', 'default')}",
                    MetricData=[
                        {
                            'MetricName': 'WorkloadsScheduled',
                            'Value': 1,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'WorkloadsShifted',
                            'Value': 1 if schedule['optimization_type'] in ['time_shift', 'location_shift'] else 0,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'EstimatedCarbonIntensity',
                            'Value': schedule['estimated_carbon_intensity'],
                            'Unit': 'None',
                            'Dimensions': [
                                {
                                    'Name': 'Region',
                                    'Value': schedule['region']
                                }
                            ]
                        }
                    ]
                )
          PYTHON
        end

        def generate_executor_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            import time
            from datetime import datetime
            
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')
            
            WORKLOAD_TABLE = os.environ['WORKLOAD_TABLE']
            WORKLOAD_TYPE = os.environ['WORKLOAD_TYPE']
            USE_SPOT = os.environ['USE_SPOT'] == 'True'
            ENABLE_REPORTING = os.environ['ENABLE_CARBON_REPORTING'] == 'True'
            
            def handler(event, context):
                workload_table = dynamodb.Table(WORKLOAD_TABLE)
                
                # Get scheduled workloads for execution
                current_time = int(time.time())
                scheduled_workloads = get_scheduled_workloads(workload_table, current_time)
                
                execution_results = []
                total_carbon_saved = 0
                
                for workload in scheduled_workloads:
                    # Execute workload
                    result = execute_workload(workload)
                    
                    # Calculate carbon metrics
                    carbon_metrics = calculate_carbon_metrics(workload, result)
                    total_carbon_saved += carbon_metrics['carbon_saved']
                    
                    # Update workload status
                    update_workload_status(
                        workload_table,
                        workload['workload_id'],
                        'completed',
                        result,
                        carbon_metrics
                    )
                    
                    # Emit execution metrics
                    if ENABLE_REPORTING:
                        emit_execution_metrics(workload, result, carbon_metrics)
                    
                    execution_results.append({
                        'workload_id': workload['workload_id'],
                        'status': 'completed',
                        'carbon_saved': carbon_metrics['carbon_saved']
                    })
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'executed': len(execution_results),
                        'total_carbon_saved': total_carbon_saved,
                        'results': execution_results
                    })
                }
            
            def get_scheduled_workloads(table, current_time):
                # Query for workloads scheduled to run now
                response = table.query(
                    IndexName='region-status-index',
                    KeyConditionExpression='#status = :status',
                    FilterExpression='scheduled_time <= :current_time',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={
                        ':status': 'scheduled',
                        ':current_time': current_time
                    }
                )
                return response.get('Items', [])
            
            def execute_workload(workload):
                start_time = time.time()
                
                # Simulate workload execution based on type
                if WORKLOAD_TYPE == 'batch':
                    result = execute_batch_job(workload)
                elif WORKLOAD_TYPE == 'ml_training':
                    result = execute_ml_training(workload)
                elif WORKLOAD_TYPE == 'data_pipeline':
                    result = execute_data_pipeline(workload)
                else:
                    result = execute_generic_workload(workload)
                
                execution_time = time.time() - start_time
                
                return {
                    'execution_time': execution_time,
                    'compute_units': calculate_compute_units(execution_time),
                    'success': True,
                    'instance_type': 'graviton' if workload.get('use_graviton') else 'x86',
                    'spot_used': USE_SPOT
                }
            
            def execute_batch_job(workload):
                # Simulate batch processing
                time.sleep(2)  # Simulate work
                return {'records_processed': 1000}
            
            def execute_ml_training(workload):
                # Simulate ML training
                time.sleep(5)  # Simulate training
                return {'model_accuracy': 0.95}
            
            def execute_data_pipeline(workload):
                # Simulate data processing
                time.sleep(3)  # Simulate processing
                return {'data_processed_gb': 10}
            
            def execute_generic_workload(workload):
                # Generic workload execution
                time.sleep(1)
                return {'tasks_completed': 50}
            
            def calculate_compute_units(execution_time):
                # Calculate compute units based on execution time and resources
                cpu_units = int(os.environ.get('CPU_UNITS', 256))
                return (execution_time / 3600) * (cpu_units / 1024)  # vCPU-hours
            
            def calculate_carbon_metrics(workload, result):
                # Calculate carbon emissions and savings
                compute_units = result['compute_units']
                
                # Get actual vs baseline carbon intensity
                actual_intensity = workload.get('estimated_carbon', 300)
                baseline_intensity = 400  # Average grid intensity
                
                # Calculate emissions
                actual_emissions = compute_units * actual_intensity
                baseline_emissions = compute_units * baseline_intensity
                carbon_saved = baseline_emissions - actual_emissions
                
                # Additional savings from efficient computing
                if result.get('instance_type') == 'graviton':
                    carbon_saved *= 1.2  # 20% more efficient
                
                if result.get('spot_used'):
                    carbon_saved *= 1.1  # 10% bonus for using excess capacity
                
                return {
                    'actual_emissions': actual_emissions,
                    'baseline_emissions': baseline_emissions,
                    'carbon_saved': max(0, carbon_saved),
                    'carbon_intensity': actual_intensity,
                    'efficiency_score': (carbon_saved / baseline_emissions) * 100 if baseline_emissions > 0 else 0
                }
            
            def update_workload_status(table, workload_id, status, result, carbon_metrics):
                table.update_item(
                    Key={'workload_id': workload_id},
                    UpdateExpression='SET #status = :status, execution_result = :result, carbon_metrics = :metrics, completed_time = :time',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={
                        ':status': status,
                        ':result': json.dumps(result),
                        ':metrics': json.dumps(carbon_metrics),
                        ':time': int(time.time())
                    }
                )
            
            def emit_execution_metrics(workload, result, carbon_metrics):
                cloudwatch.put_metric_data(
                    Namespace=f"CarbonAwareCompute/{os.environ.get('COMPONENT_NAME', 'default')}",
                    MetricData=[
                        {
                            'MetricName': 'WorkloadsExecuted',
                            'Value': 1,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'CarbonEmissions',
                            'Value': carbon_metrics['actual_emissions'],
                            'Unit': 'None',
                            'Dimensions': [
                                {'Name': 'WorkloadType', 'Value': WORKLOAD_TYPE},
                                {'Name': 'Region', 'Value': workload.get('region', 'unknown')}
                            ]
                        },
                        {
                            'MetricName': 'CarbonSaved',
                            'Value': carbon_metrics['carbon_saved'],
                            'Unit': 'None'
                        },
                        {
                            'MetricName': 'ComputeEfficiency',
                            'Value': carbon_metrics['efficiency_score'],
                            'Unit': 'Percent'
                        },
                        {
                            'MetricName': 'ComputeUnits',
                            'Value': result['compute_units'],
                            'Unit': 'None'
                        }
                    ]
                )
          PYTHON
        end

        def generate_monitor_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            import time
            import requests
            from datetime import datetime
            
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')
            
            CARBON_TABLE = os.environ['CARBON_TABLE']
            CARBON_DATA_SOURCE = os.environ['CARBON_DATA_SOURCE']
            PREFERRED_REGIONS = os.environ['PREFERRED_REGIONS'].split(',')
            ENABLE_REPORTING = os.environ['ENABLE_REPORTING'] == 'True'
            
            def handler(event, context):
                carbon_table = dynamodb.Table(CARBON_TABLE)
                
                # Fetch latest carbon intensity data for all regions
                carbon_data = fetch_all_carbon_data(PREFERRED_REGIONS)
                
                # Store in DynamoDB
                store_carbon_data(carbon_table, carbon_data)
                
                # Emit monitoring metrics
                if ENABLE_REPORTING:
                    emit_carbon_metrics(carbon_data)
                
                # Check for anomalies or significant changes
                anomalies = detect_carbon_anomalies(carbon_data)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'updated_regions': len(carbon_data),
                        'anomalies': anomalies
                    })
                }
            
            def fetch_all_carbon_data(regions):
                carbon_data = {}
                
                if CARBON_DATA_SOURCE == 'electricity-maps':
                    # Fetch from Electricity Maps API (requires API key)
                    for region in regions:
                        intensity = fetch_from_electricity_maps(region)
                        carbon_data[region] = intensity
                elif CARBON_DATA_SOURCE == 'watttime':
                    # Fetch from WattTime API
                    for region in regions:
                        intensity = fetch_from_watttime(region)
                        carbon_data[region] = intensity
                else:
                    # Use simulated data
                    for region in regions:
                        intensity = simulate_carbon_intensity(region)
                        carbon_data[region] = intensity
                
                return carbon_data
            
            def fetch_from_electricity_maps(region):
                # Map AWS regions to Electricity Maps zones
                region_mapping = {
                    'us-west-2': 'US-NW-PACW',  # Oregon
                    'eu-north-1': 'SE',          # Sweden
                    'eu-west-1': 'IE',           # Ireland
                    'ca-central-1': 'CA-ON',     # Ontario
                    'us-east-1': 'US-MIDA-PJM',  # Virginia
                    'ap-southeast-1': 'SG'       # Singapore
                }
                
                zone = region_mapping.get(region, 'US-MIDA-PJM')
                
                # In production, make actual API call
                # For now, return simulated data
                return simulate_carbon_intensity(region)
            
            def fetch_from_watttime(region):
                # Similar to electricity maps but using WattTime API
                return simulate_carbon_intensity(region)
            
            def simulate_carbon_intensity(region):
                # Realistic carbon intensity simulation
                base_intensities = {
                    'us-west-2': 50,      # Oregon - mostly hydro
                    'eu-north-1': 40,     # Stockholm - renewable heavy
                    'eu-west-1': 80,      # Ireland - wind + gas
                    'ca-central-1': 30,   # Canada - hydro/nuclear
                    'us-east-1': 400,     # Virginia - mixed grid
                    'ap-southeast-1': 600,# Singapore - gas heavy
                    'us-west-1': 250,     # California - mixed
                    'eu-central-1': 350,  # Frankfurt - mixed
                    'ap-northeast-1': 450 # Tokyo - gas/coal
                }
                
                base = base_intensities.get(region, 300)
                
                # Add realistic variations
                hour = datetime.now().hour
                day_of_week = datetime.now().weekday()
                
                # Time of day factors
                if 6 <= hour <= 9:  # Morning peak
                    time_factor = 1.3
                elif 17 <= hour <= 20:  # Evening peak
                    time_factor = 1.4
                elif 0 <= hour <= 5:  # Night
                    time_factor = 0.8
                else:
                    time_factor = 1.0
                
                # Weekend factor
                weekend_factor = 0.85 if day_of_week >= 5 else 1.0
                
                # Seasonal factor (simplified)
                month = datetime.now().month
                if month in [12, 1, 2]:  # Winter
                    seasonal_factor = 1.2
                elif month in [6, 7, 8]:  # Summer
                    seasonal_factor = 1.1
                else:
                    seasonal_factor = 1.0
                
                # Random variation (+/- 10%)
                import random
                random_factor = 0.9 + random.random() * 0.2
                
                final_intensity = base * time_factor * weekend_factor * seasonal_factor * random_factor
                
                return {
                    'carbon_intensity': int(final_intensity),
                    'timestamp': int(time.time()),
                    'renewable_percentage': calculate_renewable_percentage(region, final_intensity),
                    'grid_region': region,
                    'data_source': CARBON_DATA_SOURCE
                }
            
            def calculate_renewable_percentage(region, intensity):
                # Estimate renewable percentage based on intensity
                if intensity < 100:
                    return 80 + (100 - intensity) / 5  # 80-100%
                elif intensity < 200:
                    return 60 + (200 - intensity) / 5  # 60-80%
                elif intensity < 400:
                    return 30 + (400 - intensity) / 10  # 30-60%
                else:
                    return max(0, 30 - (intensity - 400) / 20)  # 0-30%
            
            def store_carbon_data(table, carbon_data):
                current_time = int(time.time())
                
                for region, data in carbon_data.items():
                    table.put_item(Item={
                        'region': region,
                        'timestamp': current_time,
                        'carbon_intensity': data['carbon_intensity'],
                        'renewable_percentage': data['renewable_percentage'],
                        'data_source': data['data_source'],
                        'expiration': current_time + 3600  # 1 hour TTL
                    })
            
            def emit_carbon_metrics(carbon_data):
                metric_data = []
                
                for region, data in carbon_data.items():
                    metric_data.extend([
                        {
                            'MetricName': 'RegionCarbonIntensity',
                            'Value': data['carbon_intensity'],
                            'Unit': 'None',
                            'Dimensions': [{'Name': 'RegionName', 'Value': region}]
                        },
                        {
                            'MetricName': 'RegionRenewablePercentage',
                            'Value': data['renewable_percentage'],
                            'Unit': 'Percent',
                            'Dimensions': [{'Name': 'RegionName', 'Value': region}]
                        }
                    ])
                
                # Add aggregate metrics
                avg_intensity = sum(d['carbon_intensity'] for d in carbon_data.values()) / len(carbon_data)
                min_intensity = min(d['carbon_intensity'] for d in carbon_data.values())
                max_intensity = max(d['carbon_intensity'] for d in carbon_data.values())
                
                metric_data.extend([
                    {
                        'MetricName': 'AverageCarbonIntensity',
                        'Value': avg_intensity,
                        'Unit': 'None'
                    },
                    {
                        'MetricName': 'MinCarbonIntensity',
                        'Value': min_intensity,
                        'Unit': 'None'
                    },
                    {
                        'MetricName': 'MaxCarbonIntensity',
                        'Value': max_intensity,
                        'Unit': 'None'
                    }
                ])
                
                cloudwatch.put_metric_data(
                    Namespace=f"CarbonAwareCompute/{os.environ.get('COMPONENT_NAME', 'default')}",
                    MetricData=metric_data
                )
            
            def detect_carbon_anomalies(carbon_data):
                anomalies = []
                
                for region, data in carbon_data.items():
                    intensity = data['carbon_intensity']
                    
                    # Check for unusually high intensity
                    if intensity > 600:
                        anomalies.append({
                            'region': region,
                            'type': 'high_intensity',
                            'value': intensity,
                            'message': f'Unusually high carbon intensity in {region}: {intensity} gCO2/kWh'
                        })
                    
                    # Check for very low renewable percentage
                    if data['renewable_percentage'] < 10:
                        anomalies.append({
                            'region': region,
                            'type': 'low_renewable',
                            'value': data['renewable_percentage'],
                            'message': f'Very low renewable energy in {region}: {data["renewable_percentage"]}%'
                        })
                
                return anomalies
          PYTHON
        end
      end
    end
  end
end