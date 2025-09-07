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


# Example: Advanced ML and Healthcare Infrastructure
# This example demonstrates the newly implemented AWS resources for healthcare,
# machine learning, and advanced analytics use cases.

require 'pangea'

# Healthcare Data Management with FHIR
template :healthcare_data_platform do
  provider :aws do
    region "us-east-1"
  end

  # FHIR Datastore for clinical data
  clinical_datastore = aws_healthlake_fhir_datastore(:clinical_fhir_store, {
    datastore_name: "clinical-patient-data",
    datastore_type_version: "R4",
    description: "Primary datastore for patient clinical records",
    sse_configuration: {
      kms_encryption_config: {
        cmk_type: "CUSTOMER_MANAGED_KMS_KEY",
        kms_key_id: ref(:aws_kms_key, :healthcare_encryption, :arn)
      }
    },
    identity_provider_configuration: {
      authorization_strategy: "SMART_ON_FHIR_V1",
      fine_grained_authorization_enabled: true
    },
    tags: {
      Purpose: "ClinicalData",
      Compliance: "HIPAA",
      Environment: "production"
    }
  })

  # Medical text analysis jobs
  aws_comprehendmedical_phi_detection_job(:phi_detection, {
    job_name: "clinical-notes-phi-detection",
    input_data_config: {
      s3_bucket: "clinical-documents-raw",
      s3_key: "patient-notes/"
    },
    output_data_config: {
      s3_bucket: "phi-detection-results",
      s3_key: "detected-phi/"
    },
    data_access_role_arn: ref(:aws_iam_role, :medical_nlp_role, :arn),
    language_code: "en",
    kms_key: ref(:aws_kms_key, :healthcare_encryption, :arn)
  })

  aws_comprehendmedical_icd10_cm_inference_job(:diagnostic_coding, {
    job_name: "diagnostic-icd10-coding",
    input_data_config: {
      s3_bucket: "diagnostic-reports",
      s3_key: "radiology-reports/"
    },
    output_data_config: {
      s3_bucket: "medical-coding-results",
      s3_key: "icd10-codes/"
    },
    data_access_role_arn: ref(:aws_iam_role, :medical_coding_role, :arn),
    language_code: "en"
  })

  # Export clinical data for analytics
  aws_healthlake_fhir_export_job(:clinical_analytics_export, {
    job_name: "quarterly-clinical-analytics-export",
    datastore_id: clinical_datastore.datastore_id,
    data_access_role_arn: ref(:aws_iam_role, :healthcare_analytics_role, :arn),
    output_data_config: {
      s3_configuration: {
        s3_uri: "s3://clinical-analytics-data/quarterly-export/",
        kms_key_id: ref(:aws_kms_key, :healthcare_encryption, :arn)
      }
    }
  })
end

