# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_uploaded_certificate/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudUploadedCertificate
      # Upload SSL/TLS certificate to Hetzner Cloud
      def hcloud_uploaded_certificate(name, attributes = {})
        cert_attrs = Hetzner::Types::UploadedCertificateAttributes.new(attributes)

        resource(:hcloud_uploaded_certificate, name) do
          name cert_attrs.name
          certificate cert_attrs.certificate
          private_key cert_attrs.private_key
          labels cert_attrs.labels
        end

        ResourceReference.new(
          type: 'hcloud_uploaded_certificate',
          name: name,
          resource_attributes: cert_attrs.to_h,
          outputs: {
            id: "${hcloud_uploaded_certificate.#{name}.id}",
            name: "${hcloud_uploaded_certificate.#{name}.name}",
            not_valid_before: "${hcloud_uploaded_certificate.#{name}.not_valid_before}",
            not_valid_after: "${hcloud_uploaded_certificate.#{name}.not_valid_after}",
            fingerprint: "${hcloud_uploaded_certificate.#{name}.fingerprint}"
          }
        )
      end
    end

    module Hetzner
      include HcloudUploadedCertificate
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
