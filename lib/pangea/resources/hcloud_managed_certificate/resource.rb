# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_managed_certificate/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudManagedCertificate
      # Create Managed Certificate (Let's Encrypt)
      def hcloud_managed_certificate(name, attributes = {})
        mc_attrs = Hetzner::Types::ManagedCertificateAttributes.new(attributes)

        resource(:hcloud_managed_certificate, name) do
          name mc_attrs.name
          domain_names mc_attrs.domain_names

          if mc_attrs.labels.any?
            labels do
              mc_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_managed_certificate',
          name: name,
          resource_attributes: mc_attrs.to_h,
          outputs: {
            id: "${hcloud_managed_certificate.#{name}.id}",
            name: "${hcloud_managed_certificate.#{name}.name}",
            domain_names: "${hcloud_managed_certificate.#{name}.domain_names}",
            certificate: "${hcloud_managed_certificate.#{name}.certificate}"
          }
        )
      end
    end

    module Hetzner
      include HcloudManagedCertificate
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