# Machine Learning Feature Store and Model Registry
template :ml_infrastructure do
  provider :aws do
    region "us-east-1"
  end

  # Model package group for version management
  fraud_models = aws_sagemaker_model_package_group(:fraud_detection_models, {
    model_package_group_name: "fraud-detection-models",
    model_package_group_description: "Model versions for real-time fraud detection",
    tags: {
      Team: "DataScience",
      Project: "FraudPrevention",
      ModelType: "Classification"
    }
  })

  # Feature group for real-time feature serving
  transaction_features = aws_sagemaker_feature_group(:transaction_features, {
    feature_group_name: "transaction-behavioral-features",
    record_identifier_feature_name: "transaction_id",
    event_time_feature_name: "transaction_time",
    role_arn: ref(:aws_iam_role, :sagemaker_feature_store_role, :arn),
    description: "Real-time transaction features for fraud detection",
    feature_definitions: [
      { feature_name: "transaction_id", feature_type: "String" },
      { feature_name: "amount", feature_type: "Fractional" },
      { feature_name: "merchant_category", feature_type: "String" },
      { feature_name: "is_weekend", feature_type: "Integral" },
      { feature_name: "hour_of_day", feature_type: "Integral" },
      { feature_name: "days_since_last_transaction", feature_type: "Integral" },
      { feature_name: "avg_transaction_last_30d", feature_type: "Fractional" },
      { feature_name: "transaction_time", feature_type: "Fractional" }
    ],
    online_store_config: {
      enable_online_store: true,
      security_config: {
        kms_key_id: ref(:aws_kms_key, :ml_feature_store_encryption, :arn)
      }
    },
    offline_store_config: {
      s3_storage_config: {
        s3_uri: "s3://ml-feature-store/transaction-features/",
        kms_key_id: ref(:aws_kms_key, :ml_feature_store_encryption, :arn)
      },
      disable_glue_table_creation: false,
      data_catalog_config: {
        table_name: "transaction_features",
        catalog: "AwsDataCatalog",
        database: "ml_features"
      }
    },
    tags: {
      UseCase: "FraudDetection",
      DataSource: "TransactionStream",
      Team: "MLEngineering"
    }
  })

  # ML pipeline for automated model training and deployment
  aws_sagemaker_pipeline(:fraud_ml_pipeline, {
    pipeline_name: "fraud-detection-mlops-pipeline",
    pipeline_display_name: "Fraud Detection MLOps Pipeline",
    pipeline_description: "Automated pipeline for fraud model training, evaluation, and deployment",
    role_arn: ref(:aws_iam_role, :sagemaker_pipeline_execution_role, :arn),
    parallelism_configuration: {
      max_parallel_execution_steps: 5
    },
    pipeline_definition: JSON.pretty_generate({
      Version: "2020-12-01",
      Metadata: {},
      Parameters: [
        {
          Name: "InputDataPath",
          Type: "String",
          DefaultValue: "s3://fraud-training-data/features/"
        },
        {
          Name: "ModelOutputPath",
          Type: "String",
          DefaultValue: "s3://fraud-model-artifacts/"
        },
        {
          Name: "TrainingInstanceType",
          Type: "String",
          DefaultValue: "ml.m5.2xlarge"
        }
      ],
      Steps: [
        {
          Name: "DataPreprocessing",
          Type: "Processing",
          Arguments: {
            ProcessingResources: {
              ClusterConfig: {
                InstanceType: "ml.m5.xlarge",
                InstanceCount: 1,
                VolumeSizeInGB: 20
              }
            },
            AppSpecification: {
              ImageUri: "246618743249.dkr.ecr.us-east-1.amazonaws.com/sklearn-processing:0.20.0-cpu-py3"
            }
          }
        },
        {
          Name: "ModelTraining",
          Type: "Training",
          Arguments: {
            TrainingJobName: "fraud-detection-training",
            AlgorithmSpecification: {
              TrainingImage: "246618743249.dkr.ecr.us-east-1.amazonaws.com/xgboost:latest",
              TrainingInputMode: "File"
            },
            ResourceConfig: {
              InstanceType: { Get: "Parameters.TrainingInstanceType" },
              InstanceCount: 1,
              VolumeSizeInGB: 10
            }
          }
        },
        {
          Name: "ModelEvaluation",
          Type: "Processing",
          Arguments: {
            ProcessingResources: {
              ClusterConfig: {
                InstanceType: "ml.m5.xlarge",
                InstanceCount: 1,
                VolumeSizeInGB: 20
              }
            }
          }
        }
      ]
    }),
    tags: {
      Project: "FraudDetection",
      Environment: "production",
      Team: "MLOps",
      PipelineType: "TrainingAndDeployment"
    }
  })
end

