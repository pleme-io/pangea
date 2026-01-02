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
      # Create a Wavelength application deployment
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Application deployment attributes
      # @option attributes [String] :application_name (required) The application name
      # @option attributes [String] :wavelength_zone (required) The Wavelength zone
      # @option attributes [Hash] :application_configuration Application configuration
      # @option attributes [String] :runtime_environment Runtime environment (e.g., "docker", "kubernetes")
      # @option attributes [Hash] :network_configuration Network configuration
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_application_deployment(name, attributes = {})
        required_attrs = %i[application_name wavelength_zone]
        optional_attrs = {
          application_configuration: {},
          runtime_environment: "docker",
          network_configuration: {},
          tags: {}
        }

        app_attrs = optional_attrs.merge(attributes)

        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless app_attrs.key?(attr)
        end

        resource(:aws_wavelength_application_deployment, name) do
          application_name app_attrs[:application_name]
          wavelength_zone app_attrs[:wavelength_zone]
          runtime_environment app_attrs[:runtime_environment]

          if app_attrs[:application_configuration].any?
            application_configuration app_attrs[:application_configuration]
          end

          if app_attrs[:network_configuration].any?
            network_configuration app_attrs[:network_configuration]
          end

          if app_attrs[:tags].any?
            tags app_attrs[:tags]
          end
        end

        ResourceReference.new(
          type: 'aws_wavelength_application_deployment',
          name: name,
          resource_attributes: app_attrs,
          outputs: {
            id: "${aws_wavelength_application_deployment.#{name}.id}",
            arn: "${aws_wavelength_application_deployment.#{name}.arn}",
            endpoint_url: "${aws_wavelength_application_deployment.#{name}.endpoint_url}",
            status: "${aws_wavelength_application_deployment.#{name}.status}"
          }
        )
      end
    end
  end
end
