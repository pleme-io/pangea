# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Validation logic for Braket Job attributes
        module BraketJobValidation
          def self.validate(attrs)
            validate_job_name(attrs.job_name)
            validate_role_arn(attrs.role_arn)
            validate_s3_uris(attrs)
            validate_volume_size(attrs.instance_config[:volume_size_in_gb])
            validate_instance_count(attrs)
          end

          def self.validate_job_name(job_name)
            return if job_name.match?(/\A[a-zA-Z0-9\-]{1,63}\z/)

            raise Dry::Struct::Error,
                  'job_name must be 1-63 characters long and contain only alphanumeric characters and hyphens'
          end

          def self.validate_role_arn(role_arn)
            return if role_arn.match?(/\Aarn:aws:iam::\d{12}:role\/.*\z/)

            raise Dry::Struct::Error, 'role_arn must be a valid IAM role ARN'
          end

          def self.validate_s3_uris(attrs)
            collect_s3_uris(attrs).compact.each do |s3_uri|
              next if s3_uri.match?(/\As3:\/\/[a-z0-9.\-]+(\/.*)?\z/)

              raise Dry::Struct::Error, "Invalid S3 URI format: #{s3_uri}"
            end
          end

          def self.collect_s3_uris(attrs)
            uris = [
              attrs.algorithm_specification[:script_mode_config][:s3_uri],
              attrs.output_data_config[:s3_path]
            ]
            uris << attrs.checkpoint_config[:s3_uri] if attrs.checkpoint_config
            attrs.input_data_config&.each do |input_config|
              uris << input_config[:data_source][:s3_data_source][:s3_uri]
            end
            uris
          end

          def self.validate_volume_size(volume_size)
            return if volume_size >= 1 && volume_size <= 16_384

            raise Dry::Struct::Error, 'volume_size_in_gb must be between 1 and 16384 GB'
          end

          def self.validate_instance_count(attrs)
            instance_count = attrs.instance_config[:instance_count]
            return unless instance_count && instance_count > 1
            return if attrs.device_config[:device].include?('local')

            raise Dry::Struct::Error, 'Multi-instance jobs are only supported with local simulators'
          end
        end
      end
    end
  end
end