# EMR on EKS for Big Data Processing
template :big_data_analytics do
  provider :aws do
    region "us-east-1"
  end

  # Virtual cluster for EMR on EKS
  analytics_cluster = aws_emrcontainers_virtual_cluster(:analytics_virtual_cluster, {
    name: "customer-analytics-emr-cluster",
    container_provider: {
      id: "customer-analytics-eks",
      type: "EKS",
      info: {
        eks_info: {
          namespace: "emr-customer-analytics"
        }
      }
    },
    tags: {
      Environment: "production",
      Team: "DataEngineering",
      Application: "CustomerAnalytics"
    }
  })

  # Job template for standardized analytics jobs
  aws_emrcontainers_job_template(:customer_analytics_template, {
    name: "customer-analytics-job-template",
    job_template_data: {
      execution_role_arn: ref(:aws_iam_role, :emr_job_execution_role, :arn),
      release_label: "emr-6.15.0",
      job_driver: {
        spark_submit_job_driver: {
          entry_point: "s3://analytics-code/customer-insights/main.jar",
          entry_point_arguments: [
            "--input-path", "{{ InputPath }}",
            "--output-path", "{{ OutputPath }}",
            "--analysis-type", "{{ AnalysisType }}"
          ],
          spark_submit_parameters: "--class com.company.analytics.CustomerInsights --conf spark.sql.adaptive.enabled=true"
        }
      },
      configuration_overrides: {
        application_configuration: [
          {
            classification: "spark-defaults",
            properties: {
              "spark.dynamicAllocation.enabled" => "true",
              "spark.dynamicAllocation.minExecutors" => "2",
              "spark.dynamicAllocation.maxExecutors" => "20"
            }
          }
        ],
        monitoring_configuration: {
          persistent_app_ui: "ENABLED",
          cloud_watch_monitoring_configuration: {
            log_group_name: "/aws/emr-containers/customer-analytics",
            log_stream_name_prefix: "analytics-job"
          }
        }
      },
      parameter_configuration: {
        "InputPath": {
          type: "STRING"
        },
        "OutputPath": {
          type: "STRING"
        },
        "AnalysisType": {
          type: "STRING",
          default_value: "churn_prediction"
        }
      }
    },
    tags: {
      Purpose: "CustomerAnalytics",
      Team: "DataEngineering",
      TemplateVersion: "2.0"
    }
  })

  # Managed endpoint for interactive analytics
  aws_emrcontainers_managed_endpoint(:analytics_notebook_endpoint, {
    name: "customer-analytics-jupyter",
    virtual_cluster_id: analytics_cluster.id,
    type: "JUPYTER_ENTERPRISE_GATEWAY",
    release_label: "emr-6.15.0",
    execution_role_arn: ref(:aws_iam_role, :emr_notebook_execution_role, :arn),
    configuration_overrides: {
      application_configuration: [
        {
          classification: "jupyter-kernel-overrides",
          properties: {
            "spark.executor.memory" => "4g",
            "spark.executor.cores" => "2",
            "spark.kubernetes.executor.request.cores" => "1800m"
          }
        }
      ],
      monitoring_configuration: {
        persistent_app_ui: "ENABLED",
        cloud_watch_monitoring_configuration: {
          log_group_name: "/aws/emr-containers/notebooks",
          log_stream_name_prefix: "analytics-jupyter"
        }
      }
    },
    tags: {
      Team: "DataScience",
      Environment: "production",
      Purpose: "InteractiveAnalytics"
    }
  })
end

# Fraud Detection Infrastructure
template :fraud_detection do
  provider :aws do
    region "us-east-1"
  end

  # Entity type for customers
  customer_entity = aws_frauddetector_entity_type(:customer_entity, {
    name: "customer",
    description: "Represents customers in fraud detection models",
    tags: {
      EntityCategory: "Customer",
      DataType: "PersonalIdentifier"
    }
  })

  # Variables for fraud detection
  transaction_amount_var = aws_frauddetector_variable(:transaction_amount_var, {
    name: "transaction_amount",
    data_type: "FLOAT",
    data_source: "EVENT",
    default_value: "0.0",
    description: "The monetary amount of the transaction",
    variable_type: "CONTINUOUS",
    tags: {
      VariableCategory: "Financial",
      DataSensitivity: "Medium"
    }
  })

  payment_method_var = aws_frauddetector_variable(:payment_method_var, {
    name: "payment_method",
    data_type: "STRING",
    data_source: "EVENT",
    description: "The payment method used (credit_card, debit_card, etc.)",
    variable_type: "CATEGORICAL",
    tags: {
      VariableCategory: "PaymentInfo",
      DataSensitivity: "Low"
    }
  })

  # Outcomes
  fraud_outcome = aws_frauddetector_outcome(:fraud_detected, {
    name: "fraud_detected",
    description: "Outcome indicating fraudulent activity detected",
    tags: {
      OutcomeType: "Fraud",
      Action: "Block",
      Severity: "High"
    }
  })

  legitimate_outcome = aws_frauddetector_outcome(:legitimate, {
    name: "legitimate",
    description: "Outcome indicating legitimate transaction",
    tags: {
      OutcomeType: "Legitimate",
      Action: "Allow",
      Severity: "None"
    }
  })

  # Event type for payment transactions
  payment_event = aws_frauddetector_event_type(:payment_event, {
    name: "payment_transaction",
    description: "Online payment transaction events for fraud detection",
    entity_types: [customer_entity.name],
    event_variables: [
      transaction_amount_var.name,
      payment_method_var.name
    ],
    labels: [
      fraud_outcome.name,
      legitimate_outcome.name
    ],
    tags: {
      EventCategory: "Payment",
      RiskType: "Transaction",
      Industry: "Ecommerce"
    }
  })

  # Main fraud detector
  aws_frauddetector_detector(:payment_fraud_detector, {
    detector_id: "online_payment_fraud_detector",
    description: "Detects fraudulent online payment transactions in real-time",
    event_type_name: payment_event.name,
    tags: {
      UseCase: "PaymentFraud",
      BusinessUnit: "Payments",
      RiskLevel: "High",
      Environment: "production"
    }
  })
