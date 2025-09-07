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

module Pangea
  module Resources
    module AWS
      module Types
        # ECR Repository Policy resource attributes with validation
        class ECRRepositoryPolicyAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :repository, Resources::Types::String
          attribute :policy, Resources::Types::String
          
          # Validate attributes
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate repository name format
            if attrs[:repository]
              repo = attrs[:repository]
              # Allow terraform references or valid repository names
              unless repo.match?(/^\$\{/) || repo.match?(/^[a-z0-9]+(?:[._-][a-z0-9]+)*$/)
                raise Dry::Struct::Error, "repository must be a valid repository name or terraform reference"
              end
            end
            
            # Validate policy JSON
            if attrs[:policy]
              policy_str = attrs[:policy]
              
              # Skip validation if it's a terraform function call
              unless policy_str.match?(/^\$\{/) || policy_str.match?(/^data\.aws_iam_policy_document\./)
                begin
                  policy_doc = JSON.parse(policy_str)
                  
                  # Validate basic policy structure
                  unless policy_doc.is_a?(Hash) && policy_doc['Statement']
                    raise Dry::Struct::Error, "policy must contain a Statement array"
                  end
                  
                  unless policy_doc['Statement'].is_a?(Array)
                    raise Dry::Struct::Error, "policy Statement must be an array"
                  end
                  
                  # Validate each statement has required fields
                  policy_doc['Statement'].each_with_index do |stmt, idx|
                    unless stmt.is_a?(Hash)
                      raise Dry::Struct::Error, "Statement[#{idx}] must be a hash"
                    end
                    
                    unless stmt['Effect'] && %w[Allow Deny].include?(stmt['Effect'])
                      raise Dry::Struct::Error, "Statement[#{idx}] must have Effect of Allow or Deny"
                    end
                    
                    unless stmt['Principal'] || stmt['AWS']
                      raise Dry::Struct::Error, "Statement[#{idx}] must specify Principal or AWS"
                    end
                    
                    unless stmt['Action']
                      raise Dry::Struct::Error, "Statement[#{idx}] must specify Action"
                    end
                  end
                  
                rescue JSON::ParserError => e
                  raise Dry::Struct::Error, "policy must be valid JSON: #{e.message}"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def policy_document_hash
            return nil if policy.match?(/^\$\{/) || policy.match?(/^data\.aws_iam_policy_document\./)
            
            begin
              JSON.parse(policy)
            rescue JSON::ParserError
              nil
            end
          end
          
          def statement_count
            doc = policy_document_hash
            return 0 unless doc && doc['Statement']
            doc['Statement'].size
          end
          
          def allows_cross_account_access?
            doc = policy_document_hash
            return false unless doc
            
            doc['Statement'].any? do |stmt|
              stmt['Effect'] == 'Allow' && (
                (stmt['Principal'] && stmt['Principal']['AWS'] && 
                 stmt['Principal']['AWS'].to_s.include?('*')) ||
                (stmt['AWS'] && stmt['AWS'].to_s.include?('*'))
              )
            end
          end
          
          def allowed_actions
            doc = policy_document_hash
            return [] unless doc
            
            actions = []
            doc['Statement'].each do |stmt|
              next unless stmt['Effect'] == 'Allow'
              
              if stmt['Action'].is_a?(Array)
                actions.concat(stmt['Action'])
              elsif stmt['Action'].is_a?(String)
                actions << stmt['Action']
              end
            end
            
            actions.uniq
          end
          
          def denied_actions
            doc = policy_document_hash
            return [] unless doc
            
            actions = []
            doc['Statement'].each do |stmt|
              next unless stmt['Effect'] == 'Deny'
              
              if stmt['Action'].is_a?(Array)
                actions.concat(stmt['Action'])
              elsif stmt['Action'].is_a?(String)
                actions << stmt['Action']
              end
            end
            
            actions.uniq
          end
          
          def grants_pull_access?
            allowed_actions.any? do |action|
              %w[
                ecr:GetDownloadUrlForLayer
                ecr:BatchGetImage
                ecr:BatchCheckLayerAvailability
              ].include?(action) || action == 'ecr:*'
            end
          end
          
          def grants_push_access?
            allowed_actions.any? do |action|
              %w[
                ecr:PutImage
                ecr:InitiateLayerUpload
                ecr:UploadLayerPart
                ecr:CompleteLayerUpload
              ].include?(action) || action == 'ecr:*'
            end
          end
          
          def is_terraform_reference?
            policy.match?(/^\$\{/) || policy.match?(/^data\.aws_iam_policy_document\./)
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