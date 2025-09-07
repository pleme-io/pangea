# Sustainable ML Training Component

Eco-friendly machine learning training infrastructure that reduces carbon footprint through intelligent scheduling, efficient architectures, and optimized resource utilization while maintaining model performance.

## Overview

The Sustainable ML Training component transforms traditional ML training into an environmentally conscious process. By combining carbon-aware scheduling, mixed precision training, model compression, and efficient hardware utilization, it reduces energy consumption by up to 70% and carbon emissions by up to 85% compared to standard training approaches.

## Key Features

- **Carbon-Aware Scheduling**: Trains models when renewable energy is abundant
- **Efficient Architectures**: Automatic mixed precision, quantization, and pruning
- **Spot Instance Integration**: Uses excess capacity for cost and carbon savings
- **Model Compression**: Reduces model size by up to 90% with minimal accuracy loss
- **Multi-Region Training**: Follows renewable energy across regions
- **Early Stopping**: Prevents wasteful overtraining
- **Energy Monitoring**: Real-time tracking of power consumption and emissions
- **Experiment Tracking**: Comprehensive metrics for sustainability reporting

## Usage

```ruby
ml_training = Pangea::Components::SustainableMLTraining.build(
  name: "bert-sustainable-training",
  model_type: "natural_language",
  s3_bucket_name: "my-ml-training-data",
  
  # Training configuration
  dataset_size_gb: 50.0,
  estimated_training_hours: 12.0,
  checkpoint_frequency_minutes: 30,
  
  # Sustainability settings
  training_strategy: "carbon_aware_scheduling",
  compute_optimization: "mixed_precision",
  enable_model_compression: true,
  target_model_size_reduction: 0.7,
  
  # Carbon optimization
  carbon_intensity_threshold: 100,
  preferred_training_regions: [
    "us-west-2",    # Oregon - renewable
    "eu-north-1",   # Stockholm - renewable
    "ca-central-1"  # Montreal - hydro
  ],
  
  # Instance configuration
  instance_priority: "carbon_optimized",
  preferred_instance_types: [
    "ml.p4d.24xlarge",   # A100 - most efficient
    "ml.g5.48xlarge",    # A10G - balanced
    "ml.trn1.32xlarge"   # Trainium - AWS chips
  ],
  use_spot_instances: true,
  
  # Monitoring
  track_carbon_emissions: true,
  track_energy_usage: true,
  enable_experiment_tracking: true,
  
  tags: {
    "Project" => "nlp-research",
    "Sustainability" => "optimized"
  }
)

# Access outputs
puts ml_training.training_job_name
puts ml_training.dashboard_url
puts ml_training.model_artifacts_location
```

## Training Strategies

### Carbon-Aware Scheduling
Schedules training during periods of low grid carbon intensity.

```ruby
training_strategy: "carbon_aware_scheduling"
carbon_intensity_threshold: 150  # gCO2/kWh
```

### Efficient Architecture
Uses model architectures optimized for performance per watt.

```ruby
training_strategy: "efficient_architecture"
# Automatically selects EfficientNet, MobileNet, DistilBERT, etc.
```

### Mixed Precision Training
Reduces compute by 40% using FP16/BF16 with minimal accuracy impact.

```ruby
training_strategy: "mixed_precision"
enable_automatic_mixed_precision: true
```

### Gradient Checkpointing
Trades compute for memory, enabling larger batch sizes.

```ruby
training_strategy: "gradient_checkpointing"
enable_gradient_accumulation: true
```

### Federated Learning
Distributes training across multiple low-carbon regions.

```ruby
training_strategy: "federated_learning"
enable_cross_region_training: true
```

## Model Types and Optimizations

### Computer Vision
```ruby
cv_training = Pangea::Components::SustainableMLTraining.build(
  name: "efficientnet-training",
  model_type: "computer_vision",
  dataset_size_gb: 100.0,
  
  # Vision-specific optimizations
  compute_optimization: "mixed_precision",
  enable_data_augmentation: true,
  cache_dataset_in_memory: true,
  
  # Prefer GPUs optimized for convolutions
  preferred_instance_types: ["ml.p4d.24xlarge", "ml.g5.48xlarge"]
)
```

### Natural Language Processing
```ruby
nlp_training = Pangea::Components::SustainableMLTraining.build(
  name: "distilbert-training",
  model_type: "natural_language",
  dataset_size_gb: 200.0,
  
  # NLP-specific optimizations
  compute_optimization: "distillation",
  enable_model_compression: true,
  target_model_size_reduction: 0.6,
  
  # Sequence length optimization
  enable_gradient_accumulation: true
)
```

### Generative AI
```ruby
genai_training = Pangea::Components::SustainableMLTraining.build(
  name: "gpt-sustainable",
  model_type: "generative_ai",
  dataset_size_gb: 500.0,
  estimated_training_hours: 168.0,  # 7 days
  
  # GenAI optimizations
  compute_optimization: "pruning",
  enable_early_stopping: true,
  early_stopping_patience: 10,
  
  # Distributed training
  preferred_instance_types: ["ml.p4d.24xlarge"],
  use_fsx_lustre: true  # High-performance storage
)
```

## Compute Optimizations

### Mixed Precision
- **Benefit**: 40% reduction in compute and memory
- **Impact**: <1% accuracy loss
- **Best for**: Most model types

