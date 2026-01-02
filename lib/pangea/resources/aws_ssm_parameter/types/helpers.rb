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
      module Types
        # Helper methods for SSM Parameter attributes
        module SsmParameterHelpers
          def is_secure_string?
            type == "SecureString"
          end

          def is_string_list?
            type == "StringList"
          end

          def is_string?
            type == "String"
          end

          def uses_kms_key?
            !key_id.nil?
          end

          def is_advanced_tier?
            tier == "Advanced"
          end

          def is_standard_tier?
            tier == "Standard"
          end

          def has_description?
            !description.nil?
          end

          def has_allowed_pattern?
            !allowed_pattern.nil?
          end

          def has_data_type?
            !data_type.nil?
          end

          def allows_overwrite?
            overwrite
          end

          def is_hierarchical?
            name.include?('/')
          end

          def parameter_path
            return '/' unless is_hierarchical?
            parts = name.split('/')[0...-1]
            parts.empty? ? '/' : parts.join('/')
          end

          def parameter_name_only
            return name unless is_hierarchical?
            name.split('/').last
          end

          def string_list_values
            return [] unless is_string_list?
            value.split(',').map(&:strip)
          end

          def estimated_monthly_cost
            # SSM Parameter Store pricing
            base_cost = 0.0

            if is_advanced_tier?
              base_cost = 0.05 # $0.05 per parameter per month for Advanced
            # Standard tier parameters are free
            end

            if is_advanced_tier?
              "~$#{base_cost}/month"
            else
              "Free (Standard tier)"
            end
          end
        end
      end
    end
  end
end
