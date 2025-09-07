# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module ServiceCatalog
        # AWS Service Catalog Tag Option Resource Association resource
        # This resource manages the association between tag options and Service Catalog resources
        # such as portfolios or products. This enables standardized tagging across the catalog.
        #
        # @see https://docs.aws.amazon.com/servicecatalog/latest/adminguide/tagoptions.html
        module TagOptionResourceAssociation
          # Creates an AWS Service Catalog Tag Option Resource Association
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the association
          # @option attributes [String] :tag_option_id The tag option identifier (required)
          # @option attributes [String] :resource_id The resource identifier (portfolio or product ID) (required)
          #
          # @example Associate tag option with portfolio
          #   aws_servicecatalog_tag_option_resource_association(:env_tag_on_portfolio, {
          #     tag_option_id: ref(:aws_servicecatalog_tag_option, :environment_prod, :id),
          #     resource_id: ref(:aws_servicecatalog_portfolio, :engineering, :id)
          #   })
          #
          # @example Associate tag option with product
          #   aws_servicecatalog_tag_option_resource_association(:cost_center_on_product, {
          #     tag_option_id: ref(:aws_servicecatalog_tag_option, :cost_center_it, :id),
          #     resource_id: ref(:aws_servicecatalog_product, :web_app, :id)
          #   })
          #
          # @example Associate multiple tag options with a resource
          #   [:environment_prod, :cost_center_it, :team_backend].each_with_index do |tag, index|
          #     aws_servicecatalog_tag_option_resource_association(:"tag_#{index}_on_product", {
          #       tag_option_id: ref(:aws_servicecatalog_tag_option, tag, :id),
          #       resource_id: ref(:aws_servicecatalog_product, :api_service, :id)
          #     })
          #   end
          #
          # @return [TagOptionResourceAssociationResource] The association resource
          def aws_servicecatalog_tag_option_resource_association(name, attributes = {})
            resource :aws_servicecatalog_tag_option_resource_association, name do
              tag_option_id attributes[:tag_option_id] if attributes[:tag_option_id]
              resource_id attributes[:resource_id] if attributes[:resource_id]
            end
          end
        end
      end
    end
  end
end