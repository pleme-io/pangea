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

# Example: Data Processing Pipeline
# This example demonstrates a comprehensive data processing pipeline using:
# - Amazon Kinesis for real-time streaming
# - AWS Glue for ETL processing and data catalog
# - Amazon EMR for big data analytics
# - Data Lake architecture with S3
# - Lambda for serverless data processing
# - Step Functions for workflow orchestration

# Template 1: Data Lake Foundation
template :data_lake_foundation do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "DataProcessingPipeline"
        Template "data_lake_foundation"
      end
    end
  end
  
  # S3 buckets for data lake zones
  raw_data_bucket = resource :aws_s3_bucket, :raw_data do
    bucket "data-lake-raw-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "DataLake-RawData-#{namespace}"
      Purpose "RawDataStorage"
      Zone "raw"
    end
  end
  
  processed_data_bucket = resource :aws_s3_bucket, :processed_data do
    bucket "data-lake-processed-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "DataLake-ProcessedData-#{namespace}"
      Purpose "ProcessedDataStorage"
      Zone "processed"
    end
  end
  
  curated_data_bucket = resource :aws_s3_bucket, :curated_data do
    bucket "data-lake-curated-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "DataLake-CuratedData-#{namespace}"
      Purpose "CuratedDataStorage"
      Zone "curated"
    end
  end
  
  analytics_results_bucket = resource :aws_s3_bucket, :analytics_results do
    bucket "data-lake-analytics-results-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "DataLake-AnalyticsResults-#{namespace}"
      Purpose "AnalyticsResultsStorage"
      Zone "results"
    end
  end
  
  # Enable versioning for all data lake buckets
  [raw_data_bucket, processed_data_bucket, curated_data_bucket, analytics_results_bucket].each_with_index do |bucket, index|
    bucket_names = [:raw_data, :processed_data, :curated_data, :analytics_results]
    
    resource :"aws_s3_bucket_versioning", bucket_names[index] do
      bucket ref(:"aws_s3_bucket", bucket_names[index], :id)
      versioning_configuration do
        status "Enabled"
      end
    end
  end
  
  # KMS key for data lake encryption
  data_lake_kms_key = resource :aws_kms_key, :data_lake_encryption do
    description "KMS key for data lake encryption"
    deletion_window_in_days 7
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { AWS: "arn:aws:iam::#{data(:aws_caller_identity, :current, :account_id)}:root" },
          Action: "kms:*",
          Resource: "*"
        },
        {
          Effect: "Allow",
          Principal: { Service: [
            "glue.amazonaws.com",
            "kinesis.amazonaws.com",
            "lambda.amazonaws.com",
            "s3.amazonaws.com"
          ]},
          Action: [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey*",
            "kms:ReEncrypt*"
          ],
          Resource: "*"
        }
      ]
    })
    
    tags do
      Name "DataLake-Encryption-Key-#{namespace}"
      Purpose "DataLakeEncryption"
    end
  end
  
  resource :aws_kms_alias, :data_lake_encryption do
    name "alias/data-lake-#{namespace}"
    target_key_id ref(:aws_kms_key, :data_lake_encryption, :key_id)
  end
  
  # S3 bucket encryption for all data lake buckets
  bucket_names = [:raw_data, :processed_data, :curated_data, :analytics_results]
  bucket_names.each do |bucket_name|
    resource :"aws_s3_bucket_server_side_encryption_configuration", bucket_name do
      bucket ref(:"aws_s3_bucket", bucket_name, :id)
      
      rule do
        apply_server_side_encryption_by_default do
          sse_algorithm "aws:kms"
          kms_master_key_id ref(:aws_kms_key, :data_lake_encryption, :arn)
        end
        bucket_key_enabled true
      end
    end
    
    # Block public access
    resource :"aws_s3_bucket_public_access_block", bucket_name do
      bucket ref(:"aws_s3_bucket", bucket_name, :id)
      
      block_public_acls true
      block_public_policy true
      ignore_public_acls true
      restrict_public_buckets true
    end
  end
  
  # S3 lifecycle policies for cost optimization
  resource :aws_s3_bucket_lifecycle_configuration, :raw_data do
    bucket ref(:aws_s3_bucket, :raw_data, :id)
    
    rule do
      id "raw_data_lifecycle"
      status "Enabled"
      
      transition do
        days 30
        storage_class "STANDARD_IA"
      end
      
      transition do
        days 90
        storage_class "GLACIER"
      end
      
      transition do
        days 365
        storage_class "DEEP_ARCHIVE"
      end
      
      expiration do
        days 2555 # 7 years
      end
      
      noncurrent_version_expiration do
        noncurrent_days 90
      end
    end
  end
  
  resource :aws_s3_bucket_lifecycle_configuration, :processed_data do
    bucket ref(:aws_s3_bucket, :processed_data, :id)
    
    rule do
      id "processed_data_lifecycle"
      status "Enabled"
      
      transition do
        days 60
        storage_class "STANDARD_IA"
      end
      
      transition do
        days 180
        storage_class "GLACIER"
      end
      
      expiration do
        days 1825 # 5 years
      end
    end
  end
  
  # Glue Data Catalog database
  glue_database = resource :aws_glue_catalog_database, :main do
    name "data_processing_catalog_#{namespace.gsub('-', '_')}"
    description "Data catalog for data processing pipeline"
    
    create_table_default_permission do
      permissions ["SELECT"]
      principal "arn:aws:iam::#{data(:aws_caller_identity, :current, :account_id)}:root"
    end
  end
  
  # Get current AWS account ID
  data :aws_caller_identity, :current do
  end
  
  # CloudWatch Log Groups for data processing
  resource :aws_cloudwatch_log_group, :glue_jobs do
    name "/aws/glue/jobs/data-processing-#{namespace}"
    retention_in_days 30
    
    tags do
      Name "DataProcessing-Glue-Logs-#{namespace}"
      Purpose "ETLLogging"
    end
  end
  
  resource :aws_cloudwatch_log_group, :lambda_processing do
    name "/aws/lambda/data-processing-#{namespace}"
    retention_in_days 14
    
    tags do
      Name "DataProcessing-Lambda-Logs-#{namespace}"
      Purpose "StreamProcessingLogging"
    end
  end
  
  # VPC for EMR and other resources (optional but recommended)
  vpc = resource :aws_vpc, :data_processing do
    cidr_block "10.1.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "DataProcessing-VPC-#{namespace}"
      Purpose "DataProcessingNetwork"
    end
  end
  
  # Internet Gateway
  igw = resource :aws_internet_gateway, :main do
    vpc_id ref(:aws_vpc, :data_processing, :id)
    
    tags do
      Name "DataProcessing-IGW-#{namespace}"
    end
  end
  
  # Public subnets for NAT gateways
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  availability_zones.each_with_index do |az, index|
    resource :"aws_subnet", :"public_#{index + 1}" do
      vpc_id ref(:aws_vpc, :data_processing, :id)
      cidr_block "10.1.#{index + 1}.0/24"
      availability_zone az
      map_public_ip_on_launch true
      
      tags do
        Name "DataProcessing-Public-#{index + 1}-#{namespace}"
        Type "public"
        AZ az
      end
    end
    
    resource :"aws_subnet", :"private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :data_processing, :id)
      cidr_block "10.1.#{index + 10}.0/24"
      availability_zone az
      
      tags do
        Name "DataProcessing-Private-#{index + 1}-#{namespace}"
        Type "private"
        Purpose "dataprocessing"
        AZ az
      end
    end
  end
  
  # NAT Gateways for outbound internet access
  availability_zones.each_with_index do |az, index|
    resource :"aws_eip", :"nat_#{index + 1}" do
      domain "vpc"
      
      tags do
        Name "DataProcessing-NAT-EIP-#{index + 1}-#{namespace}"
        AZ az
      end
    end
    
    resource :"aws_nat_gateway", :"main_#{index + 1}" do
      allocation_id ref(:"aws_eip", :"nat_#{index + 1}", :id)
      subnet_id ref(:"aws_subnet", :"public_#{index + 1}", :id)
      
      tags do
        Name "DataProcessing-NAT-#{index + 1}-#{namespace}"
        AZ az
      end
    end
  end
  
  # Route tables
  public_rt = resource :aws_route_table, :public do
    vpc_id ref(:aws_vpc, :data_processing, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :main, :id)
    end
    
    tags do
      Name "DataProcessing-Public-RT-#{namespace}"
    end
  end
  
  # Associate public subnets with public route table
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table_association", :"public_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"public_#{index + 1}", :id)
      route_table_id ref(:aws_route_table, :public, :id)
    end
    
    # Private route tables with NAT gateway
    resource :"aws_route_table", :"private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :data_processing, :id)
      
      route do
        cidr_block "0.0.0.0/0"
        nat_gateway_id ref(:"aws_nat_gateway", :"main_#{index + 1}", :id)
      end
      
      tags do
        Name "DataProcessing-Private-RT-#{index + 1}-#{namespace}"
        AZ az
      end
    end
    
    resource :"aws_route_table_association", :"private_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"private_#{index + 1}", :id)
      route_table_id ref(:"aws_route_table", :"private_#{index + 1}", :id)
    end
  end
  
  # Outputs for other templates
  output :raw_data_bucket_name do
    value ref(:aws_s3_bucket, :raw_data, :bucket)
    description "S3 bucket name for raw data"
  end
  
  output :processed_data_bucket_name do
    value ref(:aws_s3_bucket, :processed_data, :bucket)
    description "S3 bucket name for processed data"
  end
  
  output :curated_data_bucket_name do
    value ref(:aws_s3_bucket, :curated_data, :bucket)
    description "S3 bucket name for curated data"
  end
  
  output :analytics_results_bucket_name do
    value ref(:aws_s3_bucket, :analytics_results, :bucket)
    description "S3 bucket name for analytics results"
  end
  
  output :glue_database_name do
    value ref(:aws_glue_catalog_database, :main, :name)
    description "Glue database name"
  end
  
  output :kms_key_id do
    value ref(:aws_kms_key, :data_lake_encryption, :key_id)
    description "KMS key ID for data lake encryption"
  end
  
  output :kms_key_arn do
    value ref(:aws_kms_key, :data_lake_encryption, :arn)
    description "KMS key ARN for data lake encryption"
  end
  
  output :vpc_id do
    value ref(:aws_vpc, :data_processing, :id)
    description "VPC ID for data processing"
  end
  
  output :private_subnet_ids do
    value [
      ref(:aws_subnet, :private_1, :id),
      ref(:aws_subnet, :private_2, :id)
    ]
    description "Private subnet IDs for data processing"
  end
