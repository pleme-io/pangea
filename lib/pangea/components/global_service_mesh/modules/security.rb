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

require 'json'

module Pangea
  module Components
    module GlobalServiceMesh
      # Security infrastructure: mTLS, IAM roles, and Secrets Manager
      module Security
        def create_security_infrastructure(name, attrs, _mesh_ref, tags)
          security_resources = {}

          if attrs.security.mtls_enabled && !attrs.security.certificate_authority_arn
            security_resources[:ca] = create_private_ca(name, attrs, tags)
          end

          if attrs.security.service_auth_enabled
            security_resources[:service_roles] = create_service_roles(name, attrs, tags, security_resources)
          end

          if attrs.security.secrets_manager_integration
            security_resources[:secrets] = create_service_secrets(name, attrs, tags)
          end

          security_resources
        end

        private

        def create_private_ca(name, attrs, tags)
          aws_acmpca_certificate_authority(
            component_resource_name(name, :private_ca),
            {
              certificate_authority_configuration: {
                key_algorithm: "RSA_4096",
                signing_algorithm: "SHA512WITHRSA",
                subject: { common_name: "#{attrs.mesh_name}.ca" }
              },
              type: "ROOT",
              tags: tags
            }
          )
        end

        def create_service_roles(name, attrs, tags, security_resources)
          service_roles = {}

          attrs.services.each do |service|
            role_ref = create_service_role(name, service, tags)
            service_roles[service.name.to_sym] = role_ref

            security_resources["policy_#{service.name}".to_sym] = attach_appmesh_policy(name, service, role_ref)
          end

          service_roles
        end

        def create_service_role(name, service, tags)
          aws_iam_role(
            component_resource_name(name, :service_role, service.name.to_sym),
            {
              name: "#{name}-#{service.name}-role",
              assume_role_policy: build_assume_role_policy(service),
              tags: tags.merge(Service: service.name)
            }
          )
        end

        def build_assume_role_policy(service)
          JSON.generate({
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Principal: { Service: "ecs-tasks.amazonaws.com" },
              Action: "sts:AssumeRole",
              Condition: {
                StringEquals: { "sts:ExternalId": service.name }
              }
            }]
          })
        end

        def attach_appmesh_policy(name, service, role_ref)
          aws_iam_role_policy_attachment(
            component_resource_name(name, :service_policy, service.name.to_sym),
            {
              role: role_ref.name,
              policy_arn: "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
            }
          )
        end

        def create_service_secrets(name, attrs, tags)
          secrets = {}

          attrs.services.each do |service|
            secrets[service.name.to_sym] = aws_secretsmanager_secret(
              component_resource_name(name, :service_secret, service.name.to_sym),
              {
                name: "#{name}/#{service.name}/config",
                description: "Configuration secrets for #{service.name}",
                tags: tags.merge(Service: service.name)
              }
            )
          end

          secrets
        end
      end
    end
  end
end
