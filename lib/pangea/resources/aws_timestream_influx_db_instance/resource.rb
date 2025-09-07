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
require 'pangea/resources/aws_timestream_influx_db_instance/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Timestream for InfluxDB instance resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_timestream_influx_db_instance(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::TimestreamInfluxDbInstanceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_timestream_influx_db_instance, name) do
          allocated_storage attrs.allocated_storage if attrs.allocated_storage
          bucket attrs.bucket if attrs.bucket
          db_instance_type attrs.db_instance_type if attrs.db_instance_type
          db_name attrs.db_name if attrs.db_name
          db_parameter_group_identifier attrs.db_parameter_group_identifier if attrs.db_parameter_group_identifier
          deployment_type attrs.deployment_type if attrs.deployment_type
          log_delivery_configuration attrs.log_delivery_configuration if attrs.log_delivery_configuration
          name attrs.name if attrs.name
          organization attrs.organization if attrs.organization
          password attrs.password if attrs.password
          publicly_accessible attrs.publicly_accessible if attrs.publicly_accessible
          username attrs.username if attrs.username
          vpc_security_group_ids attrs.vpc_security_group_ids if attrs.vpc_security_group_ids
          vpc_subnet_ids attrs.vpc_subnet_ids if attrs.vpc_subnet_ids
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_timestream_influx_db_instance',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_timestream_influx_db_instance.#{name}.id}",
            arn: "${aws_timestream_influx_db_instance.#{name}.arn}",
            availability_zone: "${aws_timestream_influx_db_instance.#{name}.availability_zone}",
            endpoint: "${aws_timestream_influx_db_instance.#{name}.endpoint}",
            influx_auth_parameters_secret_arn: "${aws_timestream_influx_db_instance.#{name}.influx_auth_parameters_secret_arn}",
            secondary_availability_zone: "${aws_timestream_influx_db_instance.#{name}.secondary_availability_zone}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)