end

# Template 2: Streaming Data Infrastructure
template :streaming_infrastructure do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "DataProcessingPipeline"
        Template "streaming_infrastructure"
      end
    end
  end
  
  # Reference data lake foundation
  data :aws_s3_bucket, :raw_data do
    filter do
      name "tag:Name"
      values ["DataLake-RawData-#{namespace}"]
    end
  end
  
  data :aws_kms_key, :data_lake_encryption do
    filter do
      name "tag:Name"
      values ["DataLake-Encryption-Key-#{namespace}"]
    end
  end
  
  data :aws_glue_catalog_database, :main do
    filter do
      name "tag:Name"
      values ["DataProcessing-Glue-Database-#{namespace}"]
    end
  end
  
  # Kinesis Data Streams for real-time ingestion
  main_stream = resource :aws_kinesis_stream, :main do
    name "data-processing-main-stream-#{namespace}"
    shard_count ENV['KINESIS_SHARD_COUNT']&.to_i || 2
    retention_period 48 # hours
    
    encryption_type "KMS"
    kms_key_id data(:aws_kms_key, :data_lake_encryption, :arn)
    
    stream_mode_details do
      stream_mode namespace == "production" ? "PROVISIONED" : "ON_DEMAND"
    end
    
    tags do
      Name "DataProcessing-MainStream-#{namespace}"
      Purpose "RealTimeIngestion"
    end
  end
  
  # Kinesis Data Analytics application for real-time processing
  analytics_app = resource :aws_kinesisanalyticsv2_application, :realtime_processor do
    name "realtime-data-processor-#{namespace}"
    description "Real-time data processing and enrichment"
    runtime_environment "FLINK-1_15"
    service_execution_role ref(:aws_iam_role, :kinesis_analytics, :arn)
    
    application_configuration do
      application_code_configuration do
        code_content do
          text_content <<~SQL
            CREATE TABLE source_stream (
              event_time TIMESTAMP(3),
              user_id VARCHAR(32),
              event_type VARCHAR(16),
              event_data VARCHAR(1024),
              WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
            ) WITH (
              'connector' = 'kinesis',
              'stream' = '#{ref(:aws_kinesis_stream, :main, :name)}',
              'aws.region' = 'us-east-1',
              'scan.stream.initpos' = 'LATEST',
              'format' = 'json'
            );
            
            CREATE TABLE enriched_events (
              event_time TIMESTAMP(3),
              user_id VARCHAR(32),
              event_type VARCHAR(16),
              event_data VARCHAR(1024),
              processing_time TIMESTAMP(3),
              hour_of_day INT,
              day_of_week INT
            ) WITH (
              'connector' = 'kinesis',
              'stream' = '#{ref(:aws_kinesis_stream, :processed, :name)}',
              'aws.region' = 'us-east-1',
              'format' = 'json'
            );
            
            INSERT INTO enriched_events
            SELECT 
              event_time,
              user_id,
              event_type,
              event_data,
              CURRENT_TIMESTAMP as processing_time,
              EXTRACT(HOUR FROM event_time) as hour_of_day,
              EXTRACT(DOW FROM event_time) as day_of_week
            FROM source_stream;
          SQL
        end
        
        code_content_type "PLAINTEXT"
      end
      
      environment_properties do
        property_group do
          property_group_id "kinesis.analytics.flink.run.options"
          property_map do
            "python.fn-execution.arrow.batch.size" = "1000"
          end
        end
      end
    end
    
    tags do
      Name "DataProcessing-Analytics-App-#{namespace}"
      Purpose "RealTimeAnalytics"
    end
  end
  
  # Processed data stream
  processed_stream = resource :aws_kinesis_stream, :processed do
    name "data-processing-processed-stream-#{namespace}"
    shard_count ENV['KINESIS_SHARD_COUNT']&.to_i || 1
    retention_period 24
    
    encryption_type "KMS"
    kms_key_id data(:aws_kms_key, :data_lake_encryption, :arn)
    
    stream_mode_details do
      stream_mode namespace == "production" ? "PROVISIONED" : "ON_DEMAND"
    end
    
    tags do
      Name "DataProcessing-ProcessedStream-#{namespace}"
      Purpose "ProcessedDataStream"
    end
  end
  
  # IAM role for Kinesis Analytics
  kinesis_analytics_role = resource :aws_iam_role, :kinesis_analytics do
    name_prefix "DataProcessing-KinesisAnalytics-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "kinesisanalytics.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "DataProcessing-KinesisAnalytics-Role-#{namespace}"
      Purpose "StreamAnalytics"
    end
  end
  
  resource :aws_iam_role_policy, :kinesis_analytics do
    name_prefix "DataProcessing-KinesisAnalytics-Policy-"
    role ref(:aws_iam_role, :kinesis_analytics, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "kinesis:DescribeStream",
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:ListShards",
            "kinesis:PutRecord",
            "kinesis:PutRecords"
          ],
          Resource: [
            ref(:aws_kinesis_stream, :main, :arn),
            ref(:aws_kinesis_stream, :processed, :arn)
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource: data(:aws_kms_key, :data_lake_encryption, :arn)
        }
      ]
    })
  end
  
  # Kinesis Data Firehose for data lake ingestion
  firehose_delivery_stream = resource :aws_kinesis_firehose_delivery_stream, :data_lake do
    name "data-lake-delivery-stream-#{namespace}"
    destination "extended_s3"
    
    extended_s3_configuration do
      role_arn ref(:aws_iam_role, :firehose, :arn)
      bucket_arn data(:aws_s3_bucket, :raw_data, :arn)
      prefix "year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
      error_output_prefix "errors/"
      buffer_size 5
      buffer_interval 60
      compression_format "GZIP"
      
      kms_key_arn data(:aws_kms_key, :data_lake_encryption, :arn)
      
      data_format_conversion_configuration do
        enabled true
        output_format_configuration do
          serializer do
            parquet_ser_de do
            end
          end
        end
        
        schema_configuration do
          database_name data(:aws_glue_catalog_database, :main, :name)
          table_name "raw_events"
          role_arn ref(:aws_iam_role, :firehose, :arn)
          version_id "LATEST"
        end
      end
      
      processing_configuration do
        enabled true
        processors do
          type "Lambda"
          parameters do
            parameter_name "LambdaArn"
            parameter_value ref(:aws_lambda_function, :data_transformer, :arn)
          end
        end
      end
      
      cloudwatch_logging_options do
        enabled true
        log_group_name "/aws/kinesisfirehose/data-lake-delivery-#{namespace}"
      end
    end
    
    tags do
      Name "DataProcessing-FirehoseDelivery-#{namespace}"
      Purpose "DataLakeIngestion"
    end
  end
  
  # IAM role for Firehose
  firehose_role = resource :aws_iam_role, :firehose do
    name_prefix "DataProcessing-Firehose-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "firehose.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "DataProcessing-Firehose-Role-#{namespace}"
      Purpose "DataLakeDelivery"
    end
  end
  
  resource :aws_iam_role_policy, :firehose do
    name_prefix "DataProcessing-Firehose-Policy-"
    role ref(:aws_iam_role, :firehose, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          Resource: [
            data(:aws_s3_bucket, :raw_data, :arn),
            "#{data(:aws_s3_bucket, :raw_data, :arn)}/*"
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "glue:GetTable",
            "glue:GetTableVersion",
            "glue:GetTableVersions"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource: data(:aws_kms_key, :data_lake_encryption, :arn)
        },
        {
          Effect: "Allow",
          Action: [
            "lambda:InvokeFunction",
            "lambda:GetFunctionConfiguration"
          ],
          Resource: ref(:aws_lambda_function, :data_transformer, :arn)
        }
      ]
    })
  end
  
  # Lambda function for data transformation
  lambda_function = resource :aws_lambda_function, :data_transformer do
    filename "data_transformer.zip"
    function_name "data-transformer-#{namespace}"
    role ref(:aws_iam_role, :lambda_transformer, :arn)
    handler "index.handler"
    source_code_hash data(:archive_file, :lambda_zip, :output_base64sha256)
    runtime "python3.9"
    timeout 60
    
    environment do
      variables do
        ENVIRONMENT namespace
        LOG_LEVEL namespace == "production" ? "INFO" : "DEBUG"
      end
    end
    
    kms_key_arn data(:aws_kms_key, :data_lake_encryption, :arn)
    
    tags do
      Name "DataProcessing-DataTransformer-#{namespace}"
      Purpose "StreamTransformation"
    end
  end
  
  # Lambda deployment package
  data :archive_file, :lambda_zip do
    type "zip"
    output_path "data_transformer.zip"
    
    source do
      content <<~PYTHON
        import json
        import base64
        import boto3
        from datetime import datetime
        
        def handler(event, context):
            output = []
            
            for record in event['records']:
                # Decode the data
                payload = base64.b64decode(record['data']).decode('utf-8')
                data = json.loads(payload)
                
                # Add processing metadata
                data['processed_at'] = datetime.utcnow().isoformat()
                data['processor'] = 'lambda-transformer'
                
                # Validation and enrichment
                if validate_record(data):
                    enriched_data = enrich_record(data)
                    
                    output_record = {
                        'recordId': record['recordId'],
                        'result': 'Ok',
                        'data': base64.b64encode(
                            json.dumps(enriched_data).encode('utf-8')
                        ).decode('utf-8')
                    }
                else:
                    # Send to error stream
                    output_record = {
                        'recordId': record['recordId'],
                        'result': 'ProcessingFailed'
                    }
                
                output.append(output_record)
            
            return {'records': output}
        
        def validate_record(data):
            required_fields = ['event_time', 'user_id', 'event_type']
            return all(field in data for field in required_fields)
        
        def enrich_record(data):
            # Add derived fields
            if 'event_time' in data:
                dt = datetime.fromisoformat(data['event_time'].replace('Z', '+00:00'))
                data['hour_of_day'] = dt.hour
                data['day_of_week'] = dt.weekday()
            
            return data
      PYTHON
      filename "index.py"
    end
  end
  
  # IAM role for Lambda
  lambda_role = resource :aws_iam_role, :lambda_transformer do
    name_prefix "DataProcessing-LambdaTransformer-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "lambda.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "DataProcessing-LambdaTransformer-Role-#{namespace}"
      Purpose "DataTransformation"
    end
  end
  
  resource :aws_iam_role_policy_attachment, :lambda_basic do
    policy_arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    role ref(:aws_iam_role, :lambda_transformer, :name)
  end
  
  # CloudWatch Log Group for Firehose
  resource :aws_cloudwatch_log_group, :firehose do
    name "/aws/kinesisfirehose/data-lake-delivery-#{namespace}"
    retention_in_days 14
    
    tags do
      Name "DataProcessing-Firehose-Logs-#{namespace}"
      Purpose "FirehoseLogging"
    end
  end
  
  # Outputs
  output :main_stream_name do
    value ref(:aws_kinesis_stream, :main, :name)
    description "Main Kinesis stream name for data ingestion"
  end
  
  output :main_stream_arn do
    value ref(:aws_kinesis_stream, :main, :arn)
    description "Main Kinesis stream ARN"
  end
  
  output :processed_stream_name do
    value ref(:aws_kinesis_stream, :processed, :name)
    description "Processed Kinesis stream name"
  end
  
  output :firehose_delivery_stream_name do
    value ref(:aws_kinesis_firehose_delivery_stream, :data_lake, :name)
    description "Kinesis Data Firehose delivery stream name"
  end
  
  output :analytics_application_name do
    value ref(:aws_kinesisanalyticsv2_application, :realtime_processor, :name)
    description "Kinesis Analytics application name"
  end
