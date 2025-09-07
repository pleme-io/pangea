# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Publisher resource
        # Registers the calling account as a CloudFormation type publisher.
        # This enables publishing custom types to the CloudFormation registry.
        module Publisher
          # Creates an AWS CloudFormation Publisher registration
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the publisher
          # @option attributes [String] :accept_terms_and_conditions Whether to accept terms (required)
          # @option attributes [String] :connection_arn CodeStar connection ARN
          #
          # @example Register as CloudFormation publisher
          #   cf_publisher = aws_cloudformation_publisher(:company_publisher, {
          #     accept_terms_and_conditions: true,
          #     connection_arn: ref(:aws_codestar_connection, :github_connection, :arn)
          #   })
          #
          # @return [ResourceReference] The publisher resource reference
          def aws_cloudformation_publisher(name, attributes = {})
            resource(:aws_cloudformation_publisher, name) do
              accept_terms_and_conditions attributes[:accept_terms_and_conditions] if attributes.key?(:accept_terms_and_conditions)
              connection_arn attributes[:connection_arn] if attributes[:connection_arn]
            end
            
            ResourceReference.new(
              type: 'aws_cloudformation_publisher',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cloudformation_publisher.#{name}.id}",
                publisher_id: "${aws_cloudformation_publisher.#{name}.publisher_id}",
                publisher_profile: "${aws_cloudformation_publisher.#{name}.publisher_profile}"
              }
            )
          end
        end
      end
    end
  end
end