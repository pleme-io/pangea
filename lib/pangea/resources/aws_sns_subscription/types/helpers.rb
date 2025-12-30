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
        # Helper methods for SNS Subscription attributes
        module SNSSubscriptionHelpers
          def requires_confirmation?
            %w[email email-json http https].include?(protocol) && !endpoint_auto_confirms
          end

          def supports_filter_policy?
            %w[sqs lambda http https firehose].include?(protocol)
          end

          def supports_raw_delivery?
            %w[sqs lambda http https firehose].include?(protocol)
          end

          def supports_dlq?
            %w[sqs lambda http https firehose].include?(protocol)
          end

          def is_email_subscription?
            %w[email email-json].include?(protocol)
          end

          def is_webhook_subscription?
            %w[http https].include?(protocol)
          end

          def filter_policy_attributes
            return [] unless filter_policy

            begin
              policy = JSON.parse(filter_policy)
              policy.keys
            rescue StandardError
              []
            end
          end

          def has_numeric_filters?
            return false unless filter_policy

            begin
              policy = JSON.parse(filter_policy)
              policy.values.any? do |filter|
                filter.is_a?(Hash) && filter.key?('numeric')
              end
            rescue StandardError
              false
            end
          end
        end
      end
    end
  end
end
