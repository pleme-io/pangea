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
      module ApplicationDiscoveryService
        # AWS Application Discovery Service Application resource
        # This resource manages applications within the Application Discovery Service.
        # Applications represent logical groupings of servers and help organize
        # discovered infrastructure for migration planning.
        #
        # @see https://docs.aws.amazon.com/application-discovery/latest/userguide/applications.html
        module Application
          # Creates an AWS Application Discovery Service Application
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the application
          # @option attributes [String] :name The name of the application (required)
          # @option attributes [String] :description A description of the application
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic application
          #   aws_applicationdiscoveryservice_application(:web_app, {
          #     name: "E-commerce Web Application",
          #     description: "Customer-facing web application with database backend"
          #   })
          #
          # @example Application with tags
          #   aws_applicationdiscoveryservice_application(:legacy_erp, {
          #     name: "Legacy ERP System",
          #     description: "Legacy enterprise resource planning system for migration assessment",
          #     tags: {
          #       Environment: "production",
          #       MigrationWave: "wave-2",
          #       BusinessUnit: "finance",
          #       Criticality: "high"
          #     }
          #   })
          #
          # @example Multiple applications for migration assessment
          #   [
          #     { name: :crm_system, display_name: "Customer Relationship Management", description: "Salesforce-like CRM system" },
          #     { name: :inventory_system, display_name: "Inventory Management", description: "Warehouse inventory tracking system" },
          #     { name: :hr_portal, display_name: "HR Employee Portal", description: "Human resources self-service portal" }
          #   ].each do |app|
          #     aws_applicationdiscoveryservice_application(app[:name], {
          #       name: app[:display_name],
          #       description: app[:description],
          #       tags: {
          #         MigrationWave: "wave-1",
          #         Assessment: "in-progress"
          #       }
          #     })
          #   end
          #
          # @return [ApplicationResource] The application resource
          def aws_applicationdiscoveryservice_application(name, attributes = {})
            resource :aws_applicationdiscoveryservice_application, name do
              name attributes[:name] if attributes[:name]
              description attributes[:description] if attributes[:description]
              tags attributes[:tags] if attributes[:tags]
            end
          end
        end
      end
    end
  end
end