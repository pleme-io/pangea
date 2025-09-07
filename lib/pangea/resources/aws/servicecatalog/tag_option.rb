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
        # AWS Service Catalog Tag Option resource
        # This resource manages tag options which are key-value pairs that can be applied
        # to Service Catalog resources. Tag options help standardize tagging across
        # portfolios and products.
        #
        # @see https://docs.aws.amazon.com/servicecatalog/latest/adminguide/tagoptions.html
        module TagOption
          # Creates an AWS Service Catalog Tag Option
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the tag option
          # @option attributes [String] :key The key of the tag option (required)
          # @option attributes [String] :value The value of the tag option (required)
          # @option attributes [Boolean] :active Whether the tag option is active (default: true)
          #
          # @example Basic tag option
          #   aws_servicecatalog_tag_option(:environment_tag, {
          #     key: "Environment",
          #     value: "Production"
          #   })
          #
          # @example Multiple tag options for standardization
          #   [
          #     { name: :env_prod, key: "Environment", value: "Production" },
          #     { name: :env_staging, key: "Environment", value: "Staging" },
          #     { name: :env_dev, key: "Environment", value: "Development" },
          #     { name: :cost_center_it, key: "CostCenter", value: "IT-001" },
          #     { name: :cost_center_eng, key: "CostCenter", value: "ENG-002" }
          #   ].each do |tag|
          #     aws_servicecatalog_tag_option(tag[:name], {
          #       key: tag[:key],
          #       value: tag[:value]
          #     })
          #   end
          #
          # @example Inactive tag option
          #   aws_servicecatalog_tag_option(:deprecated_tag, {
          #     key: "OldTag",
          #     value: "OldValue",
          #     active: false
          #   })
          #
          # @return [TagOptionResource] The tag option resource
          def aws_servicecatalog_tag_option(name, attributes = {})
            resource :aws_servicecatalog_tag_option, name do
              key attributes[:key] if attributes[:key]
              value attributes[:value] if attributes[:value]
              active attributes[:active] if attributes.key?(:active)
            end
          end
        end
      end
    end
  end
end