# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module SecureS3BucketComponent
      # Core bucket configuration methods
      module BucketConfig
        def create_bucket(name, component_attrs, component_tag_set)
          bucket_name = component_attrs.bucket_name || "#{name}-secure-bucket-#{SecureRandom.hex(8)}"
          aws_s3_bucket(component_resource_name(name, :bucket), { bucket: bucket_name, force_destroy: component_attrs.force_destroy,
                                                                   object_lock_enabled: component_attrs.object_lock_enabled, tags: component_tag_set })
        end

        def configure_versioning(name, bucket_ref, component_attrs)
          aws_s3_bucket_versioning(component_resource_name(name, :versioning), {
            bucket: bucket_ref.id, versioning_configuration: { status: component_attrs.versioning.status, mfa_delete: component_attrs.versioning.mfa_delete }.compact
          })
        end

        def configure_encryption(name, bucket_ref, component_attrs)
          encryption_rule = { apply_server_side_encryption_by_default: { sse_algorithm: component_attrs.encryption.sse_algorithm,
                                                                          kms_master_key_id: component_attrs.encryption.kms_key_id }.compact,
                              bucket_key_enabled: component_attrs.encryption.bucket_key_enabled }
          aws_s3_bucket_server_side_encryption_configuration(component_resource_name(name, :encryption), { bucket: bucket_ref.id, rule: [encryption_rule] })
        end

        def configure_public_access(name, bucket_ref, component_attrs)
          aws_s3_bucket_public_access_block(component_resource_name(name, :public_access), {
            bucket: bucket_ref.id, block_public_acls: component_attrs.public_access_block.block_public_acls,
            block_public_policy: component_attrs.public_access_block.block_public_policy, ignore_public_acls: component_attrs.public_access_block.ignore_public_acls,
            restrict_public_buckets: component_attrs.public_access_block.restrict_public_buckets
          })
        end

        def configure_lifecycle(name, bucket_ref, component_attrs)
          return nil unless component_attrs.lifecycle_rules.any?

          lifecycle_rules = component_attrs.lifecycle_rules.map do |rule|
            { id: rule.id, status: rule.status, filter: rule.filter || {},
              transition: rule.transitions.map { |t| { days: t[:days], storage_class: t[:storage_class] } },
              expiration: rule.expiration, noncurrent_version_transition: rule.noncurrent_version_transitions,
              noncurrent_version_expiration: rule.noncurrent_version_expiration, abort_incomplete_multipart_upload: rule.abort_incomplete_multipart_upload }.compact
          end
          aws_s3_bucket_lifecycle_configuration(component_resource_name(name, :lifecycle), { bucket: bucket_ref.id, rule: lifecycle_rules })
        end
      end
    end
  end
end
