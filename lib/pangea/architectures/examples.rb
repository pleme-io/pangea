# frozen_string_literal: true

require 'pangea/architectures/patterns/web_application'
require 'pangea/architectures/patterns/microservices'
require 'pangea/architectures/patterns/data_processing'

module Pangea
  module Architectures
    # Example architecture compositions demonstrating real-world patterns
    module Examples
      include Patterns::WebApplication
      include Patterns::Microservices 
      include Patterns::DataProcessing

      # Example 1: Complete E-commerce Platform
      # Combines web application, microservices, and data processing
      def ecommerce_platform_architecture(name, attributes = {})
        platform_attrs = {
          domain: attributes[:domain] || "#{name}.com",
          environment: attributes[:environment] || 'production',
          high_availability: true,
          regions: attributes[:regions] || ['us-east-1', 'us-west-2']
        }

        # 1. Create core web application
        web_app = web_application_architecture(
          :"#{name}_web", 
          platform_attrs.merge({
            auto_scaling: { min: 3, max: 20 },
            database_engine: 'postgresql',
            cdn_enabled: true,
            waf_enabled: true
          })
        )

        # 2. Create microservices platform for core services
        services_platform = microservices_platform_architecture(
          :"#{name}_services",
          platform_name: "#{name}-services",
          environment: platform_attrs[:environment],
          vpc_cidr: '10.1.0.0/16',
          service_mesh: 'istio',
          orchestrator: 'ecs',
          message_queue: 'sqs',
          shared_cache: true
        )

        # 3. Deploy core microservices
        user_service = microservice_architecture(
          :"#{name}_user_service",
          platform_ref: services_platform,
          attributes: {
            runtime: 'nodejs',
            database_type: 'postgresql',
            min_instances: 2,
            max_instances: 10,
            cache_enabled: true
          }
        )

        inventory_service = microservice_architecture(
          :"#{name}_inventory_service",
          platform_ref: services_platform,
          attributes: {
            runtime: 'java',
            database_type: 'postgresql', 
            min_instances: 2,
            max_instances: 15,
            depends_on: ['user_service']
          }
        )

        order_service = microservice_architecture(
          :"#{name}_order_service",
          platform_ref: services_platform,
          attributes: {
            runtime: 'golang',
            database_type: 'postgresql',
            min_instances: 3,
            max_instances: 20,
            security_level: 'high',
            depends_on: ['user_service', 'inventory_service']
          }
        )

        payment_service = microservice_architecture(
          :"#{name}_payment_service",
          platform_ref: services_platform,
          attributes: {
            runtime: 'java',
            database_type: 'postgresql',
            min_instances: 2,
            max_instances: 8,
            security_level: 'high',
            depends_on: ['user_service', 'order_service']
          }
        )

        # 4. Create data processing pipeline
        analytics_platform = data_lake_architecture(
          :"#{name}_analytics",
          data_lake_name: "#{name}-analytics",
          environment: platform_attrs[:environment],
          vpc_cidr: '10.2.0.0/16',
          data_sources: ['rds', 'kinesis', 's3'],
          real_time_processing: true,
          batch_processing: true,
          data_warehouse: 'redshift',
          machine_learning: true,
          business_intelligence: true
        )

        # 5. Create composite architecture reference
        composite_ref = create_architecture_reference('ecommerce_platform', name, platform_attrs)
        composite_ref.web_application = web_app
        composite_ref.microservices_platform = services_platform
        composite_ref.services = {
          user: user_service,
          inventory: inventory_service,
          order: order_service,
          payment: payment_service
        }
        composite_ref.analytics = analytics_platform

        composite_ref
      end

      # Example 2: Multi-Region SaaS Platform
      # Demonstrates cross-region architecture with disaster recovery
      def multi_region_saas_architecture(name, attributes = {})
        primary_region = attributes[:primary_region] || 'us-east-1'
        secondary_region = attributes[:secondary_region] || 'us-west-2'
        domain = attributes[:domain] || "#{name}.com"

        # Primary region deployment
        primary_app = web_application_architecture(
          :"#{name}_primary",
          domain: domain,
          environment: 'production',
          availability_zones: ["#{primary_region}a", "#{primary_region}b", "#{primary_region}c"],
          vpc_cidr: '10.0.0.0/16',
          high_availability: true,
          auto_scaling: { min: 5, max: 50 },
          database_engine: 'postgresql',
          database_backup_retention: 30,
          cdn_enabled: true,
          waf_enabled: true,
          monitoring_enabled: true
        )

        # Secondary region deployment (disaster recovery)
        secondary_app = web_application_architecture(
          :"#{name}_secondary",
          domain: "dr.#{domain}",
          environment: 'production',
          availability_zones: ["#{secondary_region}a", "#{secondary_region}b"],
          vpc_cidr: '10.10.0.0/16',
          high_availability: true,
          auto_scaling: { min: 2, max: 20 },
          database_engine: 'postgresql',
          database_backup_retention: 30,
          cdn_enabled: false,  # Uses same CDN as primary
          monitoring_enabled: true
        )

        # Shared data processing across regions
        global_analytics = streaming_data_architecture(
          :"#{name}_global_stream",
          stream_name: "#{name}-global-events",
          stream_type: 'kinesis',
          shard_count: 10,
          retention_hours: 168,  # 7 days
          stream_processing_framework: 'kinesis-analytics',
          output_destinations: ['s3', 'elasticsearch'],
          monitoring_enabled: true,
          alerting_enabled: true
        )

        # Composite reference
        composite_ref = create_architecture_reference('multi_region_saas', name, {
          primary_region: primary_region,
          secondary_region: secondary_region,
          domain: domain
        })
        
        composite_ref.primary_region = primary_app
        composite_ref.secondary_region = secondary_app  
        composite_ref.global_analytics = global_analytics

        composite_ref
      end

      # Example 3: AI/ML Platform
      # Combines data processing with machine learning services
      def ml_platform_architecture(name, attributes = {})
        platform_attrs = {
          environment: attributes[:environment] || 'production',
          domain: attributes[:domain] || "ml.#{name}.com",
          vpc_cidr: '10.3.0.0/16'
        }

        # 1. Data ingestion and processing foundation
        data_platform = data_lake_architecture(
          :"#{name}_data_lake",
          data_lake_name: "#{name}-ml-data",
          environment: platform_attrs[:environment],
          vpc_cidr: platform_attrs[:vpc_cidr],
          data_sources: ['s3', 'rds', 'kinesis'],
          real_time_processing: true,
          batch_processing: true,
          data_warehouse: 'redshift',
          machine_learning: true,
          raw_data_retention_days: 2555,  # 7 years
          processed_data_retention_days: 1095  # 3 years
        )

        # 2. Real-time streaming for model inference
        inference_stream = streaming_data_architecture(
          :"#{name}_inference_stream", 
          stream_name: "#{name}-inference-requests",
          stream_type: 'kinesis',
          shard_count: 20,
          retention_hours: 24,
          stream_processing_framework: 'kinesis-analytics',
          windowing_strategy: 'sliding',
          window_size_minutes: 1,
          output_destinations: ['s3', 'dynamodb'],
          error_handling: 'dlq'
        )

        # 3. Web application for model management
        ml_web_app = web_application_architecture(
          :"#{name}_web",
          domain: platform_attrs[:domain],
          environment: platform_attrs[:environment],
          vpc_cidr: '10.4.0.0/16',
          high_availability: true,
          auto_scaling: { min: 2, max: 10 },
          database_engine: 'postgresql',
          s3_bucket_enabled: true,
          monitoring_enabled: true
        )

        # Composite reference
        composite_ref = create_architecture_reference('ml_platform', name, platform_attrs)
        composite_ref.data_platform = data_platform
        composite_ref.inference_stream = inference_stream
        composite_ref.web_application = ml_web_app

        # Custom ML-specific extensions
        composite_ref.extend do |arch_ref|
          # Add SageMaker endpoints (simplified representation)
          arch_ref.ml_endpoints = {
            model_training: {
              type: 'sagemaker_training_job',
              name: "#{name}-training",
              role_arn: 'arn:aws:iam::account:role/SageMakerRole',
              algorithm_specification: {
                training_image: '382416733822.dkr.ecr.us-east-1.amazonaws.com/xgboost:latest',
                training_input_mode: 'File'
              },
              input_data_config: [{
                channel_name: 'training',
                data_source: {
                  s3_data_source: {
                    s3_data_type: 'S3Prefix',
                    s3_uri: "s3://#{data_platform.storage[:processed_bucket].bucket}/training-data/",
                    s3_data_distribution_type: 'FullyReplicated'
                  }
                }
              }],
              output_data_config: {
                s3_output_path: "s3://#{data_platform.storage[:processed_bucket].bucket}/model-artifacts/"
              },
              resource_config: {
                instance_type: 'ml.m5.large',
                instance_count: 1,
                volume_size_in_gb: 30
              }
            },
            
            inference_endpoint: {
              type: 'sagemaker_endpoint',
              name: "#{name}-inference",
              endpoint_config_name: "#{name}-endpoint-config",
              initial_instance_count: 2,
              instance_type: 'ml.t2.medium'
            }
          }

          # Add model registry
          arch_ref.model_registry = {
            type: 'sagemaker_model_package_group',
            name: "#{name}-models",
            description: "Model registry for #{name} ML platform"
          }
        end

        composite_ref
      end

      # Example 4: DevOps Platform
      # CI/CD pipeline with monitoring and infrastructure automation
      def devops_platform_architecture(name, attributes = {})
        platform_attrs = {
          environment: attributes[:environment] || 'production',
          vpc_cidr: '10.5.0.0/16',
          git_provider: attributes[:git_provider] || 'github'
        }

        # 1. Core infrastructure platform
        infrastructure_platform = microservices_platform_architecture(
          :"#{name}_infra_platform",
          platform_name: "#{name}-devops",
          environment: platform_attrs[:environment],
          vpc_cidr: platform_attrs[:vpc_cidr],
          service_mesh: 'none',  # Simplified for DevOps tools
          orchestrator: 'ecs',
          api_gateway: true,
          message_queue: 'sqs',
          shared_cache: true,
          centralized_logging: true,
          metrics_collection: true,
          rbac_enabled: true,
          secrets_management: true
        )

        # 2. Monitoring and observability stack
        monitoring_data = data_lake_architecture(
          :"#{name}_monitoring_data",
          data_lake_name: "#{name}-metrics",
          environment: platform_attrs[:environment],
          vpc_cidr: '10.6.0.0/16',
          data_sources: ['kinesis'],
          real_time_processing: true,
          batch_processing: true,
          data_warehouse: 'athena',
          raw_data_retention_days: 90,
          processed_data_retention_days: 365
        )

        # Composite reference
        composite_ref = create_architecture_reference('devops_platform', name, platform_attrs)
        composite_ref.infrastructure_platform = infrastructure_platform
        composite_ref.monitoring_data = monitoring_data

        # Add DevOps-specific services
        composite_ref.extend do |arch_ref|
          # CI/CD services (simplified representations)
          arch_ref.cicd_services = {
            build_service: {
              type: 'codebuild_project',
              name: "#{name}-build",
              service_role: 'arn:aws:iam::account:role/CodeBuildServiceRole',
              artifacts: {
                type: 'S3',
                location: "#{name}-build-artifacts"
              },
              environment: {
                compute_type: 'BUILD_GENERAL1_MEDIUM',
                image: 'aws/codebuild/amazonlinux2-x86_64-standard:3.0',
                type: 'LINUX_CONTAINER'
              },
              source: {
                type: platform_attrs[:git_provider].upcase,
                location: attributes[:repository_url]
              }
            },

            deployment_pipeline: {
              type: 'codepipeline',
              name: "#{name}-pipeline",
              role_arn: 'arn:aws:iam::account:role/CodePipelineServiceRole',
              artifact_store: {
                location: "#{name}-pipeline-artifacts",
                type: 'S3'
              },
              stages: [
                {
                  name: 'Source',
                  actions: [{
                    name: 'Source',
                    action_type_id: {
                      category: 'Source',
                      owner: 'ThirdParty',
                      provider: 'GitHub',
                      version: '1'
                    }
                  }]
                },
                {
                  name: 'Build', 
                  actions: [{
                    name: 'Build',
                    action_type_id: {
                      category: 'Build',
                      owner: 'AWS',
                      provider: 'CodeBuild',
                      version: '1'
                    }
                  }]
                },
                {
                  name: 'Deploy',
                  actions: [{
                    name: 'Deploy',
                    action_type_id: {
                      category: 'Deploy',
                      owner: 'AWS', 
                      provider: 'ECS',
                      version: '1'
                    }
                  }]
                }
              ]
            }
          }

          # Infrastructure as Code service
          arch_ref.iac_service = {
            type: 'pangea_service',
            name: "#{name}-pangea-runner",
            container_image: "#{name}/pangea-runner:latest",
            task_role_arn: 'arn:aws:iam::account:role/PangeaRunnerRole',
            environment_variables: {
              PANGEA_STATE_BACKEND: 's3',
              PANGEA_STATE_BUCKET: "#{name}-pangea-state",
              PANGEA_LOCK_TABLE: "#{name}-pangea-locks"
            }
          }

          # Artifact storage
          arch_ref.artifact_storage = {
            build_artifacts: {
              type: 's3_bucket',
              name: "#{name}-build-artifacts",
              versioning: 'Enabled',
              lifecycle_rules: [
                {
                  id: 'cleanup_old_artifacts',
                  status: 'Enabled',
                  expiration: { days: 90 }
                }
              ]
            },

            container_registry: {
              type: 'ecr_repository',
              name: "#{name}/services",
              image_tag_mutability: 'MUTABLE',
              image_scanning: true,
              lifecycle_policy: {
                rules: [{
                  selection: {
                    tag_status: 'untagged',
                    count_type: 'sinceImagePushed',
                    count_unit: 'days',
                    count_number: 7
                  },
                  action: { type: 'expire' }
                }]
              }
            }
          }
        end

        composite_ref
      end

      # Helper method for creating architecture-specific resource names
      def composite_resource_name(platform_name, architecture_type, resource_name)
        :"#{platform_name}_#{architecture_type}_#{resource_name}"
      end

      # Helper method for cross-architecture resource sharing
      def share_resources_between_architectures(source_arch, target_arch, shared_resources = [])
        shared_resources.each do |resource_type|
          case resource_type
          when :vpc
            target_arch.network = source_arch.network if source_arch.network
          when :database
            target_arch.database = source_arch.database if source_arch.database
          when :security_groups
            if source_arch.security && target_arch.security
              target_arch.security = target_arch.security.merge(source_arch.security)
            end
          when :monitoring
            target_arch.monitoring = source_arch.monitoring if source_arch.monitoring
          end
        end
      end
    end
  end
end