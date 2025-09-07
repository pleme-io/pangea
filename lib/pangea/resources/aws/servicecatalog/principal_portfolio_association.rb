# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module ServiceCatalog
        # AWS Service Catalog Principal Portfolio Association resource
        # This resource manages the association between principals (IAM users, groups, or roles)
        # and Service Catalog portfolios. This controls who can access and launch products
        # from a portfolio.
        #
        # @see https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios_users.html
        module PrincipalPortfolioAssociation
          # Creates an AWS Service Catalog Principal Portfolio Association
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the association
          # @option attributes [String] :portfolio_id The portfolio identifier (required)
          # @option attributes [String] :principal_arn The principal ARN (IAM user, group, or role) (required)
          # @option attributes [String] :principal_type The type of principal (default: "IAM")
          # @option attributes [String] :accept_language The language code (default: "en")
          #
          # @example Associate IAM role with portfolio
          #   aws_servicecatalog_principal_portfolio_association(:dev_team_access, {
          #     portfolio_id: ref(:aws_servicecatalog_portfolio, :engineering, :id),
          #     principal_arn: ref(:aws_iam_role, :developer_role, :arn)
          #   })
          #
          # @example Associate IAM group with portfolio
          #   aws_servicecatalog_principal_portfolio_association(:admin_access, {
          #     portfolio_id: ref(:aws_servicecatalog_portfolio, :production, :id),
          #     principal_arn: "arn:aws:iam::123456789012:group/Administrators",
          #     principal_type: "IAM"
          #   })
          #
          # @example Associate with custom language
          #   aws_servicecatalog_principal_portfolio_association(:french_team_access, {
          #     portfolio_id: ref(:aws_servicecatalog_portfolio, :french_products, :id),
          #     principal_arn: ref(:aws_iam_role, :french_team_role, :arn),
          #     accept_language: "fr"
          #   })
          #
          # @return [PrincipalPortfolioAssociationResource] The association resource
          def aws_servicecatalog_principal_portfolio_association(name, attributes = {})
            resource :aws_servicecatalog_principal_portfolio_association, name do
              portfolio_id attributes[:portfolio_id] if attributes[:portfolio_id]
              principal_arn attributes[:principal_arn] if attributes[:principal_arn]
              principal_type attributes[:principal_type] if attributes[:principal_type]
              accept_language attributes[:accept_language] if attributes[:accept_language]
            end
          end
        end
      end
    end
  end
end