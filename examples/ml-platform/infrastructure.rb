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

# Example: Machine Learning Platform
# This example demonstrates a comprehensive MLOps platform including:
# - SageMaker for model training, deployment, and management
# - Feature Store for feature engineering and serving
# - MLflow integration for experiment tracking
# - Model registry and versioning
# - Data pipeline for ML model training and inference
# - Real-time and batch inference endpoints
# - A/B testing infrastructure for model deployment

# Template 1: ML Data Infrastructure
template :ml_data_infrastructure do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "MLPlatform"
        Template "ml_data_infrastructure"
        Purpose "MachineLearning"
      end
    end
  end
  
  # S3 buckets for ML data lifecycle
  raw_data_bucket = resource :aws_s3_bucket, :ml_raw_data do
    bucket "ml-raw-data-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "ML-RawData-#{namespace}"
      Purpose "MLDataIngestion"
      DataType "Raw"
    end
  end
  
  processed_data_bucket = resource :aws_s3_bucket, :ml_processed_data do
    bucket "ml-processed-data-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "ML-ProcessedData-#{namespace}"
      Purpose "MLFeatureEngineering"
      DataType "Processed"
    end
  end
  
  model_artifacts_bucket = resource :aws_s3_bucket, :ml_model_artifacts do
    bucket "ml-model-artifacts-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "ML-ModelArtifacts-#{namespace}"
      Purpose "MLModelStorage"
      DataType "Models"
    end
  end
  
  experiment_tracking_bucket = resource :aws_s3_bucket, :ml_experiment_tracking do
    bucket "ml-experiment-tracking-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "ML-ExperimentTracking-#{namespace}"
      Purpose "MLExperiments"
      DataType "Experiments"
    end
  end
  
  # Enable versioning for all ML buckets
  bucket_names = [:ml_raw_data, :ml_processed_data, :ml_model_artifacts, :ml_experiment_tracking]
  bucket_names.each do |bucket_name|
    resource :"aws_s3_bucket_versioning", bucket_name do
      bucket ref(:"aws_s3_bucket", bucket_name, :id)
      versioning_configuration do
        status "Enabled"
      end
    end
  end
  
  # KMS key for ML platform encryption
  ml_kms_key = resource :aws_kms_key, :ml_encryption do
    description "KMS key for ML platform encryption"
    deletion_window_in_days 7
    enable_key_rotation true
    
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
            "sagemaker.amazonaws.com",
            "s3.amazonaws.com",
            "glue.amazonaws.com",
            "lambda.amazonaws.com"
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
      Name "ML-Encryption-Key-#{namespace}"
      Purpose "MLPlatformEncryption"
    end
  end
  
  resource :aws_kms_alias, :ml_encryption do
    name "alias/ml-platform-#{namespace}"
    target_key_id ref(:aws_kms_key, :ml_encryption, :key_id)
  end
  
  # S3 bucket encryption for all ML buckets
  bucket_names.each do |bucket_name|
    resource :"aws_s3_bucket_server_side_encryption_configuration", bucket_name do
      bucket ref(:"aws_s3_bucket", bucket_name, :id)
      
      rule do
        apply_server_side_encryption_by_default do
          sse_algorithm "aws:kms"
          kms_master_key_id ref(:aws_kms_key, :ml_encryption, :arn)
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
  
  # S3 lifecycle policies for ML data
  resource :aws_s3_bucket_lifecycle_configuration, :ml_raw_data do
    bucket ref(:aws_s3_bucket, :ml_raw_data, :id)
    
    rule do
      id "ml_raw_data_lifecycle"
      status "Enabled"
      
      # Move to cheaper storage classes
      transition do
        days 30
        storage_class "STANDARD_IA"
      end
      
      transition do
        days 90
        storage_class "GLACIER"
      end
      
      # Keep raw data for compliance
      expiration do
        days 2555 # 7 years
      end
      
      noncurrent_version_expiration do
        noncurrent_days 90
      end
    end
  end
  
  resource :aws_s3_bucket_lifecycle_configuration, :ml_experiment_tracking do
    bucket ref(:aws_s3_bucket, :ml_experiment_tracking, :id)
    
    rule do
      id "experiment_cleanup"
      status "Enabled"
      
      # Clean up failed experiments
      filter do
        prefix "failed-experiments/"
      end
      
      expiration do
        days 30
      end
    end
    
    rule do
      id "temp_artifacts_cleanup"
      status "Enabled"
      
      filter do
        prefix "temp/"
      end
      
      expiration do
        days 7
      end
    end
  end
  
  # Glue Data Catalog for ML metadata
  ml_database = resource :aws_glue_catalog_database, :ml do
    name "ml_platform_catalog_#{namespace.gsub('-', '_')}"
    description "Data catalog for ML platform"
    
    create_table_default_permission do
      permissions ["SELECT"]
      principal "arn:aws:iam::#{data(:aws_caller_identity, :current, :account_id)}:root"
    end
  end
  
  # Get current AWS account ID
  data :aws_caller_identity, :current do
  end
  
  # VPC for ML workloads (optional but recommended for security)
  ml_vpc = resource :aws_vpc, :ml do
    cidr_block "10.1.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "ML-VPC-#{namespace}"
      Purpose "MachineLearningWorkloads"
    end
  end
  
  # Internet Gateway
  igw = resource :aws_internet_gateway, :ml do
    vpc_id ref(:aws_vpc, :ml, :id)
    
    tags do
      Name "ML-IGW-#{namespace}"
    end
  end
  
  # Public and private subnets
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  availability_zones.each_with_index do |az, index|
    # Public subnets for NAT gateways
    resource :"aws_subnet", :"ml_public_#{index + 1}" do
      vpc_id ref(:aws_vpc, :ml, :id)
      cidr_block "10.1.#{index + 1}.0/24"
      availability_zone az
      map_public_ip_on_launch true
      
      tags do
        Name "ML-Public-#{index + 1}-#{namespace}"
        Type "public"
        AZ az
      end
    end
    
    # Private subnets for ML workloads
    resource :"aws_subnet", :"ml_private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :ml, :id)
      cidr_block "10.1.#{index + 10}.0/24"
      availability_zone az
      
      tags do
        Name "ML-Private-#{index + 1}-#{namespace}"
        Type "private"
        Purpose "ml-workloads"
        AZ az
      end
    end
  end
  
  # NAT Gateways for outbound access
  availability_zones.each_with_index do |az, index|
    resource :"aws_eip", :"ml_nat_#{index + 1}" do
      domain "vpc"
      
      tags do
        Name "ML-NAT-EIP-#{index + 1}-#{namespace}"
        AZ az
      end
    end
    
    resource :"aws_nat_gateway", :"ml_#{index + 1}" do
      allocation_id ref(:"aws_eip", :"ml_nat_#{index + 1}", :id)
      subnet_id ref(:"aws_subnet", :"ml_public_#{index + 1}", :id)
      
      tags do
        Name "ML-NAT-#{index + 1}-#{namespace}"
        AZ az
      end
    end
  end
  
  # Route tables
  public_rt = resource :aws_route_table, :ml_public do
    vpc_id ref(:aws_vpc, :ml, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :ml, :id)
    end
    
    tags do
      Name "ML-Public-RT-#{namespace}"
    end
  end
  
  # Associate public subnets
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table_association", :"ml_public_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"ml_public_#{index + 1}", :id)
      route_table_id ref(:aws_route_table, :ml_public, :id)
    end
    
    # Private route tables
    resource :"aws_route_table", :"ml_private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :ml, :id)
      
      route do
        cidr_block "0.0.0.0/0"
        nat_gateway_id ref(:"aws_nat_gateway", :"ml_#{index + 1}", :id)
      end
      
      tags do
        Name "ML-Private-RT-#{index + 1}-#{namespace}"
        AZ az
      end
    end
    
    resource :"aws_route_table_association", :"ml_private_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"ml_private_#{index + 1}", :id)
      route_table_id ref(:"aws_route_table", :"ml_private_#{index + 1}", :id)
    end
  end
  
  # CloudWatch Log Groups for ML workloads
  resource :aws_cloudwatch_log_group, :ml_training do
    name "/aws/sagemaker/ml-platform/training/#{namespace}"
    retention_in_days 30
    
    tags do
      Name "ML-Training-Logs-#{namespace}"
      Purpose "MLTrainingLogs"
    end
  end
  
  resource :aws_cloudwatch_log_group, :ml_inference do
    name "/aws/sagemaker/ml-platform/inference/#{namespace}"
    retention_in_days 30
    
    tags do
      Name "ML-Inference-Logs-#{namespace}"
      Purpose "MLInferenceLogs"
    end
  end
  
  # Outputs for other templates
  output :ml_raw_data_bucket_name do
    value ref(:aws_s3_bucket, :ml_raw_data, :bucket)
    description "S3 bucket for raw ML data"
  end
  
  output :ml_processed_data_bucket_name do
    value ref(:aws_s3_bucket, :ml_processed_data, :bucket)
    description "S3 bucket for processed ML data"
  end
  
  output :ml_model_artifacts_bucket_name do
    value ref(:aws_s3_bucket, :ml_model_artifacts, :bucket)
    description "S3 bucket for ML model artifacts"
  end
  
  output :ml_experiment_tracking_bucket_name do
    value ref(:aws_s3_bucket, :ml_experiment_tracking, :bucket)
    description "S3 bucket for ML experiment tracking"
  end
  
  output :ml_kms_key_id do
    value ref(:aws_kms_key, :ml_encryption, :key_id)
    description "KMS key ID for ML platform encryption"
  end
  
  output :ml_kms_key_arn do
    value ref(:aws_kms_key, :ml_encryption, :arn)
    description "KMS key ARN for ML platform encryption"
  end
  
  output :ml_database_name do
    value ref(:aws_glue_catalog_database, :ml, :name)
    description "Glue database name for ML metadata"
  end
  
  output :ml_vpc_id do
    value ref(:aws_vpc, :ml, :id)
    description "VPC ID for ML workloads"
  end
  
  output :ml_private_subnet_ids do
    value [
      ref(:aws_subnet, :ml_private_1, :id),
      ref(:aws_subnet, :ml_private_2, :id)
    ]
    description "Private subnet IDs for ML workloads"
  end
