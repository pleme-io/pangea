# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module SecureS3BucketComponent
      # Output calculation methods
      module Outputs
        def calculate_outputs(bucket_ref, component_attrs)
          {
            bucket_name: bucket_ref.id, bucket_arn: bucket_ref.arn, bucket_domain_name: bucket_ref.bucket_domain_name,
            bucket_regional_domain_name: bucket_ref.bucket_regional_domain_name, bucket_hosted_zone_id: bucket_ref.hosted_zone_id,
            versioning_enabled: component_attrs.versioning.status == 'Enabled', encryption_enabled: true,
            encryption_algorithm: component_attrs.encryption.sse_algorithm, kms_key_id: component_attrs.encryption.kms_key_id,
            public_access_blocked: component_attrs.public_access_block.block_public_acls, object_lock_enabled: component_attrs.object_lock_enabled,
            lifecycle_rules_count: component_attrs.lifecycle_rules.count,
            security_features: security_features(component_attrs), compliance_features: compliance_features(component_attrs),
            cost_optimization_features: cost_features(component_attrs), estimated_monthly_cost: estimate_s3_monthly_cost(component_attrs)
          }
        end

        private

        def security_features(attrs)
          ['Server-Side Encryption', (attrs.encryption.sse_algorithm.start_with?('aws:kms') ? 'KMS Encryption' : nil),
           (attrs.versioning.status == 'Enabled' ? 'Versioning' : nil), (attrs.object_lock_enabled ? 'Object Lock' : nil),
           (attrs.encryption.enforce_ssl ? 'SSL Enforcement' : nil), (attrs.public_access_block.block_public_acls ? 'Public Access Blocked' : nil),
           (attrs.lifecycle_rules.any? ? 'Lifecycle Management' : nil), (attrs.replication.enabled ? 'Cross-Region Replication' : nil),
           (attrs.logging.enabled ? 'Access Logging' : nil), (attrs.acceleration.enabled ? 'Transfer Acceleration' : nil),
           (attrs.metrics.enabled ? 'CloudWatch Monitoring' : nil)].compact
        end

        def compliance_features(attrs)
          [(attrs.object_lock_enabled ? 'GDPR Ready' : nil),
           (attrs.versioning.status == 'Enabled' && attrs.logging.enabled ? 'SOX Compliant' : nil),
           (attrs.encryption.sse_algorithm.start_with?('aws:kms') ? 'HIPAA Ready' : nil),
           (attrs.encryption.enforce_ssl ? 'PCI DSS Ready' : nil)].compact
        end

        def cost_features(attrs)
          [(attrs.lifecycle_rules.any? { |r| r.transitions.any? { |t| t[:storage_class] == 'INTELLIGENT_TIERING' } } ? 'Intelligent Tiering' : nil),
           (attrs.lifecycle_rules.any? { |r| r.transitions.any? } ? 'Lifecycle Transitions' : nil),
           (attrs.request_payer == 'Requester' ? 'Request Payer' : nil),
           (attrs.acceleration.enabled ? 'Transfer Acceleration' : nil)].compact
        end

        def estimate_s3_monthly_cost(attrs)
          cost = 20.0
          cost *= 0.7 if attrs.lifecycle_rules.any? { |r| r.transitions.any? { |t| t[:storage_class] == 'INTELLIGENT_TIERING' } }
          cost *= 1.2 if attrs.versioning.status == 'Enabled'
          cost *= 1.5 if attrs.replication.enabled
          cost.round(2)
        end
      end
    end
  end
end
