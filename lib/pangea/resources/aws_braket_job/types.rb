# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Braket Job resources
      class BraketJobAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Job name (required)
        attribute :job_name, Resources::Types::String

        # Role ARN (required)
        attribute :role_arn, Resources::Types::String

        # Algorithm specification (required)
        attribute :algorithm_specification, Resources::Types::Hash.schema(
          script_mode_config: Resources::Types::Hash.schema(
            entry_point: Resources::Types::String,
            s3_uri: Resources::Types::String,
            compression_type?: Resources::Types::String.enum('NONE', 'GZIP').optional
          )
        )

        # Device configuration (required)
        attribute :device_config, Resources::Types::Hash.schema(
          device: Resources::Types::String  # Device ARN or name
        )

        # Instance configuration (required)
        attribute :instance_config, Resources::Types::Hash.schema(
          instance_type: Resources::Types::String.enum(
            'ml.m5.large',
            'ml.m5.xlarge', 
            'ml.m5.2xlarge',
            'ml.m5.4xlarge',
            'ml.m5.12xlarge',
            'ml.m5.24xlarge',
            'ml.c5.large',
            'ml.c5.xlarge',
            'ml.c5.2xlarge',
            'ml.c5.4xlarge',
            'ml.c5.9xlarge',
            'ml.c5.18xlarge',
            'ml.p3.2xlarge',
            'ml.p3.8xlarge',
            'ml.p3.16xlarge',
            'ml.g4dn.xlarge',
            'ml.g4dn.2xlarge',
            'ml.g4dn.4xlarge',
            'ml.g4dn.8xlarge',
            'ml.g4dn.12xlarge',
            'ml.g4dn.16xlarge'
          ),
          volume_size_in_gb: Resources::Types::Integer,
          instance_count?: Resources::Types::Integer.constrained(gteq: 1).optional
        )

        # Output data configuration (required)
        attribute :output_data_config, Resources::Types::Hash.schema(
          s3_path: Resources::Types::String,
          kms_key_id?: Resources::Types::String.optional
        )

        # Stopping condition (required)
        attribute :stopping_condition, Resources::Types::Hash.schema(
          max_runtime_in_seconds: Resources::Types::Integer.constrained(gteq: 1, lteq: 2592000) # Max 30 days
        )

        # Checkpoint configuration (optional)
        attribute? :checkpoint_config, Resources::Types::Hash.schema(
          s3_uri: Resources::Types::String,
          local_path?: Resources::Types::String.optional
        ).optional

        # Hyperparameters (optional)
        attribute? :hyper_parameters, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Input data configuration (optional)
        attribute? :input_data_config, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            channel_name: Resources::Types::String,
            data_source: Resources::Types::Hash.schema(
              s3_data_source: Resources::Types::Hash.schema(
                s3_uri: Resources::Types::String,
                s3_data_type?: Resources::Types::String.enum('ManifestFile', 'S3Prefix').optional
              )
            ),
            content_type?: Resources::Types::String.optional,
            compression_type?: Resources::Types::String.enum('None', 'Gzip').optional,
            record_wrapper_type?: Resources::Types::String.enum('None', 'RecordIO').optional
          )
        ).optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate job name
          unless attrs.job_name.match?(/\A[a-zA-Z0-9\-]{1,63}\z/)
            raise Dry::Struct::Error, "job_name must be 1-63 characters long and contain only alphanumeric characters and hyphens"
          end

          # Validate role ARN
          unless attrs.role_arn.match?(/\Aarn:aws:iam::\d{12}:role\/.*\z/)
            raise Dry::Struct::Error, "role_arn must be a valid IAM role ARN"
          end

          # Validate S3 URIs
          s3_uris = [
            attrs.algorithm_specification[:script_mode_config][:s3_uri],
            attrs.output_data_config[:s3_path]
          ]
          
          if attrs.checkpoint_config
            s3_uris << attrs.checkpoint_config[:s3_uri]
          end
          
          if attrs.input_data_config
            attrs.input_data_config.each do |input_config|
              s3_uris << input_config[:data_source][:s3_data_source][:s3_uri]
            end
          end

          s3_uris.compact.each do |s3_uri|
            unless s3_uri.match?(/\As3:\/\/[a-z0-9.\-]+(\/.*)?\z/)
              raise Dry::Struct::Error, "Invalid S3 URI format: #{s3_uri}"
            end
          end

          # Validate volume size
          if attrs.instance_config[:volume_size_in_gb] < 1 || attrs.instance_config[:volume_size_in_gb] > 16384
            raise Dry::Struct::Error, "volume_size_in_gb must be between 1 and 16384 GB"
          end

          # Validate instance count for distributed jobs
          if attrs.instance_config[:instance_count] && attrs.instance_config[:instance_count] > 1
            unless attrs.device_config[:device].include?('local')
              raise Dry::Struct::Error, "Multi-instance jobs are only supported with local simulators"
            end
          end

          attrs
        end

        # Helper methods
        def is_hybrid_job?
          device_config[:device].include?('hybrid')
        end

        def is_quantum_simulation?
          device_config[:device].include?('local') || device_config[:device].include?('simulator')
        end

        def estimated_cost_per_hour
          # Base cost estimates for different instance types (USD per hour)
          instance_costs = {
            'ml.m5.large' => 0.10,
            'ml.m5.xlarge' => 0.20,
            'ml.m5.2xlarge' => 0.40,
            'ml.m5.4xlarge' => 0.80,
            'ml.m5.12xlarge' => 2.40,
            'ml.m5.24xlarge' => 4.80,
            'ml.c5.large' => 0.09,
            'ml.c5.xlarge' => 0.17,
            'ml.c5.2xlarge' => 0.34,
            'ml.c5.4xlarge' => 0.68,
            'ml.c5.9xlarge' => 1.53,
            'ml.c5.18xlarge' => 3.06,
            'ml.p3.2xlarge' => 3.06,
            'ml.p3.8xlarge' => 12.24,
            'ml.p3.16xlarge' => 24.48,
            'ml.g4dn.xlarge' => 0.526,
            'ml.g4dn.2xlarge' => 0.752,
            'ml.g4dn.4xlarge' => 1.204,
            'ml.g4dn.8xlarge' => 2.176,
            'ml.g4dn.12xlarge' => 3.912,
            'ml.g4dn.16xlarge' => 4.352
          }

          base_cost = instance_costs[instance_config[:instance_type]] || 1.0
          instance_count = instance_config[:instance_count] || 1
          
          base_cost * instance_count
        end

        def total_volume_size_gb
          instance_count = instance_config[:instance_count] || 1
          instance_config[:volume_size_in_gb] * instance_count
        end

        def max_runtime_hours
          stopping_condition[:max_runtime_in_seconds] / 3600.0
        end

        def has_checkpoints?
          !checkpoint_config.nil?
        end

        def has_input_data?
          input_data_config && !input_data_config.empty?
        end

        def instance_family
          instance_config[:instance_type].split('.')[1] # ml.m5.large -> m5
        end

        def compression_enabled?
          compression_type = algorithm_specification[:script_mode_config][:compression_type]
          compression_type && compression_type != 'NONE'
        end

        def algorithm_entry_script
          algorithm_specification[:script_mode_config][:entry_point]
        end

        def device_type
          device = device_config[:device]
          
          case device
          when /local/
            'local_simulator'
          when /sv1/
            'state_vector_simulator'
          when /tn1/
            'tensor_network_simulator'
          when /dm1/
            'density_matrix_simulator'
          when /qpu/
            'quantum_processing_unit'
          else
            'unknown'
          end
        end
      end
    end
      end
    end
  end
end