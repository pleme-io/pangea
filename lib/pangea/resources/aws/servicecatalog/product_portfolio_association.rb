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
        # AWS Service Catalog Product Portfolio Association resource
        # This resource manages the association between Service Catalog products and portfolios.
        # Products must be associated with portfolios to be made available to end users.
        #
        # @see https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios_adding-products.html
        module ProductPortfolioAssociation
          # Creates an AWS Service Catalog Product Portfolio Association
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the association
          # @option attributes [String] :portfolio_id The portfolio identifier (required)
          # @option attributes [String] :product_id The product identifier (required)
          # @option attributes [String] :source_portfolio_id The identifier of the source portfolio (for shared products)
          # @option attributes [String] :accept_language The language code (default: "en")
          #
          # @example Basic product-portfolio association
          #   aws_servicecatalog_product_portfolio_association(:web_app_to_engineering, {
          #     portfolio_id: ref(:aws_servicecatalog_portfolio, :engineering, :id),
          #     product_id: ref(:aws_servicecatalog_product, :web_app, :id)
          #   })
          #
          # @example Associate shared product
          #   aws_servicecatalog_product_portfolio_association(:shared_product_association, {
          #     portfolio_id: ref(:aws_servicecatalog_portfolio, :department_portfolio, :id),
          #     product_id: "prod-abcdef123456",
          #     source_portfolio_id: "port-shared123456"
          #   })
          #
          # @example Multiple product associations
          #   [:web_app, :api_service, :database].each do |product|
          #     aws_servicecatalog_product_portfolio_association(:"#{product}_association", {
          #       portfolio_id: ref(:aws_servicecatalog_portfolio, :main, :id),
          #       product_id: ref(:aws_servicecatalog_product, product, :id)
          #     })
          #   end
          #
          # @return [ProductPortfolioAssociationResource] The association resource
          def aws_servicecatalog_product_portfolio_association(name, attributes = {})
            resource :aws_servicecatalog_product_portfolio_association, name do
              portfolio_id attributes[:portfolio_id] if attributes[:portfolio_id]
              product_id attributes[:product_id] if attributes[:product_id]
              source_portfolio_id attributes[:source_portfolio_id] if attributes[:source_portfolio_id]
              accept_language attributes[:accept_language] if attributes[:accept_language]
            end
          end
        end
      end
    end
  end
end