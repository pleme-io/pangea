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
require 'pangea/resources/aws_iot_analytics_channel/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_iot_analytics_channel(name, attributes = {})
        channel_attrs = Types::IotAnalyticsChannelAttributes.new(attributes)
        
        resource(:aws_iot_analytics_channel, name) do
          channel_name channel_attrs.channel_name
          
          if channel_attrs.channel_storage
            channel_storage do
              storage = channel_attrs.channel_storage
              if storage[:service_managed_s3]
                service_managed_s3 do
                  # Service managed S3 configuration
                end
              elsif storage[:customer_managed_s3]
                customer_managed_s3 do
                  bucket storage[:customer_managed_s3][:bucket]
                  key_prefix storage[:customer_managed_s3][:key_prefix] if storage[:customer_managed_s3][:key_prefix]
                  role_arn storage[:customer_managed_s3][:role_arn]
                end
              end
            end
          end
          
          if channel_attrs.retention_period
            retention_period do
              if channel_attrs.retention_period[:unlimited]
                unlimited channel_attrs.retention_period[:unlimited]
              else
                number_of_days channel_attrs.retention_period[:number_of_days]
              end
            end
          end
          
          if channel_attrs.tags.any?
            tags do
              channel_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_iot_analytics_channel',
          name: name,
          resource_attributes: channel_attrs.to_h,
          outputs: {
            name: "${aws_iot_analytics_channel.#{name}.name}",
            arn: "${aws_iot_analytics_channel.#{name}.arn}",
            creation_time: "${aws_iot_analytics_channel.#{name}.creation_time}",
            last_message_arrival_time: "${aws_iot_analytics_channel.#{name}.last_message_arrival_time}",
            last_update_time: "${aws_iot_analytics_channel.#{name}.last_update_time}"
          },
          computed_properties: {
            has_custom_storage: channel_attrs.has_custom_storage?,
            retention_period_days: channel_attrs.retention_period_days,
            has_unlimited_retention: channel_attrs.has_unlimited_retention?,
            storage_type: channel_attrs.storage_type,
            estimated_cost_tier: channel_attrs.estimated_cost_tier
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)