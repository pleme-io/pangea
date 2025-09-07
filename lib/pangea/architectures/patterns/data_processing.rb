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


require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/architectures/base'

module Pangea
  module Architectures
    module Patterns
      # Data Processing Architecture - Comprehensive data pipeline and analytics platform
      module DataProcessing
        include Base
        
        # Data lake architecture attributes
        class DataLakeAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core configuration
          attribute :data_lake_name, Types::String
          attribute :environment, Types::String.default('development').enum('development', 'staging', 'production')
          attribute :vpc_cidr, Types::String.default('10.1.0.0/16')
          attribute :availability_zones, Types::Array.of(Types::String).default(['us-east-1a', 'us-east-1b'].freeze)
          
          # Data sources
          attribute :data_sources, Types::Array.of(Types::String).default(['s3', 'rds', 'kinesis'].freeze)
          attribute :real_time_processing, Types::Bool.default(true)
          attribute :batch_processing, Types::Bool.default(true)
          
          # Storage configuration
          attribute :raw_data_retention_days, Types::Integer.default(2555)  # 7 years
          attribute :processed_data_retention_days, Types::Integer.default(365)  # 1 year
          attribute :data_encryption, Types::Bool.default(true)
          attribute :cross_region_replication, Types::Bool.default(false)
          
          # Processing configuration
          attribute :batch_processing_schedule, Types::String.default('daily').enum('hourly', 'daily', 'weekly')
          attribute :streaming_buffer_size, Types::Integer.default(128)  # MB
          attribute :streaming_buffer_interval, Types::Integer.default(60)  # seconds
          
          # Analytics configuration
          attribute :data_warehouse, Types::String.default('athena').enum('redshift', 'snowflake', 'athena', 'none')
          attribute :machine_learning, Types::Bool.default(false)
          attribute :business_intelligence, Types::Bool.default(true)
          
          # Compute configuration
          attribute :emr_enabled, Types::Bool.default(true)
          attribute :glue_enabled, Types::Bool.default(true)
          attribute :lambda_enabled, Types::Bool.default(true)
          
          attribute :tags, Types::Hash.default({}.freeze)
        end
        
        # Real-time streaming architecture attributes
        class StreamingArchitectureAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Stream configuration
          attribute :stream_name, Types::String
          attribute :stream_type, Types::String.default('kinesis').enum('kinesis', 'kafka', 'pulsar')
          attribute :shard_count, Types::Integer.default(1)
          attribute :retention_hours, Types::Integer.default(24)
          
          # Processing configuration
          attribute :stream_processing_framework, Types::String.default('kinesis-analytics').enum('kinesis-analytics', 'flink', 'spark-streaming')
          attribute :windowing_strategy, Types::String.default('tumbling').enum('tumbling', 'sliding', 'session')
          attribute :window_size_minutes, Types::Integer.default(5)
          
          # Output configuration
          attribute :output_destinations, Types::Array.of(Types::String).default(['s3', 'elasticsearch', 'dynamodb'].freeze)
          attribute :error_handling, Types::String.default('dlq').enum('retry', 'dlq', 'ignore')
          
          # Monitoring
          attribute :monitoring_enabled, Types::Bool.default(true)
          attribute :alerting_enabled, Types::Bool.default(true)
          
          attribute :tags, Types::Hash.default({}.freeze)
        end
        
        # Create a complete data lake architecture
        #
        # @param name [Symbol] Data lake name
        # @param attributes [Hash] Data lake configuration
        # @return [ArchitectureReference] Complete data lake reference
        def data_lake_architecture(name, attributes = {})
          # Validate and set defaults
          data_attrs = DataLakeAttributes.new(attributes)
          arch_ref = create_architecture_reference('data_lake', name, data_attrs.to_h)
          
          # Generate base tags
          base_tags = architecture_tags(arch_ref, {
            DataLake: data_attrs.data_lake_name,
            Environment: data_attrs.environment
          }.merge(data_attrs.tags))
          
          # 1. Create network foundation (if needed for processing resources)
          if data_attrs.emr_enabled
            arch_ref.network = vpc_with_subnets(
              architecture_resource_name(name, :data_network),
              vpc_cidr: data_attrs.vpc_cidr,
              availability_zones: data_attrs.availability_zones,
              attributes: {
                vpc_tags: base_tags.merge(Tier: 'network'),
                private_subnet_tags: base_tags.merge(Tier: 'private', Purpose: 'processing')
              }
            )
          end
          
          # 2. Create storage tier
          storage = create_data_storage_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.storage = storage
          
          # 3. Create ingestion tier
          ingestion = create_data_ingestion_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.compute = { ingestion: ingestion }
          
          # 4. Create processing tier
          processing = create_data_processing_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.compute[:processing] = processing
          
          # 5. Create analytics tier
          analytics = create_analytics_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.compute[:analytics] = analytics
          
          # 6. Create security tier
          security = create_data_security_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.security = security
          
          # 7. Create monitoring tier
          monitoring = create_data_monitoring_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.monitoring = monitoring
          
          arch_ref
        end
        
        # Create a real-time streaming data architecture
        #
        # @param name [Symbol] Stream name
        # @param attributes [Hash] Streaming configuration
        # @return [ArchitectureReference] Complete streaming reference
        def streaming_data_architecture(name, attributes = {})
          # Validate and set defaults
          stream_attrs = StreamingArchitectureAttributes.new(attributes)
          arch_ref = create_architecture_reference('streaming_data', name, stream_attrs.to_h)
          
          # Generate base tags
          base_tags = architecture_tags(arch_ref, {
            Stream: stream_attrs.stream_name,
            StreamType: stream_attrs.stream_type
          }.merge(stream_attrs.tags))
          
          # 1. Create streaming ingestion
          ingestion = create_streaming_ingestion(name, arch_ref, stream_attrs, base_tags)
          arch_ref.compute = { ingestion: ingestion }
          
          # 2. Create stream processing
          processing = create_stream_processing(name, arch_ref, stream_attrs, base_tags)
          arch_ref.compute[:processing] = processing
          
          # 3. Create output sinks
          outputs = create_streaming_outputs(name, arch_ref, stream_attrs, base_tags)
          arch_ref.storage = outputs
          
          # 4. Create monitoring
          monitoring = create_streaming_monitoring(name, arch_ref, stream_attrs, base_tags)
          arch_ref.monitoring = monitoring
          
          arch_ref
        end
        
        private
        
        # Create S3 data lake storage structure
        def create_data_storage_tier(name, arch_ref, data_attrs, base_tags)
          storage = {}
          
          # Raw data bucket
          storage[:raw_bucket] = aws_s3_bucket(
            architecture_resource_name(name, :raw_data),
            bucket_name: "#{name.to_s.gsub('_', '-')}-raw-data-#{Time.now.to_i}",
            versioning: 'Enabled',
            encryption: data_attrs.data_encryption ? {
              sse_algorithm: 'AES256'
            } : nil,
            lifecycle_rules: [
              {
                id: 'raw_data_lifecycle',
                status: 'Enabled',
                transitions: [
                  {
                    days: 30,
                    storage_class: 'STANDARD_IA'
                  },
                  {
                    days: 90,
                    storage_class: 'GLACIER'
                  }
                ],
                expiration: { days: data_attrs.raw_data_retention_days }
              }
            ],
            tags: base_tags.merge(Tier: 'storage', DataType: 'raw')
          )
          
          # Processed data bucket
          storage[:processed_bucket] = aws_s3_bucket(
            architecture_resource_name(name, :processed_data),
            bucket_name: "#{name.to_s.gsub('_', '-')}-processed-data-#{Time.now.to_i}",
            versioning: 'Enabled',
            encryption: data_attrs.data_encryption ? {
              sse_algorithm: 'AES256'
            } : nil,
            lifecycle_rules: [
              {
                id: 'processed_data_lifecycle',
                status: 'Enabled',
                transitions: [
                  {
                    days: 30,
                    storage_class: 'STANDARD_IA'
                  }
                ],
                expiration: { days: data_attrs.processed_data_retention_days }
              }
            ],
            tags: base_tags.merge(Tier: 'storage', DataType: 'processed')
          )
          
          # Analytics results bucket
          storage[:analytics_bucket] = aws_s3_bucket(
            architecture_resource_name(name, :analytics_results),
            bucket_name: "#{name.to_s.gsub('_', '-')}-analytics-#{Time.now.to_i}",
            versioning: 'Enabled',
            tags: base_tags.merge(Tier: 'storage', DataType: 'analytics')
          )
          
          storage
        end
        
        # Create data ingestion services
        def create_data_ingestion_tier(name, arch_ref, data_attrs, base_tags)
          ingestion = {}
          
          # Kinesis Data Streams (for real-time)
          if data_attrs.real_time_processing && data_attrs.data_sources.include?('kinesis')
            ingestion[:kinesis_stream] = aws_kinesis_stream(
              architecture_resource_name(name, :kinesis_stream),
              name: "#{name}-data-stream",
              shard_count: 1,
              retention_period: 24,
              shard_level_metrics: ['IncomingRecords', 'OutgoingRecords'],
              tags: base_tags.merge(Tier: 'ingestion', Component: 'kinesis')
            )
            
            # Kinesis Firehose for S3 delivery
            ingestion[:firehose] = aws_kinesis_firehose_delivery_stream(
              architecture_resource_name(name, :firehose),
              name: "#{name}-firehose",
              destination: 's3',
              s3_configuration: {
                role_arn: create_firehose_role(name, arch_ref, base_tags).arn,
                bucket_arn: arch_ref.storage[:raw_bucket].arn,
                prefix: 'year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/',
                error_output_prefix: 'errors/',
                buffer_size: data_attrs.streaming_buffer_size,
                buffer_interval: data_attrs.streaming_buffer_interval,
                compression_format: 'GZIP'
              },
              tags: base_tags.merge(Tier: 'ingestion', Component: 'firehose')
            )
          end
          
          # Database CDC (Change Data Capture)
          if data_attrs.data_sources.include?('rds')
            ingestion[:dms_replication] = aws_dms_replication_instance(
              architecture_resource_name(name, :dms_instance),
              allocated_storage: 100,
              apply_immediately: true,
              auto_minor_version_upgrade: true,
              multi_az: data_attrs.environment == 'production',
              publicly_accessible: false,
              replication_instance_class: 'dms.t3.micro',
              replication_instance_id: "#{name}-dms",
              tags: base_tags.merge(Tier: 'ingestion', Component: 'dms')
            )
          end
          
          ingestion
        end
        
        # Create data processing services
        def create_data_processing_tier(name, arch_ref, data_attrs, base_tags)
          processing = {}
          
          # AWS Glue for ETL
          if data_attrs.glue_enabled
            processing[:glue_catalog] = aws_glue_catalog_database(
              architecture_resource_name(name, :glue_catalog),
              name: "#{name.to_s.gsub('-', '_')}_catalog"
            )
            
            processing[:glue_crawler] = aws_glue_crawler(
              architecture_resource_name(name, :glue_crawler),
              name: "#{name}-crawler",
              role: create_glue_role(name, arch_ref, base_tags).arn,
              database_name: processing[:glue_catalog].name,
              s3_target: [
                {
                  path: "s3://#{arch_ref.storage[:raw_bucket].bucket}/"
                }
              ],
              schedule: data_attrs.batch_processing_schedule == 'daily' ? 'cron(0 2 * * ? *)' : nil,
              tags: base_tags.merge(Tier: 'processing', Component: 'glue-crawler')
            )
          end
          
          # EMR for big data processing
          if data_attrs.emr_enabled && arch_ref.network
            processing[:emr_cluster] = aws_emr_cluster(
              architecture_resource_name(name, :emr_cluster),
              name: "#{name}-emr-cluster",
              release_label: 'emr-6.10.0',
              applications: ['Spark', 'Hadoop', 'Hive'],
              
              ec2_attributes: {
                instance_profile: create_emr_instance_profile(name, base_tags).arn,
                key_name: nil,
                subnet_id: arch_ref.network.private_subnets.first.id
              },
              
              master_instance_group: {
                instance_type: 'm5.xlarge',
                instance_count: 1
              },
              
              core_instance_group: {
                instance_type: 'm5.xlarge',
                instance_count: 2
              },
              
              service_role: create_emr_service_role(name, base_tags).arn,
              
              tags: base_tags.merge(Tier: 'processing', Component: 'emr')
            )
          end
          
          # Lambda for serverless processing
          if data_attrs.lambda_enabled
            processing[:lambda_processor] = aws_lambda_function(
              architecture_resource_name(name, :lambda_processor),
              function_name: "#{name}-data-processor",
              runtime: 'python3.9',
              handler: 'lambda_function.lambda_handler',
              role: create_lambda_role(name, arch_ref, base_tags).arn,
              timeout: 300,
              memory_size: 512,
              
              environment: {
                variables: {
                  RAW_BUCKET: arch_ref.storage[:raw_bucket].bucket,
                  PROCESSED_BUCKET: arch_ref.storage[:processed_bucket].bucket
                }
              },
              
              tags: base_tags.merge(Tier: 'processing', Component: 'lambda')
            )
          end
          
          processing
        end
        
        # Create analytics services
        def create_analytics_tier(name, arch_ref, data_attrs, base_tags)
          analytics = {}
          
          case data_attrs.data_warehouse
          when 'athena'
            analytics[:athena_workgroup] = aws_athena_workgroup(
              architecture_resource_name(name, :athena_workgroup),
              name: "#{name}-analytics",
              description: "Athena workgroup for #{name} analytics",
              
              configuration: {
                result_configuration: {
                  output_location: "s3://#{arch_ref.storage[:analytics_bucket].bucket}/athena-results/"
                },
                enforce_workgroup_configuration: true,
                publish_cloudwatch_metrics: true
              },
              
              tags: base_tags.merge(Tier: 'analytics', Component: 'athena')
            )
            
          when 'redshift'
            analytics[:redshift_cluster] = aws_redshift_cluster(
              architecture_resource_name(name, :redshift_cluster),
              cluster_identifier: "#{name}-redshift",
              database_name: name.to_s.gsub(/[^a-zA-Z0-9]/, ''),
              master_username: 'admin',
              master_password: 'TempPassword123!',  # Should use Secrets Manager
              node_type: 'dc2.large',
              cluster_type: 'single-node',
              
              vpc_security_group_ids: [create_redshift_sg(name, arch_ref, base_tags).id],
              db_subnet_group_name: create_redshift_subnet_group(name, arch_ref, base_tags).name,
              
              encrypted: data_attrs.data_encryption,
              publicly_accessible: false,
              
              tags: base_tags.merge(Tier: 'analytics', Component: 'redshift')
            )
          end
          
          # QuickSight for BI (if enabled)
          if data_attrs.business_intelligence
            analytics[:quicksight_dataset] = {
              type: 'quicksight_dataset',
              name: "#{name}-dataset",
              data_source: data_attrs.data_warehouse
            }
          end
          
          analytics
        end
        
        # Create data security services
        def create_data_security_tier(name, arch_ref, data_attrs, base_tags)
          security = {}
          
          # KMS key for encryption
          if data_attrs.data_encryption
            security[:kms_key] = aws_kms_key(
              architecture_resource_name(name, :kms_key),
              description: "KMS key for #{name} data lake encryption",
              tags: base_tags.merge(Tier: 'security', Component: 'kms')
            )
          end
          
          # Lake Formation for data governance
          security[:lake_formation] = {
            type: 'lake_formation_settings',
            name: "#{name}-governance",
            admins: [], # Would be populated with IAM roles/users
            create_database_default_permissions: [],
            create_table_default_permissions: []
          }
          
          security
        end
        
        # Create data monitoring services
        def create_data_monitoring_tier(name, arch_ref, data_attrs, base_tags)
          monitoring = {}
          
          # CloudWatch dashboard for data pipeline
          monitoring[:dashboard] = aws_cloudwatch_dashboard(
            architecture_resource_name(name, :data_dashboard),
            dashboard_name: "#{name.to_s.gsub('_', '-')}-DataLake-Dashboard",
            dashboard_body: generate_data_dashboard_body(name, arch_ref, data_attrs)
          )
          
          # CloudWatch alarms
          monitoring[:data_freshness_alarm] = aws_cloudwatch_metric_alarm(
            architecture_resource_name(name, :data_freshness_alarm),
            alarm_name: "#{name}-data-freshness",
            comparison_operator: 'LessThanThreshold',
            evaluation_periods: '2',
            metric_name: 'IncomingRecords',
            namespace: 'AWS/Kinesis',
            period: '300',
            statistic: 'Sum',
            threshold: '1',
            alarm_description: 'Data freshness alarm for #{name}',
            alarm_actions: [], # Would include SNS topic ARN
            
            dimensions: {
              StreamName: arch_ref.compute[:ingestion][:kinesis_stream]&.name
            }
          )
          
          monitoring
        end
        
        # Create streaming-specific services
        def create_streaming_ingestion(name, arch_ref, stream_attrs, base_tags)
          case stream_attrs.stream_type
          when 'kinesis'
            {
              stream: aws_kinesis_stream(
                architecture_resource_name(name, :stream),
                name: "#{name}-stream",
                shard_count: stream_attrs.shard_count,
                retention_period: stream_attrs.retention_hours,
                tags: base_tags.merge(Tier: 'ingestion', Component: 'kinesis-stream')
              )
            }
          end
        end
        
        def create_stream_processing(name, arch_ref, stream_attrs, base_tags)
          case stream_attrs.stream_processing_framework
          when 'kinesis-analytics'
            {
              application: aws_kinesis_analytics_application(
                architecture_resource_name(name, :analytics_app),
                name: "#{name}-stream-processing",
                description: "Stream processing application for #{name}",
                
                inputs: [
                  {
                    name_prefix: 'source_stream',
                    kinesis_stream: {
                      resource_arn: arch_ref.compute[:ingestion][:stream].arn,
                      role_arn: create_kinesis_analytics_role(name, base_tags).arn
                    },
                    schema: {
                      record_columns: [
                        { name: 'timestamp', sql_type: 'TIMESTAMP', mapping: '$.timestamp' },
                        { name: 'data', sql_type: 'VARCHAR(32)', mapping: '$.data' }
                      ],
                      record_format: {
                        record_format_type: 'JSON'
                      }
                    }
                  }
                ],
                
                tags: base_tags.merge(Tier: 'processing', Component: 'kinesis-analytics')
              )
            }
          end
        end
        
        def create_streaming_outputs(name, arch_ref, stream_attrs, base_tags)
          outputs = {}
          
          stream_attrs.output_destinations.each do |destination|
            case destination
            when 's3'
              outputs[:s3_output] = aws_s3_bucket(
                architecture_resource_name(name, :stream_output),
                bucket_name: "#{name.to_s.gsub('_', '-')}-stream-output-#{Time.now.to_i}",
                tags: base_tags.merge(Tier: 'storage', Component: 'stream-output')
              )
            when 'elasticsearch'
              outputs[:elasticsearch] = aws_elasticsearch_domain(
                architecture_resource_name(name, :elasticsearch),
                domain_name: "#{name.to_s.gsub('_', '-')}-search",
                elasticsearch_version: '7.10',
                
                cluster_config: {
                  instance_type: 't3.small.elasticsearch',
                  instance_count: 1
                },
                
                ebs_options: {
                  ebs_enabled: true,
                  volume_type: 'gp2',
                  volume_size: 20
                },
                
                tags: base_tags.merge(Tier: 'storage', Component: 'elasticsearch')
              )
            end
          end
          
          outputs
        end
        
        def create_streaming_monitoring(name, arch_ref, stream_attrs, base_tags)
          {
            dashboard: aws_cloudwatch_dashboard(
              architecture_resource_name(name, :stream_dashboard),
              dashboard_name: "#{name.to_s.gsub('_', '-')}-Streaming-Dashboard",
              dashboard_body: generate_streaming_dashboard_body(name, arch_ref, stream_attrs)
            )
          }
        end
        
        # Helper methods for IAM roles
        def create_firehose_role(name, arch_ref, base_tags)
          aws_iam_role(
            architecture_resource_name(name, :firehose_role),
            name: "#{name}-firehose-role",
            assume_role_policy: jsonencode({
              Version: '2012-10-17',
              Statement: [
                {
                  Action: 'sts:AssumeRole',
                  Effect: 'Allow',
                  Principal: { Service: 'firehose.amazonaws.com' }
                }
              ]
            }),
            inline_policies: [
              {
                name: 'FirehoseS3Access',
                policy: jsonencode({
                  Version: '2012-10-17',
                  Statement: [
                    {
                      Effect: 'Allow',
                      Action: ['s3:PutObject', 's3:GetObject', 's3:ListBucket'],
                      Resource: ["#{arch_ref.storage[:raw_bucket].arn}/*", arch_ref.storage[:raw_bucket].arn]
                    }
                  ]
                })
              }
            ],
            tags: base_tags.merge(Tier: 'security', Component: 'firehose-role')
          )
        end
        
        def generate_data_dashboard_body(name, arch_ref, data_attrs)
          jsonencode({
            widgets: [
              {
                type: 'metric',
                properties: {
                  metrics: [
                    ['AWS/S3', 'BucketSizeBytes', 'BucketName', arch_ref.storage[:raw_bucket].bucket, 'StorageType', 'StandardStorage'],
                    ['AWS/S3', 'BucketSizeBytes', 'BucketName', arch_ref.storage[:processed_bucket].bucket, 'StorageType', 'StandardStorage']
                  ],
                  period: 86400,
                  stat: 'Average',
                  region: 'us-east-1',
                  title: 'Data Lake Storage Usage'
                }
              }
            ]
          })
        end
        
        def generate_streaming_dashboard_body(name, arch_ref, stream_attrs)
          jsonencode({
            widgets: [
              {
                type: 'metric',
                properties: {
                  metrics: [
                    ['AWS/Kinesis', 'IncomingRecords', 'StreamName', arch_ref.compute[:ingestion][:stream].name],
                    ['AWS/Kinesis', 'OutgoingRecords', 'StreamName', arch_ref.compute[:ingestion][:stream].name]
                  ],
                  period: 300,
                  stat: 'Sum',
                  region: 'us-east-1',
                  title: 'Stream Throughput'
                }
              }
            ]
          })
        end
      end
    end
  end
end