# Machine Learning Platform Infrastructure

This example demonstrates a comprehensive MLOps platform using Pangea, featuring model training, deployment, monitoring, and management capabilities with AWS SageMaker and supporting services.

## Overview

The ML platform includes:

- **Model Development**: SageMaker notebooks and training infrastructure
- **Feature Store**: Centralized feature engineering and serving
- **Experiment Tracking**: MLflow integration for experiment management
- **Model Registry**: Version control and model lifecycle management
- **Training Pipeline**: Automated model training with hyperparameter tuning
- **Inference Infrastructure**: Real-time and batch prediction endpoints
- **A/B Testing**: Model deployment with traffic splitting
- **Monitoring**: Model performance and data drift detection

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Data Sources                                  │
│              (S3, Databases, Streaming, APIs)                       │
└────────────────────┬───────────────────────────┬────────────────────┘
                     │                           │
         ┌───────────▼────────────┐   ┌─────────▼────────────┐
         │   Data Processing      │   │   Feature Store       │
         │  (Glue ETL, EMR)      │   │   (SageMaker FS)      │
         └───────────┬────────────┘   └─────────┬────────────┘
                     │                           │
                     └───────────┬───────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   ML Development        │
                    │  ┌─────────────────┐   │
                    │  │ SageMaker       │   │
                    │  │ Notebooks       │   │
                    │  └────────┬────────┘   │
                    │           │            │
                    │  ┌────────▼────────┐   │
                    │  │ Experiment      │   │
                    │  │ Tracking        │   │
                    │  │ (MLflow)        │   │
                    │  └─────────────────┘   │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Model Training        │
                    │  ┌─────────────────┐   │
                    │  │ Training Jobs   │   │
                    │  │ (SageMaker)     │   │
                    │  └────────┬────────┘   │
                    │           │            │
                    │  ┌────────▼────────┐   │
                    │  │ Hyperparameter  │   │
                    │  │ Tuning          │   │
                    │  └─────────────────┘   │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Model Registry        │
                    │  (Version Control)      │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────────────────┐
                    │        Model Deployment              │
                    │  ┌─────────────┐  ┌──────────────┐  │
                    │  │ Real-time   │  │    Batch     │  │
                    │  │ Endpoints   │  │  Transform   │  │
                    │  └──────┬──────┘  └──────┬───────┘  │
                    │         │                 │          │
                    │  ┌──────▼─────────────────▼──────┐  │
                    │  │    A/B Testing & Routing      │  │
                    │  └────────────────────────────────┘  │
                    └──────────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Model Monitoring      │
                    │  - Performance Metrics  │
                    │  - Data Drift Detection │
                    │  - Explainability      │
                    └──────────────────────────┘
```

## Templates

### 1. ML Data Infrastructure (`ml_data_infrastructure`)

Core data layer for ML platform:
- S3 buckets for data lifecycle (raw, processed, models, experiments)
- Data encryption with KMS
- VPC for secure ML workloads
- Glue Data Catalog for metadata
- CloudWatch log groups

### 2. Feature Store (`ml_feature_store`)

Feature engineering and serving:
- SageMaker Feature Store groups
- Online and offline feature storage
- Feature transformation pipelines
- Feature versioning
- Access control and monitoring

### 3. Training Infrastructure (`ml_training_infrastructure`)

Model development and training:
- SageMaker notebook instances
- Training job configurations
- Hyperparameter tuning
- Distributed training support
- GPU instance management
- MLflow integration

### 4. Model Serving (`ml_model_serving`)

Model deployment and inference:
- Real-time endpoints with auto-scaling
- Batch transform jobs
- Multi-model endpoints
- A/B testing infrastructure
- Model monitoring
- API Gateway integration

## Deployment

### Prerequisites

1. AWS account with SageMaker access
2. S3 buckets for state management
3. Domain for model serving endpoints (optional)

### Development Environment

```bash
# Deploy all ML infrastructure
pangea apply infrastructure.rb

