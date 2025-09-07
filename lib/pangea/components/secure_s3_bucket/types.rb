# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Components
    module SecureS3Bucket
      # Lifecycle rule configuration
      class LifecycleRule < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :id, Types::String
        attribute :status, Types::String.default("Enabled").enum('Enabled', 'Disabled')
        attribute :filter, Types::Hash.optional
        
        # Transition rules
        attribute :transitions, Types::Array.default([].freeze).constructor { |value|
          # Validate transition storage classes and days
          valid_storage_classes = [
            'STANDARD_IA', 'ONEZONE_IA', 'INTELLIGENT_TIERING', 'GLACIER_IR',
            'GLACIER', 'DEEP_ARCHIVE'
          ]
          
          value.each do |transition|
            unless valid_storage_classes.include?(transition[:storage_class])
              raise Dry::Types::ConstraintError, "Invalid storage class: #{transition[:storage_class]}"
            end
            
            unless transition[:days] && transition[:days] > 0
              raise Dry::Types::ConstraintError, "Transition days must be positive"
            end
          end
          
          value
        }
        
        # Expiration rules
        attribute :expiration, Types::Hash.optional
        attribute :noncurrent_version_expiration, Types::Hash.optional
        attribute :noncurrent_version_transitions, Types::Array.default([].freeze)
        attribute :abort_incomplete_multipart_upload, Types::Hash.optional
      end
      
      # Versioning configuration
      class VersioningConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :status, Types::S3Versioning.default("Enabled")
        attribute :mfa_delete, Types::String.optional.enum('Enabled', 'Disabled')
      end
      
      # Server-side encryption configuration
      class EncryptionConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :sse_algorithm, Types::String.default("AES256").enum('AES256', 'aws:kms', 'aws:kms:dsse')
        attribute :kms_key_id, Types::String.optional
        attribute :bucket_key_enabled, Types::Bool.default(true)
        attribute :enforce_ssl, Types::Bool.default(true)
      end
      
      # Public access block configuration
      class PublicAccessBlockConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :block_public_acls, Types::Bool.default(true)
        attribute :block_public_policy, Types::Bool.default(true)
        attribute :ignore_public_acls, Types::Bool.default(true)
        attribute :restrict_public_buckets, Types::Bool.default(true)
      end
      
      # Notification configuration for events
      class NotificationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :lambda_configurations, Types::Array.default([].freeze)
        attribute :topic_configurations, Types::Array.default([].freeze)
        attribute :queue_configurations, Types::Array.default([].freeze)
      end
      
      # CORS configuration
      class CorsConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :cors_rules, Types::Array.default([].freeze)
      end
      
      # Replication configuration
      class ReplicationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :role_arn, Types::String.optional.constrained(format: /\Aarn:aws:iam::\d{12}:role\//)
        attribute :rules, Types::Array.default([].freeze)
      end
      
      # Logging configuration
      class LoggingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :target_bucket, Types::String.optional
        attribute :target_prefix, Types::String.default("access-logs/")
        attribute :target_object_key_format, Types::String.optional.enum('SimplePrefix', 'PartitionedPrefix')
      end
      
      # Transfer acceleration configuration
      class AccelerationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :status, Types::String.optional.enum('Enabled', 'Suspended')
      end
      
      # Analytics configuration
      class AnalyticsConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :configurations, Types::Array.default([].freeze)
      end
      
      # Inventory configuration
      class InventoryConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :configurations, Types::Array.default([].freeze)
      end
      
      # Metrics configuration for CloudWatch
      class MetricsConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :request_metrics, Types::Array.default([].freeze)
        attribute :enable_request_metrics, Types::Bool.default(true)
        attribute :enable_data_events_logging, Types::Bool.default(false)
      end
      
      # Main Secure S3 Bucket component attributes
      class SecureS3BucketAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Basic bucket configuration
        attribute :bucket_name, Types::String.optional.constructor { |value|
          next value unless value
          
          # S3 bucket naming validation
          unless value.match?(/\A[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]\z/)
            raise Dry::Types::ConstraintError, "Invalid S3 bucket name format"
          end
          
          # Additional validation
          if value.include?('..')
            raise Dry::Types::ConstraintError, "Bucket name cannot contain consecutive periods"
          end
          
          if value.match?(/\A\d+\.\d+\.\d+\.\d+\z/)
            raise Dry::Types::ConstraintError, "Bucket name cannot be formatted as IP address"
          end
          
          value
        }
        
        # Bucket configuration
        attribute :force_destroy, Types::Bool.default(false)
        attribute :object_lock_enabled, Types::Bool.default(false)
        
        # Versioning
        attribute :versioning, VersioningConfig.default({})
        
        # Encryption
        attribute :encryption, EncryptionConfig.default({})
        
        # Public access
        attribute :public_access_block, PublicAccessBlockConfig.default({})
        
        # Lifecycle management
        attribute :lifecycle_rules, Types::Array.of(LifecycleRule).default([
          # Default intelligent tiering rule
          LifecycleRule.new({
            id: "intelligent-tiering",
            status: "Enabled",
            transitions: [{
              days: 0,
              storage_class: "INTELLIGENT_TIERING"
            }]
          })
        ].freeze)
        
        # Cross-region replication
        attribute :replication, ReplicationConfig.default({})
        
        # Notifications
        attribute :notifications, NotificationConfig.default({})
        
        # CORS configuration
        attribute :cors, CorsConfig.default({})
        
        # Access logging
        attribute :logging, LoggingConfig.default({})
        
        # Transfer acceleration
        attribute :acceleration, AccelerationConfig.default({})
        
        # Analytics
        attribute :analytics, AnalyticsConfig.default({})
        
        # Inventory reporting
        attribute :inventory, InventoryConfig.default({})
        
        # Metrics and monitoring
        attribute :metrics, MetricsConfig.default({})
        
        # Object lock configuration
        attribute :object_lock_configuration, Types::Hash.optional
        
        # Common tags
        attribute :tags, Types::AwsTags.default({}.freeze)
        
        # Request payer configuration
        attribute :request_payer, Types::String.default("BucketOwner").enum('BucketOwner', 'Requester')
        
        # Website configuration
        attribute :website_configuration, Types::Hash.optional
        
        # Policy document (JSON string)
        attribute :policy, Types::String.optional.constructor { |value|
          next value unless value
          
          begin
            JSON.parse(value)
            value
          rescue JSON::ParserError
            raise Dry::Types::ConstraintError, "Bucket policy must be valid JSON"
          end
        }
        
        # Custom validation for conflicting configurations
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate object lock requires versioning
          if attrs.object_lock_enabled && attrs.versioning.status != 'Enabled'
            raise Dry::Types::ConstraintError, "Object Lock requires versioning to be enabled"
          end
          
          # Validate KMS configuration
          if attrs.encryption.sse_algorithm.start_with?('aws:kms') && !attrs.encryption.kms_key_id
            raise Dry::Types::ConstraintError, "KMS key ID required for KMS encryption"
          end
          
          # Validate replication requirements
          if attrs.replication.enabled
            unless attrs.replication.role_arn
              raise Dry::Types::ConstraintError, "Replication role ARN required when replication is enabled"
            end
            
            unless attrs.versioning.status == 'Enabled'
              raise Dry::Types::ConstraintError, "Versioning must be enabled for replication"
            end
          end
          
          # Validate logging configuration
          if attrs.logging.enabled && !attrs.logging.target_bucket
            raise Dry::Types::ConstraintError, "Target bucket required when logging is enabled"
          end
          
          attrs
        end
      end
    end
  end
end