end

# Predictive Maintenance with Lookout for Equipment
template :predictive_maintenance do
  provider :aws do
    region "us-east-1"
  end

  # Dataset for equipment sensor data
  equipment_dataset = aws_lookoutequipment_dataset(:turbine_sensor_dataset, {
    dataset_name: "wind-turbine-sensor-data",
    dataset_schema: JSON.pretty_generate({
      Components: [
        {
          ComponentName: "Turbine",
          Columns: [
            { Name: "timestamp", Type: "DATETIME" },
            { Name: "turbine_id", Type: "CATEGORICAL" },
            { Name: "rotor_speed", Type: "DOUBLE" },
            { Name: "generator_temperature", Type: "DOUBLE" },
            { Name: "gearbox_oil_temperature", Type: "DOUBLE" },
            { Name: "vibration_x", Type: "DOUBLE" },
            { Name: "vibration_y", Type: "DOUBLE" },
            { Name: "vibration_z", Type: "DOUBLE" },
            { Name: "power_output", Type: "DOUBLE" }
          ]
        }
      ]
    }),
    server_side_kms_key_id: ref(:aws_kms_key, :equipment_data_encryption, :arn),
    tags: {
      Equipment: "WindTurbine",
      Purpose: "PredictiveMaintenance",
      DataType: "SensorReadings"
    }
  })

  # Anomaly detection model
  equipment_model = aws_lookoutequipment_model(:turbine_anomaly_model, {
    model_name: "wind-turbine-anomaly-detection",
    dataset_name: equipment_dataset.dataset_name,
    role_arn: ref(:aws_iam_role, :lookout_equipment_role, :arn),
    training_data_start_time: "2023-01-01T00:00:00.000Z",
    training_data_end_time: "2023-06-30T23:59:59.000Z",
    evaluation_data_start_time: "2023-07-01T00:00:00.000Z",
    evaluation_data_end_time: "2023-08-31T23:59:59.000Z",
    server_side_kms_key_id: ref(:aws_kms_key, :equipment_data_encryption, :arn),
    tags: {
      ModelType: "AnomalyDetection",
      Equipment: "WindTurbine",
      Version: "1.0"
    }
  })

  # Inference scheduler for real-time monitoring
  aws_lookoutequipment_inference_scheduler(:turbine_monitoring_scheduler, {
    inference_scheduler_name: "wind-turbine-real-time-monitoring",
    model_name: equipment_model.model_name,
    role_arn: ref(:aws_iam_role, :lookout_inference_role, :arn),
    data_upload_frequency: "PT15M",
    data_delay_offset_in_minutes: "5",
    data_input_configuration: {
      s3_input_configuration: {
        bucket: "equipment-sensor-data",
        prefix: "turbine-realtime/"
      }
    },
    data_output_configuration: {
      s3_output_configuration: {
        bucket: "equipment-inference-results",
        prefix: "turbine-anomalies/",
        kms_key_id: ref(:aws_kms_key, :equipment_data_encryption, :arn)
      }
    },
    server_side_kms_key_id: ref(:aws_kms_key, :equipment_data_encryption, :arn),
    tags: {
      Equipment: "WindTurbine",
      MonitoringType: "RealTime",
      Frequency: "15Minutes",
      Purpose: "PreventiveMaintenance"
    }
  })

  # Metrics detector for business KPIs
  aws_lookoutmetrics_detector(:equipment_performance_detector, {
    anomaly_detector_name: "equipment-performance-metrics",
    anomaly_detector_description: "Monitors equipment performance KPIs and operational metrics",
    anomaly_detector_config: {
      anomaly_detector_frequency: "PT1H"
    },
    tags: {
      MetricType: "EquipmentPerformance",
      DetectionFrequency: "Hourly",
      BusinessUnit: "Operations"
    }
  })
end