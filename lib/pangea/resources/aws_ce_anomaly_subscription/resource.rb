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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ce_anomaly_subscription/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_ce_anomaly_subscription(name, attributes = {})
        subscription_attrs = Types::AnomalySubscriptionAttributes.new(attributes)
        
        resource(:aws_ce_anomaly_subscription, name) do
          name subscription_attrs.name
          frequency subscription_attrs.frequency
          monitor_arn_list subscription_attrs.monitor_arn_list
          subscribers subscription_attrs.subscribers
          threshold_expression subscription_attrs.threshold_expression if subscription_attrs.threshold_expression
          
          if subscription_attrs.tags&.any?
            tags do
              subscription_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_ce_anomaly_subscription',
          name: name,
          resource_attributes: subscription_attrs.to_h,
          outputs: {
            arn: "${aws_ce_anomaly_subscription.#{name}.arn}",
            name: "${aws_ce_anomaly_subscription.#{name}.name}",
            frequency: "${aws_ce_anomaly_subscription.#{name}.frequency}",
            subscriber_count: subscription_attrs.subscriber_count,
            monitor_count: subscription_attrs.monitor_count,
            is_immediate: subscription_attrs.is_immediate?,
            has_threshold: subscription_attrs.has_threshold?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)