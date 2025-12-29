# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        # Processing tier for data lake
        module Processing
          def create_data_processing_tier(name, arch_ref, data_attrs, base_tags)
            processing = {}

            create_glue_resources(name, arch_ref, data_attrs, base_tags, processing) if data_attrs.glue_enabled
            create_emr_resources(name, arch_ref, data_attrs, base_tags, processing) if data_attrs.emr_enabled && arch_ref.network
            create_lambda_processor(name, arch_ref, base_tags, processing) if data_attrs.lambda_enabled

            processing
          end

          private

          def create_glue_resources(name, arch_ref, data_attrs, base_tags, processing)
            processing[:glue_catalog] = aws_glue_catalog_database(
              architecture_resource_name(name, :glue_catalog),
              name: "#{name.to_s.tr('-', '_')}_catalog"
            )

            processing[:glue_crawler] = aws_glue_crawler(
              architecture_resource_name(name, :glue_crawler),
              name: "#{name}-crawler",
              role: create_glue_role(name, arch_ref, base_tags).arn,
              database_name: processing[:glue_catalog].name,
              s3_target: [{ path: "s3://#{arch_ref.storage[:raw_bucket].bucket}/" }],
              schedule: data_attrs.batch_processing_schedule == 'daily' ? 'cron(0 2 * * ? *)' : nil,
              tags: base_tags.merge(Tier: 'processing', Component: 'glue-crawler')
            )
          end

          def create_emr_resources(name, arch_ref, base_tags, processing)
            processing[:emr_cluster] = aws_emr_cluster(
              architecture_resource_name(name, :emr_cluster),
              name: "#{name}-emr-cluster",
              release_label: 'emr-6.10.0',
              applications: %w[Spark Hadoop Hive],
              ec2_attributes: {
                instance_profile: create_emr_instance_profile(name, base_tags).arn,
                key_name: nil,
                subnet_id: arch_ref.network.private_subnets.first.id
              },
              master_instance_group: { instance_type: 'm5.xlarge', instance_count: 1 },
              core_instance_group: { instance_type: 'm5.xlarge', instance_count: 2 },
              service_role: create_emr_service_role(name, base_tags).arn,
              tags: base_tags.merge(Tier: 'processing', Component: 'emr')
            )
          end

          def create_lambda_processor(name, arch_ref, base_tags, processing)
            processing[:lambda_processor] = aws_lambda_function(
              architecture_resource_name(name, :lambda_processor),
              function_name: "#{name}-data-processor",
              runtime: 'python3.9',
              handler: 'lambda_function.lambda_handler',
              role: create_lambda_role(name, arch_ref, base_tags).arn,
              timeout: 300,
              memory_size: 512,
              environment: {
                variables: {
                  RAW_BUCKET: arch_ref.storage[:raw_bucket].bucket,
                  PROCESSED_BUCKET: arch_ref.storage[:processed_bucket].bucket
                }
              },
              tags: base_tags.merge(Tier: 'processing', Component: 'lambda')
            )
          end
        end
      end
    end
  end
end
