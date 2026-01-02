# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        # Storage tier for data lake
        module Storage
          def create_data_storage_tier(name, _arch_ref, data_attrs, base_tags)
            {
              raw_bucket: create_raw_bucket(name, data_attrs, base_tags),
              processed_bucket: create_processed_bucket(name, data_attrs, base_tags),
              analytics_bucket: create_analytics_bucket(name, base_tags)
            }
          end

          private

          def create_raw_bucket(name, data_attrs, base_tags)
            aws_s3_bucket(
              architecture_resource_name(name, :raw_data),
              bucket_name: "#{name.to_s.tr('_', '-')}-raw-data-#{Time.now.to_i}",
              versioning: 'Enabled',
              encryption: data_attrs.data_encryption ? { sse_algorithm: 'AES256' } : nil,
              lifecycle_rules: raw_lifecycle_rules(data_attrs),
              tags: base_tags.merge(Tier: 'storage', DataType: 'raw')
            )
          end

          def create_processed_bucket(name, data_attrs, base_tags)
            aws_s3_bucket(
              architecture_resource_name(name, :processed_data),
              bucket_name: "#{name.to_s.tr('_', '-')}-processed-data-#{Time.now.to_i}",
              versioning: 'Enabled',
              encryption: data_attrs.data_encryption ? { sse_algorithm: 'AES256' } : nil,
              lifecycle_rules: processed_lifecycle_rules(data_attrs),
              tags: base_tags.merge(Tier: 'storage', DataType: 'processed')
            )
          end

          def create_analytics_bucket(name, base_tags)
            aws_s3_bucket(
              architecture_resource_name(name, :analytics_results),
              bucket_name: "#{name.to_s.tr('_', '-')}-analytics-#{Time.now.to_i}",
              versioning: 'Enabled',
              tags: base_tags.merge(Tier: 'storage', DataType: 'analytics')
            )
          end

          def raw_lifecycle_rules(data_attrs)
            [{
              id: 'raw_data_lifecycle',
              status: 'Enabled',
              transitions: [
                { days: 30, storage_class: 'STANDARD_IA' },
                { days: 90, storage_class: 'GLACIER' }
              ],
              expiration: { days: data_attrs.raw_data_retention_days }
            }]
          end

          def processed_lifecycle_rules(data_attrs)
            [{
              id: 'processed_data_lifecycle',
              status: 'Enabled',
              transitions: [{ days: 30, storage_class: 'STANDARD_IA' }],
              expiration: { days: data_attrs.processed_data_retention_days }
            }]
          end
        end
      end
    end
  end
end
