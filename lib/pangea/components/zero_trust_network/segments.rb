# frozen_string_literal: true

module Pangea
  module Components
    module ZeroTrustNetwork
      # Network segment management for Zero Trust Network
      module Segments
        def create_network_segments(name, attrs, resources)
          attrs.network_segments.each do |segment|
            create_segment_security_group(name, attrs, resources, segment)
            create_segment_nacl(name, attrs, resources, segment) if segment[:nacl_rules]&.any?
          end
        end

        private

        def create_segment_security_group(name, attrs, resources, segment)
          sg_name = component_resource_name(name, :sg, segment[:name])
          resources[:security_groups][segment[:name]] = aws_security_group(sg_name, {
            name: "zt-#{name}-#{segment[:name]}",
            description: segment[:description] || "Zero Trust segment: #{segment[:name]}",
            vpc_id: attrs.vpc_ref,
            tags: component_tags('zero_trust_network', name, attrs.tags.merge(Segment: segment[:name]))
          })

          aws_vpc_security_group_ingress_rule(:"#{sg_name}_va_ingress", {
            security_group_id: resources[:security_groups][segment[:name]].id,
            description: 'Allow verified access',
            from_port: 443, to_port: 443, ip_protocol: 'tcp', cidr_ipv4: '0.0.0.0/0'
          })
        end

        def create_segment_nacl(name, attrs, resources, segment)
          nacl_name = component_resource_name(name, :nacl, segment[:name])
          resources[:network_acls][segment[:name]] = aws_network_acl(nacl_name, {
            vpc_id: attrs.vpc_ref,
            tags: component_tags('zero_trust_network', name, attrs.tags.merge(Segment: segment[:name]))
          })

          segment[:nacl_rules].each_with_index do |rule, index|
            aws_network_acl_rule(:"#{nacl_name}_rule_#{index}", nacl_rule_attrs(resources, segment, rule, index))
          end
        end

        def nacl_rule_attrs(resources, segment, rule, index)
          {
            network_acl_id: resources[:network_acls][segment[:name]].id,
            rule_number: rule[:rule_number] || (index + 1) * 100,
            protocol: rule[:protocol] || 'tcp',
            rule_action: rule[:action] || 'allow',
            cidr_block: rule[:cidr_block],
            from_port: rule[:from_port],
            to_port: rule[:to_port]
          }
        end
      end
    end
  end
end
