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
        # AWS Service Catalog Provisioned Product resource
        # This resource manages a provisioned product which is an instance of a Service Catalog
        # product that has been launched. It represents the deployed resources created from
        # the product's CloudFormation template.
        #
        # @see https://docs.aws.amazon.com/servicecatalog/latest/userguide/provisioned-products.html
        module ProvisionedProduct
          # Creates an AWS Service Catalog Provisioned Product
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the provisioned product
          # @option attributes [String] :product_name The name of the product to provision
          # @option attributes [String] :product_id The ID of the product to provision
          # @option attributes [String] :provisioning_artifact_name The name of the provisioning artifact
          # @option attributes [String] :provisioning_artifact_id The ID of the provisioning artifact
          # @option attributes [String] :path_name The name of the path
          # @option attributes [String] :path_id The ID of the path
          # @option attributes [Array<Hash>] :provisioning_parameters Parameters for the provisioning
          # @option attributes [String] :provisioned_product_name The user-friendly name of the provisioned product
          # @option attributes [Array<String>] :notification_arns SNS topic ARNs for notifications
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          # @option attributes [String] :accept_language The language code (default: "en")
          #
          # @example Basic provisioned product
          #   aws_servicecatalog_provisioned_product(:web_app_instance, {
          #     product_id: ref(:aws_servicecatalog_product, :web_app, :id),
          #     provisioning_artifact_id: "pa-abc123",
          #     provisioned_product_name: "MyWebApp"
          #   })
          #
          # @example Provisioned product with parameters
          #   aws_servicecatalog_provisioned_product(:database_stack, {
          #     product_name: "RDS Database Stack",
          #     provisioning_artifact_name: "v2.0",
          #     provisioned_product_name: "ProductionDatabase",
          #     provisioning_parameters: [
          #       { key: "DBInstanceClass", value: "db.t3.medium" },
          #       { key: "AllocatedStorage", value: "100" },
          #       { key: "MultiAZ", value: "true" }
          #     ],
          #     notification_arns: [ref(:aws_sns_topic, :provisioning_alerts, :arn)],
          #     tags: {
          #       Environment: "production",
          #       Application: "backend"
          #     }
          #   })
          #
          # @return [ProvisionedProductResource] The provisioned product resource
          def aws_servicecatalog_provisioned_product(name, attributes = {})
            resource :aws_servicecatalog_provisioned_product, name do
              product_name attributes[:product_name] if attributes[:product_name]
              product_id attributes[:product_id] if attributes[:product_id]
              provisioning_artifact_name attributes[:provisioning_artifact_name] if attributes[:provisioning_artifact_name]
              provisioning_artifact_id attributes[:provisioning_artifact_id] if attributes[:provisioning_artifact_id]
              path_name attributes[:path_name] if attributes[:path_name]
              path_id attributes[:path_id] if attributes[:path_id]
              provisioned_product_name attributes[:provisioned_product_name] if attributes[:provisioned_product_name]
              notification_arns attributes[:notification_arns] if attributes[:notification_arns]
              accept_language attributes[:accept_language] if attributes[:accept_language]
              tags attributes[:tags] if attributes[:tags]
              
              if attributes[:provisioning_parameters]
                attributes[:provisioning_parameters].each do |param|
                  provisioning_parameters do
                    key param[:key]
                    value param[:value]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end