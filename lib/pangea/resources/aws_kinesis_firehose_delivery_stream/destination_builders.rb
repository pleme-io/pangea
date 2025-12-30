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

require_relative 's3_builders'

module Pangea
  module Resources
    module AWS
      # Builder methods for Kinesis Firehose destination configurations
      module FirehoseDestinationBuilders
        include FirehoseS3Builders

        private

        def build_redshift_configuration(builder, rs_config)
          builder.redshift_configuration do
            role_arn rs_config[:role_arn]
            cluster_jdbcurl rs_config[:cluster_jdbcurl]
            username rs_config[:username]
            password rs_config[:password]
            data_table_name rs_config[:data_table_name]
            copy_options rs_config[:copy_options] if rs_config[:copy_options]
            data_table_columns rs_config[:data_table_columns] if rs_config[:data_table_columns]
            s3_backup_mode rs_config[:s3_backup_mode] if rs_config[:s3_backup_mode]
          end
        end

        def build_elasticsearch_configuration(builder, es_config)
          builder.elasticsearch_configuration do
            role_arn es_config[:role_arn]
            domain_arn es_config[:domain_arn]
            index_name es_config[:index_name]
            type_name es_config[:type_name] if es_config[:type_name]
            index_rotation_period es_config[:index_rotation_period] if es_config[:index_rotation_period]
            buffering_size es_config[:buffering_size] if es_config[:buffering_size]
            buffering_interval es_config[:buffering_interval] if es_config[:buffering_interval]
            retry_duration es_config[:retry_duration] if es_config[:retry_duration]
            s3_backup_mode es_config[:s3_backup_mode] if es_config[:s3_backup_mode]
          end
        end

        def build_opensearch_configuration(builder, aos_config)
          builder.amazonopensearch_configuration do
            role_arn aos_config[:role_arn]
            domain_arn aos_config[:domain_arn]
            index_name aos_config[:index_name]
            type_name aos_config[:type_name] if aos_config[:type_name]
            index_rotation_period aos_config[:index_rotation_period] if aos_config[:index_rotation_period]
            buffering_size aos_config[:buffering_size] if aos_config[:buffering_size]
            buffering_interval aos_config[:buffering_interval] if aos_config[:buffering_interval]
            retry_duration aos_config[:retry_duration] if aos_config[:retry_duration]
            s3_backup_mode aos_config[:s3_backup_mode] if aos_config[:s3_backup_mode]
          end
        end

        def build_splunk_configuration(builder, splunk_config)
          builder.splunk_configuration do
            hec_endpoint splunk_config[:hec_endpoint]
            hec_token splunk_config[:hec_token]
            hec_acknowledgment_timeout splunk_config[:hec_acknowledgment_timeout] if splunk_config[:hec_acknowledgment_timeout]
            hec_endpoint_type splunk_config[:hec_endpoint_type] if splunk_config[:hec_endpoint_type]
            retry_duration splunk_config[:retry_duration] if splunk_config[:retry_duration]
            s3_backup_mode splunk_config[:s3_backup_mode] if splunk_config[:s3_backup_mode]
          end
        end

        def build_http_endpoint_configuration(builder, http_config)
          builder.http_endpoint_configuration do
            url http_config[:url]
            name http_config[:name] if http_config[:name]
            access_key http_config[:access_key] if http_config[:access_key]
            buffering_size http_config[:buffering_size] if http_config[:buffering_size]
            buffering_interval http_config[:buffering_interval] if http_config[:buffering_interval]
            retry_duration http_config[:retry_duration] if http_config[:retry_duration]
            s3_backup_mode http_config[:s3_backup_mode] if http_config[:s3_backup_mode]

            build_http_request_configuration(self, http_config[:request_configuration]) if http_config[:request_configuration]
          end
        end

        def build_http_request_configuration(builder, req_config)
          builder.request_configuration do
            content_encoding req_config[:content_encoding] if req_config[:content_encoding]
            req_config[:common_attributes]&.each do |key, value|
              common_attributes do
                name key
                value value
              end
            end
          end
        end
      end
    end
  end
end
