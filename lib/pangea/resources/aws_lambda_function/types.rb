# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Lambda function attributes with validation
        class LambdaFunctionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :function_name, Pangea::Resources::Types::String.constrained(
            min_size: 1, 
            max_size: 64,
            format: /\A[a-zA-Z0-9_-]+\z/
          )
          attribute :role, Pangea::Resources::Types::String
          attribute :handler, Pangea::Resources::Types::String
          attribute :runtime, Pangea::Resources::Types::LambdaRuntime
          
          # Code source - either filename/s3 or image_uri
          attribute :filename, Pangea::Resources::Types::String.optional
          attribute :s3_bucket, Pangea::Resources::Types::String.optional
          attribute :s3_key, Pangea::Resources::Types::String.optional
          attribute :s3_object_version, Pangea::Resources::Types::String.optional
          attribute :image_uri, Pangea::Resources::Types::String.optional
          
          # Optional attributes
          attribute :description, Pangea::Resources::Types::String.optional.default(nil)
          attribute :timeout, Pangea::Resources::Types::LambdaTimeout.default(3)
          attribute :memory_size, Pangea::Resources::Types::LambdaMemory.default(128)
          attribute :publish, Pangea::Resources::Types::Bool.default(false)
          attribute :reserved_concurrent_executions, Pangea::Resources::Types::LambdaReservedConcurrency.optional
          attribute :layers, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :architectures, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::LambdaArchitecture).default(['x86_64'].freeze)
          attribute :package_type, Pangea::Resources::Types::LambdaPackageType.default('Zip')
          
          # Environment configuration
          attribute :environment, Pangea::Resources::Types::Hash.schema(
            variables?: Pangea::Resources::Types::LambdaEnvironmentVariables.optional
          ).optional
          
          # VPC configuration
          attribute :vpc_config, Pangea::Resources::Types::LambdaVpcConfig.optional
          
          # Dead letter queue configuration
          attribute :dead_letter_config, Pangea::Resources::Types::LambdaDeadLetterConfig.optional
          
          # File system configuration (EFS)
          attribute :file_system_config, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::LambdaFileSystemConfig).default([].freeze)
          
          # Tracing configuration
          attribute :tracing_config, Pangea::Resources::Types::Hash.schema(
            mode: Pangea::Resources::Types::LambdaTracingMode
          ).optional
          
          # KMS key for environment variable encryption
          attribute :kms_key_arn, Pangea::Resources::Types::String.optional
          
          # Image configuration (for container images)
          attribute :image_config, Pangea::Resources::Types::LambdaImageConfig.optional
          
          # Code signing
          attribute :code_signing_config_arn, Pangea::Resources::Types::String.optional
          
          # Ephemeral storage
          attribute :ephemeral_storage, Pangea::Resources::Types::LambdaEphemeralStorage.optional
          
          # Snap start (Java runtimes)
          attribute :snap_start, Pangea::Resources::Types::LambdaSnapStart.optional
          
          # Logging configuration
          attribute :logging_config, Pangea::Resources::Types::Hash.schema(
            log_format?: Pangea::Resources::Types::String.constrained(included_in: ['JSON', 'Text']).optional,
            log_group?: Pangea::Resources::Types::String.optional,
            system_log_level?: Pangea::Resources::Types::String.constrained(included_in: ['DEBUG', 'INFO', 'WARN']).optional,
            application_log_level?: Pangea::Resources::Types::String.constrained(included_in: ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL']).optional
          ).optional
          
          # Tags
          attribute :tags, Pangea::Resources::Types::AwsTags
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate package type and code source consistency
            if attrs[:package_type] == 'Image'
              if attrs[:image_uri].nil?
                raise Dry::Struct::Error, "image_uri is required when package_type is 'Image'"
              end
              if attrs[:handler] || attrs[:runtime] != 'provided.al2'
                raise Dry::Struct::Error, "handler and runtime should not be specified for container images"
              end
            else
              if attrs[:image_uri]
                raise Dry::Struct::Error, "image_uri can only be used when package_type is 'Image'"
              end
              if attrs[:filename].nil? && attrs[:s3_bucket].nil?
                raise Dry::Struct::Error, "Either filename or s3_bucket/s3_key must be specified for Zip package type"
              end
              if attrs[:s3_bucket] && attrs[:s3_key].nil?
                raise Dry::Struct::Error, "s3_key is required when s3_bucket is specified"
              end
            end
            
            # Validate handler format based on runtime
            if attrs[:handler] && attrs[:runtime]
              validate_handler_format(attrs[:handler], attrs[:runtime])
            end
            
            # Validate snap start is only for Java runtimes
            if attrs[:snap_start] && attrs[:snap_start][:apply_on] != 'None'
              unless attrs[:runtime]&.start_with?('java')
                raise Dry::Struct::Error, "Snap start is only supported for Java runtimes"
              end
            end
            
            # Validate architectures
            if attrs[:architectures] && attrs[:architectures].size > 1
              raise Dry::Struct::Error, "Lambda functions can only have one architecture"
            end
            
            super(attrs)
          end
          
          # Handler format validation by runtime
          def self.validate_handler_format(handler, runtime)
            case runtime
            when /^python/
              unless handler =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\z/
                raise Dry::Struct::Error, "Python handler must be in format 'filename.function_name'"
              end
            when /^nodejs/
              unless handler =~ /\A[a-zA-Z0-9_./-]+\.[a-zA-Z_][a-zA-Z0-9_]*\z/
                raise Dry::Struct::Error, "Node.js handler must be in format 'filename.export'"
              end
            when /^java/
              unless handler =~ /\A[a-zA-Z_][a-zA-Z0-9_.$]*::[a-zA-Z_][a-zA-Z0-9_]*\z/
                raise Dry::Struct::Error, "Java handler must be in format 'package.Class::method'"
              end
            when /^dotnet/
              unless handler =~ /\A[a-zA-Z_][a-zA-Z0-9_.$]*::[a-zA-Z_][a-zA-Z0-9_.$]*::[a-zA-Z_][a-zA-Z0-9_]*\z/
                raise Dry::Struct::Error, ".NET handler must be in format 'Assembly::Namespace.Class::Method'"
              end
            when 'go1.x'
              unless handler =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
                raise Dry::Struct::Error, "Go handler must be the executable name"
              end
            when /^ruby/
              unless handler =~ /\A[a-zA-Z_][a-zA-Z0-9_/]*\.[a-zA-Z_][a-zA-Z0-9_]*\z/
                raise Dry::Struct::Error, "Ruby handler must be in format 'filename.method_name'"
              end
            end
          end
          
          # Computed properties
          def estimated_monthly_cost
            # Base cost per GB-second
            gb_seconds_cost = 0.0000166667
            # Request cost per million
            request_cost = 0.20
            
            # Assume average 100ms execution time and 1M requests/month
            execution_time_seconds = 0.1
            monthly_requests = 1_000_000
            
            gb_seconds = (memory_size / 1024.0) * execution_time_seconds * monthly_requests
            
            (gb_seconds * gb_seconds_cost) + (monthly_requests / 1_000_000 * request_cost)
          end
          
          def requires_vpc?
            !vpc_config.nil?
          end
          
          def has_dlq?
            !dead_letter_config.nil?
          end
          
          def uses_efs?
            file_system_config.any?
          end
          
          def is_container_based?
            package_type == 'Image'
          end
          
          def supports_snap_start?
            runtime&.start_with?('java')
          end
          
          def architecture
            architectures.first
          end
        end
      end
    end
  end
end