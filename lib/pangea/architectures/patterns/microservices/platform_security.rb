# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module Microservices
        # Platform security services (KMS, Security Groups)
        module PlatformSecurity
          def create_security_services(name, arch_ref, platform_attrs, base_tags)
            security = {}

            if platform_attrs.secrets_management
              security[:secrets_key] = create_secrets_key(name, base_tags)
            end

            security[:default_sg] = create_default_security_group(name, arch_ref, base_tags)
            security
          end

          private

          def create_secrets_key(name, base_tags)
            aws_kms_key(
              architecture_resource_name(name, :secrets_key),
              description: "KMS key for #{name} platform secrets",
              tags: base_tags.merge(Tier: 'security', Component: 'kms')
            )
          end

          def create_default_security_group(name, arch_ref, base_tags)
            aws_security_group(
              architecture_resource_name(name, :default_sg),
              name_prefix: "#{name}-default-",
              vpc_id: arch_ref.network.vpc.id,
              ingress_rules: [{
                from_port: 0,
                to_port: 65_535,
                protocol: 'tcp',
                self: true,
                description: 'All traffic within security group'
              }],
              egress_rules: [{
                from_port: 0,
                to_port: 0,
                protocol: '-1',
                cidr_blocks: ['0.0.0.0/0'],
                description: 'All outbound traffic'
              }],
              tags: base_tags.merge(Tier: 'security', Component: 'default-sg')
            )
          end
        end
      end
    end
  end
end
