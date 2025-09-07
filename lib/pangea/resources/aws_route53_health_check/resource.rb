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
require 'pangea/resources/aws_route53_health_check/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Route53 Health Check with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Route53 health check attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_route53_health_check(name, attributes = {})
        # Validate attributes using dry-struct
        health_check_attrs = AWS::Types::Types::Route53HealthCheckAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_route53_health_check, name) do
          type health_check_attrs.type
          
          # Endpoint configuration (for HTTP/HTTPS/TCP types)
          if health_check_attrs.is_endpoint_health_check?
            fqdn health_check_attrs.fqdn if health_check_attrs.fqdn
            ip_address health_check_attrs.ip_address if health_check_attrs.ip_address
            port health_check_attrs.port if health_check_attrs.port
            resource_path health_check_attrs.resource_path if health_check_attrs.resource_path
            
            # String matching configuration
            if health_check_attrs.supports_string_matching? && health_check_attrs.search_string
              search_string health_check_attrs.search_string
            end
            
            # SSL configuration
            if health_check_attrs.supports_ssl?
              enable_sni health_check_attrs.enable_sni
            end
          end
          
          # Calculated health check configuration
          if health_check_attrs.is_calculated_health_check?
            child_health_checks health_check_attrs.child_health_checks
            child_health_threshold health_check_attrs.child_health_threshold
          end
          
          # CloudWatch alarm configuration
          if health_check_attrs.is_cloudwatch_health_check?
            cloudwatch_alarm_name health_check_attrs.cloudwatch_alarm_name
            cloudwatch_alarm_region health_check_attrs.cloudwatch_alarm_region
            insufficient_data_health_status health_check_attrs.insufficient_data_health_status if health_check_attrs.insufficient_data_health_status
          end
          
          # General configuration
          failure_threshold health_check_attrs.failure_threshold
          request_interval health_check_attrs.request_interval
          
          # Optional configurations
          measure_latency health_check_attrs.measure_latency if health_check_attrs.measure_latency
          invert_healthcheck health_check_attrs.invert_healthcheck if health_check_attrs.invert_healthcheck
          disabled health_check_attrs.disabled if health_check_attrs.disabled
          reference_name health_check_attrs.reference_name if health_check_attrs.reference_name
          
          # Regions for health checking
          if health_check_attrs.regions.any?
            regions health_check_attrs.regions
          end
          
          # Apply tags if present
          if health_check_attrs.tags.any?
            tags do
              health_check_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Create resource reference
        ref = ResourceReference.new(
          type: 'aws_route53_health_check',
          name: name,
          resource_attributes: health_check_attrs.to_h,
          outputs: {
            id: "${aws_route53_health_check.#{name}.id}",
            arn: "${aws_route53_health_check.#{name}.arn}",
            reference_name: "${aws_route53_health_check.#{name}.reference_name}",
            type: "${aws_route53_health_check.#{name}.type}",
            fqdn: "${aws_route53_health_check.#{name}.fqdn}",
            ip_address: "${aws_route53_health_check.#{name}.ip_address}",
            port: "${aws_route53_health_check.#{name}.port}",
            failure_threshold: "${aws_route53_health_check.#{name}.failure_threshold}",
            request_interval: "${aws_route53_health_check.#{name}.request_interval}",
            tags_all: "${aws_route53_health_check.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_endpoint_health_check?) { health_check_attrs.is_endpoint_health_check? }
        ref.define_singleton_method(:is_calculated_health_check?) { health_check_attrs.is_calculated_health_check? }
        ref.define_singleton_method(:is_cloudwatch_health_check?) { health_check_attrs.is_cloudwatch_health_check? }
        ref.define_singleton_method(:requires_endpoint?) { health_check_attrs.requires_endpoint? }
        ref.define_singleton_method(:supports_string_matching?) { health_check_attrs.supports_string_matching? }
        ref.define_singleton_method(:supports_ssl?) { health_check_attrs.supports_ssl? }
        ref.define_singleton_method(:endpoint_identifier) { health_check_attrs.endpoint_identifier }
        ref.define_singleton_method(:default_port_for_type) { health_check_attrs.default_port_for_type }
        ref.define_singleton_method(:configuration_warnings) { health_check_attrs.validate_configuration }
        ref.define_singleton_method(:estimated_monthly_cost) { health_check_attrs.estimated_monthly_cost }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)