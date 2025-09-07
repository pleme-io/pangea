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
require 'pangea/resources/aws_braket_job/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Braket Job for hybrid quantum-classical computation
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Braket job attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_braket_job(name, attributes = {})
        # Validate attributes using dry-struct
        job_attrs = Types::BraketJobAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_braket_job, name) do
          # Set job name
          job_name job_attrs.job_name
          
          # Set role ARN for execution
          role_arn job_attrs.role_arn
          
          # Set algorithm specification
          algorithm_specification do
            script_mode_config do
              entry_point job_attrs.algorithm_specification[:script_mode_config][:entry_point]
              s3_uri job_attrs.algorithm_specification[:script_mode_config][:s3_uri]
              
              if job_attrs.algorithm_specification[:script_mode_config][:compression_type]
                compression_type job_attrs.algorithm_specification[:script_mode_config][:compression_type]
              end
            end
          end
          
          # Set device configuration
          device_config do
            device job_attrs.device_config[:device]
          end
          
          # Set instance configuration
          instance_config do
            instance_type job_attrs.instance_config[:instance_type]
            volume_size_in_gb job_attrs.instance_config[:volume_size_in_gb]
            
            if job_attrs.instance_config[:instance_count]
              instance_count job_attrs.instance_config[:instance_count]
            end
          end
          
          # Set output data configuration
          output_data_config do
            s3_path job_attrs.output_data_config[:s3_path]
            
            if job_attrs.output_data_config[:kms_key_id]
              kms_key_id job_attrs.output_data_config[:kms_key_id]
            end
          end
          
          # Set checkpoint configuration if provided
          if job_attrs.checkpoint_config
            checkpoint_config do
              s3_uri job_attrs.checkpoint_config[:s3_uri]
              
              if job_attrs.checkpoint_config[:local_path]
                local_path job_attrs.checkpoint_config[:local_path]
              end
            end
          end
          
          # Set hyperparameters if provided
          if job_attrs.hyper_parameters && !job_attrs.hyper_parameters.empty?
            hyper_parameters job_attrs.hyper_parameters
          end
          
          # Set input data configuration if provided
          if job_attrs.input_data_config && !job_attrs.input_data_config.empty?
            job_attrs.input_data_config.each_with_index do |input_config, index|
              input_data_config do
                channel_name input_config[:channel_name]
                data_source do
                  s3_data_source do
                    s3_uri input_config[:data_source][:s3_data_source][:s3_uri]
                    
                    if input_config[:data_source][:s3_data_source][:s3_data_type]
                      s3_data_type input_config[:data_source][:s3_data_source][:s3_data_type]
                    end
                  end
                end
                
                if input_config[:content_type]
                  content_type input_config[:content_type]
                end
              end
            end
          end
          
          # Set stopping condition
          stopping_condition do
            max_runtime_in_seconds job_attrs.stopping_condition[:max_runtime_in_seconds]
          end
          
          # Set tags
          if job_attrs.tags && !job_attrs.tags.empty?
            tags job_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_braket_job',
          name: name,
          resource_attributes: job_attrs.to_h,
          outputs: {
            arn: "${aws_braket_job.#{name}.arn}",
            job_name: "${aws_braket_job.#{name}.job_name}",
            status: "${aws_braket_job.#{name}.status}",
            failure_reason: "${aws_braket_job.#{name}.failure_reason}",
            created_at: "${aws_braket_job.#{name}.created_at}",
            ended_at: "${aws_braket_job.#{name}.ended_at}",
            started_at: "${aws_braket_job.#{name}.started_at}",
            output_data_config: "${aws_braket_job.#{name}.output_data_config}"
          },
          computed: {
            is_hybrid_job: job_attrs.is_hybrid_job?,
            is_quantum_simulation: job_attrs.is_quantum_simulation?,
            estimated_cost_per_hour: job_attrs.estimated_cost_per_hour,
            total_volume_size_gb: job_attrs.total_volume_size_gb,
            max_runtime_hours: job_attrs.max_runtime_hours,
            has_checkpoints: job_attrs.has_checkpoints?,
            has_input_data: job_attrs.has_input_data?,
            instance_family: job_attrs.instance_family,
            compression_enabled: job_attrs.compression_enabled?,
            algorithm_entry_script: job_attrs.algorithm_entry_script,
            device_type: job_attrs.device_type
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)