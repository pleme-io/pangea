# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module SecureS3BucketComponent
      # Optional feature configuration methods
      module Features
        def configure_policy(name, bucket_ref, component_attrs)
          return nil unless component_attrs.encryption.enforce_ssl || component_attrs.policy

          policy = component_attrs.encryption.enforce_ssl ? build_ssl_policy(bucket_ref, component_attrs) : JSON.parse(component_attrs.policy)
          aws_s3_bucket_policy(component_resource_name(name, :policy), { bucket: bucket_ref.id, policy: JSON.pretty_generate(policy) })
        end

        def configure_cors(name, bucket_ref, component_attrs)
          return nil unless component_attrs.cors.enabled && component_attrs.cors.cors_rules.any?
          aws_s3_bucket_cors_configuration(component_resource_name(name, :cors), { bucket: bucket_ref.id, cors_rule: component_attrs.cors.cors_rules })
        end

        def configure_logging(name, bucket_ref, component_attrs)
          return nil unless component_attrs.logging.enabled
          attrs = { bucket: bucket_ref.id, target_bucket: component_attrs.logging.target_bucket, target_prefix: component_attrs.logging.target_prefix }
          attrs[:target_object_key_format] = build_logging_format(component_attrs.logging.target_object_key_format) if component_attrs.logging.target_object_key_format
          aws_s3_bucket_logging(component_resource_name(name, :logging), attrs)
        end

        def configure_acceleration(name, bucket_ref, component_attrs)
          return nil unless component_attrs.acceleration.enabled
          aws_s3_bucket_accelerate_configuration(component_resource_name(name, :acceleration), { bucket: bucket_ref.id, status: component_attrs.acceleration.status || 'Enabled' })
        end

        def configure_website(name, bucket_ref, component_attrs)
          return nil unless component_attrs.website_configuration
          aws_s3_bucket_website_configuration(component_resource_name(name, :website), { bucket: bucket_ref.id }.merge(component_attrs.website_configuration))
        end

        def configure_object_lock(name, bucket_ref, component_attrs)
          return nil unless component_attrs.object_lock_enabled && component_attrs.object_lock_configuration
          aws_s3_bucket_object_lock_configuration(component_resource_name(name, :object_lock), { bucket: bucket_ref.id, object_lock_enabled: 'Enabled' }.merge(component_attrs.object_lock_configuration))
        end

        def configure_notifications(name, bucket_ref, component_attrs)
          return nil unless component_attrs.notifications.enabled
          aws_s3_bucket_notification(component_resource_name(name, :notification), { bucket: bucket_ref.id, lambda_configuration: component_attrs.notifications.lambda_configurations,
                                                                                      topic_configuration: component_attrs.notifications.topic_configurations,
                                                                                      queue_configuration: component_attrs.notifications.queue_configurations }.compact)
        end

        def configure_replication(name, bucket_ref, component_attrs)
          return nil unless component_attrs.replication.enabled
          aws_s3_bucket_replication_configuration(component_resource_name(name, :replication), { bucket: bucket_ref.id, role: component_attrs.replication.role_arn, rule: component_attrs.replication.rules })
        end

        private

        def build_ssl_policy(bucket_ref, component_attrs)
          policy = { 'Version' => '2012-10-17', 'Id' => 'EnforceSSLRequestsOnly',
                     'Statement' => [{ 'Sid' => 'DenyInsecureConnections', 'Effect' => 'Deny', 'Principal' => '*', 'Action' => 's3:*',
                                       'Resource' => [bucket_ref.arn, "#{bucket_ref.arn}/*"], 'Condition' => { 'Bool' => { 'aws:SecureTransport' => 'false' } } }] }
          return policy unless component_attrs.policy
          existing = JSON.parse(component_attrs.policy)
          existing['Statement'] = (existing['Statement'] || []) + policy['Statement']
          existing
        end

        def build_logging_format(format)
          { simple_prefix: format == 'SimplePrefix' ? {} : nil,
            partitioned_prefix: format == 'PartitionedPrefix' ? { partition_date_source: 'EventTime' } : nil }.compact
        end
      end
    end
  end
end
