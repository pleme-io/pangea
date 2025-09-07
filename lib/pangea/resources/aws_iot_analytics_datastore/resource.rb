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
require 'pangea/resources/aws_iot_analytics_datastore/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_iot_analytics_datastore(name, attributes = {})
        datastore_attrs = Types::IotAnalyticsDatastoreAttributes.new(attributes)
        
        resource(:aws_iot_analytics_datastore, name) do
          datastore_name datastore_attrs.datastore_name
          
          if datastore_attrs.datastore_storage
            datastore_storage do
              storage = datastore_attrs.datastore_storage
              if storage[:service_managed_s3]
                service_managed_s3 {}
              elsif storage[:customer_managed_s3]
                customer_managed_s3 do
                  bucket storage[:customer_managed_s3][:bucket]
                  key_prefix storage[:customer_managed_s3][:key_prefix] if storage[:customer_managed_s3][:key_prefix]
                  role_arn storage[:customer_managed_s3][:role_arn]
                end
              elsif storage[:iot_site_wise_multi_layer_storage]
                iot_site_wise_multi_layer_storage do
                  customer_managed_s3_storage do
                    bucket storage[:iot_site_wise_multi_layer_storage][:customer_managed_s3_storage][:bucket]
                    key_prefix storage[:iot_site_wise_multi_layer_storage][:customer_managed_s3_storage][:key_prefix] if storage[:iot_site_wise_multi_layer_storage][:customer_managed_s3_storage][:key_prefix]
                  end
                end
              end
            end
          end
          
          if datastore_attrs.retention_period
            retention_period do
              if datastore_attrs.retention_period[:unlimited]
                unlimited datastore_attrs.retention_period[:unlimited]
              else
                number_of_days datastore_attrs.retention_period[:number_of_days]
              end
            end
          end
          
          if datastore_attrs.file_format_configuration
            file_format_configuration do
              format_config = datastore_attrs.file_format_configuration
              if format_config[:json_configuration]
                json_configuration {}
              elsif format_config[:parquet_configuration]
                parquet_configuration do
                  schema_definition format_config[:parquet_configuration][:schema_definition] if format_config[:parquet_configuration][:schema_definition]
                end
              end
            end
          end
          
          if datastore_attrs.tags.any?
            tags do
              datastore_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_iot_analytics_datastore',
          name: name,
          resource_attributes: datastore_attrs.to_h,
          outputs: {
            name: "${aws_iot_analytics_datastore.#{name}.name}",
            arn: "${aws_iot_analytics_datastore.#{name}.arn}",
            creation_time: "${aws_iot_analytics_datastore.#{name}.creation_time}",
            last_update_time: "${aws_iot_analytics_datastore.#{name}.last_update_time}",
            status: "${aws_iot_analytics_datastore.#{name}.status}"
          },
          computed_properties: {
            has_parquet_format: datastore_attrs.has_parquet_format?,
            has_json_format: datastore_attrs.has_json_format?,
            format_type: datastore_attrs.format_type,
            storage_optimization_level: datastore_attrs.storage_optimization_level,
            retention_days: datastore_attrs.retention_days,
            query_performance_tier: datastore_attrs.query_performance_tier
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)