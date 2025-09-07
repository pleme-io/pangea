# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CDK
        # AWS CDK Bootstrap Version resource
        # Manages CDK bootstrap version information for environments.
        module BootstrapVersion
          def aws_cdk_bootstrap_version(name, attributes = {})
            resource(:aws_cdk_bootstrap_version, name) do
              bootstrap_version attributes[:bootstrap_version] if attributes[:bootstrap_version]
              qualifier attributes[:qualifier] if attributes[:qualifier]
            end
            
            ResourceReference.new(
              type: 'aws_cdk_bootstrap_version',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cdk_bootstrap_version.#{name}.id}",
                version: "${aws_cdk_bootstrap_version.#{name}.version}"
              }
            )
          end
        end
      end
    end
  end
end