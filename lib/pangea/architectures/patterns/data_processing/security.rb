# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        # Security tier for data lake
        module Security
          def create_data_security_tier(name, _arch_ref, data_attrs, base_tags)
            security = {}

            if data_attrs.data_encryption
              security[:kms_key] = aws_kms_key(
                architecture_resource_name(name, :kms_key),
                description: "KMS key for #{name} data lake encryption",
                tags: base_tags.merge(Tier: 'security', Component: 'kms')
              )
            end

            security[:lake_formation] = {
              type: 'lake_formation_settings',
              name: "#{name}-governance",
              admins: [],
              create_database_default_permissions: [],
              create_table_default_permissions: []
            }

            security
          end
        end
      end
    end
  end
end
