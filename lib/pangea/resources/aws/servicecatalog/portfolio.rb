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
        # AWS Service Catalog Portfolio resource
        # This resource manages a Service Catalog portfolio which is a collection of products
        # that your organization offers to end users. Portfolios help organize and manage
        # product access permissions and sharing across AWS accounts.
        #
        # @see https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios.html
        module Portfolio
          # Creates an AWS Service Catalog Portfolio
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the portfolio
          # @option attributes [String] :display_name The name of the portfolio (required)
          # @option attributes [String] :description The description of the portfolio
          # @option attributes [String] :provider_name The name of the person or organization who owns the portfolio (required)
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic portfolio
          #   aws_servicecatalog_portfolio(:engineering_portfolio, {
          #     display_name: "Engineering Portfolio",
          #     description: "Portfolio for engineering team products",
          #     provider_name: "Engineering Team"
          #   })
          #
          # @example Portfolio with tags
          #   aws_servicecatalog_portfolio(:prod_portfolio, {
          #     display_name: "Production Portfolio",
          #     description: "Production ready services and applications",
          #     provider_name: "DevOps Team",
          #     tags: {
          #       Environment: "production",
          #       Department: "IT",
          #       CostCenter: "12345"
          #     }
          #   })
          #
          # @return [PortfolioResource] The portfolio resource
          def aws_servicecatalog_portfolio(name, attributes = {})
            resource :aws_servicecatalog_portfolio, name do
              display_name attributes[:display_name] if attributes[:display_name]
              description attributes[:description] if attributes[:description]
              provider_name attributes[:provider_name] if attributes[:provider_name]
              tags attributes[:tags] if attributes[:tags]
            end
          end
        end
      end
    end
  end
end