# Deploy individual components
pangea apply infrastructure.rb --template ml_data_infrastructure
pangea apply infrastructure.rb --template ml_feature_store
pangea apply infrastructure.rb --template ml_training_infrastructure
pangea apply infrastructure.rb --template ml_model_serving
```

### Production Environment

```bash
# Set production variables
export SAGEMAKER_INSTANCE_TYPE=ml.p3.2xlarge
export ENDPOINT_INSTANCE_TYPE=ml.m5.xlarge
export ENABLE_MODEL_MONITORING=true

# Deploy with approval
pangea apply infrastructure.rb --namespace production --no-auto-approve
```

## ML Workflows

### 1. Feature Engineering

```python
# Create feature group
import sagemaker
from sagemaker.feature_store.feature_group import FeatureGroup

feature_group = FeatureGroup(
    name="customer-features",
    sagemaker_session=sagemaker.Session()
)

# Define features
feature_group.feature_definitions = [
    {"FeatureName": "customer_id", "FeatureType": "String"},
    {"FeatureName": "age", "FeatureType": "Integral"},
    {"FeatureName": "purchase_history", "FeatureType": "Fractional"},
    {"FeatureName": "churn_score", "FeatureType": "Fractional"}
]

# Create feature group
feature_group.create(
    s3_uri=f"s3://{processed_data_bucket}/feature-store/",
    record_identifier_name="customer_id",
    event_time_feature_name="event_time",
    role_arn=feature_store_role_arn,
    enable_online_store=True
)
```

### 2. Model Training

```python
# SageMaker training job
from sagemaker.estimator import Estimator

estimator = Estimator(
    image_uri="your-ecr-repo/ml-algorithm:latest",
    instance_type="ml.p3.2xlarge",
    instance_count=1,
    role=sagemaker_role,
    output_path=f"s3://{model_artifacts_bucket}/models/",
    base_job_name="customer-churn-model"
)

# Hyperparameter tuning
from sagemaker.tuner import HyperparameterTuner

tuner = HyperparameterTuner(
    estimator,
    objective_metric_name="validation:auc",
    objective_type="Maximize",
    hyperparameter_ranges={
        "learning_rate": ContinuousParameter(0.001, 0.1),
        "batch_size": CategoricalParameter([32, 64, 128]),
        "epochs": IntegerParameter(10, 50)
    },
    max_jobs=20,
    max_parallel_jobs=4
)

tuner.fit({"train": train_data, "validation": val_data})
```

### 3. Model Deployment

```python
# Deploy model with A/B testing
from sagemaker.model import Model

# Primary model
primary_model = Model(
    model_data=f"s3://{model_artifacts_bucket}/models/v1/model.tar.gz",
    image_uri="your-ecr-repo/inference:latest",
    role=sagemaker_role
)

# Challenger model
challenger_model = Model(
    model_data=f"s3://{model_artifacts_bucket}/models/v2/model.tar.gz",
    image_uri="your-ecr-repo/inference:latest",
    role=sagemaker_role
)

# Create endpoint with traffic splitting
from sagemaker.endpoint_configuration import EndpointConfiguration

endpoint_config = EndpointConfiguration(
    name="customer-churn-endpoint-config",
    production_variants=[
        {
            "ModelName": primary_model.name,
            "VariantName": "primary",
            "InstanceType": "ml.m5.xlarge",
            "InitialInstanceCount": 2,
            "InitialVariantWeight": 0.8  # 80% traffic
        },
        {
            "ModelName": challenger_model.name,
            "VariantName": "challenger",
            "InstanceType": "ml.m5.xlarge",
            "InitialInstanceCount": 1,
            "InitialVariantWeight": 0.2  # 20% traffic
        }
    ]
)
```

### 4. Model Monitoring

```python
# Enable model monitoring
from sagemaker.model_monitor import DataCaptureConfig

data_capture_config = DataCaptureConfig(
    enable_capture=True,
    sampling_percentage=100,
    destination_s3_uri=f"s3://{model_artifacts_bucket}/monitoring/"
)

# Create monitoring schedule
from sagemaker.model_monitor import DefaultModelMonitor

monitor = DefaultModelMonitor(
    role=sagemaker_role,
    instance_count=1,
    instance_type="ml.m5.xlarge",
    volume_size_in_gb=20,
    max_runtime_in_seconds=3600
)

