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
        # AWS Service Catalog Constraint resource
        # This resource manages constraints on Service Catalog products within a portfolio.
        # Constraints control the deployment options and parameters for products when they
        # are launched by end users.
        #
        # @see https://docs.aws.amazon.com/servicecatalog/latest/adminguide/constraints.html
        module Constraint
          # Creates an AWS Service Catalog Constraint
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the constraint
          # @option attributes [String] :portfolio_id The portfolio identifier (required)
          # @option attributes [String] :product_id The product identifier (required)
          # @option attributes [String] :type The type of constraint (required)
          # @option attributes [String] :parameters JSON string of constraint parameters (required for most types)
          # @option attributes [String] :description A description of the constraint
          # @option attributes [String] :accept_language The language code (default: "en")
          #
          # @example Launch constraint
          #   aws_servicecatalog_constraint(:launch_role_constraint, {
          #     portfolio_id: ref(:aws_servicecatalog_portfolio, :main, :id),
          #     product_id: ref(:aws_servicecatalog_product, :web_app, :id),
          #     type: "LAUNCH",
          #     parameters: JSON.generate({
          #       RoleArn: ref(:aws_iam_role, :launch_role, :arn)
          #     })
          #   })
          #
          # @example Template constraint
          #   aws_servicecatalog_constraint(:parameter_constraint, {
          #     portfolio_id: ref(:aws_servicecatalog_portfolio, :main, :id),
          #     product_id: ref(:aws_servicecatalog_product, :database, :id),
          #     type: "TEMPLATE",
          #     description: "Restrict database instance types",
          #     parameters: JSON.generate({
          #       Rules: {
          #         InstanceTypeRule: {
          #           Assertions: [{
          #             Assert: { "Fn::Contains": [["db.t3.micro", "db.t3.small"], { "Ref": "InstanceType" }] },
          #             AssertDescription: "Instance type must be db.t3.micro or db.t3.small"
          #           }]
          #         }
          #       }
          #     })
          #   })
          #
          # @example Notification constraint
          #   aws_servicecatalog_constraint(:notification_constraint, {
          #     portfolio_id: ref(:aws_servicecatalog_portfolio, :main, :id),
          #     product_id: ref(:aws_servicecatalog_product, :web_app, :id),
          #     type: "NOTIFICATION",
          #     description: "Send notifications on stack events",
          #     parameters: JSON.generate({
          #       NotificationArns: [ref(:aws_sns_topic, :service_catalog_events, :arn)]
          #     })
          #   })
          #
          # @return [ConstraintResource] The constraint resource
          def aws_servicecatalog_constraint(name, attributes = {})
            resource :aws_servicecatalog_constraint, name do
              portfolio_id attributes[:portfolio_id] if attributes[:portfolio_id]
              product_id attributes[:product_id] if attributes[:product_id]
              type attributes[:type] if attributes[:type]
              parameters attributes[:parameters] if attributes[:parameters]
              description attributes[:description] if attributes[:description]
              accept_language attributes[:accept_language] if attributes[:accept_language]
            end
          end
        end
      end
    end
  end
end