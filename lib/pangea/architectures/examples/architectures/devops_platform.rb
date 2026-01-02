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

module Pangea
  module Architectures
    module Examples
      # DevOps platform architecture example
      module DevopsPlatform
        def devops_platform_architecture(name, attributes = {})
          platform_attrs = {
            environment: attributes[:environment] || 'production',
            vpc_cidr: '10.5.0.0/16',
            git_provider: attributes[:git_provider] || 'github',
            repository_url: attributes[:repository_url]
          }

          infrastructure_platform = create_infrastructure_platform(name, platform_attrs)
          monitoring_data = create_monitoring_data(name, platform_attrs)

          composite_ref = create_architecture_reference('devops_platform', name, platform_attrs)
          composite_ref.infrastructure_platform = infrastructure_platform
          composite_ref.monitoring_data = monitoring_data

          add_devops_extensions(composite_ref, name, platform_attrs)

          composite_ref
        end

        private

        def create_infrastructure_platform(name, platform_attrs)
          microservices_platform_architecture(
            :"#{name}_infra_platform",
            platform_name: "#{name}-devops",
            environment: platform_attrs[:environment],
            vpc_cidr: platform_attrs[:vpc_cidr],
            service_mesh: 'none',
            orchestrator: 'ecs',
            api_gateway: true,
            message_queue: 'sqs',
            shared_cache: true,
            centralized_logging: true,
            metrics_collection: true,
            rbac_enabled: true,
            secrets_management: true
          )
        end

        def create_monitoring_data(name, platform_attrs)
          data_lake_architecture(
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
        end

        def add_devops_extensions(composite_ref, name, platform_attrs)
          composite_ref.extend do |arch_ref|
            arch_ref.cicd_services = build_cicd_services(name, platform_attrs)
            arch_ref.iac_service = build_iac_service(name)
            arch_ref.artifact_storage = build_artifact_storage(name)
          end
        end

        def build_cicd_services(name, platform_attrs)
          {
            build_service: {
              type: 'codebuild_project', name: "#{name}-build",
              service_role: 'arn:aws:iam::account:role/CodeBuildServiceRole',
              artifacts: { type: 'S3', location: "#{name}-build-artifacts" },
              environment: { compute_type: 'BUILD_GENERAL1_MEDIUM', image: 'aws/codebuild/amazonlinux2-x86_64-standard:3.0', type: 'LINUX_CONTAINER' },
              source: { type: platform_attrs[:git_provider].upcase, location: platform_attrs[:repository_url] }
            },
            deployment_pipeline: build_deployment_pipeline(name)
          }
        end

        def build_deployment_pipeline(name)
          {
            type: 'codepipeline', name: "#{name}-pipeline",
            role_arn: 'arn:aws:iam::account:role/CodePipelineServiceRole',
            artifact_store: { location: "#{name}-pipeline-artifacts", type: 'S3' },
            stages: [
              { name: 'Source', actions: [{ name: 'Source', action_type_id: { category: 'Source', owner: 'ThirdParty', provider: 'GitHub', version: '1' } }] },
              { name: 'Build', actions: [{ name: 'Build', action_type_id: { category: 'Build', owner: 'AWS', provider: 'CodeBuild', version: '1' } }] },
              { name: 'Deploy', actions: [{ name: 'Deploy', action_type_id: { category: 'Deploy', owner: 'AWS', provider: 'ECS', version: '1' } }] }
            ]
          }
        end

        def build_iac_service(name)
          {
            type: 'pangea_service', name: "#{name}-pangea-runner",
            container_image: "#{name}/pangea-runner:latest",
            task_role_arn: 'arn:aws:iam::account:role/PangeaRunnerRole',
            environment_variables: { PANGEA_STATE_BACKEND: 's3', PANGEA_STATE_BUCKET: "#{name}-pangea-state", PANGEA_LOCK_TABLE: "#{name}-pangea-locks" }
          }
        end

        def build_artifact_storage(name)
          {
            build_artifacts: { type: 's3_bucket', name: "#{name}-build-artifacts", versioning: 'Enabled', lifecycle_rules: [{ id: 'cleanup_old_artifacts', status: 'Enabled', expiration: { days: 90 } }] },
            container_registry: { type: 'ecr_repository', name: "#{name}/services", image_tag_mutability: 'MUTABLE', image_scanning: true, lifecycle_policy: { rules: [{ selection: { tag_status: 'untagged', count_type: 'sinceImagePushed', count_unit: 'days', count_number: 7 }, action: { type: 'expire' } }] } }
          }
        end
      end
    end
  end
end