monitor.create_monitoring_schedule(
    monitor_schedule_name="customer-churn-monitor",
    endpoint_input=endpoint.name,
    statistics=baseline_statistics,
    constraints=baseline_constraints,
    schedule_cron_expression="cron(0 * * * ? *)"  # Hourly
)
```

## MLflow Integration

### Experiment Tracking

```python
import mlflow
import mlflow.sagemaker

# Set tracking URI
mlflow.set_tracking_uri(f"s3://{experiment_tracking_bucket}/mlflow")

# Start experiment
mlflow.set_experiment("customer-churn-prediction")

with mlflow.start_run():
    # Log parameters
    mlflow.log_param("learning_rate", 0.01)
    mlflow.log_param("batch_size", 64)
    
    # Train model
    model = train_model(params)
    
    # Log metrics
    mlflow.log_metric("auc", 0.85)
    mlflow.log_metric("accuracy", 0.92)
    
    # Log model
    mlflow.sagemaker.log_model(
        model,
        "model",
        registered_model_name="customer-churn-model"
    )
```

## Best Practices

### 1. Data Management
- Partition data by date for efficient processing
- Use Parquet format for better compression
- Implement data validation pipelines
- Version control training datasets

### 2. Model Development
- Use notebooks for experimentation
- Commit code to version control
- Document model assumptions
- Track all experiments

### 3. Training Optimization
- Use spot instances for cost savings
- Implement checkpointing for long runs
- Optimize hyperparameter search space
- Use distributed training for large datasets

### 4. Deployment Strategy
- Start with shadow deployments
- Implement gradual rollout
- Monitor model performance
- Set up automated rollback

### 5. Security
- Encrypt data at rest and in transit
- Use VPC endpoints for API calls
- Implement least privilege IAM
- Audit model access

## Cost Optimization

### Training Costs
- **Spot Instances**: Save up to 90% on training
- **Reserved Instances**: Save 30-50% on inference
- **Auto-scaling**: Scale down during low usage
- **Model Optimization**: Quantize models for smaller size

### Storage Costs
- **Lifecycle Policies**: Archive old experiments
- **Data Deduplication**: Remove duplicate datasets
- **Compression**: Use Parquet and gzip
- **Cleanup Jobs**: Delete failed experiments

## Monitoring and Alerts

### Key Metrics
1. **Model Performance**
   - Accuracy, Precision, Recall
   - AUC-ROC for classification
   - RMSE for regression

2. **Data Quality**
   - Missing value rates
   - Distribution shifts
   - Outlier detection

3. **Infrastructure**
   - Endpoint latency
   - Request errors
   - Instance utilization

### Alerting
```bash
# Create CloudWatch alarm for model accuracy
aws cloudwatch put-metric-alarm \
  --alarm-name "ml-model-accuracy-low" \
  --alarm-description "Model accuracy below threshold" \
  --metric-name "ModelAccuracy" \
  --namespace "ML/Models" \
  --statistic Average \
  --period 3600 \
  --threshold 0.8 \
  --comparison-operator LessThanThreshold \
  --evaluation-periods 2
```

## Troubleshooting

### Common Issues

1. **Training Failures**
   - Check CloudWatch logs
   - Verify data access permissions
   - Validate input data format

2. **Endpoint Errors**
   - Review endpoint logs
   - Check model artifacts
   - Verify instance health

3. **Performance Degradation**
   - Analyze data drift reports
   - Review feature distributions
   - Check for concept drift

## Clean Up

Remove ML infrastructure in reverse order:

```bash
# Remove model serving
pangea destroy infrastructure.rb --template ml_model_serving

# Remove training infrastructure
pangea destroy infrastructure.rb --template ml_training_infrastructure

# Remove feature store
pangea destroy infrastructure.rb --template ml_feature_store

# Remove data infrastructure
pangea destroy infrastructure.rb --template ml_data_infrastructure
```

## Next Steps

1. Integrate with CI/CD for model deployment
2. Implement automated retraining pipelines
3. Add explainability features
4. Set up multi-region deployment
5. Implement federated learning