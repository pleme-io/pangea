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
      module DynamoDBTable
        # Builds DynamoDB table optional configuration blocks
        module ConfigBuilder
          module_function

          def build_optional_features(context, attrs)
            build_ttl(context, attrs)
            build_stream(context, attrs)
            build_pitr(context, attrs)
            build_encryption(context, attrs)
            build_table_settings(context, attrs)
          end

          def build_ttl(context, attrs)
            return unless attrs.ttl

            context.ttl do
              attribute_name attrs.ttl[:attribute_name]
              enabled attrs.ttl[:enabled]
            end
          end

          def build_stream(context, attrs)
            return unless attrs.stream_enabled

            context.instance_eval do
              stream_enabled attrs.stream_enabled
              stream_view_type attrs.stream_view_type
            end
          end

          def build_pitr(context, attrs)
            context.point_in_time_recovery do
              enabled attrs.point_in_time_recovery_enabled
            end
          end

          def build_encryption(context, attrs)
            return unless attrs.server_side_encryption

            sse = attrs.server_side_encryption
            context.server_side_encryption do
              enabled sse[:enabled]
              kms_key_id sse[:kms_key_id] if sse[:kms_key_id]
            end
          end

          def build_table_settings(context, attrs)
            context.instance_eval do
              deletion_protection_enabled attrs.deletion_protection_enabled
              table_class attrs.table_class
            end
          end

          def build_restore_config(context, attrs)
            context.instance_eval do
              if attrs.restore_source_name
                restore_source_name attrs.restore_source_name
              elsif attrs.restore_source_table_arn
                restore_source_table_arn attrs.restore_source_table_arn
                restore_to_time attrs.restore_to_time if attrs.restore_to_time
                restore_date_time attrs.restore_date_time if attrs.restore_date_time
              end
            end
          end

          def build_import_config(context, attrs)
            return unless attrs.import_table

            import = attrs.import_table
            context.import_table do
              input_format import[:input_format]
              build_s3_source(self, import[:s3_bucket_source])
              build_format_options(self, import[:input_format_options])
              input_compression_type import[:input_compression_type] if import[:input_compression_type]
            end
          end

          def build_s3_source(context, source)
            context.s3_bucket_source do
              bucket source[:bucket]
              bucket_owner source[:bucket_owner] if source[:bucket_owner]
              key_prefix source[:key_prefix] if source[:key_prefix]
            end
          end

          def build_format_options(context, options)
            return unless options&.dig(:csv)

            csv_opts = options[:csv]
            context.input_format_options do
              csv do
                delimiter csv_opts[:delimiter] if csv_opts[:delimiter]
                header_list csv_opts[:header_list] if csv_opts[:header_list]
              end
            end
          end

          def build_replicas(context, attrs)
            attrs.replica.each do |replica_config|
              context.replica do
                region_name replica_config[:region_name]
                kms_key_id replica_config[:kms_key_id] if replica_config[:kms_key_id]
                point_in_time_recovery replica_config[:point_in_time_recovery] if replica_config[:point_in_time_recovery]
                table_class replica_config[:table_class] if replica_config[:table_class]
                build_replica_gsi(self, replica_config[:global_secondary_index])
              end
            end
          end

          def build_replica_gsi(context, gsi_list)
            return unless gsi_list

            gsi_list.each do |replica_gsi|
              context.global_secondary_index do
                name replica_gsi[:name]
                read_capacity replica_gsi[:read_capacity] if replica_gsi[:read_capacity]
                write_capacity replica_gsi[:write_capacity] if replica_gsi[:write_capacity]
              end
            end
          end

          def build_tags(context, attrs)
            return unless attrs.tags.any?

            context.tags do
              attrs.tags.each { |key, value| public_send(key, value) }
            end
          end
        end
      end
    end
  end
end
