# frozen_string_literal: true

require 'pangea/resources/aws/servicecatalog/portfolio'
require 'pangea/resources/aws/servicecatalog/product'
require 'pangea/resources/aws/servicecatalog/constraint'
require 'pangea/resources/aws/servicecatalog/principal_portfolio_association'
require 'pangea/resources/aws/servicecatalog/product_portfolio_association'
require 'pangea/resources/aws/servicecatalog/provisioned_product'
require 'pangea/resources/aws/servicecatalog/tag_option'
require 'pangea/resources/aws/servicecatalog/tag_option_resource_association'

module Pangea
  module Resources
    module AWS
      # AWS Service Catalog resources module
      # Includes all Service Catalog resource implementations for managing portfolios,
      # products, and governance controls in AWS Service Catalog.
      module ServiceCatalog
        include Portfolio
        include Product
        include Constraint
        include PrincipalPortfolioAssociation
        include ProductPortfolioAssociation
        include ProvisionedProduct
        include TagOption
        include TagOptionResourceAssociation
      end
    end
  end
end