# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        # Analytics tier for data lake
        module Analytics
          def create_analytics_tier(name, arch_ref, data_attrs, base_tags)
            analytics = {}

            case data_attrs.data_warehouse
            when 'athena'
              create_athena_resources(name, arch_ref, base_tags, analytics)
            when 'redshift'
              create_redshift_resources(name, arch_ref, data_attrs, base_tags, analytics)
            end

            create_bi_resources(name, data_attrs, analytics) if data_attrs.business_intelligence

            analytics
          end

          private

          def create_athena_resources(name, arch_ref, base_tags, analytics)
            analytics[:athena_workgroup] = aws_athena_workgroup(
              architecture_resource_name(name, :athena_workgroup),
              name: "#{name}-analytics",
              description: "Athena workgroup for #{name} analytics",
              configuration: {
                result_configuration: {
                  output_location: "s3://#{arch_ref.storage[:analytics_bucket].bucket}/athena-results/"
                },
                enforce_workgroup_configuration: true,
                publish_cloudwatch_metrics: true
              },
              tags: base_tags.merge(Tier: 'analytics', Component: 'athena')
            )
          end

          def create_redshift_resources(name, arch_ref, data_attrs, base_tags, analytics)
            analytics[:redshift_cluster] = aws_redshift_cluster(
              architecture_resource_name(name, :redshift_cluster),
              cluster_identifier: "#{name}-redshift",
              database_name: name.to_s.gsub(/[^a-zA-Z0-9]/, ''),
              master_username: 'admin',
              master_password: 'TempPassword123!',
              node_type: 'dc2.large',
              cluster_type: 'single-node',
              vpc_security_group_ids: [create_redshift_sg(name, arch_ref, base_tags).id],
              db_subnet_group_name: create_redshift_subnet_group(name, arch_ref, base_tags).name,
              encrypted: data_attrs.data_encryption,
              publicly_accessible: false,
              tags: base_tags.merge(Tier: 'analytics', Component: 'redshift')
            )
          end

          def create_bi_resources(name, data_attrs, analytics)
            analytics[:quicksight_dataset] = {
              type: 'quicksight_dataset',
              name: "#{name}-dataset",
              data_source: data_attrs.data_warehouse
            }
          end
        end
      end
    end
  end
end
