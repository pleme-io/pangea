# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        # Ingestion tier for data lake
        module Ingestion
          def create_data_ingestion_tier(name, arch_ref, data_attrs, base_tags)
            ingestion = {}

            if data_attrs.real_time_processing && data_attrs.data_sources.include?('kinesis')
              create_kinesis_ingestion(name, arch_ref, data_attrs, base_tags, ingestion)
            end

            if data_attrs.data_sources.include?('rds')
              create_dms_ingestion(name, data_attrs, base_tags, ingestion)
            end

            ingestion
          end

          private

          def create_kinesis_ingestion(name, arch_ref, data_attrs, base_tags, ingestion)
            ingestion[:kinesis_stream] = aws_kinesis_stream(
              architecture_resource_name(name, :kinesis_stream),
              name: "#{name}-data-stream",
              shard_count: 1,
              retention_period: 24,
              shard_level_metrics: %w[IncomingRecords OutgoingRecords],
              tags: base_tags.merge(Tier: 'ingestion', Component: 'kinesis')
            )

            ingestion[:firehose] = aws_kinesis_firehose_delivery_stream(
              architecture_resource_name(name, :firehose),
              name: "#{name}-firehose",
              destination: 's3',
              s3_configuration: firehose_s3_config(name, arch_ref, data_attrs, base_tags),
              tags: base_tags.merge(Tier: 'ingestion', Component: 'firehose')
            )
          end

          def firehose_s3_config(name, arch_ref, data_attrs, base_tags)
            {
              role_arn: create_firehose_role(name, arch_ref, base_tags).arn,
              bucket_arn: arch_ref.storage[:raw_bucket].arn,
              prefix: 'year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/',
              error_output_prefix: 'errors/',
              buffer_size: data_attrs.streaming_buffer_size,
              buffer_interval: data_attrs.streaming_buffer_interval,
              compression_format: 'GZIP'
            }
          end

          def create_dms_ingestion(name, data_attrs, base_tags, ingestion)
            ingestion[:dms_replication] = aws_dms_replication_instance(
              architecture_resource_name(name, :dms_instance),
              allocated_storage: 100,
              apply_immediately: true,
              auto_minor_version_upgrade: true,
              multi_az: data_attrs.environment == 'production',
              publicly_accessible: false,
              replication_instance_class: 'dms.t3.micro',
              replication_instance_id: "#{name}-dms",
              tags: base_tags.merge(Tier: 'ingestion', Component: 'dms')
            )
          end
        end
      end
    end
  end
end
