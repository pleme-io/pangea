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