### Quantization
- **Benefit**: 75% model size reduction
- **Impact**: 1-2% accuracy loss
- **Best for**: Inference optimization

### Pruning
- **Benefit**: 50-90% parameter reduction
- **Impact**: 2-3% accuracy loss
- **Best for**: Large overparameterized models

### Distillation
- **Benefit**: 90% size reduction with student models
- **Impact**: 3-5% accuracy loss
- **Best for**: Deploying smaller models

### Neural Architecture Search
- **Benefit**: Finds optimal efficient architectures
- **Impact**: Can match original accuracy
- **Best for**: New model development

## Instance Selection Strategy

### GPU Efficiency Ratings

| GPU Type | Performance/Watt | Best Use Case |
|----------|------------------|---------------|
| H100 | 1.2x | Large language models |
| A100 | 1.0x (baseline) | General training |
| A10G | 0.8x | Balanced performance/cost |
| T4 | 0.7x | Inference, small models |
| V100 | 0.6x | Legacy workloads |
| Trainium | 1.1x | AWS-optimized models |

### Instance Priority Modes

**GPU Efficient** (Default for large models):
```ruby
instance_priority: "gpu_efficient"
# Prioritizes A100/H100 instances
```

**Cost Optimized** (For budget-conscious):
```ruby
instance_priority: "cost_optimized"
# Uses older GPUs and spot instances
```

**Carbon Optimized** (Maximum sustainability):
```ruby
instance_priority: "carbon_optimized"
# Graviton and renewable regions only
```

## Monitoring and Metrics

### Carbon Tracking
- Real-time carbon intensity (gCO2/kWh)
- Total emissions (kgCO2e)
- Carbon per million parameters
- Regional renewable percentage

### Energy Monitoring
- Power consumption (Watts)
- Energy usage (kWh)
- Performance per watt
- Efficiency vs baseline

### Training Metrics
- GPU/CPU utilization
- Memory usage
- Training/validation loss
- Model size and compression

### Efficiency Scores
- Overall efficiency rating (0-100)
- Bottleneck identification
- Optimization recommendations
- Cost savings achieved

## Example: Sustainable BERT Training

```ruby
bert_training = Pangea::Components::SustainableMLTraining.build(
  name: "bert-base-sustainable",
  model_type: "natural_language",
  s3_bucket_name: "bert-training-data",
  dataset_size_gb: 16.0,  # Wikipedia + BookCorpus
  estimated_training_hours: 96.0,  # 4 days
  
  # Aggressive sustainability settings
  training_strategy: "carbon_aware_scheduling",
  carbon_intensity_threshold: 50,  # Very low threshold
  preferred_training_regions: ["ca-central-1", "eu-north-1"],
  
  # Efficiency optimizations
  compute_optimization: "mixed_precision",
  enable_automatic_mixed_precision: true,
  enable_gradient_accumulation: true,
  
  # Model compression
  enable_model_compression: true,
  target_model_size_reduction: 0.5,  # DistilBERT-like
  
  # Early stopping to prevent overtraining
  enable_early_stopping: true,
  early_stopping_patience: 5,
  
  # Maximum spot savings
  use_spot_instances: true,
  spot_interruption_behavior: "checkpoint",
  max_spot_price_percentage: 70
)
```

## Best Practices

1. **Profile First**: Run small experiments to understand resource needs
2. **Start with Mixed Precision**: Easy 40% efficiency gain
3. **Use Gradient Accumulation**: Simulate larger batches efficiently
4. **Enable Checkpointing**: Protect against spot interruptions
5. **Monitor Carbon Metrics**: Track and report sustainability impact
6. **Compress Post-Training**: Further reduce deployment footprint
7. **Share Models**: Avoid redundant training through model registries

## Integration with MLOps

### SageMaker Pipelines Integration
```ruby
# Add to existing pipeline
pipeline.add_step(
  ml_training.training_job,
  depends_on: ["data-preprocessing"]
)
```

### Model Registry
```ruby
# Register compressed model
model = aws_sagemaker_model(:sustainable_model, {
  execution_role_arn: ml_training.sagemaker_role.arn,
  primary_container: {
    image: ml_training.training_job.algorithm_specification.training_image,
    model_data_url: "#{ml_training.model_artifacts_location}/compressed/model.tar.gz"
  }
})
```

## Sustainability Reporting

The component automatically generates sustainability reports including:

- Total carbon emissions (kgCO2e)
- Energy consumption (kWh)
- Renewable energy usage (%)
- Efficiency improvements vs baseline
- Cost savings achieved
- Model compression ratios

Access reports via CloudWatch dashboard or export to S3:
```ruby
report_location = "s3://#{ml_training.s3_bucket.bucket}/sustainability-reports/"
```

## Troubleshooting

### Training Job Fails to Start
- Verify S3 bucket permissions
- Check instance availability in preferred regions
- Ensure carbon threshold isn't too restrictive

### Low GPU Utilization
- Increase batch size
- Enable gradient accumulation
- Check data pipeline bottlenecks
- Consider mixed precision training

### Model Accuracy Degradation
- Reduce compression target
- Adjust early stopping patience
- Fine-tune after compression
- Try different optimization techniques

### High Carbon Emissions
- Lower carbon intensity threshold
- Add more renewable regions
- Schedule during off-peak hours
- Consider smaller model architectures