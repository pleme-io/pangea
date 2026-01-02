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
require 'json'

require_relative 'types/validation'
require_relative 'types/computed'

module Pangea
  module Resources
    module AWS
      module Types
        # ECR Lifecycle Policy resource attributes with validation
        class ECRLifecyclePolicyAttributes < Dry::Struct
          include Computed

          transform_keys(&:to_sym)

          # Required attributes
          attribute :repository, Resources::Types::String
          attribute :policy, Resources::Types::String

          # Validate attributes
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            validate_repository(attrs[:repository]) if attrs[:repository]
            validate_policy(attrs[:policy]) if attrs[:policy]

            super(attrs)
          end

          def self.validate_repository(repo)
            # Allow terraform references or valid repository names
            unless repo.match?(/^\$\{/) || repo.match?(/^[a-z0-9]+(?:[._-][a-z0-9]+)*$/)
              raise Dry::Struct::Error, 'repository must be a valid repository name or terraform reference'
            end
          end

          def self.validate_policy(policy_str)
            # Skip validation if it's a terraform function call
            return if policy_str.match?(/^\$\{/) || policy_str.match?(/^jsonencode\(/)

            begin
              policy_doc = JSON.parse(policy_str)
              validate_policy_structure(policy_doc)
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "lifecycle policy must be valid JSON: #{e.message}"
            end
          end

          def self.validate_policy_structure(policy_doc)
            unless policy_doc.is_a?(Hash) && policy_doc['rules']
              raise Dry::Struct::Error, 'lifecycle policy must contain a rules array'
            end

            unless policy_doc['rules'].is_a?(Array)
              raise Dry::Struct::Error, 'lifecycle policy rules must be an array'
            end

            if policy_doc['rules'].empty?
              raise Dry::Struct::Error, 'lifecycle policy must contain at least one rule'
            end

            policy_doc['rules'].each_with_index do |rule, idx|
              Validation.validate_lifecycle_rule(rule, idx)
            end
          end

          def to_h
            {
              repository: repository,
              policy: policy
            }
          end
        end
      end
    end
  end
end
