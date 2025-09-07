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
require 'pangea/resources/aws_route53_query_log/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Route53 Query Log Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Route53 query log configuration attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_route53_query_log(name, attributes = {})
        # Validate attributes using dry-struct
        query_log_attrs = Types::Route53QueryLogAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_route53_query_log, name) do
          name query_log_attrs.name
          hosted_zone_id query_log_attrs.hosted_zone_id
          destination_arn query_log_attrs.destination_arn
          
          # Apply tags if present
          if query_log_attrs.tags.any?
            tags do
              query_log_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_route53_query_log',
          name: name,
          resource_attributes: query_log_attrs.to_h,
          outputs: {
            id: "${aws_route53_query_log.#{name}.id}",
            arn: "${aws_route53_query_log.#{name}.arn}",
            name: "${aws_route53_query_log.#{name}.name}",
            hosted_zone_id: "${aws_route53_query_log.#{name}.hosted_zone_id}",
            destination_arn: "${aws_route53_query_log.#{name}.destination_arn}",
            tags_all: "${aws_route53_query_log.#{name}.tags_all}"
          },
          computed_properties: {
            log_group_name: query_log_attrs.log_group_name,
            aws_region: query_log_attrs.aws_region,
            aws_account_id: query_log_attrs.aws_account_id,
            logging_scope: query_log_attrs.logging_scope,
            private_zone_logging: query_log_attrs.private_zone_logging?,
            configuration_warnings: query_log_attrs.validate_configuration,
            estimated_monthly_cost: query_log_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)