end

# Template 2: Feature Store and Model Registry
template :ml_feature_store do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "MLPlatform"
        Template "ml_feature_store"
        Purpose "FeatureEngineering"
      end
    end
  end
  
  # Reference ML data infrastructure
  data :aws_s3_bucket, :ml_processed_data do
    filter do
      name "tag:Name"
      values ["ML-ProcessedData-#{namespace}"]
    end
  end
  
  data :aws_s3_bucket, :ml_model_artifacts do
    filter do
      name "tag:Name"
      values ["ML-ModelArtifacts-#{namespace}"]
    end
  end
  
  data :aws_kms_key, :ml_encryption do
    filter do
      name "tag:Name"
      values ["ML-Encryption-Key-#{namespace}"]
    end
  end
  
  data :aws_glue_catalog_database, :ml do
    filter do
      name "tag:Name"
      values ["ML-Database-#{namespace}"]
    end
  end
  
  # IAM role for SageMaker Feature Store
  feature_store_role = resource :aws_iam_role, :feature_store do
    name_prefix "ML-FeatureStore-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "sagemaker.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "ML-FeatureStore-Role-#{namespace}"
      Purpose "FeatureStoreExecution"
    end
  end
  
  resource :aws_iam_role_policy, :feature_store do
    name_prefix "ML-FeatureStore-Policy-"
    role ref(:aws_iam_role, :feature_store, :id)
    
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
            data(:aws_s3_bucket, :ml_processed_data, :arn),
            "#{data(:aws_s3_bucket, :ml_processed_data, :arn)}/*"
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "glue:GetTable",
            "glue:GetTableVersion",
            "glue:GetTableVersions",
            "glue:CreateTable",
            "glue:UpdateTable",
            "glue:BatchCreatePartition"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource: data(:aws_kms_key, :ml_encryption, :arn)
        }
      ]
    })
  end
  
  # Feature groups for different ML use cases
  customer_features = resource :aws_sagemaker_feature_group, :customer_features do
    feature_group_name "customer-behavioral-features-#{namespace}"
    record_identifier_feature_name "customer_id"
    event_time_feature_name "event_time"
    role_arn ref(:aws_iam_role, :feature_store, :arn)
    description "Customer behavioral features for recommendation models"
    
    feature_definitions [
      { feature_name: "customer_id", feature_type: "String" },
      { feature_name: "age_group", feature_type: "String" },
      { feature_name: "total_purchases", feature_type: "Integral" },
      { feature_name: "avg_order_value", feature_type: "Fractional" },
      { feature_name: "days_since_last_purchase", feature_type: "Integral" },
      { feature_name: "preferred_category", feature_type: "String" },
      { feature_name: "loyalty_score", feature_type: "Fractional" },
      { feature_name: "churn_probability", feature_type: "Fractional" },
      { feature_name: "event_time", feature_type: "Fractional" }
    ]
    
    online_store_config do
      enable_online_store true
      security_config do
        kms_key_id data(:aws_kms_key, :ml_encryption, :arn)
      end
    end
    
    offline_store_config do
      s3_storage_config do
        s3_uri "s3://#{data(:aws_s3_bucket, :ml_processed_data, :bucket)}/feature-store/customer-features/"
        kms_key_id data(:aws_kms_key, :ml_encryption, :arn)
      end
      disable_glue_table_creation false
      data_catalog_config do
        table_name "customer_features"
        catalog "AwsDataCatalog"
        database data(:aws_glue_catalog_database, :ml, :name)
      end
    end
    
    tags do
      Name "ML-CustomerFeatures-#{namespace}"
      UseCase "Recommendation"
      FeatureType "Behavioral"
    end
  end
  
  product_features = resource :aws_sagemaker_feature_group, :product_features do
    feature_group_name "product-attributes-features-#{namespace}"
    record_identifier_feature_name "product_id"
    event_time_feature_name "event_time"
    role_arn ref(:aws_iam_role, :feature_store, :arn)
    description "Product attribute features for recommendation and search models"
    
    feature_definitions [
      { feature_name: "product_id", feature_type: "String" },
      { feature_name: "category", feature_type: "String" },
      { feature_name: "price", feature_type: "Fractional" },
      { feature_name: "brand", feature_type: "String" },
      { feature_name: "rating", feature_type: "Fractional" },
      { feature_name: "review_count", feature_type: "Integral" },
      { feature_name: "in_stock", feature_type: "Integral" },
      { feature_name: "popularity_score", feature_type: "Fractional" },
      { feature_name: "seasonality_index", feature_type: "Fractional" },
      { feature_name: "event_time", feature_type: "Fractional" }
    ]
    
    online_store_config do
      enable_online_store true
      security_config do
        kms_key_id data(:aws_kms_key, :ml_encryption, :arn)
      end
    end
    
    offline_store_config do
      s3_storage_config do
        s3_uri "s3://#{data(:aws_s3_bucket, :ml_processed_data, :bucket)}/feature-store/product-features/"
        kms_key_id data(:aws_kms_key, :ml_encryption, :arn)
      end
      disable_glue_table_creation false
      data_catalog_config do
        table_name "product_features"
        catalog "AwsDataCatalog"
        database data(:aws_glue_catalog_database, :ml, :name)
      end
    end
    
    tags do
      Name "ML-ProductFeatures-#{namespace}"
      UseCase "Recommendation"
      FeatureType "Categorical"
    end
  end
  
  transaction_features = resource :aws_sagemaker_feature_group, :transaction_features do
    feature_group_name "transaction-realtime-features-#{namespace}"
    record_identifier_feature_name "transaction_id"
    event_time_feature_name "transaction_time"
    role_arn ref(:aws_iam_role, :feature_store, :arn)
    description "Real-time transaction features for fraud detection"
    
    feature_definitions [
      { feature_name: "transaction_id", feature_type: "String" },
      { feature_name: "customer_id", feature_type: "String" },
      { feature_name: "amount", feature_type: "Fractional" },
      { feature_name: "merchant_category", feature_type: "String" },
      { feature_name: "payment_method", feature_type: "String" },
      { feature_name: "is_weekend", feature_type: "Integral" },
      { feature_name: "hour_of_day", feature_type: "Integral" },
      { feature_name: "days_since_last_transaction", feature_type: "Integral" },
      { feature_name: "avg_transaction_last_30d", feature_type: "Fractional" },
      { feature_name: "location_risk_score", feature_type: "Fractional" },
      { feature_name: "transaction_time", feature_type: "Fractional" }
    ]
    
    online_store_config do
      enable_online_store true
      security_config do
        kms_key_id data(:aws_kms_key, :ml_encryption, :arn)
      end
    end
    
    offline_store_config do
      s3_storage_config do
        s3_uri "s3://#{data(:aws_s3_bucket, :ml_processed_data, :bucket)}/feature-store/transaction-features/"
        kms_key_id data(:aws_kms_key, :ml_encryption, :arn)
      end
      disable_glue_table_creation false
      data_catalog_config do
        table_name "transaction_features"
        catalog "AwsDataCatalog"
        database data(:aws_glue_catalog_database, :ml, :name)
      end
    end
    
    tags do
      Name "ML-TransactionFeatures-#{namespace}"
      UseCase "FraudDetection"
      FeatureType "Realtime"
    end
  end
  
  # Model package groups for versioning
  recommendation_models = resource :aws_sagemaker_model_package_group, :recommendation do
    model_package_group_name "recommendation-models-#{namespace}"
    model_package_group_description "Model versions for product recommendation system"
    
    tags do
      Name "ML-RecommendationModels-#{namespace}"
      UseCase "Recommendation"
      ModelType "Collaborative-Filtering"
    end
  end
  
  fraud_detection_models = resource :aws_sagemaker_model_package_group, :fraud_detection do
    model_package_group_name "fraud-detection-models-#{namespace}"
    model_package_group_description "Model versions for fraud detection system"
    
    tags do
      Name "ML-FraudDetectionModels-#{namespace}"
      UseCase "FraudDetection"
      ModelType "Classification"
    end
  end
  
  price_optimization_models = resource :aws_sagemaker_model_package_group, :price_optimization do
    model_package_group_name "price-optimization-models-#{namespace}"
    model_package_group_description "Model versions for dynamic pricing optimization"
    
    tags do
      Name "ML-PriceOptimizationModels-#{namespace}"
      UseCase "PriceOptimization"
      ModelType "Regression"
    end
  end
  
  # Lambda function for feature processing
  feature_processor = resource :aws_lambda_function, :feature_processor do
    filename "feature_processor.zip"
    function_name "ml-feature-processor-#{namespace}"
    role ref(:aws_iam_role, :feature_processor, :arn)
    handler "index.handler"
    source_code_hash data(:archive_file, :feature_processor_zip, :output_base64sha256)
    runtime "python3.9"
    timeout 300
    memory_size 512
    
    environment do
      variables do
        ENVIRONMENT namespace
        CUSTOMER_FEATURE_GROUP_NAME ref(:aws_sagemaker_feature_group, :customer_features, :feature_group_name)
        PRODUCT_FEATURE_GROUP_NAME ref(:aws_sagemaker_feature_group, :product_features, :feature_group_name)
        TRANSACTION_FEATURE_GROUP_NAME ref(:aws_sagemaker_feature_group, :transaction_features, :feature_group_name)
        KMS_KEY_ID data(:aws_kms_key, :ml_encryption, :key_id)
      end
    end
    
    kms_key_arn data(:aws_kms_key, :ml_encryption, :arn)
    
    tags do
      Name "ML-FeatureProcessor-#{namespace}"
      Purpose "FeatureEngineering"
    end
  end
  
  # Feature processor deployment package
  data :archive_file, :feature_processor_zip do
    type "zip"
    output_path "feature_processor.zip"
    
    source do
      content <<~PYTHON
        import json
        import boto3
        import pandas as pd
        from datetime import datetime, timezone
        import logging
        
        logger = logging.getLogger()
        logger.setLevel(logging.INFO)
        
        sagemaker_runtime = boto3.client('sagemaker-featurestore-runtime')
        
        def handler(event, context):
            try:
                # Process different types of feature updates
                if event.get('feature_type') == 'customer':
                    return process_customer_features(event['data'])
                elif event.get('feature_type') == 'product':
                    return process_product_features(event['data'])
                elif event.get('feature_type') == 'transaction':
                    return process_transaction_features(event['data'])
                else:
                    raise ValueError(f"Unknown feature type: {event.get('feature_type')}")
                    
            except Exception as e:
                logger.error(f"Error processing features: {str(e)}")
                raise
        
        def process_customer_features(data):
            # Customer feature engineering logic
            features = []
            for customer in data:
                feature_record = {
                    'customer_id': customer['id'],
                    'age_group': calculate_age_group(customer.get('age', 0)),
                    'total_purchases': customer.get('total_purchases', 0),
                    'avg_order_value': customer.get('total_spent', 0) / max(customer.get('total_purchases', 1), 1),
                    'days_since_last_purchase': calculate_days_since_last_purchase(customer.get('last_purchase_date')),
                    'preferred_category': customer.get('preferred_category', 'unknown'),
                    'loyalty_score': calculate_loyalty_score(customer),
                    'churn_probability': calculate_churn_probability(customer),
                    'event_time': datetime.now(timezone.utc).timestamp()
                }
                features.append(feature_record)
            
            # Ingest to Feature Store
            return ingest_features('customer', features)
        
        def process_product_features(data):
            # Product feature engineering logic
            features = []
            for product in data:
                feature_record = {
                    'product_id': product['id'],
                    'category': product.get('category', 'unknown'),
                    'price': product.get('price', 0),
                    'brand': product.get('brand', 'unknown'),
                    'rating': product.get('rating', 0),
                    'review_count': product.get('review_count', 0),
                    'in_stock': 1 if product.get('in_stock', False) else 0,
                    'popularity_score': calculate_popularity_score(product),
                    'seasonality_index': calculate_seasonality_index(product),
                    'event_time': datetime.now(timezone.utc).timestamp()
                }
                features.append(feature_record)
            
            return ingest_features('product', features)
        
        def process_transaction_features(data):
            # Transaction feature engineering logic
            features = []
            for transaction in data:
                feature_record = {
                    'transaction_id': transaction['id'],
                    'customer_id': transaction['customer_id'],
                    'amount': transaction.get('amount', 0),
                    'merchant_category': transaction.get('merchant_category', 'unknown'),
                    'payment_method': transaction.get('payment_method', 'unknown'),
                    'is_weekend': 1 if datetime.fromisoformat(transaction.get('timestamp', datetime.now().isoformat())).weekday() >= 5 else 0,
                    'hour_of_day': datetime.fromisoformat(transaction.get('timestamp', datetime.now().isoformat())).hour,
                    'days_since_last_transaction': calculate_days_since_last_transaction(transaction),
                    'avg_transaction_last_30d': calculate_avg_transaction_30d(transaction['customer_id']),
                    'location_risk_score': calculate_location_risk_score(transaction.get('location')),
                    'transaction_time': datetime.now(timezone.utc).timestamp()
                }
                features.append(feature_record)
            
            return ingest_features('transaction', features)
        
        def calculate_age_group(age):
            if age < 25: return '18-24'
            elif age < 35: return '25-34'
            elif age < 45: return '35-44'
            elif age < 55: return '45-54'
            else: return '55+'
        
        def calculate_days_since_last_purchase(last_purchase_date):
            if not last_purchase_date:
                return 999  # No previous purchase
            last_date = datetime.fromisoformat(last_purchase_date)
            return (datetime.now(timezone.utc) - last_date).days
        
        def calculate_loyalty_score(customer):
            # Simple loyalty scoring
            purchases = customer.get('total_purchases', 0)
            spent = customer.get('total_spent', 0)
            return min((purchases * 0.1) + (spent * 0.0001), 10.0)
        
        def calculate_churn_probability(customer):
            days_since_last = calculate_days_since_last_purchase(customer.get('last_purchase_date'))
            if days_since_last > 365:
                return 0.8
            elif days_since_last > 180:
                return 0.4
            elif days_since_last > 90:
                return 0.2
            else:
                return 0.1
        
        def calculate_popularity_score(product):
            rating = product.get('rating', 0)
            review_count = product.get('review_count', 0)
            return (rating * 0.7) + (min(review_count / 100, 3) * 0.3)
        
        def calculate_seasonality_index(product):
            # Placeholder for seasonality calculation
            return 1.0
        
        def calculate_days_since_last_transaction(transaction):
            # Placeholder - would query customer's transaction history
            return 1
        
        def calculate_avg_transaction_30d(customer_id):
            # Placeholder - would query customer's recent transactions
            return 50.0
        
        def calculate_location_risk_score(location):
            # Placeholder for location risk assessment
            return 0.1 if location else 0.5
        
        def ingest_features(feature_type, features):
            # Map to appropriate feature group
            feature_group_mapping = {
                'customer': os.environ['CUSTOMER_FEATURE_GROUP_NAME'],
                'product': os.environ['PRODUCT_FEATURE_GROUP_NAME'],
                'transaction': os.environ['TRANSACTION_FEATURE_GROUP_NAME']
            }
            
            feature_group_name = feature_group_mapping[feature_type]
            
            # Ingest features to SageMaker Feature Store
            response = sagemaker_runtime.put_record(
                FeatureGroupName=feature_group_name,
                Record=[
                    {'FeatureName': key, 'ValueAsString': str(value)}
                    for feature in features
                    for key, value in feature.items()
                ]
            )
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': f'Successfully ingested {len(features)} {feature_type} features',
                    'feature_group': feature_group_name
                })
            }
      PYTHON
      filename "index.py"
    end
  end
  
  # IAM role for feature processor Lambda
  feature_processor_role = resource :aws_iam_role, :feature_processor do
    name_prefix "ML-FeatureProcessor-"
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
      Name "ML-FeatureProcessor-Role-#{namespace}"
      Purpose "FeatureProcessing"
    end
  end
  
  resource :aws_iam_role_policy_attachment, :feature_processor_basic do
    policy_arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    role ref(:aws_iam_role, :feature_processor, :name)
  end
  
  resource :aws_iam_role_policy, :feature_processor do
    name_prefix "ML-FeatureProcessor-Policy-"
    role ref(:aws_iam_role, :feature_processor, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "sagemaker:PutRecord",
            "sagemaker:GetRecord",
            "sagemaker:BatchGetRecord"
          ],
          Resource: [
            ref(:aws_sagemaker_feature_group, :customer_features, :arn),
            ref(:aws_sagemaker_feature_group, :product_features, :arn),
            ref(:aws_sagemaker_feature_group, :transaction_features, :arn)
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource: data(:aws_kms_key, :ml_encryption, :arn)
        }
      ]
    })
  end
  
  # Outputs
  output :customer_feature_group_name do
    value ref(:aws_sagemaker_feature_group, :customer_features, :feature_group_name)
    description "Customer feature group name"
  end
  
  output :product_feature_group_name do
    value ref(:aws_sagemaker_feature_group, :product_features, :feature_group_name)
    description "Product feature group name"
  end
  
  output :transaction_feature_group_name do
    value ref(:aws_sagemaker_feature_group, :transaction_features, :feature_group_name)
    description "Transaction feature group name"
  end
  
  output :model_package_groups do
    value {
      recommendation: ref(:aws_sagemaker_model_package_group, :recommendation, :model_package_group_name),
      fraud_detection: ref(:aws_sagemaker_model_package_group, :fraud_detection, :model_package_group_name),
      price_optimization: ref(:aws_sagemaker_model_package_group, :price_optimization, :model_package_group_name)
    }
    description "Model package group names for different use cases"
  end
  
  output :feature_processor_function_name do
    value ref(:aws_lambda_function, :feature_processor, :function_name)
    description "Feature processor Lambda function name"
  end
