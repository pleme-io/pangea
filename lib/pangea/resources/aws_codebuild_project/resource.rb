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
require 'pangea/resources/aws_codebuild_project/block_builders'
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
        project_attrs = Types::CodeBuildProjectAttributes.new(attributes)
        builders = CodeBuildBlockBuilders

        resource(:aws_codebuild_project, name) do
          name project_attrs.name
          description project_attrs.description if project_attrs.description
          service_role project_attrs.service_role

          build_timeout project_attrs.build_timeout
          queued_timeout project_attrs.queued_timeout
          concurrent_build_limit project_attrs.concurrent_build_limit if project_attrs.concurrent_build_limit

          badge_enabled project_attrs.badge_enabled
          encryption_key project_attrs.encryption_key if project_attrs.encryption_key
          resource_access_role project_attrs.resource_access_role if project_attrs.resource_access_role

          builders.apply_source(self, project_attrs.source)
          builders.apply_secondary_sources(self, project_attrs.secondary_sources)
          builders.apply_artifacts(self, project_attrs.artifacts)
          builders.apply_secondary_artifacts(self, project_attrs.secondary_artifacts)
          builders.apply_environment(self, project_attrs.environment)

          if project_attrs.cache[:type] != 'NO_CACHE'
            cache do
              type project_attrs.cache[:type]
              location project_attrs.cache[:location] if project_attrs.cache[:location]
              modes project_attrs.cache[:modes] if project_attrs.cache[:modes]
            end
          end

          if project_attrs.vpc_config
            vpc_config do
              vpc_id project_attrs.vpc_config[:vpc_id]
              subnets project_attrs.vpc_config[:subnets]
              security_group_ids project_attrs.vpc_config[:security_group_ids]
            end
          end

          builders.apply_logs_config(self, project_attrs.logs_config)
          builders.apply_build_batch_config(self, project_attrs.build_batch_config)

          project_attrs.file_system_locations.each do |fs_location|
            file_system_locations do
              type fs_location[:type]
              location fs_location[:location]
              mount_point fs_location[:mount_point]
              identifier fs_location[:identifier]
              mount_options fs_location[:mount_options] if fs_location[:mount_options]
            end
          end

          if project_attrs.tags.any?
            tags do
              project_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

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
