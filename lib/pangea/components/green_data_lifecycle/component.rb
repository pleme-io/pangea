# frozen_string_literal: true

require_relative "types"

module Pangea
  module Components
    module GreenDataLifecycle
      class Component
        include Pangea::DSL

        def self.build(input)
          new.build(input)
        end

        def build(input)
          input = Types::Input.new(input) unless input.is_a?(Types::Input)
          
          # Validate input parameters
          Types.validate_transition_days(
            input.transition_to_ia_days,
            input.transition_to_glacier_ir_days,
            input.transition_to_glacier_days,
            input.transition_to_deep_archive_days
          )
          Types.validate_carbon_threshold(input.carbon_threshold_gco2_per_gb)
          Types.validate_access_window(input.access_pattern_window_days)

          # Create IAM roles
          lifecycle_role = create_lifecycle_role(input)
          analyzer_role = create_analyzer_role(input)

          # Create S3 buckets
          primary_bucket = create_primary_bucket(input)
          archive_bucket = input.enable_glacier_archive ? create_archive_bucket(input) : nil

          # Create lifecycle configuration
          lifecycle_configuration = create_lifecycle_configuration(input, primary_bucket)
          
          # Create intelligent tiering if enabled
          intelligent_tiering_configuration = input.enable_intelligent_tiering ? 
            create_intelligent_tiering_configuration(input, primary_bucket) : nil

          # Create Glacier vault for deep archive
          glacier_vault = input.enable_glacier_archive ? create_glacier_vault(input) : nil

          # Create Lambda functions
          access_analyzer = create_access_analyzer_function(input, analyzer_role, primary_bucket)
          carbon_optimizer = create_carbon_optimizer_function(input, analyzer_role, primary_bucket)
          lifecycle_manager = create_lifecycle_manager_function(input, analyzer_role, primary_bucket)

          # Create S3 inventory if enabled
          inventory_configuration = input.enable_inventory ? 
            create_inventory_configuration(input, primary_bucket) : nil

          # Create CloudWatch metrics and dashboard
          storage_metrics = create_storage_metrics(input, primary_bucket)
          carbon_dashboard = create_carbon_dashboard(input, primary_bucket, storage_metrics)
          efficiency_alarms = create_efficiency_alarms(input, storage_metrics)

          Types::Output.new(
            primary_bucket: primary_bucket,
            archive_bucket: archive_bucket,
            lifecycle_configuration: lifecycle_configuration,
            intelligent_tiering_configuration: intelligent_tiering_configuration,
            glacier_vault: glacier_vault,
            access_analyzer_function: access_analyzer,
            carbon_optimizer_function: carbon_optimizer,
            lifecycle_manager_function: lifecycle_manager,
            storage_metrics: storage_metrics,
            carbon_dashboard: carbon_dashboard,
            efficiency_alarms: efficiency_alarms,
            inventory_configuration: inventory_configuration,
            lifecycle_role: lifecycle_role,
            analyzer_role: analyzer_role
          )
        end

        private

        def create_lifecycle_role(input)
          aws_iam_role(:"#{input.name}-lifecycle-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "s3.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            inline_policy: [{
              name: "lifecycle-transition-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [{
                  Effect: "Allow",
                  Action: [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "glacier:UploadArchive",
                    "glacier:DeleteArchive"
                  ],
                  Resource: "*"
                }]
              })
            }],
            tags: input.tags.merge("Component" => "green-data-lifecycle")
          })
        end

        def create_analyzer_role(input)
          aws_iam_role(:"#{input.name}-analyzer-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "lambda.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            inline_policy: [{
              name: "analyzer-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "s3:GetObject",
                      "s3:ListBucket",
                      "s3:GetObjectTagging",
                      "s3:PutObjectTagging",
                      "s3:GetBucketInventoryConfiguration",
                      "s3:GetMetricsConfiguration"
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
            tags: input.tags.merge("Component" => "green-data-lifecycle")
          })
        end

        def create_primary_bucket(input)
          bucket_name = input.bucket_prefix ? "#{input.bucket_prefix}-#{input.name}" : input.name
          
          aws_s3_bucket(:"#{input.name}-primary", {
            bucket: bucket_name,
            tags: input.tags.merge(
              "Component" => "green-data-lifecycle",
              "Purpose" => "primary-storage",
              "Sustainability" => "enabled"
            )
          })
        end

        def create_archive_bucket(input)
          bucket_name = input.bucket_prefix ? "#{input.bucket_prefix}-#{input.name}-archive" : "#{input.name}-archive"
          
          aws_s3_bucket(:"#{input.name}-archive", {
            bucket: bucket_name,
            tags: input.tags.merge(
              "Component" => "green-data-lifecycle",
              "Purpose" => "archive-storage",
              "Sustainability" => "optimized"
            )
          })
        end

        def create_lifecycle_configuration(input, bucket)
          rules = []

          # Intelligent transition rules based on strategy
          case input.lifecycle_strategy
          when 'carbon_optimized'
            rules.concat(create_carbon_optimized_rules(input))
          when 'access_pattern_based'
            rules.concat(create_access_pattern_rules(input))
          when 'time_based'
            rules.concat(create_time_based_rules(input))
          when 'size_based'
            rules.concat(create_size_based_rules(input))
          when 'cost_optimized'
            rules.concat(create_cost_optimized_rules(input))
          end

          # Add expiration rule if configured
          if input.expire_days
            rules << {
              id: "expire-old-objects",
              status: "Enabled",
              expiration: {
                days: input.expire_days
              }
            }
          end

          aws_s3_bucket_lifecycle_configuration(:"#{input.name}-lifecycle", {
            bucket: bucket.id,
            rule: rules
          })
        end

        def create_carbon_optimized_rules(input)
          [
            {
              id: "carbon-optimize-standard-to-ia",
              status: "Enabled",
              transition: [{
                days: input.transition_to_ia_days,
                storage_class: "STANDARD_IA"
              }],
              noncurrent_version_transition: [{
                noncurrent_days: input.transition_to_ia_days / 2,
                storage_class: "STANDARD_IA"
              }]
            },
            {
              id: "carbon-optimize-ia-to-glacier-ir",
              status: "Enabled",
              transition: [{
                days: input.transition_to_glacier_ir_days,
                storage_class: "GLACIER_IR"
              }]
            },
            {
              id: "carbon-optimize-to-deep-archive",
              status: "Enabled",
              transition: [{
                days: input.transition_to_deep_archive_days,
                storage_class: "DEEP_ARCHIVE"
              }]
            }
          ]
        end

        def create_access_pattern_rules(input)
          [
            {
              id: "access-pattern-optimization",
              status: "Enabled",
              transition: [
                {
                  days: 30,
                  storage_class: "INTELLIGENT_TIERING"
                }
              ]
            }
          ]
        end

        def create_time_based_rules(input)
          [
            {
              id: "time-based-transitions",
              status: "Enabled",
              transition: [
                {
                  days: input.transition_to_ia_days,
                  storage_class: "STANDARD_IA"
                },
                {
                  days: input.transition_to_glacier_days,
                  storage_class: "GLACIER_FLEXIBLE"
                }
              ]
            }
          ]
        end

        def create_size_based_rules(input)
          [
            {
              id: "large-object-archive",
              status: "Enabled",
              filter: {
                object_size_greater_than: input.large_object_threshold_mb * 1024 * 1024
              },
              transition: [{
                days: input.archive_large_objects_days,
                storage_class: "GLACIER_IR"
              }]
            }
          ]
        end

        def create_cost_optimized_rules(input)
          [
            {
              id: "cost-optimize-all",
              status: "Enabled",
              transition: [
                {
                  days: 30,
                  storage_class: "STANDARD_IA"
                },
                {
                  days: 90,
                  storage_class: "GLACIER_FLEXIBLE"
                }
              ]
            }
          ]
        end

        def create_intelligent_tiering_configuration(input, bucket)
          aws_s3_bucket_intelligent_tiering_configuration(:"#{input.name}-intelligent-tiering", {
            bucket: bucket.id,
            name: "#{input.name}-tiering",
            status: "Enabled",
            filter: {
              prefix: ""
            },
            tiering: [
              {
                days: 90,
                access_tier: "ARCHIVE_ACCESS"
              },
              {
                days: 180,
                access_tier: "DEEP_ARCHIVE_ACCESS"
              }
            ]
          })
        end

        def create_glacier_vault(input)
          aws_glacier_vault(:"#{input.name}-vault", {
            name: "#{input.name}-deep-archive",
            access_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { AWS: "*" },
                Action: ["glacier:UploadArchive"],
                Resource: "*",
                Condition: {
                  StringEquals: {
                    "glacier:ArchiveDescription": ["green-lifecycle-archive"]
                  }
                }
              }]
            }),
            notification: {
              sns_topic: ref(:aws_sns_topic, :"#{input.name}-glacier-notifications", :arn),
              events: ["ArchiveRetrievalCompleted", "InventoryRetrievalCompleted"]
            },
            tags: input.tags.merge("Component" => "green-data-lifecycle")
          })
        end

        def create_access_analyzer_function(input, role, bucket)
          aws_lambda_function(:"#{input.name}-access-analyzer", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: 512,
            environment: {
              variables: {
                "BUCKET_NAME": bucket.bucket,
                "ANALYSIS_WINDOW_DAYS": input.access_pattern_window_days.to_s,
                "OPTIMIZE_READ_HEAVY": input.optimize_for_read_heavy.to_s,
                "MONITOR_PATTERNS": input.monitor_access_patterns.to_s
              }
            },
            code: {
              zip_file: generate_access_analyzer_code(input)
            },
            tags: input.tags.merge(
              "Component" => "green-data-lifecycle",
              "Function" => "access-analyzer"
            )
          })
        end

        def create_carbon_optimizer_function(input, role, bucket)
          aws_lambda_function(:"#{input.name}-carbon-optimizer", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 1024,
            environment: {
              variables: {
                "BUCKET_NAME": bucket.bucket,
                "CARBON_THRESHOLD": input.carbon_threshold_gco2_per_gb.to_s,
                "PREFER_RENEWABLE": input.prefer_renewable_regions.to_s,
                "LIFECYCLE_STRATEGY": input.lifecycle_strategy
              }
            },
            code: {
              zip_file: generate_carbon_optimizer_code(input)
            },
            tags: input.tags.merge(
              "Component" => "green-data-lifecycle",
              "Function" => "carbon-optimizer"
            )
          })
        end

        def create_lifecycle_manager_function(input, role, bucket)
          aws_lambda_function(:"#{input.name}-lifecycle-manager", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 512,
            environment: {
              variables: {
                "BUCKET_NAME": bucket.bucket,
                "COMPLIANCE_MODE": input.compliance_mode.to_s,
                "DELETION_PROTECTION": input.deletion_protection.to_s,
                "LEGAL_HOLD_TAGS": input.legal_hold_tags.join(",")
              }
            },
            code: {
              zip_file: generate_lifecycle_manager_code(input)
            },
            tags: input.tags.merge(
              "Component" => "green-data-lifecycle",
              "Function" => "lifecycle-manager"
            )
          })
        end

        def create_inventory_configuration(input, bucket)
          aws_s3_bucket_inventory(:"#{input.name}-inventory", {
            bucket: bucket.id,
            name: "#{input.name}-inventory",
            included_object_versions: "All",
            optional_fields: [
              "Size",
              "LastModifiedDate",
              "StorageClass",
              "IntelligentTieringAccessTier",
              "ObjectAccessControlList",
              "ObjectOwner"
            ],
            schedule: {
              frequency: "Daily"
            },
            destination: {
              bucket: {
                format: "Parquet",
                bucket_arn: bucket.arn,
                prefix: "inventory/"
              }
            }
          })
        end

        def create_storage_metrics(input, bucket)
          storage_classes = ['STANDARD', 'STANDARD_IA', 'GLACIER_IR', 'GLACIER_FLEXIBLE', 'DEEP_ARCHIVE']
          
          storage_classes.map do |storage_class|
            aws_cloudwatch_metric_alarm(:"#{input.name}-#{storage_class.downcase.gsub('_', '-')}-metric", {
              alarm_name: "#{input.name}-#{storage_class}-storage",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 1,
              metric_name: "BucketSizeBytes",
              namespace: "AWS/S3",
              period: 86400,  # Daily
              statistic: "Average",
              threshold: 0,
              dimensions: [
                { name: "BucketName", value: bucket.bucket },
                { name: "StorageType", value: storage_class }
              ],
              treat_missing_data: "notBreaching"
            })
          end
        end

        def create_carbon_dashboard(input, bucket, metrics)
          aws_cloudwatch_dashboard(:"#{input.name}-carbon-dashboard", {
            dashboard_name: "#{input.name}-green-storage-dashboard",
            dashboard_body: JSON.pretty_generate({
              widgets: [
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["GreenDataLifecycle/#{input.name}", "TotalCarbonFootprint", { stat: "Average" }],
                      [".", "CarbonPerGB", { stat: "Average", yAxis: "right" }]
                    ],
                    period: 86400,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Storage Carbon Footprint",
                    yAxis: {
                      left: { label: "Total gCO2" },
                      right: { label: "gCO2/GB" }
                    }
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: Types::STORAGE_CARBON_INTENSITY.keys.map { |storage_class|
                      ["AWS/S3", "BucketSizeBytes", 
                       { "BucketName": bucket.bucket, "StorageType": storage_class }]
                    },
                    period: 86400,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Storage Distribution by Class",
                    stacked: true
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["GreenDataLifecycle/#{input.name}", "ObjectsTransitioned", { stat: "Sum" }],
                      [".", "ObjectsArchived", { stat: "Sum" }],
                      [".", "ObjectsDeleted", { stat: "Sum" }]
                    ],
                    period: 86400,
                    stat: "Sum",
                    region: "us-east-1",
                    title: "Lifecycle Activity"
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["GreenDataLifecycle/#{input.name}", "AccessPatternScore", { stat: "Average" }],
                      [".", "StorageEfficiency", { stat: "Average" }],
                      [".", "CarbonEfficiency", { stat: "Average" }]
                    ],
                    period: 86400,
                    stat: "Average",
                    region: "us-east-1",
                    title: "Efficiency Metrics",
                    yAxis: {
                      left: { min: 0, max: 100 }
                    }
                  }
                }
              ]
            })
          })
        end

        def create_efficiency_alarms(input, metrics)
          alarms = []

          if input.alert_on_high_storage_carbon
            alarms << aws_cloudwatch_alarm(:"#{input.name}-high-carbon-alarm", {
              alarm_name: "#{input.name}-high-storage-carbon",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 2,
              metric_name: "CarbonPerGB",
              namespace: "GreenDataLifecycle/#{input.name}",
              period: 86400,
              statistic: "Average",
              threshold: input.carbon_threshold_gco2_per_gb,
              alarm_description: "Alert when storage carbon intensity is high",
              treat_missing_data: "notBreaching",
              tags: input.tags
            })
          end

          alarms << aws_cloudwatch_alarm(:"#{input.name}-inefficient-storage-alarm", {
            alarm_name: "#{input.name}-inefficient-storage",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 3,
            metric_name: "StorageEfficiency",
            namespace: "GreenDataLifecycle/#{input.name}",
            period: 86400,
            statistic: "Average",
            threshold: 70.0,
            alarm_description: "Alert when storage efficiency is low",
            treat_missing_data: "notBreaching",
            tags: input.tags
          })

          alarms
        end

        def generate_access_analyzer_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime, timedelta
            from collections import defaultdict
            
            s3 = boto3.client('s3')
            cloudwatch = boto3.client('cloudwatch')
            
            BUCKET_NAME = os.environ['BUCKET_NAME']
            ANALYSIS_WINDOW = int(os.environ['ANALYSIS_WINDOW_DAYS'])
            OPTIMIZE_READ_HEAVY = os.environ['OPTIMIZE_READ_HEAVY'] == 'True'
            
            def handler(event, context):
                # Analyze access patterns for objects in bucket
                access_patterns = analyze_bucket_access_patterns()
                
                # Calculate optimal storage classes based on access
                recommendations = generate_storage_recommendations(access_patterns)
                
                # Apply tags for lifecycle rules
                apply_access_pattern_tags(recommendations)
                
                # Emit metrics
                emit_access_metrics(access_patterns, recommendations)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'analyzed_objects': len(access_patterns),
                        'recommendations': len(recommendations)
                    })
                }
            
            def analyze_bucket_access_patterns():
                patterns = defaultdict(lambda: {
                    'access_count': 0,
                    'last_accessed': None,
                    'size': 0,
                    'storage_class': 'STANDARD'
                })
                
                # List all objects
                paginator = s3.get_paginator('list_objects_v2')
                
                for page in paginator.paginate(Bucket=BUCKET_NAME):
                    if 'Contents' not in page:
                        continue
                    
                    for obj in page['Contents']:
                        key = obj['Key']
                        
                        # Get object metadata
                        try:
                            response = s3.head_object(Bucket=BUCKET_NAME, Key=key)
                            
                            patterns[key]['size'] = obj['Size']
                            patterns[key]['storage_class'] = response.get('StorageClass', 'STANDARD')
                            patterns[key]['last_modified'] = obj['LastModified']
                            
                            # Check CloudTrail for access patterns (simplified)
                            # In production, this would query CloudTrail or S3 access logs
                            patterns[key]['access_count'] = estimate_access_count(key, obj['LastModified'])
                            patterns[key]['last_accessed'] = obj['LastModified']  # Simplified
                            
                        except Exception as e:
                            print(f"Error analyzing {key}: {str(e)}")
                
                return patterns
            
            def estimate_access_count(key, last_modified):
                # Simulate access pattern based on object age and type
                age_days = (datetime.now(last_modified.tzinfo) - last_modified).days
                
                # Hot data pattern
                if age_days < 7:
                    return 50
                # Warm data pattern
                elif age_days < 30:
                    return 10
                # Cool data pattern
                elif age_days < 90:
                    return 2
                # Cold data pattern
                else:
                    return 0
            
            def generate_storage_recommendations(patterns):
                recommendations = {}
                
                for key, pattern in patterns.items():
                    age_days = (datetime.now() - pattern['last_modified'].replace(tzinfo=None)).days
                    access_frequency = pattern['access_count'] / max(age_days, 1)
                    
                    # Determine optimal storage class
                    if access_frequency > 1:  # More than once per day
                        recommended_class = 'STANDARD'
                        classification = 'hot'
                    elif access_frequency > 0.1:  # More than once per 10 days
                        recommended_class = 'INTELLIGENT_TIERING'
                        classification = 'warm'
                    elif access_frequency > 0.01:  # More than once per 100 days
                        recommended_class = 'STANDARD_IA'
                        classification = 'cool'
                    elif age_days > 180:
                        recommended_class = 'GLACIER_FLEXIBLE'
                        classification = 'cold'
                    else:
                        recommended_class = 'GLACIER_IR'
                        classification = 'cold'
                    
                    # Override for read-heavy optimization
                    if OPTIMIZE_READ_HEAVY and classification in ['cool', 'cold']:
                        recommended_class = 'STANDARD_IA'
                        classification = 'cool'
                    
                    # Only recommend changes
                    if recommended_class != pattern['storage_class']:
                        recommendations[key] = {
                            'current_class': pattern['storage_class'],
                            'recommended_class': recommended_class,
                            'classification': classification,
                            'potential_savings': calculate_savings(
                                pattern['size'],
                                pattern['storage_class'],
                                recommended_class
                            )
                        }
                
                return recommendations
            
            def calculate_savings(size_bytes, current_class, recommended_class):
                # Storage costs per GB per month (simplified)
                costs = {
                    'STANDARD': 0.023,
                    'INTELLIGENT_TIERING': 0.023,  # Same as standard but with auto-tiering
                    'STANDARD_IA': 0.0125,
                    'GLACIER_IR': 0.004,
                    'GLACIER_FLEXIBLE': 0.0036,
                    'DEEP_ARCHIVE': 0.00099
                }
                
                size_gb = size_bytes / (1024 ** 3)
                current_cost = size_gb * costs.get(current_class, 0.023)
                recommended_cost = size_gb * costs.get(recommended_class, 0.023)
                
                return max(0, current_cost - recommended_cost)
            
            def apply_access_pattern_tags(recommendations):
                for key, recommendation in recommendations.items():
                    try:
                        # Apply tags for lifecycle rules to act on
                        s3.put_object_tagging(
                            Bucket=BUCKET_NAME,
                            Key=key,
                            Tagging={
                                'TagSet': [
                                    {
                                        'Key': 'DataClassification',
                                        'Value': recommendation['classification']
                                    },
                                    {
                                        'Key': 'RecommendedStorageClass',
                                        'Value': recommendation['recommended_class']
                                    },
                                    {
                                        'Key': 'LastAnalyzed',
                                        'Value': datetime.now().isoformat()
                                    }
                                ]
                            }
                        )
                    except Exception as e:
                        print(f"Error tagging {key}: {str(e)}")
            
            def emit_access_metrics(patterns, recommendations):
                # Calculate metrics
                total_objects = len(patterns)
                hot_objects = sum(1 for r in recommendations.values() if r['classification'] == 'hot')
                warm_objects = sum(1 for r in recommendations.values() if r['classification'] == 'warm')
                cool_objects = sum(1 for r in recommendations.values() if r['classification'] == 'cool')
                cold_objects = sum(1 for r in recommendations.values() if r['classification'] == 'cold')
                
                total_savings = sum(r['potential_savings'] for r in recommendations.values())
                
                # Calculate access pattern score (0-100)
                if total_objects > 0:
                    properly_tiered = total_objects - len(recommendations)
                    access_pattern_score = (properly_tiered / total_objects) * 100
                else:
                    access_pattern_score = 100
                
                cloudwatch.put_metric_data(
                    Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                    MetricData=[
                        {
                            'MetricName': 'AccessPatternScore',
                            'Value': access_pattern_score,
                            'Unit': 'Percent'
                        },
                        {
                            'MetricName': 'HotDataObjects',
                            'Value': hot_objects,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'WarmDataObjects',
                            'Value': warm_objects,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'CoolDataObjects',
                            'Value': cool_objects,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'ColdDataObjects',
                            'Value': cold_objects,
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'PotentialMonthlySavings',
                            'Value': total_savings,
                            'Unit': 'None'
                        }
                    ]
                )
          PYTHON
        end

        def generate_carbon_optimizer_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime
            
            s3 = boto3.client('s3')
            cloudwatch = boto3.client('cloudwatch')
            
            BUCKET_NAME = os.environ['BUCKET_NAME']
            CARBON_THRESHOLD = float(os.environ['CARBON_THRESHOLD'])
            PREFER_RENEWABLE = os.environ['PREFER_RENEWABLE'] == 'True'
            LIFECYCLE_STRATEGY = os.environ['LIFECYCLE_STRATEGY']
            
            # Carbon intensity by storage class (gCO2/GB/month)
            STORAGE_CARBON_INTENSITY = {
                'STANDARD': 0.55,
                'INTELLIGENT_TIERING': 0.45,
                'STANDARD_IA': 0.35,
                'ONEZONE_IA': 0.30,
                'GLACIER_IR': 0.15,
                'GLACIER_FLEXIBLE': 0.10,
                'DEEP_ARCHIVE': 0.05
            }
            
            def handler(event, context):
                # Calculate current carbon footprint
                current_footprint = calculate_bucket_carbon_footprint()
                
                # Generate optimization recommendations
                optimizations = generate_carbon_optimizations(current_footprint)
                
                # Apply optimizations if within threshold
                applied = apply_carbon_optimizations(optimizations)
                
                # Emit carbon metrics
                emit_carbon_metrics(current_footprint, optimizations, applied)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'current_carbon_footprint': current_footprint['total_gco2'],
                        'potential_reduction': optimizations['total_reduction'],
                        'optimizations_applied': len(applied)
                    })
                }
            
            def calculate_bucket_carbon_footprint():
                footprint = {
                    'by_storage_class': {},
                    'total_size_gb': 0,
                    'total_gco2': 0
                }
                
                # Get storage metrics for each class
                for storage_class, carbon_intensity in STORAGE_CARBON_INTENSITY.items():
                    try:
                        # Get bucket size for this storage class
                        response = cloudwatch.get_metric_statistics(
                            Namespace='AWS/S3',
                            MetricName='BucketSizeBytes',
                            Dimensions=[
                                {'Name': 'BucketName', 'Value': BUCKET_NAME},
                                {'Name': 'StorageType', 'Value': storage_class}
                            ],
                            StartTime=datetime.now().replace(hour=0, minute=0, second=0),
                            EndTime=datetime.now(),
                            Period=86400,
                            Statistics=['Average']
                        )
                        
                        if response['Datapoints']:
                            size_bytes = response['Datapoints'][0]['Average']
                            size_gb = size_bytes / (1024 ** 3)
                            carbon_gco2 = size_gb * carbon_intensity
                            
                            footprint['by_storage_class'][storage_class] = {
                                'size_gb': size_gb,
                                'carbon_gco2': carbon_gco2,
                                'carbon_intensity': carbon_intensity
                            }
                            
                            footprint['total_size_gb'] += size_gb
                            footprint['total_gco2'] += carbon_gco2
                    except Exception as e:
                        print(f"Error getting metrics for {storage_class}: {str(e)}")
                
                # Calculate average carbon intensity
                if footprint['total_size_gb'] > 0:
                    footprint['avg_carbon_intensity'] = footprint['total_gco2'] / footprint['total_size_gb']
                else:
                    footprint['avg_carbon_intensity'] = 0
                
                return footprint
            
            def generate_carbon_optimizations(footprint):
                optimizations = {
                    'recommendations': [],
                    'total_reduction': 0
                }
                
                # Find opportunities to move data to lower carbon storage
                for storage_class, data in footprint['by_storage_class'].items():
                    if data['size_gb'] == 0:
                        continue
                    
                    # Find lower carbon alternatives
                    for target_class, target_intensity in STORAGE_CARBON_INTENSITY.items():
                        if target_intensity < data['carbon_intensity']:
                            reduction = data['size_gb'] * (data['carbon_intensity'] - target_intensity)
                            
                            # Check if reduction is significant
                            if reduction > data['size_gb'] * 0.1:  # At least 10% reduction
                                optimizations['recommendations'].append({
                                    'from_class': storage_class,
                                    'to_class': target_class,
                                    'size_gb': data['size_gb'],
                                    'carbon_reduction': reduction,
                                    'percentage_reduction': (reduction / data['carbon_gco2']) * 100
                                })
                                optimizations['total_reduction'] += reduction
                
                # Sort by carbon reduction potential
                optimizations['recommendations'].sort(key=lambda x: x['carbon_reduction'], reverse=True)
                
                # Apply strategy-specific filtering
                if LIFECYCLE_STRATEGY == 'carbon_optimized':
                    # Keep all recommendations
                    pass
                elif LIFECYCLE_STRATEGY == 'cost_optimized':
                    # Filter out transitions that increase cost significantly
                    optimizations['recommendations'] = [
                        r for r in optimizations['recommendations']
                        if not is_cost_prohibitive(r['from_class'], r['to_class'])
                    ]
                
                return optimizations
            
            def is_cost_prohibitive(from_class, to_class):
                # Simple cost comparison (in reality would be more complex)
                cost_order = ['DEEP_ARCHIVE', 'GLACIER_FLEXIBLE', 'GLACIER_IR', 
                             'ONEZONE_IA', 'STANDARD_IA', 'INTELLIGENT_TIERING', 'STANDARD']
                
                from_index = cost_order.index(from_class) if from_class in cost_order else 0
                to_index = cost_order.index(to_class) if to_class in cost_order else 0
                
                # Allow transitions to cheaper storage only
                return to_index > from_index
            
            def apply_carbon_optimizations(optimizations):
                applied = []
                
                # Check if carbon footprint is above threshold
                for recommendation in optimizations['recommendations']:
                    if recommendation['carbon_reduction'] > CARBON_THRESHOLD * recommendation['size_gb']:
                        # Tag objects for transition
                        tag_objects_for_transition(
                            recommendation['from_class'],
                            recommendation['to_class']
                        )
                        applied.append(recommendation)
                        
                        # Stop after applying top 5 to avoid too many changes at once
                        if len(applied) >= 5:
                            break
                
                return applied
            
            def tag_objects_for_transition(from_class, to_class):
                # Tag objects in the from_class for lifecycle transition
                paginator = s3.get_paginator('list_objects_v2')
                
                for page in paginator.paginate(Bucket=BUCKET_NAME):
                    if 'Contents' not in page:
                        continue
                    
                    for obj in page['Contents']:
                        try:
                            # Check current storage class
                            response = s3.head_object(Bucket=BUCKET_NAME, Key=obj['Key'])
                            
                            if response.get('StorageClass', 'STANDARD') == from_class:
                                s3.put_object_tagging(
                                    Bucket=BUCKET_NAME,
                                    Key=obj['Key'],
                                    Tagging={
                                        'TagSet': [
                                            {
                                                'Key': 'CarbonOptimizationTarget',
                                                'Value': to_class
                                            },
                                            {
                                                'Key': 'CarbonOptimizationDate',
                                                'Value': datetime.now().isoformat()
                                            }
                                        ]
                                    }
                                )
                        except Exception as e:
                            print(f"Error tagging object {obj['Key']}: {str(e)}")
            
            def emit_carbon_metrics(footprint, optimizations, applied):
                # Emission metrics
                cloudwatch.put_metric_data(
                    Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                    MetricData=[
                        {
                            'MetricName': 'TotalCarbonFootprint',
                            'Value': footprint['total_gco2'],
                            'Unit': 'None'
                        },
                        {
                            'MetricName': 'CarbonPerGB',
                            'Value': footprint['avg_carbon_intensity'],
                            'Unit': 'None'
                        },
                        {
                            'MetricName': 'PotentialCarbonReduction',
                            'Value': optimizations['total_reduction'],
                            'Unit': 'None'
                        },
                        {
                            'MetricName': 'CarbonOptimizationsApplied',
                            'Value': len(applied),
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'StorageEfficiency',
                            'Value': calculate_storage_efficiency(footprint),
                            'Unit': 'Percent'
                        },
                        {
                            'MetricName': 'CarbonEfficiency',
                            'Value': calculate_carbon_efficiency(footprint),
                            'Unit': 'Percent'
                        }
                    ]
                )
                
                # Emit per storage class metrics
                for storage_class, data in footprint['by_storage_class'].items():
                    if data['size_gb'] > 0:
                        cloudwatch.put_metric_data(
                            Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                            MetricData=[{
                                'MetricName': 'StorageClassCarbon',
                                'Value': data['carbon_gco2'],
                                'Unit': 'None',
                                'Dimensions': [
                                    {'Name': 'StorageClass', 'Value': storage_class}
                                ]
                            }]
                        )
            
            def calculate_storage_efficiency(footprint):
                # Calculate how efficiently we're using storage tiers
                # Perfect efficiency = all cold data in deep archive, all hot in standard
                if footprint['total_size_gb'] == 0:
                    return 100
                
                # Simplified: lower average carbon intensity = higher efficiency
                best_possible = STORAGE_CARBON_INTENSITY['DEEP_ARCHIVE']
                worst_possible = STORAGE_CARBON_INTENSITY['STANDARD']
                
                efficiency = 100 * (worst_possible - footprint['avg_carbon_intensity']) / (worst_possible - best_possible)
                return max(0, min(100, efficiency))
            
            def calculate_carbon_efficiency(footprint):
                # Calculate carbon efficiency compared to all-standard storage
                if footprint['total_size_gb'] == 0:
                    return 100
                
                all_standard_carbon = footprint['total_size_gb'] * STORAGE_CARBON_INTENSITY['STANDARD']
                actual_carbon = footprint['total_gco2']
                
                savings_percentage = ((all_standard_carbon - actual_carbon) / all_standard_carbon) * 100
                return max(0, min(100, savings_percentage))
          PYTHON
        end

        def generate_lifecycle_manager_code(input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime, timedelta
            
            s3 = boto3.client('s3')
            cloudwatch = boto3.client('cloudwatch')
            
            BUCKET_NAME = os.environ['BUCKET_NAME']
            COMPLIANCE_MODE = os.environ['COMPLIANCE_MODE'] == 'True'
            DELETION_PROTECTION = os.environ['DELETION_PROTECTION'] == 'True'
            LEGAL_HOLD_TAGS = os.environ['LEGAL_HOLD_TAGS'].split(',') if os.environ['LEGAL_HOLD_TAGS'] else []
            
            def handler(event, context):
                # Process lifecycle transitions
                transitions = process_lifecycle_transitions()
                
                # Handle deletions with protection
                deletions = process_deletions()
                
                # Validate compliance requirements
                compliance_issues = validate_compliance()
                
                # Emit lifecycle metrics
                emit_lifecycle_metrics(transitions, deletions, compliance_issues)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'transitions': len(transitions),
                        'deletions': len(deletions),
                        'compliance_issues': len(compliance_issues)
                    })
                }
            
            def process_lifecycle_transitions():
                transitions = []
                
                # Get objects tagged for transition
                paginator = s3.get_paginator('list_objects_v2')
                
                for page in paginator.paginate(Bucket=BUCKET_NAME):
                    if 'Contents' not in page:
                        continue
                    
                    for obj in page['Contents']:
                        try:
                            # Get object tags
                            response = s3.get_object_tagging(Bucket=BUCKET_NAME, Key=obj['Key'])
                            tags = {tag['Key']: tag['Value'] for tag in response.get('TagSet', [])}
                            
                            # Check for carbon optimization transitions
                            if 'CarbonOptimizationTarget' in tags:
                                target_class = tags['CarbonOptimizationTarget']
                                
                                # Validate transition is allowed
                                if is_transition_allowed(obj, target_class, tags):
                                    transitions.append({
                                        'key': obj['Key'],
                                        'target_class': target_class,
                                        'size': obj['Size']
                                    })
                                    
                                    # Log transition for audit
                                    log_transition(obj['Key'], target_class)
                            
                            # Check for access pattern transitions
                            elif 'RecommendedStorageClass' in tags:
                                target_class = tags['RecommendedStorageClass']
                                
                                if is_transition_allowed(obj, target_class, tags):
                                    transitions.append({
                                        'key': obj['Key'],
                                        'target_class': target_class,
                                        'size': obj['Size']
                                    })
                        
                        except Exception as e:
                            print(f"Error processing {obj['Key']}: {str(e)}")
                
                return transitions
            
            def is_transition_allowed(obj, target_class, tags):
                # Check compliance mode restrictions
                if COMPLIANCE_MODE:
                    # Don't transition objects with legal hold
                    if any(tag in tags for tag in LEGAL_HOLD_TAGS):
                        return False
                    
                    # Don't transition recent objects in compliance mode
                    age_days = (datetime.now() - obj['LastModified'].replace(tzinfo=None)).days
                    if age_days < 90:  # Compliance retention period
                        return False
                
                # Validate transition makes sense
                current_class = get_storage_class(obj)
                
                # Don't transition to same class
                if current_class == target_class:
                    return False
                
                # Additional validation rules here
                return True
            
            def get_storage_class(obj):
                try:
                    response = s3.head_object(Bucket=BUCKET_NAME, Key=obj['Key'])
                    return response.get('StorageClass', 'STANDARD')
                except:
                    return 'STANDARD'
            
            def process_deletions():
                deletions = []
                
                if DELETION_PROTECTION:
                    # Only process objects explicitly marked for deletion
                    # In production, this would check for deletion markers
                    return deletions
                
                # Find expired objects
                paginator = s3.get_paginator('list_objects_v2')
                
                for page in paginator.paginate(Bucket=BUCKET_NAME):
                    if 'Contents' not in page:
                        continue
                    
                    for obj in page['Contents']:
                        # Check if object is expired based on lifecycle rules
                        if is_object_expired(obj):
                            # Double-check no legal hold
                            if not has_legal_hold(obj['Key']):
                                deletions.append({
                                    'key': obj['Key'],
                                    'size': obj['Size'],
                                    'age_days': (datetime.now() - obj['LastModified'].replace(tzinfo=None)).days
                                })
                
                return deletions
            
            def is_object_expired(obj):
                # Simplified expiration logic
                age_days = (datetime.now() - obj['LastModified'].replace(tzinfo=None)).days
                
                # Check storage class specific expiration
                storage_class = get_storage_class(obj)
                
                if storage_class == 'DEEP_ARCHIVE' and age_days > 2555:  # 7 years
                    return True
                elif storage_class == 'GLACIER_FLEXIBLE' and age_days > 1825:  # 5 years
                    return True
                
                return False
            
            def has_legal_hold(key):
                try:
                    response = s3.get_object_tagging(Bucket=BUCKET_NAME, Key=key)
                    tags = {tag['Key']: tag['Value'] for tag in response.get('TagSet', [])}
                    return any(tag in tags for tag in LEGAL_HOLD_TAGS)
                except:
                    return False  # Assume no hold if we can't check
            
            def validate_compliance():
                issues = []
                
                if not COMPLIANCE_MODE:
                    return issues
                
                # Check for compliance violations
                # 1. Objects missing required tags
                # 2. Objects in wrong storage class for compliance
                # 3. Objects approaching retention limits
                
                sample_size = 100  # Check sample of objects
                checked = 0
                
                paginator = s3.get_paginator('list_objects_v2')
                
                for page in paginator.paginate(Bucket=BUCKET_NAME):
                    if 'Contents' not in page:
                        continue
                    
                    for obj in page['Contents']:
                        if checked >= sample_size:
                            break
                        
                        try:
                            response = s3.get_object_tagging(Bucket=BUCKET_NAME, Key=obj['Key'])
                            tags = {tag['Key']: tag['Value'] for tag in response.get('TagSet', [])}
                            
                            # Check for required compliance tags
                            if 'DataClassification' not in tags:
                                issues.append({
                                    'type': 'missing_classification',
                                    'key': obj['Key']
                                })
                            
                            # Check retention compliance
                            if 'RetentionDate' in tags:
                                retention_date = datetime.fromisoformat(tags['RetentionDate'])
                                if datetime.now() > retention_date:
                                    issues.append({
                                        'type': 'retention_expired',
                                        'key': obj['Key']
                                    })
                            
                            checked += 1
                        
                        except Exception as e:
                            print(f"Compliance check error for {obj['Key']}: {str(e)}")
                
                return issues
            
            def log_transition(key, target_class):
                # Log transition for audit trail
                print(f"Transition logged: {key} -> {target_class}")
                
                # In production, this would write to CloudTrail or audit log
            
            def emit_lifecycle_metrics(transitions, deletions, compliance_issues):
                # Lifecycle activity metrics
                cloudwatch.put_metric_data(
                    Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                    MetricData=[
                        {
                            'MetricName': 'ObjectsTransitioned',
                            'Value': len(transitions),
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'ObjectsDeleted',
                            'Value': len(deletions),
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'ComplianceIssues',
                            'Value': len(compliance_issues),
                            'Unit': 'Count'
                        },
                        {
                            'MetricName': 'ObjectsArchived',
                            'Value': sum(1 for t in transitions if 'GLACIER' in t['target_class']),
                            'Unit': 'Count'
                        }
                    ]
                )
                
                # Storage saved metrics
                if transitions:
                    total_size_transitioned = sum(t['size'] for t in transitions) / (1024 ** 3)  # GB
                    cloudwatch.put_metric_data(
                        Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                        MetricData=[{
                            'MetricName': 'DataTransitionedGB',
                            'Value': total_size_transitioned,
                            'Unit': 'None'
                        }]
                    )
                
                if deletions:
                    total_size_deleted = sum(d['size'] for d in deletions) / (1024 ** 3)  # GB
                    cloudwatch.put_metric_data(
                        Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                        MetricData=[{
                            'MetricName': 'DataDeletedGB',
                            'Value': total_size_deleted,
                            'Unit': 'None'
                        }]
                    )
          PYTHON
        end
      end
    end
  end
end