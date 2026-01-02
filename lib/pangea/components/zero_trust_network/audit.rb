# frozen_string_literal: true

module Pangea
  module Components
    module ZeroTrustNetwork
      # Audit and certificate management for Zero Trust Network
      module Audit
        def create_audit_bucket(name, attrs, resources)
          bucket_name = component_resource_name(name, :audit_bucket)
          resources[:s3_buckets][:audit] = aws_s3_bucket(bucket_name, {
            bucket: "zt-audit-#{name}-#{aws_region}",
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })

          configure_audit_bucket_versioning(bucket_name, resources)
          configure_audit_bucket_encryption(bucket_name, resources)
          configure_audit_bucket_public_access(bucket_name, resources)

          resources[:s3_buckets][:audit].id
        end

        def create_certificate(domain_name, _name, _attrs, _resources)
          # This would typically request or import a certificate
          "arn:aws:acm:#{aws_region}:#{aws_account_id}:certificate/placeholder"
        end

        private

        def configure_audit_bucket_versioning(bucket_name, resources)
          aws_s3_bucket_versioning(:"#{bucket_name}_versioning", {
            bucket: resources[:s3_buckets][:audit].id,
            versioning_configuration: {
              status: 'Enabled'
            }
          })
        end

        def configure_audit_bucket_encryption(bucket_name, resources)
          aws_s3_bucket_server_side_encryption_configuration(:"#{bucket_name}_encryption", {
            bucket: resources[:s3_buckets][:audit].id,
            rule: {
              apply_server_side_encryption_by_default: {
                sse_algorithm: 'aws:kms'
              }
            }
          })
        end

        def configure_audit_bucket_public_access(bucket_name, resources)
          aws_s3_bucket_public_access_block(:"#{bucket_name}_pab", {
            bucket: resources[:s3_buckets][:audit].id,
            block_public_acls: true,
            block_public_policy: true,
            ignore_public_acls: true,
            restrict_public_buckets: true
          })
        end
      end
    end
  end
end
