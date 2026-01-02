# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        # Streaming data architecture
        module Streaming
          def create_streaming_ingestion(name, _arch_ref, stream_attrs, base_tags)
            return {} unless stream_attrs.stream_type == 'kinesis'

            {
              stream: aws_kinesis_stream(
                architecture_resource_name(name, :stream),
                name: "#{name}-stream",
                shard_count: stream_attrs.shard_count,
                retention_period: stream_attrs.retention_hours,
                tags: base_tags.merge(Tier: 'ingestion', Component: 'kinesis-stream')
              )
            }
          end

          def create_stream_processing(name, arch_ref, stream_attrs, base_tags)
            return {} unless stream_attrs.stream_processing_framework == 'kinesis-analytics'

            {
              application: aws_kinesis_analytics_application(
                architecture_resource_name(name, :analytics_app),
                name: "#{name}-stream-processing",
                description: "Stream processing application for #{name}",
                inputs: [kinesis_analytics_input(arch_ref, name, base_tags)],
                tags: base_tags.merge(Tier: 'processing', Component: 'kinesis-analytics')
              )
            }
          end

          def create_streaming_outputs(name, _arch_ref, stream_attrs, base_tags)
            outputs = {}

            stream_attrs.output_destinations.each do |destination|
              case destination
              when 's3'
                outputs[:s3_output] = create_s3_output(name, base_tags)
              when 'elasticsearch'
                outputs[:elasticsearch] = create_elasticsearch_output(name, base_tags)
              end
            end

            outputs
          end

          def create_streaming_monitoring(name, arch_ref, stream_attrs, _base_tags)
            {
              dashboard: aws_cloudwatch_dashboard(
                architecture_resource_name(name, :stream_dashboard),
                dashboard_name: "#{name.to_s.tr('_', '-')}-Streaming-Dashboard",
                dashboard_body: generate_streaming_dashboard_body(name, arch_ref, stream_attrs)
              )
            }
          end

          private

          def kinesis_analytics_input(arch_ref, name, base_tags)
            {
              name_prefix: 'source_stream',
              kinesis_stream: {
                resource_arn: arch_ref.compute[:ingestion][:stream].arn,
                role_arn: create_kinesis_analytics_role(name, base_tags).arn
              },
              schema: {
                record_columns: [
                  { name: 'timestamp', sql_type: 'TIMESTAMP', mapping: '$.timestamp' },
                  { name: 'data', sql_type: 'VARCHAR(32)', mapping: '$.data' }
                ],
                record_format: { record_format_type: 'JSON' }
              }
            }
          end

          def create_s3_output(name, base_tags)
            aws_s3_bucket(
              architecture_resource_name(name, :stream_output),
              bucket_name: "#{name.to_s.tr('_', '-')}-stream-output-#{Time.now.to_i}",
              tags: base_tags.merge(Tier: 'storage', Component: 'stream-output')
            )
          end

          def create_elasticsearch_output(name, base_tags)
            aws_elasticsearch_domain(
              architecture_resource_name(name, :elasticsearch),
              domain_name: "#{name.to_s.tr('_', '-')}-search",
              elasticsearch_version: '7.10',
              cluster_config: { instance_type: 't3.small.elasticsearch', instance_count: 1 },
              ebs_options: { ebs_enabled: true, volume_type: 'gp2', volume_size: 20 },
              tags: base_tags.merge(Tier: 'storage', Component: 'elasticsearch')
            )
          end

          def generate_streaming_dashboard_body(_name, arch_ref, _stream_attrs)
            jsonencode({
              widgets: [{
                type: 'metric',
                properties: {
                  metrics: [
                    ['AWS/Kinesis', 'IncomingRecords', 'StreamName', arch_ref.compute[:ingestion][:stream].name],
                    ['AWS/Kinesis', 'OutgoingRecords', 'StreamName', arch_ref.compute[:ingestion][:stream].name]
                  ],
                  period: 300,
                  stat: 'Sum',
                  region: 'us-east-1',
                  title: 'Stream Throughput'
                }
              }]
            })
          end
        end
      end
    end
  end
end
