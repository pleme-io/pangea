# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # ECR Lifecycle Policy resource attributes with validation
        class ECRLifecyclePolicyAttributes < Dry::Struct
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
            
            # Validate lifecycle policy JSON
            if attrs[:policy]
              policy_str = attrs[:policy]
              
              # Skip validation if it's a terraform function call
              unless policy_str.match?(/^\$\{/) || policy_str.match?(/^jsonencode\(/)
                begin
                  policy_doc = JSON.parse(policy_str)
                  
                  # Validate basic lifecycle policy structure
                  unless policy_doc.is_a?(Hash) && policy_doc['rules']
                    raise Dry::Struct::Error, "lifecycle policy must contain a rules array"
                  end
                  
                  unless policy_doc['rules'].is_a?(Array)
                    raise Dry::Struct::Error, "lifecycle policy rules must be an array"
                  end
                  
                  if policy_doc['rules'].empty?
                    raise Dry::Struct::Error, "lifecycle policy must contain at least one rule"
                  end
                  
                  # Validate each rule
                  policy_doc['rules'].each_with_index do |rule, idx|
                    validate_lifecycle_rule(rule, idx)
                  end
                  
                rescue JSON::ParserError => e
                  raise Dry::Struct::Error, "lifecycle policy must be valid JSON: #{e.message}"
                end
              end
            end
            
            super(attrs)
          end
          
          private
          
          def self.validate_lifecycle_rule(rule, idx)
            unless rule.is_a?(Hash)
              raise Dry::Struct::Error, "Rule[#{idx}] must be a hash"
            end
            
            unless rule['rulePriority'] && rule['rulePriority'].is_a?(Integer)
              raise Dry::Struct::Error, "Rule[#{idx}] must have an integer rulePriority"
            end
            
            unless rule['selection']
              raise Dry::Struct::Error, "Rule[#{idx}] must have a selection block"
            end
            
            unless rule['action']
              raise Dry::Struct::Error, "Rule[#{idx}] must have an action block"
            end
            
            # Validate selection block
            selection = rule['selection']
            unless selection['tagStatus']
              raise Dry::Struct::Error, "Rule[#{idx}] selection must specify tagStatus"
            end
            
            unless %w[tagged untagged any].include?(selection['tagStatus'])
              raise Dry::Struct::Error, "Rule[#{idx}] tagStatus must be 'tagged', 'untagged', or 'any'"
            end
            
            # Validate countType in selection
            if selection['countType'] && !%w[imageCountMoreThan sinceImagePushed].include?(selection['countType'])
              raise Dry::Struct::Error, "Rule[#{idx}] countType must be 'imageCountMoreThan' or 'sinceImagePushed'"
            end
            
            # Validate action block
            action = rule['action']
            unless action['type'] == 'expire'
              raise Dry::Struct::Error, "Rule[#{idx}] action type must be 'expire'"
            end
          end
          
          public
          
          # Computed properties
          def lifecycle_policy_hash
            return nil if policy.match?(/^\$\{/) || policy.match?(/^jsonencode\(/)
            
            begin
              JSON.parse(policy)
            rescue JSON::ParserError
              nil
            end
          end
          
          def rule_count
            doc = lifecycle_policy_hash
            return 0 unless doc && doc['rules']
            doc['rules'].size
          end
          
          def rule_priorities
            doc = lifecycle_policy_hash
            return [] unless doc && doc['rules']
            
            doc['rules'].map { |rule| rule['rulePriority'] }.compact.sort
          end
          
          def has_tagged_image_rules?
            doc = lifecycle_policy_hash
            return false unless doc && doc['rules']
            
            doc['rules'].any? { |rule| rule.dig('selection', 'tagStatus') == 'tagged' }
          end
          
          def has_untagged_image_rules?
            doc = lifecycle_policy_hash
            return false unless doc && doc['rules']
            
            doc['rules'].any? { |rule| rule.dig('selection', 'tagStatus') == 'untagged' }
          end
          
          def has_count_based_rules?
            doc = lifecycle_policy_hash
            return false unless doc && doc['rules']
            
            doc['rules'].any? do |rule|
              rule.dig('selection', 'countType') == 'imageCountMoreThan'
            end
          end
          
          def has_age_based_rules?
            doc = lifecycle_policy_hash
            return false unless doc && doc['rules']
            
            doc['rules'].any? do |rule|
              rule.dig('selection', 'countType') == 'sinceImagePushed'
            end
          end
          
          def estimated_retention_days
            doc = lifecycle_policy_hash
            return nil unless doc && doc['rules']
            
            max_days = 0
            doc['rules'].each do |rule|
              if rule.dig('selection', 'countType') == 'sinceImagePushed'
                unit = rule.dig('selection', 'countUnit')
                number = rule.dig('selection', 'countNumber')
                
                if unit && number
                  days = case unit
                         when 'days' then number
                         when 'weeks' then number * 7
                         when 'months' then number * 30
                         else 0
                         end
                  max_days = [max_days, days].max
                end
              end
            end
            
            max_days > 0 ? max_days : nil
          end
          
          def is_terraform_reference?
            policy.match?(/^\$\{/) || policy.match?(/^jsonencode\(/)
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