end

# Template 3: Batch Processing with EMR and Glue
template :batch_processing do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "DataProcessingPipeline"
        Template "batch_processing"
      end
    end
  end
  
  # Reference data lake foundation
  data :aws_s3_bucket, :raw_data do
    filter do
      name "tag:Name"
      values ["DataLake-RawData-#{namespace}"]
    end
  end
  
  data :aws_s3_bucket, :processed_data do
    filter do
      name "tag:Name"
      values ["DataLake-ProcessedData-#{namespace}"]
    end
  end
  
  data :aws_s3_bucket, :curated_data do
    filter do
      name "tag:Name"
      values ["DataLake-CuratedData-#{namespace}"]
    end
  end
  
  data :aws_glue_catalog_database, :main do
    filter do
      name "tag:Name"
      values ["DataProcessing-Glue-Database-#{namespace}"]
    end
  end
  
  data :aws_kms_key, :data_lake_encryption do
    filter do
      name "tag:Name"
      values ["DataLake-Encryption-Key-#{namespace}"]
    end
  end
  
  data :aws_vpc, :data_processing do
    filter do
      name "tag:Name"
      values ["DataProcessing-VPC-#{namespace}"]
    end
  end
  
  data :aws_subnets, :private do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :data_processing, :id)]
    end
    
    filter do
      name "tag:Purpose"
      values ["dataprocessing"]
    end
  end
  
  # IAM role for Glue jobs
  glue_role = resource :aws_iam_role, :glue do
    name_prefix "DataProcessing-Glue-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "glue.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "DataProcessing-Glue-Role-#{namespace}"
      Purpose "ETLProcessing"
    end
  end
  
  # Attach Glue service role policy
  resource :aws_iam_role_policy_attachment, :glue_service do
    policy_arn "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
    role ref(:aws_iam_role, :glue, :name)
  end
  
  resource :aws_iam_role_policy, :glue_s3_access do
    name_prefix "DataProcessing-Glue-S3-Policy-"
    role ref(:aws_iam_role, :glue, :id)
    
    policy jsonencode({
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
            data(:aws_s3_bucket, :raw_data, :arn),
            "#{data(:aws_s3_bucket, :raw_data, :arn)}/*",
            data(:aws_s3_bucket, :processed_data, :arn),
            "#{data(:aws_s3_bucket, :processed_data, :arn)}/*",
            data(:aws_s3_bucket, :curated_data, :arn),
            "#{data(:aws_s3_bucket, :curated_data, :arn)}/*"
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource: data(:aws_kms_key, :data_lake_encryption, :arn)
        }
      ]
    })
  end
  
  # Glue Crawler to discover schema
  glue_crawler = resource :aws_glue_crawler, :raw_data do
    database_name data(:aws_glue_catalog_database, :main, :name)
    name "raw-data-crawler-#{namespace}"
    role ref(:aws_iam_role, :glue, :arn)
    
    s3_target do
      path "s3://#{data(:aws_s3_bucket, :raw_data, :bucket)}/"
    end
    
    schedule "cron(0 6 * * ? *)" # Daily at 6 AM
    
    configuration jsonencode({
      Version: "1.0",
      CrawlerOutput: {
        Partitions: { AddOrUpdateBehavior: "InheritFromTable" }
      },
      Grouping: {
        TableGroupingPolicy: "CombineCompatibleSchemas"
      }
    })
    
    tags do
      Name "DataProcessing-RawDataCrawler-#{namespace}"
      Purpose "SchemaDiscovery"
    end
  end
  
  # Glue ETL job for data transformation
  etl_job_script = resource :aws_s3_object, :etl_job_script do
    bucket data(:aws_s3_bucket, :processed_data, :bucket)
    key "scripts/etl-job.py"
    content_type "text/plain"
    
    content <<~PYTHON
      import sys
      from awsglue.transforms import *
      from awsglue.utils import getResolvedOptions
      from pyspark.context import SparkContext
      from awsglue.context import GlueContext
      from awsglue.job import Job
      from awsglue.dynamicframe import DynamicFrame
      from pyspark.sql import functions as F
      from pyspark.sql.types import *
      
      args = getResolvedOptions(sys.argv, ['JOB_NAME', 'SOURCE_DATABASE', 'SOURCE_TABLE', 'TARGET_BUCKET'])
      
      sc = SparkContext()
      glueContext = GlueContext(sc)
      spark = glueContext.spark_session
      job = Job(glueContext)
      job.init(args['JOB_NAME'], args)
      
      # Read from catalog
      datasource = glueContext.create_dynamic_frame.from_catalog(
          database = args['SOURCE_DATABASE'],
          table_name = args['SOURCE_TABLE'],
          transformation_ctx = "datasource"
      )
      
      # Convert to DataFrame for easier manipulation
      df = datasource.toDF()
      
      # Data transformations
      transformed_df = df.withColumn("processed_timestamp", F.current_timestamp()) \\
                        .withColumn("event_date", F.to_date("event_time")) \\
                        .withColumn("event_hour", F.hour("event_time")) \\
                        .filter(F.col("user_id").isNotNull()) \\
                        .dropDuplicates(["user_id", "event_time", "event_type"])
      
      # Aggregate by hour
      hourly_aggregates = transformed_df.groupBy("event_date", "event_hour", "event_type") \\
                           .agg(F.count("*").alias("event_count"),
                                F.countDistinct("user_id").alias("unique_users")) \\
                           .orderBy("event_date", "event_hour")
      
      # Convert back to DynamicFrame
      transformed_dynamic_frame = DynamicFrame.fromDF(transformed_df, glueContext, "transformed_dynamic_frame")
      aggregates_dynamic_frame = DynamicFrame.fromDF(hourly_aggregates, glueContext, "aggregates_dynamic_frame")
      
      # Write detailed data to processed zone
      glueContext.write_dynamic_frame.from_options(
          frame = transformed_dynamic_frame,
          connection_type = "s3",
          connection_options = {
              "path": f"s3://{args['TARGET_BUCKET']}/processed/detailed/",
              "partitionKeys": ["event_date"]
          },
          format = "parquet",
          transformation_ctx = "write_processed_data"
      )
      
      # Write aggregates to curated zone  
      glueContext.write_dynamic_frame.from_options(
          frame = aggregates_dynamic_frame,
          connection_type = "s3", 
          connection_options = {
              "path": f"s3://{args['TARGET_BUCKET']}/curated/hourly_aggregates/",
              "partitionKeys": ["event_date"]
          },
          format = "parquet",
          transformation_ctx = "write_curated_data"
      )
      
      job.commit()
    PYTHON
    
    tags do
      Name "DataProcessing-ETL-Script-#{namespace}"
      Purpose "DataTransformation"
    end
  end
  
  # Glue ETL Job
  glue_job = resource :aws_glue_job, :etl do
    name "data-processing-etl-#{namespace}"
    role_arn ref(:aws_iam_role, :glue, :arn)
    glue_version "4.0"
    
    command do
      script_location "s3://#{ref(:aws_s3_object, :etl_job_script, :bucket)}/#{ref(:aws_s3_object, :etl_job_script, :key)}"
      python_version "3"
    end
    
    default_arguments do
      "--job-language" = "python"
      "--enable-metrics" = ""
      "--enable-continuous-cloudwatch-log" = "true"
      "--enable-spark-ui" = "true"
      "--spark-event-logs-path" = "s3://#{data(:aws_s3_bucket, :processed_data, :bucket)}/sparkHistoryLogs/"
      "--SOURCE_DATABASE" = data(:aws_glue_catalog_database, :main, :name)
      "--SOURCE_TABLE" = "raw_events"
      "--TARGET_BUCKET" = data(:aws_s3_bucket, :processed_data, :bucket)
    end
    
    execution_property do
      max_concurrent_runs namespace == "production" ? 3 : 1
    end
    
    max_retries 2
    timeout 60
    
    tags do
      Name "DataProcessing-ETL-Job-#{namespace}"
      Purpose "BatchTransformation"
    end
  end
  
  # EMR Cluster for advanced analytics
  if namespace == "production" || ENV['ENABLE_EMR'] == "true"
    # EMR cluster configuration
    emr_cluster = resource :aws_emr_cluster, :analytics do
      name "data-analytics-cluster-#{namespace}"
      release_label "emr-6.15.0"
      applications ["Spark", "Hive", "Hadoop"]
      
      service_role ref(:aws_iam_role, :emr_service, :arn)
      
      master_instance_group do
        instance_type "m5.xlarge"
        instance_count 1
        
        ebs_config do
          size 100
          type "gp3"
          volumes_per_instance 1
        end
      end
      
      core_instance_group do
        instance_type "m5.xlarge"
        instance_count namespace == "production" ? 3 : 2
        
        ebs_config do
          size 100
          type "gp3"
          volumes_per_instance 2
        end
        
        autoscaling_policy jsonencode({
          Constraints: {
            MinCapacity: 1,
            MaxCapacity: namespace == "production" ? 10 : 5
          },
          Rules: [
            {
              Name: "ScaleOutMemoryPercentage",
              Description: "Scale out if YARNMemoryAvailablePercentage is less than 15",
              Action: {
                SimpleScalingPolicyConfiguration: {
                  AdjustmentType: "CHANGE_IN_CAPACITY",
                  ScalingAdjustment: 1,
                  CoolDown: 300
                }
              },
              Trigger: {
                CloudWatchAlarmDefinition: {
                  ComparisonOperator: "LESS_THAN",
                  EvaluationPeriods: 1,
                  MetricName: "YARNMemoryAvailablePercentage",
                  Namespace: "AWS/ElasticMapReduce",
                  Period: 300,
                  Statistic: "AVERAGE",
                  Threshold: 15,
                  Unit: "PERCENT"
                }
              }
            }
          ]
        })
      end
      
      ec2_attributes do
        key_name ENV['EMR_KEY_PAIR'] if ENV['EMR_KEY_PAIR']
        subnet_id data(:aws_subnets, :private, :ids)[0]
        instance_profile ref(:aws_iam_instance_profile, :emr_instance, :arn)
        service_access_security_group ref(:aws_security_group, :emr_service, :id)
        emr_managed_master_security_group ref(:aws_security_group, :emr_master, :id)
        emr_managed_slave_security_group ref(:aws_security_group, :emr_core, :id)
      end
      
      configurations_json jsonencode([
        {
          Classification: "spark-defaults",
          Properties: {
            "spark.sql.adaptive.enabled": "true",
            "spark.sql.adaptive.coalescePartitions.enabled": "true"
          }
        },
        {
          Classification: "spark-hive-site",
          Properties: {
            "javax.jdo.option.ConnectionURL": "jdbc:mysql://localhost:3306/hive?createDatabaseIfNotExist=true",
            "javax.jdo.option.ConnectionDriverName": "org.mariadb.jdbc.Driver"
          }
        }
      ])
      
      log_uri "s3://#{data(:aws_s3_bucket, :processed_data, :bucket)}/emr-logs/"
      
      tags do
        Name "DataProcessing-EMR-Cluster-#{namespace}"
        Purpose "BigDataAnalytics"
      end
    end
    
    # EMR service role
    emr_service_role = resource :aws_iam_role, :emr_service do
      name_prefix "DataProcessing-EMR-Service-"
      assume_role_policy jsonencode({
        Version: "2012-10-17",
        Statement: [
          {
            Action: "sts:AssumeRole",
            Effect: "Allow",
            Principal: {
              Service: "elasticmapreduce.amazonaws.com"
            }
          }
        ]
      })
      
      tags do
        Name "DataProcessing-EMR-Service-Role-#{namespace}"
        Purpose "EMRService"
      end
    end
    
    resource :aws_iam_role_policy_attachment, :emr_service do
      policy_arn "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
      role ref(:aws_iam_role, :emr_service, :name)
    end
    
    # EMR instance role and profile
    emr_instance_role = resource :aws_iam_role, :emr_instance do
      name_prefix "DataProcessing-EMR-Instance-"
      assume_role_policy jsonencode({
        Version: "2012-10-17",
        Statement: [
          {
            Action: "sts:AssumeRole",
            Effect: "Allow",
            Principal: {
              Service: "ec2.amazonaws.com"
            }
          }
        ]
      })
      
      tags do
        Name "DataProcessing-EMR-Instance-Role-#{namespace}"
        Purpose "EMRInstance"
      end
    end
    
    resource :aws_iam_role_policy_attachment, :emr_instance do
      policy_arn "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
      role ref(:aws_iam_role, :emr_instance, :name)
    end
    
    resource :aws_iam_instance_profile, :emr_instance do
      name_prefix "DataProcessing-EMR-Instance-"
      role ref(:aws_iam_role, :emr_instance, :name)
      
      tags do
        Name "DataProcessing-EMR-Instance-Profile-#{namespace}"
        Purpose "EMRInstance"
      end
    end
    
    # Security groups for EMR
    emr_service_sg = resource :aws_security_group, :emr_service do
      name_prefix "data-processing-emr-service-"
      vpc_id data(:aws_vpc, :data_processing, :id)
      description "EMR service security group"
      
      egress do
        from_port 0
        to_port 0
        protocol "-1"
        cidr_blocks ["0.0.0.0/0"]
        description "All outbound traffic"
      end
      
      tags do
        Name "DataProcessing-EMR-Service-SG-#{namespace}"
        Purpose "EMRService"
      end
    end
    
    emr_master_sg = resource :aws_security_group, :emr_master do
      name_prefix "data-processing-emr-master-"
      vpc_id data(:aws_vpc, :data_processing, :id)
      description "EMR master node security group"
      
      tags do
        Name "DataProcessing-EMR-Master-SG-#{namespace}"
        Purpose "EMRMaster"
      end
    end
    
    emr_core_sg = resource :aws_security_group, :emr_core do
      name_prefix "data-processing-emr-core-"
      vpc_id data(:aws_vpc, :data_processing, :id)
      description "EMR core nodes security group"
      
      tags do
        Name "DataProcessing-EMR-Core-SG-#{namespace}"
        Purpose "EMRCore"
      end
    end
  end
  
  # Step Functions state machine for workflow orchestration
  state_machine = resource :aws_sfn_state_machine, :data_processing_workflow do
    name "data-processing-workflow-#{namespace}"
    role_arn ref(:aws_iam_role, :step_functions, :arn)
    
    definition jsonencode({
      Comment: "Data processing pipeline workflow",
      StartAt: "CrawlRawData",
      States: {
        CrawlRawData: {
          Type: "Task",
          Resource: "arn:aws:states:::aws-sdk:glue:startCrawler",
          Parameters: {
            Name: ref(:aws_glue_crawler, :raw_data, :name)
          },
          Next: "WaitForCrawlerCompletion"
        },
        WaitForCrawlerCompletion: {
          Type: "Wait",
          Seconds: 30,
          Next: "CheckCrawlerStatus"
        },
        CheckCrawlerStatus: {
          Type: "Task",
          Resource: "arn:aws:states:::aws-sdk:glue:getCrawler",
          Parameters: {
            Name: ref(:aws_glue_crawler, :raw_data, :name)
          },
          Next: "IsCrawlerComplete"
        },
        IsCrawlerComplete: {
          Type: "Choice",
          Choices: [
            {
              Variable: "$.Crawler.State",
              StringEquals: "READY",
              Next: "StartETLJob"
            }
          ],
          Default: "WaitForCrawlerCompletion"
        },
        StartETLJob: {
          Type: "Task",
          Resource: "arn:aws:states:::glue:startJobRun.sync",
          Parameters: {
            JobName: ref(:aws_glue_job, :etl, :name)
          },
          End: true
        }
      }
    })
    
    tags do
      Name "DataProcessing-Workflow-#{namespace}"
      Purpose "WorkflowOrchestration"
    end
  end
  
  # IAM role for Step Functions
  step_functions_role = resource :aws_iam_role, :step_functions do
    name_prefix "DataProcessing-StepFunctions-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "states.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "DataProcessing-StepFunctions-Role-#{namespace}"
      Purpose "WorkflowOrchestration"
    end
  end
  
  resource :aws_iam_role_policy, :step_functions do
    name_prefix "DataProcessing-StepFunctions-Policy-"
    role ref(:aws_iam_role, :step_functions, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "glue:StartCrawler",
            "glue:GetCrawler",
            "glue:StartJobRun",
            "glue:GetJobRun",
            "glue:BatchStopJobRun"
          ],
          Resource: "*"
        }
      ]
    })
  end
  
  # CloudWatch Events for scheduled execution
  resource :aws_cloudwatch_event_rule, :daily_processing do
    name "data-processing-daily-#{namespace}"
    description "Trigger daily data processing workflow"
    schedule_expression "cron(0 7 * * ? *)" # Daily at 7 AM
    
    tags do
      Name "DataProcessing-DailyTrigger-#{namespace}"
      Purpose "ScheduledProcessing"
    end
  end
  
  resource :aws_cloudwatch_event_target, :step_functions do
    rule ref(:aws_cloudwatch_event_rule, :daily_processing, :name)
    target_id "StepFunctionsTarget"
    arn ref(:aws_sfn_state_machine, :data_processing_workflow, :arn)
    role_arn ref(:aws_iam_role, :cloudwatch_events, :arn)
  end
  
  # IAM role for CloudWatch Events
  resource :aws_iam_role, :cloudwatch_events do
    name_prefix "DataProcessing-CloudWatchEvents-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "events.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "DataProcessing-CloudWatchEvents-Role-#{namespace}"
      Purpose "ScheduledExecution"
    end
  end
  
  resource :aws_iam_role_policy, :cloudwatch_events do
    name_prefix "DataProcessing-CloudWatchEvents-Policy-"
    role ref(:aws_iam_role, :cloudwatch_events, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "states:StartExecution"
          ],
          Resource: ref(:aws_sfn_state_machine, :data_processing_workflow, :arn)
        }
      ]
    })
  end
  
  # Outputs
  output :glue_job_name do
    value ref(:aws_glue_job, :etl, :name)
    description "Glue ETL job name"
  end
  
  output :glue_crawler_name do
    value ref(:aws_glue_crawler, :raw_data, :name)
    description "Glue crawler name for raw data"
  end
  
  output :step_functions_arn do
    value ref(:aws_sfn_state_machine, :data_processing_workflow, :arn)
    description "Step Functions state machine ARN"
  end
  
  if namespace == "production" || ENV['ENABLE_EMR'] == "true"
    output :emr_cluster_id do
      value ref(:aws_emr_cluster, :analytics, :id)
      description "EMR cluster ID"
    end
  end
