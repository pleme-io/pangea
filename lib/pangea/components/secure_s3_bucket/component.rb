# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/secure_s3_bucket/types'
require 'pangea/resources/aws'
require 'json'

module Pangea
  module Components
    # Secure S3 Bucket component with encryption, versioning, and lifecycle management
    # Creates a production-ready S3 bucket with comprehensive security and compliance features
    def secure_s3_bucket(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = SecureS3Bucket::SecureS3BucketAttributes.new(attributes)
      
      # Generate component-specific tags
      component_tag_set = component_tags('SecureS3Bucket', name, component_attrs.tags)
      
      resources = {}
      
      # Determine bucket name
      bucket_name = component_attrs.bucket_name || "#{name}-secure-bucket-#{SecureRandom.hex(8)}"
      
      # Create the S3 bucket
      bucket_attrs = {
        bucket: bucket_name,
        force_destroy: component_attrs.force_destroy,
        object_lock_enabled: component_attrs.object_lock_enabled,
        tags: component_tag_set
      }
      
      bucket_ref = aws_s3_bucket(component_resource_name(name, :bucket), bucket_attrs)
      resources[:bucket] = bucket_ref
      
      # Configure versioning
      versioning_ref = aws_s3_bucket_versioning(component_resource_name(name, :versioning), {
        bucket: bucket_ref.id,
        versioning_configuration: {
          status: component_attrs.versioning.status,
          mfa_delete: component_attrs.versioning.mfa_delete
        }.compact
      })
      resources[:versioning] = versioning_ref
      
      # Configure server-side encryption
      encryption_rule = {
        apply_server_side_encryption_by_default: {
          sse_algorithm: component_attrs.encryption.sse_algorithm,
          kms_master_key_id: component_attrs.encryption.kms_key_id
        }.compact,
        bucket_key_enabled: component_attrs.encryption.bucket_key_enabled
      }
      
      encryption_ref = aws_s3_bucket_server_side_encryption_configuration(
        component_resource_name(name, :encryption),
        {
          bucket: bucket_ref.id,
          rule: [encryption_rule]
        }
      )
      resources[:encryption] = encryption_ref
      
      # Configure public access block
      public_access_ref = aws_s3_bucket_public_access_block(component_resource_name(name, :public_access), {
        bucket: bucket_ref.id,
        block_public_acls: component_attrs.public_access_block.block_public_acls,
        block_public_policy: component_attrs.public_access_block.block_public_policy,
        ignore_public_acls: component_attrs.public_access_block.ignore_public_acls,
        restrict_public_buckets: component_attrs.public_access_block.restrict_public_buckets
      })
      resources[:public_access_block] = public_access_ref
      
      # Configure lifecycle rules
      if component_attrs.lifecycle_rules.any?
        lifecycle_rules = component_attrs.lifecycle_rules.map do |rule|
          {
            id: rule.id,
            status: rule.status,
            filter: rule.filter || {},
            transition: rule.transitions.map do |transition|
              {
                days: transition[:days],
                storage_class: transition[:storage_class]
              }
            end,
            expiration: rule.expiration,
            noncurrent_version_transition: rule.noncurrent_version_transitions,
            noncurrent_version_expiration: rule.noncurrent_version_expiration,
            abort_incomplete_multipart_upload: rule.abort_incomplete_multipart_upload
          }.compact
        end
        
        lifecycle_ref = aws_s3_bucket_lifecycle_configuration(
          component_resource_name(name, :lifecycle),
          {
            bucket: bucket_ref.id,
            rule: lifecycle_rules
          }
        )
        resources[:lifecycle] = lifecycle_ref
      end
      
      # Configure SSL enforcement policy if enabled
      if component_attrs.encryption.enforce_ssl
        ssl_policy = {
          "Version" => "2012-10-17",
          "Id" => "EnforceSSLRequestsOnly",
          "Statement" => [
            {
              "Sid" => "DenyInsecureConnections",
              "Effect" => "Deny",
              "Principal" => "*",
              "Action" => "s3:*",
              "Resource" => [
                bucket_ref.arn,
                "#{bucket_ref.arn}/*"
              ],
              "Condition" => {
                "Bool" => {
                  "aws:SecureTransport" => "false"
                }
              }
            }
          ]
        }
        
        # Merge with existing policy if provided
        if component_attrs.policy
          existing_policy = JSON.parse(component_attrs.policy)
          existing_policy["Statement"] = (existing_policy["Statement"] || []) + ssl_policy["Statement"]
          ssl_policy = existing_policy
        end
        
        policy_ref = aws_s3_bucket_policy(component_resource_name(name, :policy), {
          bucket: bucket_ref.id,
          policy: JSON.pretty_generate(ssl_policy)
        })
        resources[:policy] = policy_ref
      elsif component_attrs.policy
        # Apply custom policy without SSL enforcement
        policy_ref = aws_s3_bucket_policy(component_resource_name(name, :policy), {
          bucket: bucket_ref.id,
          policy: component_attrs.policy
        })
        resources[:policy] = policy_ref
      end
      
      # Configure CORS if enabled
      if component_attrs.cors.enabled && component_attrs.cors.cors_rules.any?
        cors_ref = aws_s3_bucket_cors_configuration(component_resource_name(name, :cors), {
          bucket: bucket_ref.id,
          cors_rule: component_attrs.cors.cors_rules
        })
        resources[:cors] = cors_ref
      end
      
      # Configure access logging if enabled
      if component_attrs.logging.enabled
        logging_attrs = {
          bucket: bucket_ref.id,
          target_bucket: component_attrs.logging.target_bucket,
          target_prefix: component_attrs.logging.target_prefix
        }
        
        if component_attrs.logging.target_object_key_format
          logging_attrs[:target_object_key_format] = {
            simple_prefix: component_attrs.logging.target_object_key_format == 'SimplePrefix' ? {} : nil,
            partitioned_prefix: component_attrs.logging.target_object_key_format == 'PartitionedPrefix' ? {
              partition_date_source: "EventTime"
            } : nil
          }.compact
        end
        
        logging_ref = aws_s3_bucket_logging(component_resource_name(name, :logging), logging_attrs)
        resources[:logging] = logging_ref
      end
      
      # Configure transfer acceleration if enabled
      if component_attrs.acceleration.enabled
        acceleration_ref = aws_s3_bucket_accelerate_configuration(
          component_resource_name(name, :acceleration),
          {
            bucket: bucket_ref.id,
            status: component_attrs.acceleration.status || "Enabled"
          }
        )
        resources[:acceleration] = acceleration_ref
      end
      
      # Configure request payer if not default
      if component_attrs.request_payer != "BucketOwner"
        request_payer_ref = aws_s3_bucket_request_payment_configuration(
          component_resource_name(name, :request_payer),
          {
            bucket: bucket_ref.id,
            payer: component_attrs.request_payer
          }
        )
        resources[:request_payer] = request_payer_ref
      end
      
      # Configure website if provided
      if component_attrs.website_configuration
        website_ref = aws_s3_bucket_website_configuration(
          component_resource_name(name, :website),
          {
            bucket: bucket_ref.id
          }.merge(component_attrs.website_configuration)
        )
        resources[:website] = website_ref
      end
      
      # Configure object lock if enabled
      if component_attrs.object_lock_enabled && component_attrs.object_lock_configuration
        object_lock_ref = aws_s3_bucket_object_lock_configuration(
          component_resource_name(name, :object_lock),
          {
            bucket: bucket_ref.id,
            object_lock_enabled: "Enabled"
          }.merge(component_attrs.object_lock_configuration)
        )
        resources[:object_lock] = object_lock_ref
      end
      
      # Configure notifications if enabled
      if component_attrs.notifications.enabled
        notification_attrs = {
          bucket: bucket_ref.id,
          lambda_configuration: component_attrs.notifications.lambda_configurations,
          topic_configuration: component_attrs.notifications.topic_configurations,
          queue_configuration: component_attrs.notifications.queue_configurations
        }.compact
        
        notification_ref = aws_s3_bucket_notification(
          component_resource_name(name, :notification),
          notification_attrs
        )
        resources[:notification] = notification_ref
      end
      
      # Configure replication if enabled
      if component_attrs.replication.enabled
        replication_ref = aws_s3_bucket_replication_configuration(
          component_resource_name(name, :replication),
          {
            bucket: bucket_ref.id,
            role: component_attrs.replication.role_arn,
            rule: component_attrs.replication.rules
          }
        )
        resources[:replication] = replication_ref
      end
      
      # Configure analytics if enabled
      analytics_configs = {}
      if component_attrs.analytics.enabled && component_attrs.analytics.configurations.any?
        component_attrs.analytics.configurations.each_with_index do |config, index|
          analytics_ref = aws_s3_bucket_analytics_configuration(
            component_resource_name(name, :analytics, "config#{index}".to_sym),
            {
              bucket: bucket_ref.id,
              name: config[:name] || "analytics-config-#{index}"
            }.merge(config)
          )
          analytics_configs["config#{index}".to_sym] = analytics_ref
        end
        resources[:analytics] = analytics_configs
      end
      
      # Configure inventory if enabled
      inventory_configs = {}
      if component_attrs.inventory.enabled && component_attrs.inventory.configurations.any?
        component_attrs.inventory.configurations.each_with_index do |config, index|
          inventory_ref = aws_s3_bucket_inventory(
            component_resource_name(name, :inventory, "config#{index}".to_sym),
            {
              bucket: bucket_ref.id,
              name: config[:name] || "inventory-config-#{index}"
            }.merge(config)
          )
          inventory_configs["config#{index}".to_sym] = inventory_ref
        end
        resources[:inventory] = inventory_configs
      end
      
      # Create CloudWatch metrics and alarms for monitoring
      alarms = {}
      
      if component_attrs.metrics.enabled
        # Number of objects alarm (to track bucket growth)
        object_count_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :object_count), {
          alarm_name: "#{name}-s3-object-count-high",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "1",
          metric_name: "NumberOfObjects",
          namespace: "AWS/S3",
          period: "86400", # Daily
          statistic: "Average",
          threshold: "100000",
          alarm_description: "S3 bucket has high number of objects",
          dimensions: {
            BucketName: bucket_ref.id,
            StorageType: "AllStorageTypes"
          },
          tags: component_tag_set
        })
        alarms[:object_count] = object_count_alarm
        
        # Bucket size alarm
        bucket_size_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :bucket_size), {
          alarm_name: "#{name}-s3-bucket-size-large",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "1",
          metric_name: "BucketSizeBytes",
          namespace: "AWS/S3",
          period: "86400", # Daily
          statistic: "Average",
          threshold: "107374182400", # 100GB in bytes
          alarm_description: "S3 bucket size is large",
          dimensions: {
            BucketName: bucket_ref.id,
            StorageType: "StandardStorage"
          },
          tags: component_tag_set
        })
        alarms[:bucket_size] = bucket_size_alarm
        
        # 4xx errors alarm if request metrics enabled
        if component_attrs.metrics.enable_request_metrics
          error_4xx_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :errors_4xx), {
            alarm_name: "#{name}-s3-4xx-errors-high",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "2",
            metric_name: "4xxErrors",
            namespace: "AWS/S3",
            period: "300",
            statistic: "Sum",
            threshold: "5",
            alarm_description: "S3 bucket has high 4xx error rate",
            dimensions: {
              BucketName: bucket_ref.id
            },
            tags: component_tag_set
          })
          alarms[:errors_4xx] = error_4xx_alarm
        end
      end
      
      resources[:alarms] = alarms unless alarms.empty?
      
      # Calculate outputs
      outputs = {
        bucket_name: bucket_ref.id,
        bucket_arn: bucket_ref.arn,
        bucket_domain_name: bucket_ref.bucket_domain_name,
        bucket_regional_domain_name: bucket_ref.bucket_regional_domain_name,
        bucket_hosted_zone_id: bucket_ref.hosted_zone_id,
        versioning_enabled: component_attrs.versioning.status == 'Enabled',
        encryption_enabled: true,
        encryption_algorithm: component_attrs.encryption.sse_algorithm,
        kms_key_id: component_attrs.encryption.kms_key_id,
        public_access_blocked: component_attrs.public_access_block.block_public_acls,
        object_lock_enabled: component_attrs.object_lock_enabled,
        lifecycle_rules_count: component_attrs.lifecycle_rules.count,
        security_features: [
          "Server-Side Encryption",
          ("KMS Encryption" if component_attrs.encryption.sse_algorithm.start_with?('aws:kms')),
          ("Versioning" if component_attrs.versioning.status == 'Enabled'),
          ("Object Lock" if component_attrs.object_lock_enabled),
          ("SSL Enforcement" if component_attrs.encryption.enforce_ssl),
          ("Public Access Blocked" if component_attrs.public_access_block.block_public_acls),
          ("Lifecycle Management" if component_attrs.lifecycle_rules.any?),
          ("Cross-Region Replication" if component_attrs.replication.enabled),
          ("Access Logging" if component_attrs.logging.enabled),
          ("Transfer Acceleration" if component_attrs.acceleration.enabled),
          ("CloudWatch Monitoring" if component_attrs.metrics.enabled)
        ].compact,
        compliance_features: [
          ("GDPR Ready" if component_attrs.object_lock_enabled),
          ("SOX Compliant" if component_attrs.versioning.status == 'Enabled' && component_attrs.logging.enabled),
          ("HIPAA Ready" if component_attrs.encryption.sse_algorithm.start_with?('aws:kms')),
          ("PCI DSS Ready" if component_attrs.encryption.enforce_ssl)
        ].compact,
        cost_optimization_features: [
          ("Intelligent Tiering" if component_attrs.lifecycle_rules.any? { |r| r.transitions.any? { |t| t[:storage_class] == 'INTELLIGENT_TIERING' } }),
          ("Lifecycle Transitions" if component_attrs.lifecycle_rules.any? { |r| r.transitions.any? }),
          ("Request Payer" if component_attrs.request_payer == 'Requester'),
          ("Transfer Acceleration" if component_attrs.acceleration.enabled)
        ].compact,
        estimated_monthly_cost: estimate_s3_monthly_cost(
          component_attrs.lifecycle_rules,
          component_attrs.versioning.status == 'Enabled',
          component_attrs.replication.enabled
        )
      }
      
      create_component_reference(
        'secure_s3_bucket',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def estimate_s3_monthly_cost(lifecycle_rules, versioning_enabled, replication_enabled)
      base_cost = 20.0  # Base estimate for standard storage
      
      # Reduce cost if intelligent tiering is used
      if lifecycle_rules.any? { |rule| rule.transitions.any? { |t| t[:storage_class] == 'INTELLIGENT_TIERING' } }
        base_cost *= 0.7  # 30% cost reduction with intelligent tiering
      end
      
      # Add cost for versioning (estimated 20% increase)
      base_cost *= 1.2 if versioning_enabled
      
      # Add cost for replication (estimated 50% increase)
      base_cost *= 1.5 if replication_enabled
      
      base_cost.round(2)
    end
  end
end