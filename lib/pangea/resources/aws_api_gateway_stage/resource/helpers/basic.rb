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
      module ApiGatewayStageResource
        module HelpersModules
          # Basic helper methods for API Gateway Stage resource reference
          module Basic
            def add_basic_helpers(ref, stage_attrs)
              ref.define_singleton_method(:has_caching?) { stage_attrs.has_caching? }
              ref.define_singleton_method(:has_access_logging?) { stage_attrs.has_access_logging? }
              ref.define_singleton_method(:has_canary?) { stage_attrs.has_canary? }
              ref.define_singleton_method(:has_throttling?) { stage_attrs.has_throttling? }
              ref.define_singleton_method(:has_method_settings?) { stage_attrs.has_method_settings? }
              ref.define_singleton_method(:estimated_monthly_cost) { stage_attrs.estimated_monthly_cost }
            end

            def add_stage_type_helpers(ref, stage_attrs)
              ref.define_singleton_method(:stage_type) do
                if stage_attrs.stage_name.match?(/^(prod|production)$/i)
                  "production"
                elsif stage_attrs.stage_name.match?(/^(dev|development)$/i)
                  "development"
                elsif stage_attrs.stage_name.match?(/^(stag|staging)$/i)
                  "staging"
                else
                  "custom"
                end
              end

              ref.define_singleton_method(:is_production_stage?) do
                stage_attrs.stage_name.match?(/^(prod|production)$/i)
              end

              ref.define_singleton_method(:is_development_stage?) do
                stage_attrs.stage_name.match?(/^(dev|development)$/i)
              end

              ref.define_singleton_method(:is_staging_stage?) do
                stage_attrs.stage_name.match?(/^(stag|staging)$/i)
              end
            end

            def add_variable_helpers(ref, stage_attrs)
              ref.define_singleton_method(:variable_count) { stage_attrs.variables.size }
              ref.define_singleton_method(:has_stage_variables?) { !stage_attrs.variables.empty? }
            end
          end
        end
      end
    end
  end
end