end

# This data processing pipeline example demonstrates several key concepts:
#
# 1. **Template Isolation for Data Processing Stages**: Three separate templates for:
#    - Data lake foundation (storage, encryption, networking)
#    - Streaming infrastructure (Kinesis, Lambda, real-time processing)
#    - Batch processing (Glue ETL, EMR, workflow orchestration)
#
# 2. **Comprehensive Data Architecture**: Complete data lake implementation with
#    raw, processed, and curated zones, each with appropriate access controls
#    and lifecycle policies.
#
# 3. **Real-Time and Batch Processing**: Kinesis for streaming data, Kinesis
#    Analytics for real-time processing, Glue for ETL, and EMR for big data analytics.
#
# 4. **Workflow Orchestration**: Step Functions for coordinating complex
#    data processing workflows with error handling and monitoring.
#
# 5. **Data Catalog Integration**: Glue Data Catalog for schema discovery
#    and metadata management across all processing stages.
#
# 6. **Security and Compliance**: KMS encryption throughout, IAM roles with
#    least privilege access, VPC isolation for compute resources.
#
# 7. **Cost Optimization**: S3 lifecycle policies, EMR auto-scaling,
#    environment-specific resource sizing.
#
# Deployment order:
#   pangea apply examples/data-processing-pipeline.rb --template data_lake_foundation
#   pangea apply examples/data-processing-pipeline.rb --template streaming_infrastructure
#   pangea apply examples/data-processing-pipeline.rb --template batch_processing
#
# Environment-specific deployment:
#   export ENABLE_EMR=true
#   export KINESIS_SHARD_COUNT=4
#   pangea apply examples/data-processing-pipeline.rb --namespace production
#
# This example showcases how Pangea's template isolation enables building
# sophisticated data processing pipelines with clear separation between
# real-time and batch processing while maintaining data governance.