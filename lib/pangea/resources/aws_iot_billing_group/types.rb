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
    # AWS IoT Billing Group Types
    # 
    # Billing groups enable cost allocation and usage tracking for IoT devices.
    # They help organize devices for billing purposes and provide detailed cost insights.
    module AwsIotBillingGroupTypes
      # Properties for billing group configuration
      class BillingGroupProperties < Dry::Struct
        schema schema.strict

        # Description of the billing group
        attribute :description, Resources::Types::String.optional
      end

      # Main attributes for IoT billing group resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the billing group
        attribute :billing_group_name, Resources::Types::String

        # Properties for billing group configuration
        attribute? :billing_group_properties, BillingGroupProperties.optional

        # Resource tags
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from billing group resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The billing group ARN
        attribute :arn, Resources::Types::String

        # The billing group ID
        attribute :id, Resources::Types::String

        # The billing group name
        attribute :billing_group_name, Resources::Types::String

        # The billing group version
        attribute :version, Resources::Types::Integer

        # Metadata about the billing group
        class Metadata < Dry::Struct
          schema schema.strict

          # Creation date of billing group
          attribute :creation_date, Resources::Types::String
        end

        attribute :metadata, Metadata
      end
    end
  end
end