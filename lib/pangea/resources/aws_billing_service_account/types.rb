# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Billing service account configuration
        class BillingServiceAccountAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :account_id?, String.constrained(format: /\A\d{12}\z/).optional
          attribute :tags?, AwsTags.optional
          
          def has_account_id?
            !account_id.nil?
          end
          
          def is_master_account?
            # This would typically be determined by checking if this is the organization's master account
            true # Placeholder - would need actual AWS API integration
          end
        end
      end
    end
  end
end