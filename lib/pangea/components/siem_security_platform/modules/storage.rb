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

module Pangea
  module Components
    module SiemSecurityPlatform
      # Storage resources: OpenSearch domain, S3 buckets
      module Storage
        def create_storage_resources(name, attrs, resources)
          create_opensearch_domain(name, attrs, resources)
          create_backup_bucket(name, attrs, resources)
        end

        private

        def create_opensearch_domain(name, attrs, resources)
          domain_name = attrs.opensearch_config[:domain_name]
          resources[:opensearch_domain] = aws_opensearch_domain(:"#{name}_opensearch", {
            domain_name: domain_name,
            engine_version: attrs.opensearch_config[:engine_version],
            cluster_config: build_cluster_config(attrs),
            ebs_options: build_ebs_options(attrs),
            vpc_options: build_vpc_options(attrs, resources),
            encrypt_at_rest: build_encryption_config(attrs, resources),
            node_to_node_encryption: {
              enabled: attrs.security_config[:enable_encryption_in_transit]
            },
            advanced_security_options: build_security_options(attrs),
            log_publishing_options: build_log_options(name, attrs, resources),
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        def build_cluster_config(attrs)
          config = attrs.opensearch_config
          {
            instance_type: config[:instance_type],
            instance_count: config[:instance_count],
            dedicated_master_enabled: config[:dedicated_master_enabled],
            dedicated_master_type: config[:dedicated_master_type],
            dedicated_master_count: config[:dedicated_master_count],
            zone_awareness_enabled: config[:zone_awareness_enabled],
            zone_awareness_config: config[:zone_awareness_enabled] ? {
              availability_zone_count: config[:availability_zone_count]
            } : nil
          }
        end

        def build_ebs_options(attrs)
          config = attrs.opensearch_config
          {
            ebs_enabled: config[:ebs_enabled],
            volume_type: config[:volume_type],
            volume_size: config[:volume_size],
            iops: config[:iops],
            throughput: config[:throughput]
          }
        end

        def build_vpc_options(attrs, resources)
          {
            subnet_ids: attrs.subnet_refs.take(
              attrs.opensearch_config[:availability_zone_count] || 3
            ),
            security_group_ids: [resources[:security_groups][:opensearch].id]
          }
        end

        def build_encryption_config(attrs, resources)
          return nil unless attrs.security_config[:enable_encryption_at_rest]

          {
            enabled: true,
            kms_key_id: resources[:kms_keys][:main].id
          }
        end

        def build_security_options(attrs)
          return nil unless attrs.security_config[:enable_fine_grained_access]

          {
            enabled: true,
            internal_user_database_enabled: false,
            master_user_options: {
              master_user_arn: attrs.security_config[:master_user_arn]
            }
          }
        end

        def build_log_options(name, attrs, resources)
          options = {
            ES_APPLICATION_LOGS: {
              enabled: true,
              cloudwatch_log_group_arn: create_log_group(name, 'es-application', attrs, resources)
            }
          }

          if attrs.security_config[:enable_slow_logs]
            options[:SEARCH_SLOW_LOGS] = {
              enabled: true,
              cloudwatch_log_group_arn: create_log_group(name, 'es-slow', attrs, resources)
            }
          end

          if attrs.security_config[:enable_audit_logs]
            options[:AUDIT_LOGS] = {
              enabled: true,
              cloudwatch_log_group_arn: create_log_group(name, 'es-audit', attrs, resources)
            }
          end

          options
        end

        def create_backup_bucket(name, attrs, resources)
          bucket_name = component_resource_name(name, :backup_bucket)
          resources[:s3_buckets][:backup] = create_secure_bucket(
            bucket_name,
            "siem-backup-#{name}",
            attrs,
            resources
          )
        end

        def create_secure_bucket(bucket_name, bucket_id, attrs, resources)
          bucket = aws_s3_bucket(bucket_name, {
            bucket: bucket_id,
            tags: component_tags('siem_security_platform', bucket_name, attrs.tags)
          })

          configure_bucket_versioning(bucket_name, bucket)
          configure_bucket_encryption(bucket_name, bucket, resources)
          configure_bucket_public_access(bucket_name, bucket)
          configure_bucket_lifecycle(bucket_name, bucket, attrs)

          bucket
        end

        def configure_bucket_versioning(bucket_name, bucket)
          aws_s3_bucket_versioning(:"#{bucket_name}_versioning", {
            bucket: bucket.id,
            versioning_configuration: { status: "Enabled" }
          })
        end

        def configure_bucket_encryption(bucket_name, bucket, resources)
          aws_s3_bucket_server_side_encryption_configuration(:"#{bucket_name}_encryption", {
            bucket: bucket.id,
            rule: {
              apply_server_side_encryption_by_default: {
                sse_algorithm: "aws:kms",
                kms_master_key_id: resources[:kms_keys][:main].id
              },
              bucket_key_enabled: true
            }
          })
        end

        def configure_bucket_public_access(bucket_name, bucket)
          aws_s3_bucket_public_access_block(:"#{bucket_name}_pab", {
            bucket: bucket.id,
            block_public_acls: true,
            block_public_policy: true,
            ignore_public_acls: true,
            restrict_public_buckets: true
          })
        end

        def configure_bucket_lifecycle(bucket_name, bucket, attrs)
          aws_s3_bucket_lifecycle_configuration(:"#{bucket_name}_lifecycle", {
            bucket: bucket.id,
            rule: [
              {
                id: "transition-to-glacier",
                status: "Enabled",
                transition: [{ days: 90, storage_class: "GLACIER" }],
                expiration: { days: attrs.compliance_config[:audit_trail_retention] }
              }
            ]
          })
        end
      end
    end
  end
end
