# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Config
        # AWS Config Organization Conformance Pack resource
        # Deploys conformance packs across an AWS Organization to ensure
        # consistent compliance evaluation and remediation at scale.
        module OrganizationConformancePack
          # Creates an AWS Config Organization Conformance Pack
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the conformance pack
          # @option attributes [String] :name Name of the conformance pack (required)
          # @option attributes [String] :template_body CloudFormation template body
          # @option attributes [String] :template_s3_uri S3 location of the template
          # @option attributes [String] :delivery_s3_bucket S3 bucket for evaluation results
          # @option attributes [String] :delivery_s3_key_prefix S3 key prefix for results
          # @option attributes [Array<Hash>] :excluded_accounts Accounts to exclude
          # @option attributes [Array<Hash>] :conformance_pack_input_parameters Template parameters
          #
          # @example Organization-wide security conformance pack
          #   security_conformance = aws_config_organization_conformance_pack(:security_pack, {
          #     name: "OrganizationSecurityConformancePack",
          #     template_s3_uri: "s3://config-conformance-packs/security-pack.yaml",
          #     delivery_s3_bucket: "organization-config-delivery",
          #     delivery_s3_key_prefix: "conformance-packs/",
          #     excluded_accounts: ["111111111111"], # Sandbox account
          #     conformance_pack_input_parameters: [
          #       {
          #         parameter_name: "SecurityLevel",
          #         parameter_value: "High"
          #       },
          #       {
          #         parameter_name: "NotificationEmail",
          #         parameter_value: "security@company.com"
          #       }
          #     ]
          #   })
          #
          # @return [ResourceReference] The organization conformance pack resource reference
          def aws_config_organization_conformance_pack(name, attributes = {})
            resource(:aws_config_organization_conformance_pack, name) do
              name attributes[:name] if attributes[:name]
              template_body attributes[:template_body] if attributes[:template_body]
              template_s3_uri attributes[:template_s3_uri] if attributes[:template_s3_uri]
              delivery_s3_bucket attributes[:delivery_s3_bucket] if attributes[:delivery_s3_bucket]
              delivery_s3_key_prefix attributes[:delivery_s3_key_prefix] if attributes[:delivery_s3_key_prefix]
              
              if attributes[:excluded_accounts] && !attributes[:excluded_accounts].empty?
                attributes[:excluded_accounts].each do |account|
                  excluded_accounts account
                end
              end
              
              if attributes[:conformance_pack_input_parameters]
                attributes[:conformance_pack_input_parameters].each do |param|
                  conformance_pack_input_parameters do
                    parameter_name param[:parameter_name]
                    parameter_value param[:parameter_value]
                  end
                end
              end
            end
            
            ResourceReference.new(
              type: 'aws_config_organization_conformance_pack',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_config_organization_conformance_pack.#{name}.id}",
                arn: "${aws_config_organization_conformance_pack.#{name}.arn}"
              },
              computed_properties: {
                template_source: attributes[:template_body] ? 'inline' : 's3',
                has_excluded_accounts: attributes[:excluded_accounts]&.any? || false,
                parameter_count: attributes[:conformance_pack_input_parameters]&.length || 0
              }
            )
          end
        end
      end
    end
  end
end