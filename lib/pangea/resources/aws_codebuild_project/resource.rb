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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_codebuild_project/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodeBuild Project with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodeBuild project attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_codebuild_project(name, attributes = {})
        # Validate attributes using dry-struct
        project_attrs = Types::CodeBuildProjectAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codebuild_project, name) do
          # Basic configuration
          name project_attrs.name
          description project_attrs.description if project_attrs.description
          service_role project_attrs.service_role
          
          # Timeouts
          build_timeout project_attrs.build_timeout
          queued_timeout project_attrs.queued_timeout
          concurrent_build_limit project_attrs.concurrent_build_limit if project_attrs.concurrent_build_limit
          
          # Badge
          badge_enabled project_attrs.badge_enabled
          
          # Encryption
          encryption_key project_attrs.encryption_key if project_attrs.encryption_key
          
          # Resource access role
          resource_access_role project_attrs.resource_access_role if project_attrs.resource_access_role
          
          # Source configuration
          source do
            type project_attrs.source[:type]
            location project_attrs.source[:location] if project_attrs.source[:location]
            git_clone_depth project_attrs.source[:git_clone_depth] if project_attrs.source[:git_clone_depth]
            buildspec project_attrs.source[:buildspec] if project_attrs.source[:buildspec]
            report_build_status project_attrs.source[:report_build_status] if project_attrs.source.key?(:report_build_status)
            insecure_ssl project_attrs.source[:insecure_ssl] if project_attrs.source.key?(:insecure_ssl)
            
            if project_attrs.source[:git_submodules_config]
              git_submodules_config do
                fetch_submodules project_attrs.source[:git_submodules_config][:fetch_submodules]
              end
            end
            
            if project_attrs.source[:auth]
              auth do
                type project_attrs.source[:auth][:type]
                resource project_attrs.source[:auth][:resource] if project_attrs.source[:auth][:resource]
              end
            end
          end
          
          # Secondary sources
          project_attrs.secondary_sources.each do |secondary_source|
            secondary_sources do
              source_identifier secondary_source[:source_identifier]
              type secondary_source[:type]
              location secondary_source[:location] if secondary_source[:location]
              git_clone_depth secondary_source[:git_clone_depth] if secondary_source[:git_clone_depth]
              buildspec secondary_source[:buildspec] if secondary_source[:buildspec]
              report_build_status secondary_source[:report_build_status] if secondary_source.key?(:report_build_status)
              insecure_ssl secondary_source[:insecure_ssl] if secondary_source.key?(:insecure_ssl)
            end
          end
          
          # Artifacts configuration
          artifacts do
            type project_attrs.artifacts[:type]
            location project_attrs.artifacts[:location] if project_attrs.artifacts[:location]
            name project_attrs.artifacts[:name] if project_attrs.artifacts[:name]
            namespace_type project_attrs.artifacts[:namespace_type] if project_attrs.artifacts[:namespace_type]
            packaging project_attrs.artifacts[:packaging] if project_attrs.artifacts[:packaging]
            path project_attrs.artifacts[:path] if project_attrs.artifacts[:path]
            encryption_disabled project_attrs.artifacts[:encryption_disabled] if project_attrs.artifacts.key?(:encryption_disabled)
            artifact_identifier project_attrs.artifacts[:artifact_identifier] if project_attrs.artifacts[:artifact_identifier]
            override_artifact_name project_attrs.artifacts[:override_artifact_name] if project_attrs.artifacts.key?(:override_artifact_name)
          end
          
          # Secondary artifacts
          project_attrs.secondary_artifacts.each do |secondary_artifact|
            secondary_artifacts do
              artifact_identifier secondary_artifact[:artifact_identifier]
              type secondary_artifact[:type]
              location secondary_artifact[:location] if secondary_artifact[:location]
              name secondary_artifact[:name] if secondary_artifact[:name]
              namespace_type secondary_artifact[:namespace_type] if secondary_artifact[:namespace_type]
              packaging secondary_artifact[:packaging] if secondary_artifact[:packaging]
              path secondary_artifact[:path] if secondary_artifact[:path]
              encryption_disabled secondary_artifact[:encryption_disabled] if secondary_artifact.key?(:encryption_disabled)
              override_artifact_name secondary_artifact[:override_artifact_name] if secondary_artifact.key?(:override_artifact_name)
            end
          end
          
          # Environment configuration
          environment do
            type project_attrs.environment[:type]
            image project_attrs.environment[:image]
            compute_type project_attrs.environment[:compute_type]
            privileged_mode project_attrs.environment[:privileged_mode] if project_attrs.environment.key?(:privileged_mode)
            certificate project_attrs.environment[:certificate] if project_attrs.environment[:certificate]
            image_pull_credentials_type project_attrs.environment[:image_pull_credentials_type] if project_attrs.environment[:image_pull_credentials_type]
            
            # Environment variables
            if project_attrs.environment[:environment_variables]
              project_attrs.environment[:environment_variables].each do |env_var|
                environment_variable do
                  name env_var[:name]
                  value env_var[:value]
                  type env_var[:type] if env_var[:type]
                end
              end
            end
            
            # Registry credential
            if project_attrs.environment[:registry_credential]
              registry_credential do
                credential project_attrs.environment[:registry_credential][:credential]
                credential_provider project_attrs.environment[:registry_credential][:credential_provider]
              end
            end
          end
          
          # Cache configuration
          if project_attrs.cache[:type] != 'NO_CACHE'
            cache do
              type project_attrs.cache[:type]
              location project_attrs.cache[:location] if project_attrs.cache[:location]
              modes project_attrs.cache[:modes] if project_attrs.cache[:modes]
            end
          end
          
          # VPC configuration
          if project_attrs.vpc_config
            vpc_config do
              vpc_id project_attrs.vpc_config[:vpc_id]
              subnets project_attrs.vpc_config[:subnets]
              security_group_ids project_attrs.vpc_config[:security_group_ids]
            end
          end
          
          # Logs configuration
          if project_attrs.logs_config.any?
            logs_config do
              if project_attrs.logs_config[:cloudwatch_logs]
                cloudwatch_logs do
                  status project_attrs.logs_config[:cloudwatch_logs][:status] if project_attrs.logs_config[:cloudwatch_logs][:status]
                  group_name project_attrs.logs_config[:cloudwatch_logs][:group_name] if project_attrs.logs_config[:cloudwatch_logs][:group_name]
                  stream_name project_attrs.logs_config[:cloudwatch_logs][:stream_name] if project_attrs.logs_config[:cloudwatch_logs][:stream_name]
                end
              end
              
              if project_attrs.logs_config[:s3_logs]
                s3_logs do
                  status project_attrs.logs_config[:s3_logs][:status] if project_attrs.logs_config[:s3_logs][:status]
                  location project_attrs.logs_config[:s3_logs][:location] if project_attrs.logs_config[:s3_logs][:location]
                  encryption_disabled project_attrs.logs_config[:s3_logs][:encryption_disabled] if project_attrs.logs_config[:s3_logs].key?(:encryption_disabled)
                end
              end
            end
          end
          
          # Build batch configuration
          if project_attrs.build_batch_config
            build_batch_config do
              service_role project_attrs.build_batch_config[:service_role]
              combine_artifacts project_attrs.build_batch_config[:combine_artifacts] if project_attrs.build_batch_config.key?(:combine_artifacts)
              timeout_in_mins project_attrs.build_batch_config[:timeout_in_mins] if project_attrs.build_batch_config[:timeout_in_mins]
              
              if project_attrs.build_batch_config[:restrictions]
                restrictions do
                  compute_types_allowed project_attrs.build_batch_config[:restrictions][:compute_types_allowed] if project_attrs.build_batch_config[:restrictions][:compute_types_allowed]
                  maximum_builds_allowed project_attrs.build_batch_config[:restrictions][:maximum_builds_allowed] if project_attrs.build_batch_config[:restrictions][:maximum_builds_allowed]
                end
              end
            end
          end
          
          # File system locations
          project_attrs.file_system_locations.each do |fs_location|
            file_system_locations do
              type fs_location[:type]
              location fs_location[:location]
              mount_point fs_location[:mount_point]
              identifier fs_location[:identifier]
              mount_options fs_location[:mount_options] if fs_location[:mount_options]
            end
          end
          
          # Apply tags
          if project_attrs.tags.any?
            tags do
              project_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codebuild_project',
          name: name,
          resource_attributes: project_attrs.to_h,
          outputs: {
            id: "${aws_codebuild_project.#{name}.id}",
            arn: "${aws_codebuild_project.#{name}.arn}",
            name: "${aws_codebuild_project.#{name}.name}",
            badge_url: "${aws_codebuild_project.#{name}.badge_url}",
            service_role: "${aws_codebuild_project.#{name}.service_role}"
          },
          computed: {
            uses_vpc: project_attrs.uses_vpc?,
            has_secondary_sources: project_attrs.has_secondary_sources?,
            has_secondary_artifacts: project_attrs.has_secondary_artifacts?,
            cache_enabled: project_attrs.cache_enabled?,
            cloudwatch_logs_enabled: project_attrs.cloudwatch_logs_enabled?,
            s3_logs_enabled: project_attrs.s3_logs_enabled?,
            environment_variable_count: project_attrs.environment_variable_count,
            uses_secrets: project_attrs.uses_secrets?,
            compute_size: project_attrs.compute_size
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)