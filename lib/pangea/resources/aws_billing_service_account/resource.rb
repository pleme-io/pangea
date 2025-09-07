# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_billing_service_account/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_billing_service_account(name, attributes = {})
        billing_attrs = Types::BillingServiceAccountAttributes.new(attributes)
        
        resource(:aws_billing_service_account, name) do
          account_id billing_attrs.account_id if billing_attrs.account_id
          
          if billing_attrs.tags&.any?
            tags do
              billing_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_billing_service_account',
          name: name,
          resource_attributes: billing_attrs.to_h,
          outputs: {
            id: "${aws_billing_service_account.#{name}.id}",
            account_id: "${aws_billing_service_account.#{name}.account_id}",
            arn: "${aws_billing_service_account.#{name}.arn}",
            has_account_id: billing_attrs.has_account_id?,
            is_master_account: billing_attrs.is_master_account?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)