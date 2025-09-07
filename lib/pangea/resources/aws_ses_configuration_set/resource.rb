# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ses_configuration_set/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS SES Configuration Set
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Configuration set attributes
      # @option attributes [String] :name The configuration set name
      # @option attributes [Hash] :delivery_options Delivery options including TLS policy
      # @option attributes [Boolean] :reputation_metrics_enabled Enable reputation tracking
      # @option attributes [Boolean] :sending_enabled Enable sending for this configuration set
      # @return [ResourceReference] Reference object with outputs
      def aws_ses_configuration_set(name, attributes = {})
        # Validate attributes using dry-struct
        config_attrs = Types::Types::SesConfigurationSetAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_ses_configuration_set, name) do
          name config_attrs.name
          
          # Delivery options
          if config_attrs.delivery_options
            delivery_options do
              tls_policy config_attrs.delivery_options[:tls_policy] if config_attrs.delivery_options[:tls_policy]
            end
          end
          
          reputation_metrics_enabled config_attrs.reputation_metrics_enabled if config_attrs.reputation_metrics_enabled != false
          sending_enabled config_attrs.sending_enabled if config_attrs.sending_enabled != true
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_ses_configuration_set',
          name: name,
          resource_attributes: config_attrs.to_h,
          outputs: {
            name: "${aws_ses_configuration_set.#{name}.name}",
            arn: "${aws_ses_configuration_set.#{name}.arn}",
            last_fresh_start: "${aws_ses_configuration_set.#{name}.last_fresh_start}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)