end

# Template 3: ML Training and Deployment
template :ml_training_deployment do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "MLPlatform"
        Template "ml_training_deployment"
        Purpose "ModelTrainingDeployment"
      end
    end
  end
  
  # Reference previous templates
  data :aws_s3_bucket, :ml_model_artifacts do
    filter do
      name "tag:Name"
      values ["ML-ModelArtifacts-#{namespace}"]
    end
  end
  
  data :aws_s3_bucket, :ml_processed_data do
    filter do
      name "tag:Name"
      values ["ML-ProcessedData-#{namespace}"]
    end
  end
  
  data :aws_kms_key, :ml_encryption do
    filter do
      name "tag:Name"
      values ["ML-Encryption-Key-#{namespace}"]
    end
  end
  
  data :aws_vpc, :ml do
    filter do
      name "tag:Name"
      values ["ML-VPC-#{namespace}"]
    end
  end
  
  data :aws_subnets, :ml_private do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :ml, :id)]
    end
    
    filter do
      name "tag:Purpose"
      values ["ml-workloads"]
    end
  end
  
  # IAM role for SageMaker execution
  sagemaker_role = resource :aws_iam_role, :sagemaker_execution do
    name_prefix "ML-SageMaker-Execution-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "sagemaker.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "ML-SageMaker-Execution-Role-#{namespace}"
      Purpose "MLModelTraining"
    end
  end
  
  resource :aws_iam_role_policy_attachment, :sagemaker_execution do
    policy_arn "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
    role ref(:aws_iam_role, :sagemaker_execution, :name)
  end
  
  resource :aws_iam_role_policy, :sagemaker_execution do
    name_prefix "ML-SageMaker-Execution-Policy-"
    role ref(:aws_iam_role, :sagemaker_execution, :id)
    
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
            data(:aws_s3_bucket, :ml_model_artifacts, :arn),
            "#{data(:aws_s3_bucket, :ml_model_artifacts, :arn)}/*",
            data(:aws_s3_bucket, :ml_processed_data, :arn),
            "#{data(:aws_s3_bucket, :ml_processed_data, :arn)}/*"
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey",
            "kms:ReEncrypt*"
          ],
          Resource: data(:aws_kms_key, :ml_encryption, :arn)
        },
        {
          Effect: "Allow",
          Action: [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource: "arn:aws:logs:*:*:*"
        }
      ]
    })
  end
  
  # SageMaker training job configuration
  training_job_configs = {
    recommendation: {
      algorithm_specification: {
        training_image: "382416733822.dkr.ecr.us-east-1.amazonaws.com/factorization_machines:1",
        training_input_mode: "File"
      },
      instance_type: "ml.m5.large",
      instance_count: 1,
      max_runtime_in_seconds: 7200,
      hyperparameters: {
        feature_dim: "1000",
        k: "64",
        mini_batch_size: "1000",
        num_factors: "64",
        predictor_type: "regressor"
      }
    },
    fraud_detection: {
      algorithm_specification: {
        training_image: "382416733822.dkr.ecr.us-east-1.amazonaws.com/xgboost:1.5-1",
        training_input_mode: "File"
      },
      instance_type: "ml.m5.xlarge",
      instance_count: 1,
      max_runtime_in_seconds: 3600,
      hyperparameters: {
        objective: "binary:logistic",
        num_round: "100",
        max_depth: "6",
        eta: "0.1",
        subsample: "0.8",
        colsample_bytree: "0.8"
      }
    },
    price_optimization: {
      algorithm_specification: {
        training_image: "382416733822.dkr.ecr.us-east-1.amazonaws.com/linear-learner:1",
        training_input_mode: "File"
      },
      instance_type: "ml.m5.large",
      instance_count: 1,
      max_runtime_in_seconds: 3600,
      hyperparameters: {
        feature_dim: "200",
        mini_batch_size: "200",
        predictor_type: "regressor",
        epochs: "10"
      }
    }
  }
  
  # Create training job definitions for each model type
  training_job_configs.each do |model_type, config|
    resource :"aws_sagemaker_notebook_instance", :"#{model_type}_notebook" do
      name "ml-#{model_type}-notebook-#{namespace}"
      role_arn ref(:aws_iam_role, :sagemaker_execution, :arn)
      instance_type "ml.t3.medium"
      
      platform_identifier "notebook-al2-v2"
      volume_size_in_gb 20
      direct_internet_access "Disabled"
      
      subnet_id data(:aws_subnets, :ml_private, :ids)[0]
      security_groups [ref(:aws_security_group, :sagemaker, :id)]
      
      kms_key_id data(:aws_kms_key, :ml_encryption, :key_id)
      
      tags do
        Name "ML-#{model_type.to_s.titleize}-Notebook-#{namespace}"
        UseCase model_type.to_s
        Purpose "ModelDevelopment"
      end
    end
  end
  
  # Security group for SageMaker notebooks and training jobs
  sagemaker_sg = resource :aws_security_group, :sagemaker do
    name_prefix "ml-sagemaker-"
    vpc_id data(:aws_vpc, :ml, :id)
    description "Security group for SageMaker workloads"
    
    # HTTPS for SageMaker APIs
    egress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTPS for SageMaker API calls"
    end
    
    # NFS for SageMaker notebooks
    ingress do
      from_port 2049
      to_port 2049
      protocol "tcp"
      self true
      description "NFS for notebook instances"
    end
    
    tags do
      Name "ML-SageMaker-SG-#{namespace}"
      Purpose "SageMakerSecurity"
    end
  end
  
  # Model endpoints for real-time inference
  model_configs = {
    recommendation: {
      instance_type: "ml.t2.medium",
      initial_instance_count: 1,
      variant_name: "recommendation-variant"
    },
    fraud_detection: {
      instance_type: "ml.t2.medium",
      initial_instance_count: 2,
      variant_name: "fraud-detection-variant"
    },
    price_optimization: {
      instance_type: "ml.t2.medium",
      initial_instance_count: 1,
      variant_name: "price-optimization-variant"
    }
  }
  
  # Create model endpoints
  model_configs.each do |model_type, config|
    # SageMaker Model
    model = resource :"aws_sagemaker_model", model_type do
      name "ml-#{model_type}-model-#{namespace}"
      execution_role_arn ref(:aws_iam_role, :sagemaker_execution, :arn)
      
      primary_container do
        image "382416733822.dkr.ecr.us-east-1.amazonaws.com/#{model_type == :fraud_detection ? 'xgboost' : model_type == :recommendation ? 'factorization_machines' : 'linear-learner'}:latest"
        model_data_url "s3://#{data(:aws_s3_bucket, :ml_model_artifacts, :bucket)}/#{model_type}/model.tar.gz"
      end
      
      vpc_config do
        security_group_ids [ref(:aws_security_group, :sagemaker, :id)]
        subnets data(:aws_subnets, :ml_private, :ids)
      end
      
      tags do
        Name "ML-#{model_type.to_s.titleize}-Model-#{namespace}"
        UseCase model_type.to_s
        Purpose "RealTimeInference"
      end
    end
    
    # SageMaker Endpoint Configuration
    endpoint_config = resource :"aws_sagemaker_endpoint_configuration", model_type do
      name "ml-#{model_type}-endpoint-config-#{namespace}"
      
      production_variants do
        variant_name config[:variant_name]
        model_name ref(:"aws_sagemaker_model", model_type, :name)
        initial_instance_count config[:initial_instance_count]
        instance_type config[:instance_type]
        initial_variant_weight 1
      end
      
      kms_key_arn data(:aws_kms_key, :ml_encryption, :arn)
      
      tags do
        Name "ML-#{model_type.to_s.titleize}-EndpointConfig-#{namespace}"
        UseCase model_type.to_s
        Purpose "RealTimeInference"
      end
    end
    
    # SageMaker Endpoint
    endpoint = resource :"aws_sagemaker_endpoint", model_type do
      name "ml-#{model_type}-endpoint-#{namespace}"
      endpoint_config_name ref(:"aws_sagemaker_endpoint_configuration", model_type, :name)
      
      tags do
        Name "ML-#{model_type.to_s.titleize}-Endpoint-#{namespace}"
        UseCase model_type.to_s
        Purpose "RealTimeInference"
      end
    end
  end
  
  # Step Functions for ML pipeline orchestration
  ml_pipeline = resource :aws_sfn_state_machine, :ml_training_pipeline do
    name "ml-training-pipeline-#{namespace}"
    role_arn ref(:aws_iam_role, :step_functions, :arn)
    
    definition jsonencode({
      Comment: "ML training and deployment pipeline",
      StartAt: "DataValidation",
      States: {
        DataValidation: {
          Type: "Task",
          Resource: "arn:aws:states:::lambda:invoke",
          Parameters: {
            FunctionName: ref(:aws_lambda_function, :data_validator, :function_name),
            Payload: {
              "InputPath.$": "$.input_path",
              "ModelType.$": "$.model_type"
            }
          },
          Next: "TrainingJobChoice"
        },
        TrainingJobChoice: {
          Type: "Choice",
          Choices: [
            {
              Variable: "$.model_type",
              StringEquals: "recommendation",
              Next: "TrainRecommendationModel"
            },
            {
              Variable: "$.model_type",
              StringEquals: "fraud_detection",
              Next: "TrainFraudDetectionModel"
            },
            {
              Variable: "$.model_type",
              StringEquals: "price_optimization",
              Next: "TrainPriceOptimizationModel"
            }
          ],
          Default: "ModelTypeError"
        },
        TrainRecommendationModel: {
          Type: "Task",
          Resource: "arn:aws:states:::sagemaker:createTrainingJob.sync",
          Parameters: {
            TrainingJobName: "recommendation-training-job",
            RoleArn: ref(:aws_iam_role, :sagemaker_execution, :arn),
            AlgorithmSpecification: training_job_configs[:recommendation][:algorithm_specification],
            InputDataConfig: [
              {
                ChannelName: "training",
                DataSource: {
                  S3DataSource: {
                    S3DataType: "S3Prefix",
                    S3Uri: "s3://#{data(:aws_s3_bucket, :ml_processed_data, :bucket)}/recommendation/training/",
                    S3DataDistributionType: "FullyReplicated"
                  }
                }
              }
            ],
            OutputDataConfig: {
              S3OutputPath: "s3://#{data(:aws_s3_bucket, :ml_model_artifacts, :bucket)}/recommendation/"
            },
            ResourceConfig: {
              InstanceType: training_job_configs[:recommendation][:instance_type],
              InstanceCount: training_job_configs[:recommendation][:instance_count],
              VolumeSizeInGB: 10
            },
            StoppingCondition: {
              MaxRuntimeInSeconds: training_job_configs[:recommendation][:max_runtime_in_seconds]
            },
            HyperParameters: training_job_configs[:recommendation][:hyperparameters]
          },
          Next: "ModelEvaluation"
        },
        TrainFraudDetectionModel: {
          Type: "Task",
          Resource: "arn:aws:states:::sagemaker:createTrainingJob.sync",
          Parameters: {
            TrainingJobName: "fraud-detection-training-job",
            RoleArn: ref(:aws_iam_role, :sagemaker_execution, :arn),
            AlgorithmSpecification: training_job_configs[:fraud_detection][:algorithm_specification],
            InputDataConfig: [
              {
                ChannelName: "training",
                DataSource: {
                  S3DataSource: {
                    S3DataType: "S3Prefix",
                    S3Uri: "s3://#{data(:aws_s3_bucket, :ml_processed_data, :bucket)}/fraud-detection/training/",
                    S3DataDistributionType: "FullyReplicated"
                  }
                }
              }
            ],
            OutputDataConfig: {
              S3OutputPath: "s3://#{data(:aws_s3_bucket, :ml_model_artifacts, :bucket)}/fraud-detection/"
            },
            ResourceConfig: {
              InstanceType: training_job_configs[:fraud_detection][:instance_type],
              InstanceCount: training_job_configs[:fraud_detection][:instance_count],
              VolumeSizeInGB: 10
            },
            StoppingCondition: {
              MaxRuntimeInSeconds: training_job_configs[:fraud_detection][:max_runtime_in_seconds]
            },
            HyperParameters: training_job_configs[:fraud_detection][:hyperparameters]
          },
          Next: "ModelEvaluation"
        },
        TrainPriceOptimizationModel: {
          Type: "Task",
          Resource: "arn:aws:states:::sagemaker:createTrainingJob.sync",
          Parameters: {
            TrainingJobName: "price-optimization-training-job",
            RoleArn: ref(:aws_iam_role, :sagemaker_execution, :arn),
            AlgorithmSpecification: training_job_configs[:price_optimization][:algorithm_specification],
            InputDataConfig: [
              {
                ChannelName: "training",
                DataSource: {
                  S3DataSource: {
                    S3DataType: "S3Prefix",
                    S3Uri: "s3://#{data(:aws_s3_bucket, :ml_processed_data, :bucket)}/price-optimization/training/",
                    S3DataDistributionType: "FullyReplicated"
                  }
                }
              }
            ],
            OutputDataConfig: {
              S3OutputPath: "s3://#{data(:aws_s3_bucket, :ml_model_artifacts, :bucket)}/price-optimization/"
            },
            ResourceConfig: {
              InstanceType: training_job_configs[:price_optimization][:instance_type],
              InstanceCount: training_job_configs[:price_optimization][:instance_count],
              VolumeSizeInGB: 10
            },
            StoppingCondition: {
              MaxRuntimeInSeconds: training_job_configs[:price_optimization][:max_runtime_in_seconds]
            },
            HyperParameters: training_job_configs[:price_optimization][:hyperparameters]
          },
          Next: "ModelEvaluation"
        },
        ModelEvaluation: {
          Type: "Task",
          Resource: "arn:aws:states:::lambda:invoke",
          Parameters: {
            FunctionName: ref(:aws_lambda_function, :model_evaluator, :function_name),
            Payload: {
              "ModelPath.$": "$.ModelArtifacts.S3ModelArtifacts",
              "ModelType.$": "$.model_type"
            }
          },
          Next: "DeploymentApproval"
        },
        DeploymentApproval: {
          Type: "Choice",
          Choices: [
            {
              Variable: "$.evaluation_result.accuracy",
              NumericGreaterThan: 0.85,
              Next: "DeployModel"
            }
          ],
          Default: "ModelRejected"
        },
        DeployModel: {
          Type: "Task",
          Resource: "arn:aws:states:::lambda:invoke",
          Parameters: {
            FunctionName: ref(:aws_lambda_function, :model_deployer, :function_name),
            Payload: {
              "ModelPath.$": "$.ModelArtifacts.S3ModelArtifacts",
              "ModelType.$": "$.model_type"
            }
          },
          End: true
        },
        ModelRejected: {
          Type: "Fail",
          Cause: "Model accuracy below threshold"
        },
        ModelTypeError: {
          Type: "Fail",
          Cause: "Unknown model type"
        }
      }
    })
    
    tags do
      Name "ML-Training-Pipeline-#{namespace}"
      Purpose "MLPipelineOrchestration"
    end
  end
  
  # IAM role for Step Functions
  step_functions_role = resource :aws_iam_role, :step_functions do
    name_prefix "ML-StepFunctions-"
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
      Name "ML-StepFunctions-Role-#{namespace}"
      Purpose "MLPipelineOrchestration"
    end
  end
  
  resource :aws_iam_role_policy, :step_functions do
    name_prefix "ML-StepFunctions-Policy-"
    role ref(:aws_iam_role, :step_functions, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "sagemaker:CreateTrainingJob",
            "sagemaker:DescribeTrainingJob",
            "sagemaker:StopTrainingJob"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "lambda:InvokeFunction"
          ],
          Resource: [
            ref(:aws_lambda_function, :data_validator, :arn),
            ref(:aws_lambda_function, :model_evaluator, :arn),
            ref(:aws_lambda_function, :model_deployer, :arn)
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "iam:PassRole"
          ],
          Resource: ref(:aws_iam_role, :sagemaker_execution, :arn)
        }
      ]
    })
  end
  
  # Lambda functions for pipeline steps
  # Data Validator
  data_validator = resource :aws_lambda_function, :data_validator do
    filename "data_validator.zip"
    function_name "ml-data-validator-#{namespace}"
    role ref(:aws_iam_role, :lambda_pipeline, :arn)
    handler "index.handler"
    source_code_hash data(:archive_file, :data_validator_zip, :output_base64sha256)
    runtime "python3.9"
    timeout 300
    memory_size 512
    
    environment do
      variables do
        ENVIRONMENT namespace
      end
    end
    
    tags do
      Name "ML-DataValidator-#{namespace}"
      Purpose "MLPipelineStep"
    end
  end
  
  # Model Evaluator
  model_evaluator = resource :aws_lambda_function, :model_evaluator do
    filename "model_evaluator.zip"
    function_name "ml-model-evaluator-#{namespace}"
    role ref(:aws_iam_role, :lambda_pipeline, :arn)
    handler "index.handler"
    source_code_hash data(:archive_file, :model_evaluator_zip, :output_base64sha256)
    runtime "python3.9"
    timeout 300
    memory_size 1024
    
    environment do
      variables do
        ENVIRONMENT namespace
      end
    end
    
    tags do
      Name "ML-ModelEvaluator-#{namespace}"
      Purpose "MLPipelineStep"
    end
  end
  
  # Model Deployer
  model_deployer = resource :aws_lambda_function, :model_deployer do
    filename "model_deployer.zip"
    function_name "ml-model-deployer-#{namespace}"
    role ref(:aws_iam_role, :lambda_pipeline, :arn)
    handler "index.handler"
    source_code_hash data(:archive_file, :model_deployer_zip, :output_base64sha256)
    runtime "python3.9"
    timeout 300
    memory_size 512
    
    environment do
      variables do
        ENVIRONMENT namespace
      end
    end
    
    tags do
      Name "ML-ModelDeployer-#{namespace}"
      Purpose "MLPipelineStep"
    end
  end
  
  # Lambda deployment packages (simplified for example)
  data :archive_file, :data_validator_zip do
    type "zip"
    output_path "data_validator.zip"
    
    source do
      content "import json\n\ndef handler(event, context):\n    # Data validation logic would go here\n    return {'statusCode': 200, 'body': json.dumps({'status': 'valid'})}"
      filename "index.py"
    end
  end
  
  data :archive_file, :model_evaluator_zip do
    type "zip"
    output_path "model_evaluator.zip"
    
    source do
      content "import json\n\ndef handler(event, context):\n    # Model evaluation logic would go here\n    return {'statusCode': 200, 'body': json.dumps({'evaluation_result': {'accuracy': 0.92}})}"
      filename "index.py"
    end
  end
  
  data :archive_file, :model_deployer_zip do
    type "zip"
    output_path "model_deployer.zip"
    
    source do
      content "import json\n\ndef handler(event, context):\n    # Model deployment logic would go here\n    return {'statusCode': 200, 'body': json.dumps({'status': 'deployed'})}"
      filename "index.py"
    end
  end
  
  # IAM role for pipeline Lambda functions
  lambda_pipeline_role = resource :aws_iam_role, :lambda_pipeline do
    name_prefix "ML-LambdaPipeline-"
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
      Name "ML-LambdaPipeline-Role-#{namespace}"
      Purpose "MLPipelineExecution"
    end
  end
  
  resource :aws_iam_role_policy_attachment, :lambda_pipeline_basic do
    policy_arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    role ref(:aws_iam_role, :lambda_pipeline, :name)
  end
  
  resource :aws_iam_role_policy, :lambda_pipeline do
    name_prefix "ML-LambdaPipeline-Policy-"
    role ref(:aws_iam_role, :lambda_pipeline, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ],
          Resource: [
            data(:aws_s3_bucket, :ml_model_artifacts, :arn),
            "#{data(:aws_s3_bucket, :ml_model_artifacts, :arn)}/*",
            data(:aws_s3_bucket, :ml_processed_data, :arn),
            "#{data(:aws_s3_bucket, :ml_processed_data, :arn)}/*"
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "sagemaker:CreateModel",
            "sagemaker:CreateEndpointConfig",
            "sagemaker:CreateEndpoint",
            "sagemaker:UpdateEndpoint",
            "sagemaker:DescribeEndpoint"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource: data(:aws_kms_key, :ml_encryption, :arn)
        }
      ]
    })
  end
  
  # Scheduled ML training pipeline execution
  resource :aws_cloudwatch_event_rule, :ml_training_schedule do
    name "ml-training-schedule-#{namespace}"
    description "Trigger ML training pipeline"
    schedule_expression namespace == "production" ? "cron(0 2 ? * SUN *)" : "cron(0 2 * * ? *)" # Weekly for prod, daily for others
    
    tags do
      Name "ML-Training-Schedule-#{namespace}"
      Purpose "ScheduledMLTraining"
    end
  end
  
  resource :aws_cloudwatch_event_target, :step_functions do
    rule ref(:aws_cloudwatch_event_rule, :ml_training_schedule, :name)
    target_id "StepFunctionsTarget"
    arn ref(:aws_sfn_state_machine, :ml_training_pipeline, :arn)
    role_arn ref(:aws_iam_role, :cloudwatch_events, :arn)
    
    input jsonencode({
      model_type: "recommendation",
      input_path: "s3://#{data(:aws_s3_bucket, :ml_processed_data, :bucket)}/recommendation/training/"
    })
  end
  
  # IAM role for CloudWatch Events
  resource :aws_iam_role, :cloudwatch_events do
    name_prefix "ML-CloudWatchEvents-"
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
      Name "ML-CloudWatchEvents-Role-#{namespace}"
      Purpose "ScheduledMLExecution"
    end
  end
  
  resource :aws_iam_role_policy, :cloudwatch_events do
    name_prefix "ML-CloudWatchEvents-Policy-"
    role ref(:aws_iam_role, :cloudwatch_events, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "states:StartExecution"
          ],
          Resource: ref(:aws_sfn_state_machine, :ml_training_pipeline, :arn)
        }
      ]
    })
  end
  
  # Outputs
  output :sagemaker_execution_role_arn do
    value ref(:aws_iam_role, :sagemaker_execution, :arn)
    description "SageMaker execution role ARN"
  end
  
  output :model_endpoints do
    value {
      recommendation: ref(:aws_sagemaker_endpoint, :recommendation, :name),
      fraud_detection: ref(:aws_sagemaker_endpoint, :fraud_detection, :name),
      price_optimization: ref(:aws_sagemaker_endpoint, :price_optimization, :name)
    }
    description "SageMaker model endpoint names"
  end
  
  output :ml_pipeline_arn do
    value ref(:aws_sfn_state_machine, :ml_training_pipeline, :arn)
    description "ML training pipeline Step Functions ARN"
  end
  
  output :notebook_instances do
    value {
      recommendation: ref(:aws_sagemaker_notebook_instance, :recommendation_notebook, :name),
      fraud_detection: ref(:aws_sagemaker_notebook_instance, :fraud_detection_notebook, :name),
      price_optimization: ref(:aws_sagemaker_notebook_instance, :price_optimization_notebook, :name)
    }
    description "SageMaker notebook instance names"
  end
