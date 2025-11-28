# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_certificate/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudCertificate
      # Create Certificate
      def hcloud_certificate(name, attributes = {})
        cert_attrs = Hetzner::Types::CertificateAttributes.new(attributes)

        resource(:hcloud_certificate, name) do
          name cert_attrs.name
          certificate cert_attrs.certificate if cert_attrs.certificate
          private_key cert_attrs.private_key if cert_attrs.private_key

          if cert_attrs.labels.any?
            labels do
              cert_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_certificate',
          name: name,
          resource_attributes: cert_attrs.to_h,
          outputs: {
            id: "${hcloud_certificate.#{name}.id}",
            name: "${hcloud_certificate.#{name}.name}",
            not_valid_before: "${hcloud_certificate.#{name}.not_valid_before}",
            not_valid_after: "${hcloud_certificate.#{name}.not_valid_after}"
          }
        )
      end
    end

    module Hetzner
      include HcloudCertificate
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
