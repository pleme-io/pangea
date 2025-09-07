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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # EKS addon attributes with validation
        class EksAddonAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Supported EKS add-ons and their configuration
          SUPPORTED_ADDONS = {
            'vpc-cni' => {
              versions: ['v1.12.6-eksbuild.2', 'v1.12.5-eksbuild.2', 'v1.12.2-eksbuild.1', 'v1.11.4-eksbuild.1'],
              service_account: 'aws-node',
              namespace: 'kube-system',
              description: 'Amazon VPC CNI plugin for Kubernetes'
            },
            'coredns' => {
              versions: ['v1.10.1-eksbuild.7', 'v1.10.1-eksbuild.6', 'v1.10.1-eksbuild.4', 'v1.9.3-eksbuild.11'],
              service_account: 'coredns',
              namespace: 'kube-system',
              description: 'CoreDNS DNS server for Kubernetes'
            },
            'kube-proxy' => {
              versions: ['v1.29.0-eksbuild.3', 'v1.28.5-eksbuild.3', 'v1.27.9-eksbuild.3', 'v1.26.12-eksbuild.3'],
              service_account: 'kube-proxy',
              namespace: 'kube-system',
              description: 'Kubernetes network proxy'
            },
            'aws-ebs-csi-driver' => {
              versions: ['v1.28.0-eksbuild.1', 'v1.27.0-eksbuild.1', 'v1.26.1-eksbuild.1', 'v1.25.0-eksbuild.1'],
              service_account: 'ebs-csi-controller-sa',
              namespace: 'kube-system',
              description: 'Amazon EBS CSI driver'
            },
            'aws-efs-csi-driver' => {
              versions: ['v1.7.4-eksbuild.1', 'v1.7.1-eksbuild.1', 'v1.6.0-eksbuild.1', 'v1.5.9-eksbuild.1'],
              service_account: 'efs-csi-controller-sa',
              namespace: 'kube-system',
              description: 'Amazon EFS CSI driver'
            },
            'aws-guardduty-agent' => {
              versions: ['v1.4.0-eksbuild.1', 'v1.3.0-eksbuild.1', 'v1.2.0-eksbuild.1'],
              service_account: 'aws-guardduty-agent',
              namespace: 'amazon-guardduty',
              description: 'AWS GuardDuty security monitoring agent'
            },
            'aws-mountpoint-s3-csi-driver' => {
              versions: ['v1.0.0-eksbuild.1'],
              service_account: 's3-csi-driver-sa',
              namespace: 'kube-system',
              description: 'Amazon S3 CSI driver using Mountpoint'
            },
            'snapshot-controller' => {
              versions: ['v6.3.2-eksbuild.1', 'v6.2.2-eksbuild.1'],
              service_account: 'snapshot-controller',
              namespace: 'kube-system',
              description: 'Kubernetes volume snapshot controller'
            },
            'adot' => {
              versions: ['v0.90.0-eksbuild.1', 'v0.88.0-eksbuild.1'],
              service_account: 'aws-otel-sa',
              namespace: 'aws-otel-system',
              description: 'AWS Distro for OpenTelemetry'
            }
          }.freeze
          
          RESOLVE_CONFLICTS_OPTIONS = %w[OVERWRITE NONE PRESERVE].freeze
          
          # Required attributes
          attribute :cluster_name, Pangea::Resources::Types::String
          attribute :addon_name, Pangea::Resources::Types::String.constrained(included_in: SUPPORTED_ADDONS.keys)
          
          # Optional attributes
          attribute :addon_version, Pangea::Resources::Types::String.optional.default(nil)
          attribute :service_account_role_arn, Pangea::Resources::Types::String.optional.default(nil).constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/.+\z/
          )
          attribute :resolve_conflicts, Pangea::Resources::Types::String.constrained(included_in: RESOLVE_CONFLICTS_OPTIONS).default('NONE')
          attribute :resolve_conflicts_on_create, Pangea::Resources::Types::String.optional.constrained(included_in: RESOLVE_CONFLICTS_OPTIONS).default(nil)
          attribute :resolve_conflicts_on_update, Pangea::Resources::Types::String.optional.constrained(included_in: RESOLVE_CONFLICTS_OPTIONS).default(nil)
          attribute :configuration_values, Pangea::Resources::Types::String.optional.default(nil)
          attribute :preserve, Pangea::Resources::Types::Bool.default(true)
          attribute :tags, Pangea::Resources::Types::Hash.default({}.freeze)
          
          # Validate version if specified
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate addon version if specified
            if attrs[:addon_version] && attrs[:addon_name]
              addon_info = SUPPORTED_ADDONS[attrs[:addon_name]]
              if addon_info && !addon_info[:versions].include?(attrs[:addon_version])
                raise Dry::Struct::Error, "Invalid version '#{attrs[:addon_version]}' for addon '#{attrs[:addon_name]}'. " \
                  "Supported versions: #{addon_info[:versions].join(', ')}"
              end
            end
            
            # Validate configuration_values is valid JSON if provided
            if attrs[:configuration_values]
              begin
                require 'json'
                JSON.parse(attrs[:configuration_values])
              rescue JSON::ParserError => e
                raise Dry::Struct::Error, "configuration_values must be valid JSON: #{e.message}"
              end
            end
            
            # Validate resolve_conflicts options
            if attrs[:resolve_conflicts_on_create] && attrs[:resolve_conflicts]
              raise Dry::Struct::Error, "Cannot specify both resolve_conflicts and resolve_conflicts_on_create"
            end
            
            if attrs[:resolve_conflicts_on_update] && attrs[:resolve_conflicts]
              raise Dry::Struct::Error, "Cannot specify both resolve_conflicts and resolve_conflicts_on_update"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def addon_info
            SUPPORTED_ADDONS[addon_name]
          end
          
          def service_account_name
            addon_info[:service_account]
          end
          
          def namespace
            addon_info[:namespace]
          end
          
          def requires_iam_role?
            %w[vpc-cni aws-ebs-csi-driver aws-efs-csi-driver aws-guardduty-agent aws-mountpoint-s3-csi-driver adot].include?(addon_name)
          end
          
          def is_compute_addon?
            %w[vpc-cni kube-proxy].include?(addon_name)
          end
          
          def is_storage_addon?
            %w[aws-ebs-csi-driver aws-efs-csi-driver aws-mountpoint-s3-csi-driver snapshot-controller].include?(addon_name)
          end
          
          def is_networking_addon?
            %w[vpc-cni coredns].include?(addon_name)
          end
          
          def is_observability_addon?
            %w[adot aws-guardduty-agent].include?(addon_name)
          end
          
          def to_h
            hash = {
              cluster_name: cluster_name,
              addon_name: addon_name,
              preserve: preserve
            }
            
            hash[:addon_version] = addon_version if addon_version
            hash[:service_account_role_arn] = service_account_role_arn if service_account_role_arn
            
            # Handle resolve conflicts
            if resolve_conflicts_on_create || resolve_conflicts_on_update
              hash[:resolve_conflicts_on_create] = resolve_conflicts_on_create if resolve_conflicts_on_create
              hash[:resolve_conflicts_on_update] = resolve_conflicts_on_update if resolve_conflicts_on_update
            else
              hash[:resolve_conflicts] = resolve_conflicts
            end
            
            hash[:configuration_values] = configuration_values if configuration_values
            hash[:tags] = tags if tags.any?
            
            hash
          end
        end
      end
    end
  end
end