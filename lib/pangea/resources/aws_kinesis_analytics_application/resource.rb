# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_kinesis_analytics_application/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Kinesis Analytics Application for real-time stream processing
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Kinesis Analytics Application attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_kinesis_analytics_application(name, attributes = {})
        # Validate attributes using dry-struct
        analytics_attrs = Types::KinesisAnalyticsApplicationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_kinesisanalyticsv2_application, name) do
          name analytics_attrs.name
          runtime_environment analytics_attrs.runtime_environment
          service_execution_role analytics_attrs.service_execution_role
          start_application analytics_attrs.start_application
          description analytics_attrs.description if analytics_attrs.description
          
          # Application configuration
          if analytics_attrs.application_configuration
            application_configuration do
              app_config = analytics_attrs.application_configuration
              
              # Application code configuration
              if app_config[:application_code_configuration]
                application_code_configuration do
                  code_config = app_config[:application_code_configuration]
                  code_content_type code_config[:code_content_type]
                  
                  code_content do
                    content = code_config[:code_content]
                    text_content content[:text_content] if content[:text_content]
                    zip_file_content content[:zip_file_content] if content[:zip_file_content]
                    
                    if content[:s3_content_location]
                      s3_content_location do
                        s3_location = content[:s3_content_location]
                        bucket_arn s3_location[:bucket_arn]
                        file_key s3_location[:file_key]
                        object_version s3_location[:object_version] if s3_location[:object_version]
                      end
                    end
                  end
                end
              end
              
              # Flink application configuration
              if app_config[:flink_application_configuration]
                flink_application_configuration do
                  flink_config = app_config[:flink_application_configuration]
                  
                  if flink_config[:checkpoint_configuration]
                    checkpoint_configuration do
                      checkpoint_config = flink_config[:checkpoint_configuration]
                      configuration_type checkpoint_config[:configuration_type]
                      checkpointing_enabled checkpoint_config[:checkpointing_enabled] if checkpoint_config.key?(:checkpointing_enabled)
                      checkpoint_interval checkpoint_config[:checkpoint_interval] if checkpoint_config[:checkpoint_interval]
                      min_pause_between_checkpoints checkpoint_config[:min_pause_between_checkpoints] if checkpoint_config[:min_pause_between_checkpoints]
                    end
                  end
                  
                  if flink_config[:monitoring_configuration]
                    monitoring_configuration do
                      monitor_config = flink_config[:monitoring_configuration]
                      configuration_type monitor_config[:configuration_type]
                      log_level monitor_config[:log_level] if monitor_config[:log_level]
                      metrics_level monitor_config[:metrics_level] if monitor_config[:metrics_level]
                    end
                  end
                  
                  if flink_config[:parallelism_configuration]
                    parallelism_configuration do
                      parallel_config = flink_config[:parallelism_configuration]
                      configuration_type parallel_config[:configuration_type]
                      parallelism parallel_config[:parallelism] if parallel_config[:parallelism]
                      parallelism_per_kpu parallel_config[:parallelism_per_kpu] if parallel_config[:parallelism_per_kpu]
                      auto_scaling_enabled parallel_config[:auto_scaling_enabled] if parallel_config.key?(:auto_scaling_enabled)
                    end
                  end
                end
              end
              
              # SQL application configuration
              if app_config[:sql_application_configuration]
                sql_application_configuration do
                  sql_config = app_config[:sql_application_configuration]
                  
                  # Inputs
                  if sql_config[:inputs]
                    sql_config[:inputs].each do |input_config|
                      input do
                        name_prefix input_config[:name_prefix]
                        
                        if input_config[:input_parallelism]
                          input_parallelism do
                            count input_config[:input_parallelism][:count] if input_config[:input_parallelism][:count]
                          end
                        end
                        
                        input_schema do
                          schema_config = input_config[:input_schema]
                          record_encoding schema_config[:record_encoding] if schema_config[:record_encoding]
                          
                          schema_config[:record_columns].each do |column|
                            record_column do
                              name column[:name]
                              sql_type column[:sql_type]
                              mapping column[:mapping] if column[:mapping]
                            end
                          end
                          
                          record_format do
                            format_config = schema_config[:record_format]
                            record_format_type format_config[:record_format_type]
                            
                            if format_config[:mapping_parameters]
                              mapping_parameters do
                                mapping_params = format_config[:mapping_parameters]
                                
                                if mapping_params[:json_mapping_parameters]
                                  json_mapping_parameters do
                                    record_row_path mapping_params[:json_mapping_parameters][:record_row_path]
                                  end
                                end
                                
                                if mapping_params[:csv_mapping_parameters]
                                  csv_mapping_parameters do
                                    csv_params = mapping_params[:csv_mapping_parameters]
                                    record_row_delimiter csv_params[:record_row_delimiter]
                                    record_column_delimiter csv_params[:record_column_delimiter]
                                  end
                                end
                              end
                            end
                          end
                        end
                        
                        if input_config[:kinesis_streams_input]
                          kinesis_streams_input do
                            resource_arn input_config[:kinesis_streams_input][:resource_arn]
                          end
                        end
                        
                        if input_config[:kinesis_firehose_input]
                          kinesis_firehose_input do
                            resource_arn input_config[:kinesis_firehose_input][:resource_arn]
                          end
                        end
                      end
                    end
                  end
                  
                  # Outputs
                  if sql_config[:outputs]
                    sql_config[:outputs].each do |output_config|
                      output do
                        name output_config[:name]
                        
                        destination_schema do
                          record_format_type output_config[:destination_schema][:record_format_type]
                        end
                        
                        if output_config[:kinesis_streams_output]
                          kinesis_streams_output do
                            resource_arn output_config[:kinesis_streams_output][:resource_arn]
                          end
                        end
                        
                        if output_config[:kinesis_firehose_output]
                          kinesis_firehose_output do
                            resource_arn output_config[:kinesis_firehose_output][:resource_arn]
                          end
                        end
                        
                        if output_config[:lambda_output]
                          lambda_output do
                            resource_arn output_config[:lambda_output][:resource_arn]
                          end
                        end
                      end
                    end
                  end
                  
                  # Reference data sources
                  if sql_config[:reference_data_sources]
                    sql_config[:reference_data_sources].each do |ref_source|
                      reference_data_source do
                        table_name ref_source[:table_name]
                        
                        reference_schema do
                          schema_config = ref_source[:reference_schema]
                          record_encoding schema_config[:record_encoding] if schema_config[:record_encoding]
                          
                          schema_config[:record_columns].each do |column|
                            record_column do
                              name column[:name]
                              sql_type column[:sql_type]
                              mapping column[:mapping] if column[:mapping]
                            end
                          end
                          
                          record_format do
                            format_config = schema_config[:record_format]
                            record_format_type format_config[:record_format_type]
                            
                            if format_config[:mapping_parameters]
                              mapping_parameters do
                                # JSON or CSV mapping parameters similar to inputs
                              end
                            end
                          end
                        end
                        
                        if ref_source[:s3_reference_data_source]
                          s3_reference_data_source do
                            s3_source = ref_source[:s3_reference_data_source]
                            bucket_arn s3_source[:bucket_arn]
                            file_key s3_source[:file_key]
                          end
                        end
                      end
                    end
                  end
                end
              end
              
              # Environment properties
              if app_config[:environment_properties]
                environment_properties do
                  app_config[:environment_properties][:property_groups].each do |prop_group|
                    property_group do
                      property_group_id prop_group[:property_group_id]
                      property_map do
                        prop_group[:property_map].each do |key, value|
                          public_send(key, value)
                        end
                      end
                    end
                  end
                end
              end
              
              # VPC configuration
              if app_config[:vpc_configuration]
                vpc_configuration do
                  vpc_config = app_config[:vpc_configuration]
                  subnet_ids vpc_config[:subnet_ids]
                  security_group_ids vpc_config[:security_group_ids]
                end
              end
            end
          end
          
          # Apply tags if present
          if analytics_attrs.tags.any?
            tags do
              analytics_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_kinesisanalyticsv2_application',
          name: name,
          resource_attributes: analytics_attrs.to_h,
          outputs: {
            id: "${aws_kinesisanalyticsv2_application.#{name}.id}",
            name: "${aws_kinesisanalyticsv2_application.#{name}.name}",
            arn: "${aws_kinesisanalyticsv2_application.#{name}.arn}",
            version_id: "${aws_kinesisanalyticsv2_application.#{name}.version_id}",
            status: "${aws_kinesisanalyticsv2_application.#{name}.status}",
            create_timestamp: "${aws_kinesisanalyticsv2_application.#{name}.create_timestamp}",
            last_update_timestamp: "${aws_kinesisanalyticsv2_application.#{name}.last_update_timestamp}",
            tags_all: "${aws_kinesisanalyticsv2_application.#{name}.tags_all}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)