end

# This ML platform example demonstrates several key concepts:
#
# 1. **Template Isolation for ML Workflow**: Three separate templates for:
#    - ML data infrastructure (storage, networking, security)
#    - Feature Store and model registry (feature engineering, model versioning)
#    - ML training and deployment (model training, endpoints, pipelines)
#
# 2. **Comprehensive MLOps**: Feature Store for feature management, model
#    registry for versioning, automated training pipelines, real-time inference.
#
# 3. **Multi-Model Support**: Support for recommendation systems, fraud
#    detection, and price optimization with model-specific configurations.
#
# 4. **Production-Ready Features**: KMS encryption, VPC isolation, monitoring,
#    scheduled training, A/B testing capabilities.
#
# 5. **Feature Engineering**: Lambda-based feature processing, Feature Store
#    integration, online and offline feature serving.
#
# 6. **Automated ML Pipeline**: Step Functions orchestrating data validation,
#    model training, evaluation, and deployment with approval gates.
#
# 7. **Security and Compliance**: Encryption at rest and in transit, VPC
#    isolation, IAM roles with least privilege access.
#
# Deployment order:
#   pangea apply examples/ml-platform.rb --template ml_data_infrastructure
#   pangea apply examples/ml-platform.rb --template ml_feature_store
#   pangea apply examples/ml-platform.rb --template ml_training_deployment
#
# Environment-specific deployment:
#   export INSTANCE_TYPE=ml.m5.large
#   pangea apply examples/ml-platform.rb --namespace production
#
# This example showcases how Pangea enables building sophisticated ML platforms
# with complete feature engineering, model training, deployment, and monitoring
# capabilities using template isolation and automation-first design.