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
require 'pangea/resources/aws_kinesis_analytics_application/types'
require 'pangea/resources/aws_kinesis_analytics_application/builders/application_code_builder'
require 'pangea/resources/aws_kinesis_analytics_application/builders/flink_builder'
require 'pangea/resources/aws_kinesis_analytics_application/builders/sql_builder'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Kinesis Analytics Application for real-time stream processing
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Kinesis Analytics Application attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_kinesis_analytics_application(name, attributes = {})
        # Validate attributes using dry-struct
        analytics_attrs = Types::KinesisAnalyticsApplicationAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_kinesisanalyticsv2_application, name) do
          name analytics_attrs.name
          runtime_environment analytics_attrs.runtime_environment
          service_execution_role analytics_attrs.service_execution_role
          start_application analytics_attrs.start_application
          description analytics_attrs.description if analytics_attrs.description

          # Application configuration
          build_application_configuration(self, analytics_attrs.application_configuration)

          # Apply tags if present
          build_tags(self, analytics_attrs.tags)
        end

        # Return resource reference with available outputs
        build_resource_reference(name, analytics_attrs)
      end

      private

      def build_application_configuration(context, app_config)
        return unless app_config

        context.application_configuration do
          KinesisAnalyticsApplication::Builders::ApplicationCodeBuilder.build(
            self, app_config[:application_code_configuration]
          )
          KinesisAnalyticsApplication::Builders::FlinkBuilder.build(
            self, app_config[:flink_application_configuration]
          )
          KinesisAnalyticsApplication::Builders::SqlBuilder.build(
            self, app_config[:sql_application_configuration]
          )
          build_environment_properties(self, app_config[:environment_properties])
          build_vpc_configuration(self, app_config[:vpc_configuration])
        end
      end

      def build_environment_properties(context, env_props)
        return unless env_props

        context.environment_properties do
          env_props[:property_groups].each do |prop_group|
            property_group do
              property_group_id prop_group[:property_group_id]
              property_map do
                prop_group[:property_map].each do |key, value|
                  public_send(key, value)
                end
              end
            end
          end
        end
      end

      def build_vpc_configuration(context, vpc_config)
        return unless vpc_config

        context.vpc_configuration do
          subnet_ids vpc_config[:subnet_ids]
          security_group_ids vpc_config[:security_group_ids]
        end
      end

      def build_tags(context, tags)
        return unless tags.any?

        context.tags do
          tags.each do |key, value|
            public_send(key, value)
          end
        end
      end

      def build_resource_reference(name, analytics_attrs)
        ResourceReference.new(
          type: 'aws_kinesisanalyticsv2_application',
          name: name,
          resource_attributes: analytics_attrs.to_h,
          outputs: {
            id: "${aws_kinesisanalyticsv2_application.#{name}.id}",
            name: "${aws_kinesisanalyticsv2_application.#{name}.name}",
            arn: "${aws_kinesisanalyticsv2_application.#{name}.arn}",
            version_id: "${aws_kinesisanalyticsv2_application.#{name}.version_id}",
            status: "${aws_kinesisanalyticsv2_application.#{name}.status}",
            create_timestamp: "${aws_kinesisanalyticsv2_application.#{name}.create_timestamp}",
            last_update_timestamp: "${aws_kinesisanalyticsv2_application.#{name}.last_update_timestamp}",
            tags_all: "${aws_kinesisanalyticsv2_application.#{name}.tags_all}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
