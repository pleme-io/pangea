# frozen_string_literal: true

# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Pangea
  module Resources
    module AWS
      module Lightsail
        # Networking resources for AWS Lightsail
        module Networking
          def aws_lightsail_static_ip(name, attributes = {})
            optional_attrs = { static_ip_name: nil }
            ip_attrs = optional_attrs.merge(attributes)

            resource(:aws_lightsail_static_ip, name) do
              static_ip_name ip_attrs[:static_ip_name] if ip_attrs[:static_ip_name]
            end

            ResourceReference.new(
              type: 'aws_lightsail_static_ip',
              name: name,
              resource_attributes: ip_attrs,
              outputs: {
                id: "${aws_lightsail_static_ip.#{name}.id}",
                arn: "${aws_lightsail_static_ip.#{name}.arn}",
                ip_address: "${aws_lightsail_static_ip.#{name}.ip_address}",
                support_code: "${aws_lightsail_static_ip.#{name}.support_code}"
              }
            )
          end

          def aws_lightsail_static_ip_attachment(name, attributes = {})
            required_attrs = %i[static_ip_name instance_name]
            validate_required_attrs!(required_attrs, attributes)

            resource(:aws_lightsail_static_ip_attachment, name) do
              static_ip_name attributes[:static_ip_name]
              instance_name attributes[:instance_name]
            end

            ResourceReference.new(
              type: 'aws_lightsail_static_ip_attachment',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_lightsail_static_ip_attachment.#{name}.id}",
                ip_address: "${aws_lightsail_static_ip_attachment.#{name}.ip_address}"
              }
            )
          end

          def aws_lightsail_domain(name, attributes = {})
            required_attrs = %i[domain_name]
            optional_attrs = { tags: {} }

            domain_attrs = optional_attrs.merge(attributes)
            validate_required_attrs!(required_attrs, domain_attrs)

            resource(:aws_lightsail_domain, name) do
              domain_name domain_attrs[:domain_name]
              tags domain_attrs[:tags] if domain_attrs[:tags].any?
            end

            ResourceReference.new(
              type: 'aws_lightsail_domain',
              name: name,
              resource_attributes: domain_attrs,
              outputs: {
                id: "${aws_lightsail_domain.#{name}.id}",
                arn: "${aws_lightsail_domain.#{name}.arn}",
                domain_name: "${aws_lightsail_domain.#{name}.domain_name}"
              }
            )
          end

          def aws_lightsail_certificate(name, attributes = {})
            required_attrs = %i[certificate_name domain_name]
            optional_attrs = { subject_alternative_names: [], tags: {} }

            cert_attrs = optional_attrs.merge(attributes)
            validate_required_attrs!(required_attrs, cert_attrs)

            resource(:aws_lightsail_certificate, name) do
              certificate_name cert_attrs[:certificate_name]
              domain_name cert_attrs[:domain_name]
              subject_alternative_names cert_attrs[:subject_alternative_names] if cert_attrs[:subject_alternative_names].any?
              tags cert_attrs[:tags] if cert_attrs[:tags].any?
            end

            ResourceReference.new(
              type: 'aws_lightsail_certificate',
              name: name,
              resource_attributes: cert_attrs,
              outputs: {
                id: "${aws_lightsail_certificate.#{name}.id}",
                arn: "${aws_lightsail_certificate.#{name}.arn}",
                created_at: "${aws_lightsail_certificate.#{name}.created_at}",
                domain_validation_options: "${aws_lightsail_certificate.#{name}.domain_validation_options}"
              }
            )
          end
        end
      end
    end
  end
end
