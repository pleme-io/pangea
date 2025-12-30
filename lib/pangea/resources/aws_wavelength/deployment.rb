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

module Pangea
  module Resources
    module AWS
      # Create a Wavelength deployment
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Deployment attributes
      # @option attributes [String] :deployment_name (required) The deployment name
      # @option attributes [String] :workload_id (required) The workload ID
      # @option attributes [String] :deployment_configuration (required) The deployment configuration
      # @option attributes [String] :description Deployment description
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_deployment(name, attributes = {})
        required_attrs = %i[deployment_name workload_id deployment_configuration]
        optional_attrs = {
          description: nil,
          tags: {}
        }

        deploy_attrs = optional_attrs.merge(attributes)

        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless deploy_attrs.key?(attr)
        end

        resource(:aws_wavelength_deployment, name) do
          deployment_name deploy_attrs[:deployment_name]
          workload_id deploy_attrs[:workload_id]
          deployment_configuration deploy_attrs[:deployment_configuration]
          description deploy_attrs[:description] if deploy_attrs[:description]

          if deploy_attrs[:tags].any?
            tags deploy_attrs[:tags]
          end
        end

        ResourceReference.new(
          type: 'aws_wavelength_deployment',
          name: name,
          resource_attributes: deploy_attrs,
          outputs: {
            id: "${aws_wavelength_deployment.#{name}.id}",
            arn: "${aws_wavelength_deployment.#{name}.arn}",
            status: "${aws_wavelength_deployment.#{name}.status}",
            deployment_url: "${aws_wavelength_deployment.#{name}.deployment_url}"
          }
        )
      end
    end
  end
end
