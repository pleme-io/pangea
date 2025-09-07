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
      module ServiceCatalog
        # AWS Service Catalog Product resource
        # This resource manages a Service Catalog product which represents a service or application
        # that you want to make available for deployment on AWS. Products are versioned and can
        # be associated with portfolios for access control and distribution.
        #
        # @see https://docs.aws.amazon.com/servicecatalog/latest/adminguide/productmgmt.html
        module Product
          # Creates an AWS Service Catalog Product
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the product
          # @option attributes [String] :name The name of the product (required)
          # @option attributes [String] :owner The owner of the product (required)
          # @option attributes [String] :type The type of product (default: "CLOUD_FORMATION_TEMPLATE")
          # @option attributes [String] :description The description of the product
          # @option attributes [String] :distributor The distributor of the product
          # @option attributes [String] :support_description The support information about the product
          # @option attributes [String] :support_email The contact email for product support
          # @option attributes [String] :support_url The contact URL for product support
          # @option attributes [Hash] :provisioning_artifact_parameters Parameters for the product version (required)
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic CloudFormation product
          #   aws_servicecatalog_product(:web_app_product, {
          #     name: "Web Application Template",
          #     owner: "Engineering Team",
          #     type: "CLOUD_FORMATION_TEMPLATE",
          #     provisioning_artifact_parameters: {
          #       name: "v1.0",
          #       description: "Initial version",
          #       template_url: "https://s3.amazonaws.com/mybucket/web-app-template.yaml",
          #       type: "CLOUD_FORMATION_TEMPLATE"
          #     }
          #   })
          #
          # @example Product with full configuration
          #   aws_servicecatalog_product(:database_product, {
          #     name: "RDS Database Stack",
          #     owner: "Database Team",
          #     type: "CLOUD_FORMATION_TEMPLATE",
          #     description: "Managed RDS database with automated backups",
          #     distributor: "IT Department",
          #     support_description: "Contact DBA team for support",
          #     support_email: "dba-team@company.com",
          #     support_url: "https://wiki.company.com/database-support",
          #     provisioning_artifact_parameters: {
          #       name: "v2.0",
          #       description: "Multi-AZ support added",
          #       template_url: "s3://cloudformation-templates/rds-stack-v2.yaml",
          #       type: "CLOUD_FORMATION_TEMPLATE",
          #       disable_template_validation: false
          #     },
          #     tags: {
          #       Team: "Database",
          #       Service: "RDS"
          #     }
          #   })
          #
          # @return [ProductResource] The product resource
          def aws_servicecatalog_product(name, attributes = {})
            resource :aws_servicecatalog_product, name do
              name attributes[:name] if attributes[:name]
              owner attributes[:owner] if attributes[:owner]
              type attributes[:type] if attributes[:type]
              description attributes[:description] if attributes[:description]
              distributor attributes[:distributor] if attributes[:distributor]
              support_description attributes[:support_description] if attributes[:support_description]
              support_email attributes[:support_email] if attributes[:support_email]
              support_url attributes[:support_url] if attributes[:support_url]
              
              if attributes[:provisioning_artifact_parameters]
                provisioning_artifact_parameters do
                  name attributes[:provisioning_artifact_parameters][:name]
                  description attributes[:provisioning_artifact_parameters][:description]
                  template_url attributes[:provisioning_artifact_parameters][:template_url]
                  type attributes[:provisioning_artifact_parameters][:type]
                  disable_template_validation attributes[:provisioning_artifact_parameters][:disable_template_validation] if attributes[:provisioning_artifact_parameters].key?(:disable_template_validation)
                end
              end
              
              tags attributes[:tags] if attributes[:tags]
            end
          end
        end
      end
    end
  end
end