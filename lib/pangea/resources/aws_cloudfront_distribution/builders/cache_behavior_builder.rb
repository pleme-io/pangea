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
      module CloudFrontDistribution
        # Builds cache behavior configuration blocks for CloudFront distributions
        module CacheBehaviorBuilder
          module_function

          def build_default_cache_behavior(context, behavior)
            context.default_cache_behavior do
              apply_cache_behavior_attributes(self, behavior)
              build_function_associations(self, behavior[:function_association])
              build_lambda_associations(self, behavior[:lambda_function_association])
            end
          end

          def build_ordered_cache_behaviors(context, behaviors)
            behaviors.each { |behavior| build_ordered_cache_behavior(context, behavior) }
          end

          def build_ordered_cache_behavior(context, behavior)
            context.ordered_cache_behavior do
              path_pattern behavior[:path_pattern]
              apply_cache_behavior_attributes(self, behavior)
              build_function_associations(self, behavior[:function_association])
              build_lambda_associations(self, behavior[:lambda_function_association])
            end
          end

          def apply_cache_behavior_attributes(context, behavior)
            context.instance_eval do
              target_origin_id behavior[:target_origin_id]
              viewer_protocol_policy behavior[:viewer_protocol_policy]
              allowed_methods behavior[:allowed_methods] if behavior[:allowed_methods]
              cached_methods behavior[:cached_methods] if behavior[:cached_methods]
              cache_policy_id behavior[:cache_policy_id] if behavior[:cache_policy_id]
              origin_request_policy_id behavior[:origin_request_policy_id] if behavior[:origin_request_policy_id]
              response_headers_policy_id behavior[:response_headers_policy_id] if behavior[:response_headers_policy_id]
              realtime_log_config_arn behavior[:realtime_log_config_arn] if behavior[:realtime_log_config_arn]
              smooth_streaming behavior[:smooth_streaming] if behavior[:smooth_streaming]
              trusted_signers behavior[:trusted_signers] if behavior[:trusted_signers]&.any?
              trusted_key_groups behavior[:trusted_key_groups] if behavior[:trusted_key_groups]&.any?
              compress behavior[:compress] if behavior.key?(:compress)
              field_level_encryption_id behavior[:field_level_encryption_id] if behavior[:field_level_encryption_id]
            end
          end

          def build_function_associations(context, associations)
            associations.each do |func_assoc|
              context.function_association do
                event_type func_assoc[:event_type]
                function_arn func_assoc[:function_arn]
              end
            end
          end

          def build_lambda_associations(context, associations)
            associations.each do |lambda_assoc|
              context.lambda_function_association do
                event_type lambda_assoc[:event_type]
                lambda_arn lambda_assoc[:lambda_arn]
                include_body lambda_assoc[:include_body] if lambda_assoc.key?(:include_body)
              end
            end
          end
        end
      end
    end
  end
end
