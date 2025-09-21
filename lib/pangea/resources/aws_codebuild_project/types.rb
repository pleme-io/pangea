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

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS CodeBuild Project resources
      class CodeBuildProjectAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Project name (required)
        attribute :name, Resources::Types::String.constrained(
          format: /\A[A-Za-z0-9][A-Za-z0-9\-_]*\z/,
          min_size: 2,
          max_size: 255
        )

        # Project description
        attribute? :description, Resources::Types::String.constrained(max_size: 255).optional

        # Service role ARN (required)
        attribute :service_role, Resources::Types::String

        # Build timeout in minutes (5-480)
        attribute :build_timeout, Resources::Types::Integer.constrained(gteq: 5, lteq: 480).default(60)

        # Queued timeout in minutes (5-480)
        attribute :queued_timeout, Resources::Types::Integer.constrained(gteq: 5, lteq: 480).default(480)

        # Concurrent build limit
        attribute? :concurrent_build_limit, Resources::Types::Integer.constrained(gteq: 1, lteq: 100).optional

        # Source configuration
        attribute :source, Resources::Types::Hash.schema(
          type: Resources::Types::String.enum('CODECOMMIT', 'CODEPIPELINE', 'GITHUB', 'GITHUB_ENTERPRISE', 'BITBUCKET', 'S3', 'NO_SOURCE'),
          location?: Resources::Types::String.optional,
          git_clone_depth?: Resources::Types::Integer.constrained(gteq: 0).optional,
          buildspec?: Resources::Types::String.optional,
          report_build_status?: Resources::Types::Bool.optional,
          insecure_ssl?: Resources::Types::Bool.optional,
          git_submodules_config?: Resources::Types::Hash.schema(
            fetch_submodules: Resources::Types::Bool
          ).optional,
          auth?: Resources::Types::Hash.schema(
            type: Resources::Types::String.enum('OAUTH'),
            resource?: Resources::Types::String.optional
          ).optional
        )

        # Artifacts configuration
        attribute :artifacts, Resources::Types::Hash.schema(
          type: Resources::Types::String.enum('CODEPIPELINE', 'S3', 'NO_ARTIFACTS'),
          location?: Resources::Types::String.optional,
          name?: Resources::Types::String.optional,
          namespace_type?: Resources::Types::String.enum('NONE', 'BUILD_ID').optional,
          packaging?: Resources::Types::String.enum('NONE', 'ZIP').optional,
          path?: Resources::Types::String.optional,
          encryption_disabled?: Resources::Types::Bool.optional,
          artifact_identifier?: Resources::Types::String.optional,
          override_artifact_name?: Resources::Types::Bool.optional
        )

        # Secondary sources
        attribute :secondary_sources, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            source_identifier: Resources::Types::String,
            type: Resources::Types::String.enum('CODECOMMIT', 'CODEPIPELINE', 'GITHUB', 'S3'),
            location?: Resources::Types::String.optional,
            git_clone_depth?: Resources::Types::Integer.optional,
            buildspec?: Resources::Types::String.optional,
            report_build_status?: Resources::Types::Bool.optional,
            insecure_ssl?: Resources::Types::Bool.optional
          )
        ).default([].freeze)

        # Secondary artifacts
        attribute :secondary_artifacts, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            artifact_identifier: Resources::Types::String,
            type: Resources::Types::String.enum('S3'),
            location?: Resources::Types::String.optional,
            name?: Resources::Types::String.optional,
            namespace_type?: Resources::Types::String.enum('NONE', 'BUILD_ID').optional,
            packaging?: Resources::Types::String.enum('NONE', 'ZIP').optional,
            path?: Resources::Types::String.optional,
            encryption_disabled?: Resources::Types::Bool.optional,
            override_artifact_name?: Resources::Types::Bool.optional
          )
        ).default([].freeze)

        # Environment configuration
        attribute :environment, Resources::Types::Hash.schema(
          type: Resources::Types::String.enum('LINUX_CONTAINER', 'LINUX_GPU_CONTAINER', 'WINDOWS_CONTAINER', 'WINDOWS_SERVER_2019_CONTAINER', 'ARM_CONTAINER'),
          image: Resources::Types::String,
          compute_type: Resources::Types::String.enum('BUILD_GENERAL1_SMALL', 'BUILD_GENERAL1_MEDIUM', 'BUILD_GENERAL1_LARGE', 'BUILD_GENERAL1_2XLARGE'),
          environment_variables?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              name: Resources::Types::String,
              value: Resources::Types::String,
              type?: Resources::Types::String.enum('PLAINTEXT', 'PARAMETER_STORE', 'SECRETS_MANAGER').optional
            )
          ).optional,
          privileged_mode?: Resources::Types::Bool.optional,
          certificate?: Resources::Types::String.optional,
          registry_credential?: Resources::Types::Hash.schema(
            credential: Resources::Types::String,
            credential_provider: Resources::Types::String.enum('SECRETS_MANAGER')
          ).optional,
          image_pull_credentials_type?: Resources::Types::String.enum('CODEBUILD', 'SERVICE_ROLE').optional
        )

        # Cache configuration
        attribute :cache, Resources::Types::Hash.schema(
          type: Resources::Types::String.enum('NO_CACHE', 'S3', 'LOCAL'),
          location?: Resources::Types::String.optional,
          modes?: Resources::Types::Array.of(
            Resources::Types::String.enum('LOCAL_DOCKER_LAYER_CACHE', 'LOCAL_SOURCE_CACHE', 'LOCAL_CUSTOM_CACHE')
          ).optional
        ).default({ type: 'NO_CACHE' })

        # VPC configuration
        attribute? :vpc_config, Resources::Types::Hash.schema(
          vpc_id: Resources::Types::String,
          subnets: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1),
          security_group_ids: Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1)
        ).optional

        # Logs configuration
        attribute :logs_config, Resources::Types::Hash.schema(
          cloudwatch_logs?: Resources::Types::Hash.schema(
            status?: Resources::Types::String.enum('ENABLED', 'DISABLED').optional,
            group_name?: Resources::Types::String.optional,
            stream_name?: Resources::Types::String.optional
          ).optional,
          s3_logs?: Resources::Types::Hash.schema(
            status?: Resources::Types::String.enum('ENABLED', 'DISABLED').optional,
            location?: Resources::Types::String.optional,
            encryption_disabled?: Resources::Types::Bool.optional
          ).optional
        ).default({}.freeze)

        # Build batch configuration
        attribute? :build_batch_config, Resources::Types::Hash.schema(
          service_role: Resources::Types::String,
          combine_artifacts?: Resources::Types::Bool.optional,
          restrictions?: Resources::Types::Hash.schema(
            compute_types_allowed?: Resources::Types::Array.of(Resources::Types::String).optional,
            maximum_builds_allowed?: Resources::Types::Integer.optional
          ).optional,
          timeout_in_mins?: Resources::Types::Integer.optional
        ).optional

        # File system locations
        attribute :file_system_locations, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            type: Resources::Types::String.enum('EFS'),
            location: Resources::Types::String,
            mount_point: Resources::Types::String,
            identifier: Resources::Types::String,
            mount_options?: Resources::Types::String.optional
          )
        ).default([].freeze)

        # Badge enabled
        attribute :badge_enabled, Resources::Types::Bool.default(false)

        # Encryption key
        attribute? :encryption_key, Resources::Types::String.optional

        # Resource access role
        attribute? :resource_access_role, Resources::Types::String.optional

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate source configuration
          if attrs.source[:type] != 'CODEPIPELINE' && attrs.source[:type] != 'NO_SOURCE' && attrs.source[:location].nil?
            raise Dry::Struct::Error, "Source location is required for source type #{attrs.source[:type]}"
          end

          # Validate artifacts configuration
          if attrs.artifacts[:type] == 'S3' && attrs.artifacts[:location].nil?
            raise Dry::Struct::Error, "Artifacts location is required for S3 artifact type"
          end

          # Validate VPC configuration
          if attrs.vpc_config
            if attrs.vpc_config[:subnets].empty?
              raise Dry::Struct::Error, "At least one subnet is required for VPC configuration"
            end
            if attrs.vpc_config[:security_group_ids].empty?
              raise Dry::Struct::Error, "At least one security group is required for VPC configuration"
            end
          end

          # Validate cache configuration
          if attrs.cache[:type] == 'S3' && attrs.cache[:location].nil?
            raise Dry::Struct::Error, "Cache location is required for S3 cache type"
          end

          if attrs.cache[:type] == 'LOCAL' && (attrs.cache[:modes].nil? || attrs.cache[:modes].empty?)
            raise Dry::Struct::Error, "At least one cache mode is required for LOCAL cache type"
          end

          # Validate environment variables don't have duplicates
          if attrs.environment[:environment_variables]
            var_names = attrs.environment[:environment_variables].map { |v| v[:name] }
            if var_names.size != var_names.uniq.size
              raise Dry::Struct::Error, "Environment variable names must be unique"
            end
          end

          attrs
        end

        # Helper methods
        def uses_vpc?
          vpc_config.present?
        end

        def has_secondary_sources?
          secondary_sources.any?
        end

        def has_secondary_artifacts?
          secondary_artifacts.any?
        end

        def cache_enabled?
          cache[:type] != 'NO_CACHE'
        end

        def cloudwatch_logs_enabled?
          logs_config.dig(:cloudwatch_logs, :status) == 'ENABLED'
        end

        def s3_logs_enabled?
          logs_config.dig(:s3_logs, :status) == 'ENABLED'
        end

        def environment_variable_count
          environment[:environment_variables]&.size || 0
        end

        def uses_secrets?
          return false unless environment[:environment_variables]
          
          environment[:environment_variables].any? do |var|
            var[:type] == 'PARAMETER_STORE' || var[:type] == 'SECRETS_MANAGER'
          end
        end

        def compute_size
          case environment[:compute_type]
          when 'BUILD_GENERAL1_SMALL' then 'Small (3 GB memory, 2 vCPUs)'
          when 'BUILD_GENERAL1_MEDIUM' then 'Medium (7 GB memory, 4 vCPUs)'
          when 'BUILD_GENERAL1_LARGE' then 'Large (15 GB memory, 8 vCPUs)'
          when 'BUILD_GENERAL1_2XLARGE' then '2X Large (145 GB memory, 72 vCPUs)'
          else environment[:compute_type]
          end
        end
      end
    end
      end
    end
  end
end