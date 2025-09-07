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
require 'pangea/resources/aws_kinesis_firehose_delivery_stream/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Kinesis Firehose Delivery Stream for reliable data delivery to destinations
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Kinesis Firehose Delivery Stream attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_kinesis_firehose_delivery_stream(name, attributes = {})
        # Validate attributes using dry-struct
        firehose_attrs = Types::KinesisFirehoseDeliveryStreamAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_kinesis_firehose_delivery_stream, name) do
          name firehose_attrs.name
          destination firehose_attrs.destination
          
          # Kinesis source configuration
          if firehose_attrs.has_kinesis_source?
            kinesis_source_configuration do
              kinesis_stream_arn firehose_attrs.kinesis_source_configuration[:kinesis_stream_arn]
              role_arn firehose_attrs.kinesis_source_configuration[:role_arn]
            end
          end
          
          # S3 destination configuration
          if firehose_attrs.s3_configuration
            s3_configuration do
              s3_config = firehose_attrs.s3_configuration
              role_arn s3_config[:role_arn]
              bucket_arn s3_config[:bucket_arn]
              prefix s3_config[:prefix] if s3_config[:prefix]
              error_output_prefix s3_config[:error_output_prefix] if s3_config[:error_output_prefix]
              buffer_size s3_config[:buffer_size] if s3_config[:buffer_size]
              buffer_interval s3_config[:buffer_interval] if s3_config[:buffer_interval]
              compression_format s3_config[:compression_format] if s3_config[:compression_format]
              
              if s3_config[:encryption_configuration]
                encryption_configuration do
                  enc_config = s3_config[:encryption_configuration]
                  if enc_config[:no_encryption_config]
                    no_encryption_config enc_config[:no_encryption_config]
                  elsif enc_config[:kms_encryption_config]
                    kms_encryption_config do
                      aws_kms_key_arn enc_config[:kms_encryption_config][:aws_kms_key_arn]
                    end
                  end
                end
              end
              
              if s3_config[:cloudwatch_logging_options]
                cloudwatch_logging_options do
                  log_config = s3_config[:cloudwatch_logging_options]
                  enabled log_config[:enabled] if log_config.key?(:enabled)
                  log_group_name log_config[:log_group_name] if log_config[:log_group_name]
                  log_stream_name log_config[:log_stream_name] if log_config[:log_stream_name]
                end
              end
            end
          end
          
          # Extended S3 destination configuration
          if firehose_attrs.extended_s3_configuration
            extended_s3_configuration do
              es3_config = firehose_attrs.extended_s3_configuration
              role_arn es3_config[:role_arn]
              bucket_arn es3_config[:bucket_arn]
              prefix es3_config[:prefix] if es3_config[:prefix]
              error_output_prefix es3_config[:error_output_prefix] if es3_config[:error_output_prefix]
              buffer_size es3_config[:buffer_size] if es3_config[:buffer_size]
              buffer_interval es3_config[:buffer_interval] if es3_config[:buffer_interval]
              compression_format es3_config[:compression_format] if es3_config[:compression_format]
              s3_backup_mode es3_config[:s3_backup_mode] if es3_config[:s3_backup_mode]
              
              # Data format conversion
              if es3_config[:data_format_conversion_configuration]
                data_format_conversion_configuration do
                  df_config = es3_config[:data_format_conversion_configuration]
                  enabled df_config[:enabled]
                  
                  if df_config[:output_format_configuration]
                    output_format_configuration do
                      if df_config[:output_format_configuration][:serializer]
                        serializer do
                          ser_config = df_config[:output_format_configuration][:serializer]
                          parquet_ser_de({}) if ser_config[:parquet_ser_de]
                          orc_ser_de({}) if ser_config[:orc_ser_de]
                        end
                      end
                    end
                  end
                  
                  if df_config[:schema_configuration]
                    schema_configuration do
                      schema_config = df_config[:schema_configuration]
                      database_name schema_config[:database_name]
                      table_name schema_config[:table_name]
                      role_arn schema_config[:role_arn]
                      region schema_config[:region] if schema_config[:region]
                      catalog_id schema_config[:catalog_id] if schema_config[:catalog_id]
                      version_id schema_config[:version_id] if schema_config[:version_id]
                    end
                  end
                end
              end
              
              # Processing configuration
              if es3_config[:processing_configuration]
                processing_configuration do
                  proc_config = es3_config[:processing_configuration]
                  enabled proc_config[:enabled]
                  
                  if proc_config[:processors]
                    proc_config[:processors].each do |processor|
                      processors do
                        type processor[:type]
                        if processor[:parameters]
                          processor[:parameters].each do |param|
                            parameters do
                              parameter_name param[:parameter_name]
                              parameter_value param[:parameter_value]
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
              
              if es3_config[:cloudwatch_logging_options]
                cloudwatch_logging_options do
                  log_config = es3_config[:cloudwatch_logging_options]
                  enabled log_config[:enabled] if log_config.key?(:enabled)
                  log_group_name log_config[:log_group_name] if log_config[:log_group_name]
                  log_stream_name log_config[:log_stream_name] if log_config[:log_stream_name]
                end
              end
            end
          end
          
          # Other destination configurations (Redshift, Elasticsearch, etc.)
          if firehose_attrs.redshift_configuration
            redshift_configuration do
              rs_config = firehose_attrs.redshift_configuration
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
          
          if firehose_attrs.elasticsearch_configuration
            elasticsearch_configuration do
              es_config = firehose_attrs.elasticsearch_configuration
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
          
          if firehose_attrs.amazonopensearch_configuration
            amazonopensearch_configuration do
              aos_config = firehose_attrs.amazonopensearch_configuration
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
          
          if firehose_attrs.splunk_configuration
            splunk_configuration do
              splunk_config = firehose_attrs.splunk_configuration
              hec_endpoint splunk_config[:hec_endpoint]
              hec_token splunk_config[:hec_token]
              hec_acknowledgment_timeout splunk_config[:hec_acknowledgment_timeout] if splunk_config[:hec_acknowledgment_timeout]
              hec_endpoint_type splunk_config[:hec_endpoint_type] if splunk_config[:hec_endpoint_type]
              retry_duration splunk_config[:retry_duration] if splunk_config[:retry_duration]
              s3_backup_mode splunk_config[:s3_backup_mode] if splunk_config[:s3_backup_mode]
            end
          end
          
          if firehose_attrs.http_endpoint_configuration
            http_endpoint_configuration do
              http_config = firehose_attrs.http_endpoint_configuration
              url http_config[:url]
              name http_config[:name] if http_config[:name]
              access_key http_config[:access_key] if http_config[:access_key]
              buffering_size http_config[:buffering_size] if http_config[:buffering_size]
              buffering_interval http_config[:buffering_interval] if http_config[:buffering_interval]
              retry_duration http_config[:retry_duration] if http_config[:retry_duration]
              s3_backup_mode http_config[:s3_backup_mode] if http_config[:s3_backup_mode]
              
              if http_config[:request_configuration]
                request_configuration do
                  req_config = http_config[:request_configuration]
                  content_encoding req_config[:content_encoding] if req_config[:content_encoding]
                  if req_config[:common_attributes]
                    req_config[:common_attributes].each do |key, value|
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
          
          # Server-side encryption
          if firehose_attrs.is_encrypted?
            server_side_encryption do
              sse_config = firehose_attrs.server_side_encryption
              enabled sse_config[:enabled]
              key_type sse_config[:key_type] if sse_config[:key_type]
              key_arn sse_config[:key_arn] if sse_config[:key_arn]
            end
          end
          
          # Apply tags if present
          if firehose_attrs.tags.any?
            tags do
              firehose_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_kinesis_firehose_delivery_stream',
          name: name,
          resource_attributes: firehose_attrs.to_h,
          outputs: {
            id: "${aws_kinesis_firehose_delivery_stream.#{name}.id}",
            name: "${aws_kinesis_firehose_delivery_stream.#{name}.name}",
            arn: "${aws_kinesis_firehose_delivery_stream.#{name}.arn}",
            version_id: "${aws_kinesis_firehose_delivery_stream.#{name}.version_id}",
            destination_id: "${aws_kinesis_firehose_delivery_stream.#{name}.destination_id}",
            tags_all: "${aws_kinesis_firehose_delivery_stream.#{name}.tags_all}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)