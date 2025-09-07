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
        # Fargate profile selector for pod matching
        class FargateSelector < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :namespace, Resources::Types::String
          attribute :labels, Resources::Types::Hash.default({}.freeze)
          
          # Validate namespace format
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate namespace is not empty
            if attrs[:namespace] && attrs[:namespace].strip.empty?
              raise Dry::Struct::Error, "Namespace cannot be empty"
            end
            
            # Validate label keys and values
            if attrs[:labels]
              attrs[:labels].each do |key, value|
                if key.to_s.empty? || value.to_s.empty?
                  raise Dry::Struct::Error, "Label keys and values cannot be empty"
                end
                
                # Kubernetes label key validation
                unless key.to_s.match?(/\A[a-zA-Z]([a-zA-Z0-9\-_.]*[a-zA-Z0-9])?\z/)
                  raise Dry::Struct::Error, "Invalid label key format: #{key}"
                end
              end
            end
            
            super(attrs)
          end
          
          def to_h
            hash = { namespace: namespace }
            hash[:labels] = labels if labels.any?
            hash
          end
        end
        
        # EKS Fargate profile attributes with validation
        class EksFargateProfileAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :cluster_name, Resources::Types::String
          attribute :fargate_profile_name, Resources::Types::String.optional.default(nil)
          attribute :pod_execution_role_arn, Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/.+\z/
          )
          attribute :selectors, Resources::Types::Array.of(FargateSelector).constrained(
            min_size: 1,
            max_size: 5
          )
          
          # Optional attributes
          attribute :subnet_ids, Resources::Types::Array.of(Resources::Types::String).optional.default(nil)
          attribute :tags, Resources::Types::Hash.default({}.freeze)
          
          # Validate selectors
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Convert raw selector hashes to FargateSelector objects if needed
            if attrs[:selectors] && attrs[:selectors].is_a?(Array)
              attrs[:selectors] = attrs[:selectors].map do |selector|
                selector.is_a?(FargateSelector) ? selector : FargateSelector.new(selector)
              end
            end
            
            # Validate selector count
            if attrs[:selectors] && attrs[:selectors].size > 5
              raise Dry::Struct::Error, "Fargate profile can have a maximum of 5 selectors"
            end
            
            # Validate unique namespaces when no labels
            if attrs[:selectors]
              namespace_only_selectors = attrs[:selectors].select { |s| s.labels.empty? }
              namespaces = namespace_only_selectors.map(&:namespace)
              if namespaces.size != namespaces.uniq.size
                raise Dry::Struct::Error, "Duplicate namespace selectors without labels are not allowed"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def namespaces
            selectors.map(&:namespace).uniq
          end
          
          def has_labels?
            selectors.any? { |s| s.labels.any? }
          end
          
          def selector_count
            selectors.size
          end
          
          def covers_namespace?(namespace)
            selectors.any? { |s| s.namespace == namespace }
          end
          
          def to_h
            hash = {
              cluster_name: cluster_name,
              pod_execution_role_arn: pod_execution_role_arn,
              selectors: selectors.map(&:to_h)
            }
            
            hash[:fargate_profile_name] = fargate_profile_name if fargate_profile_name
            hash[:subnet_ids] = subnet_ids if subnet_ids
            hash[:tags] = tags if tags.any?
            
            hash
          end
        end
      end
    end
  end
end