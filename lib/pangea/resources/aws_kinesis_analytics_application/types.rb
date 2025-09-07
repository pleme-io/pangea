# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Kinesis Analytics Application resource attributes with validation
        class KinesisAnalyticsApplicationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, String
          attribute :description, String.optional
          
          # Application configuration
          attribute :application_configuration, Hash.schema(
            application_code_configuration?: Hash.schema(
              code_content: Hash.schema(
                text_content?: String.optional,
                zip_file_content?: String.optional,
                s3_content_location?: Hash.schema(
                  bucket_arn: String,
                  file_key: String,
                  object_version?: String.optional
                ).optional
              ),
              code_content_type: String.enum('PLAINTEXT', 'ZIPFILE')
            ).optional,
            
            flink_application_configuration?: Hash.schema(
              checkpoint_configuration?: Hash.schema(
                configuration_type: String.enum('DEFAULT', 'CUSTOM'),
                checkpointing_enabled?: Bool.optional,
                checkpoint_interval?: Integer.constrained(gteq: 1000, lteq: 300000).optional,
                min_pause_between_checkpoints?: Integer.constrained(gteq: 0, lteq: 300000).optional
              ).optional,
              monitoring_configuration?: Hash.schema(
                configuration_type: String.enum('DEFAULT', 'CUSTOM'),
                log_level?: String.enum('INFO', 'WARN', 'ERROR', 'DEBUG').optional,
                metrics_level?: String.enum('APPLICATION', 'TASK', 'OPERATOR', 'PARALLELISM').optional
              ).optional,
              parallelism_configuration?: Hash.schema(
                configuration_type: String.enum('DEFAULT', 'CUSTOM'),
                parallelism?: Integer.constrained(gteq: 1, lteq: 1000).optional,
                parallelism_per_kpu?: Integer.constrained(gteq: 1, lteq: 4).optional,
                auto_scaling_enabled?: Bool.optional
              ).optional
            ).optional,
            
            sql_application_configuration?: Hash.schema(
              inputs?: Array.of(Hash.schema(
                name_prefix: String.constrained(min_size: 1, max_size: 32),
                input_parallelism?: Hash.schema(
                  count?: Integer.constrained(gteq: 1, lteq: 64).optional
                ).optional,
                input_schema: Hash.schema(
                  record_columns: Array.of(Hash.schema(
                    name: String.constrained(min_size: 1, max_size: 256),
                    sql_type: String.enum(
                      'BOOLEAN', 'INTEGER', 'BIGINT', 'DOUBLE', 'DECIMAL', 
                      'VARCHAR', 'CHAR', 'TIMESTAMP', 'DATE', 'TIME'
                    ),
                    mapping?: String.optional
                  )).constrained(min_size: 1, max_size: 1000),
                  record_format: Hash.schema(
                    record_format_type: String.enum('JSON', 'CSV'),
                    mapping_parameters?: Hash.schema(
                      json_mapping_parameters?: Hash.schema(
                        record_row_path: String
                      ).optional,
                      csv_mapping_parameters?: Hash.schema(
                        record_row_delimiter: String.constrained(min_size: 1, max_size: 1024),
                        record_column_delimiter: String.constrained(min_size: 1, max_size: 1024)
                      ).optional
                    ).optional
                  ),
                  record_encoding?: String.enum('UTF-8').optional
                ),
                kinesis_streams_input?: Hash.schema(
                  resource_arn: String
                ).optional,
                kinesis_firehose_input?: Hash.schema(
                  resource_arn: String
                ).optional
              )).optional,
              outputs?: Array.of(Hash.schema(
                name: String.constrained(min_size: 1, max_size: 32),
                destination_schema: Hash.schema(
                  record_format_type: String.enum('JSON', 'CSV')
                ),
                kinesis_streams_output?: Hash.schema(
                  resource_arn: String
                ).optional,
                kinesis_firehose_output?: Hash.schema(
                  resource_arn: String
                ).optional,
                lambda_output?: Hash.schema(
                  resource_arn: String
                ).optional
              )).optional,
              reference_data_sources?: Array.of(Hash.schema(
                table_name: String.constrained(min_size: 1, max_size: 32),
                reference_schema: Hash.schema(
                  record_columns: Array.of(Hash.schema(
                    name: String,
                    sql_type: String,
                    mapping?: String.optional
                  )),
                  record_format: Hash.schema(
                    record_format_type: String.enum('JSON', 'CSV'),
                    mapping_parameters?: Hash.optional
                  ),
                  record_encoding?: String.enum('UTF-8').optional
                ),
                s3_reference_data_source?: Hash.schema(
                  bucket_arn: String,
                  file_key: String
                ).optional
              )).optional
            ).optional,
            
            environment_properties?: Hash.schema(
              property_groups: Array.of(Hash.schema(
                property_group_id: String.constrained(min_size: 1, max_size: 50),
                property_map: Hash.map(
                  String.constrained(min_size: 1, max_size: 2048),
                  String.constrained(min_size: 1, max_size: 2048)
                )
              ))
            ).optional,
            
            vpc_configuration?: Hash.schema(
              subnet_ids: Array.of(String).constrained(min_size: 2, max_size: 16),
              security_group_ids: Array.of(String).constrained(min_size: 1, max_size: 5)
            ).optional
          ).optional
          
          attribute :service_execution_role, String
          attribute :runtime_environment, String.enum('SQL-1_0', 'FLINK-1_6', 'FLINK-1_8', 'FLINK-1_11', 'FLINK-1_13', 'FLINK-1_15', 'FLINK-1_18')
          attribute :start_application, Bool.default(false)
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate service execution role ARN
            if attrs[:service_execution_role] && !valid_iam_role_arn?(attrs[:service_execution_role])
              raise Dry::Struct::Error, "Invalid service execution role ARN: #{attrs[:service_execution_role]}"
            end
            
            # Validate runtime environment vs configuration compatibility
            runtime = attrs[:runtime_environment]
            app_config = attrs[:application_configuration]
            
            if runtime && app_config
              if runtime == 'SQL-1_0' && !app_config[:sql_application_configuration]
                raise Dry::Struct::Error, "SQL-1_0 runtime requires sql_application_configuration"
              end
              
              if runtime.start_with?('FLINK') && !app_config[:flink_application_configuration] && !app_config[:application_code_configuration]
                raise Dry::Struct::Error, "Flink runtime requires flink_application_configuration and/or application_code_configuration"
              end
            end
            
            # Validate code content configuration
            if app_config&.dig(:application_code_configuration)
              code_config = app_config[:application_code_configuration]
              content = code_config[:code_content]
              content_type = code_config[:code_content_type]
              
              case content_type
              when 'PLAINTEXT'
                unless content[:text_content]
                  raise Dry::Struct::Error, "PLAINTEXT code content type requires text_content"
                end
              when 'ZIPFILE'
                unless content[:zip_file_content] || content[:s3_content_location]
                  raise Dry::Struct::Error, "ZIPFILE code content type requires zip_file_content or s3_content_location"
                end
              end
            end
            
            # Validate SQL application inputs/outputs
            if app_config&.dig(:sql_application_configuration)
              sql_config = app_config[:sql_application_configuration]
              
              # Validate inputs have either Kinesis Streams or Kinesis Firehose
              if sql_config[:inputs]
                sql_config[:inputs].each do |input|
                  unless input[:kinesis_streams_input] || input[:kinesis_firehose_input]
                    raise Dry::Struct::Error, "SQL input '#{input[:name_prefix]}' must have either kinesis_streams_input or kinesis_firehose_input"
                  end
                end
              end
              
              # Validate outputs have a destination
              if sql_config[:outputs]
                sql_config[:outputs].each do |output|
                  unless output[:kinesis_streams_output] || output[:kinesis_firehose_output] || output[:lambda_output]
                    raise Dry::Struct::Error, "SQL output '#{output[:name]}' must have a destination (kinesis_streams_output, kinesis_firehose_output, or lambda_output)"
                  end
                end
              end
            end
            
            super(attrs)
          end
          
          # Validation helpers
          def self.valid_iam_role_arn?(arn)
            arn.match?(/\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_\+\=\,\.\@\-]+\z/)
          end
          
          # Computed properties
          def is_sql_application?
            runtime_environment == 'SQL-1_0'
          end
          
          def is_flink_application?
            runtime_environment.start_with?('FLINK')
          end
          
          def has_vpc_configuration?
            application_configuration&.dig(:vpc_configuration) != nil
          end
          
          def has_code_from_s3?
            application_configuration&.dig(:application_code_configuration, :code_content, :s3_content_location) != nil
          end
          
          def has_monitoring_enabled?
            flink_config = application_configuration&.dig(:flink_application_configuration, :monitoring_configuration)
            return false unless flink_config
            flink_config[:configuration_type] == 'CUSTOM'
          end
          
          def has_checkpointing_enabled?
            checkpoint_config = application_configuration&.dig(:flink_application_configuration, :checkpoint_configuration)
            return false unless checkpoint_config
            checkpoint_config[:configuration_type] == 'CUSTOM' && checkpoint_config[:checkpointing_enabled] == true
          end
          
          def parallelism_level
            parallel_config = application_configuration&.dig(:flink_application_configuration, :parallelism_configuration)
            return nil unless parallel_config
            parallel_config[:parallelism] || 1
          end
          
          def auto_scaling_enabled?
            parallel_config = application_configuration&.dig(:flink_application_configuration, :parallelism_configuration)
            return false unless parallel_config
            parallel_config[:auto_scaling_enabled] == true
          end
          
          def input_count
            return 0 unless is_sql_application?
            sql_config = application_configuration&.dig(:sql_application_configuration)
            sql_config&.dig(:inputs)&.length || 0
          end
          
          def output_count
            return 0 unless is_sql_application?
            sql_config = application_configuration&.dig(:sql_application_configuration)
            sql_config&.dig(:outputs)&.length || 0
          end
          
          def reference_data_source_count
            return 0 unless is_sql_application?
            sql_config = application_configuration&.dig(:sql_application_configuration)
            sql_config&.dig(:reference_data_sources)&.length || 0
          end
          
          def estimated_kpu_usage
            if is_sql_application?
              # SQL applications typically use 1 KPU minimum
              base_kpu = 1
              # Add KPU for inputs and outputs
              additional_kpu = (input_count + output_count) * 0.1
              (base_kpu + additional_kpu).ceil
            elsif is_flink_application?
              # Flink applications based on parallelism
              parallelism = parallelism_level || 1
              kpu_per_parallelism = application_configuration&.dig(:flink_application_configuration, :parallelism_configuration, :parallelism_per_kpu) || 1
              (parallelism.to_f / kpu_per_parallelism).ceil
            else
              1
            end
          end
          
          def estimated_monthly_cost_usd
            kpu_usage = estimated_kpu_usage
            hours_per_month = 24 * 30 # 30 days
            cost_per_kpu_hour = 0.11 # $0.11 per KPU-hour
            
            monthly_cost = kpu_usage * hours_per_month * cost_per_kpu_hour
            monthly_cost.round(2)
          end
        end
      end
    end
  end
end