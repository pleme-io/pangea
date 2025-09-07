# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Config Config Rule resource attributes with validation
        class ConfigConfigRuleAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String
          attribute :source, Resources::Types::Hash
          
          # Optional attributes
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :input_parameters, Resources::Types::String.optional.default(nil)
          attribute :maximum_execution_frequency, Resources::Types::String.optional.default(nil)
          attribute :scope, Resources::Types::Hash.optional.default(nil)
          attribute :depends_on, Resources::Types::Array.optional.default([])
          
          # Tags
          attribute :tags, Resources::Types::AwsTags
          
          # Validate config rule name and source configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:name]
              name = attrs[:name]
              
              # Must not be empty
              if name.empty?
                raise Dry::Struct::Error, "Config rule name cannot be empty"
              end
              
              # Length constraints (AWS Config allows 1-128 characters)
              if name.length > 128
                raise Dry::Struct::Error, "Config rule name cannot exceed 128 characters"
              end
              
              # Character validation - alphanumeric, hyphens, underscores
              unless name.match?(/\A[a-zA-Z0-9_-]+\z/)
                raise Dry::Struct::Error, "Config rule name can only contain alphanumeric characters, hyphens, and underscores"
              end
            end
            
            # Validate source configuration
            if attrs[:source].is_a?(Hash)
              source = attrs[:source]
              
              # Owner is required
              unless source[:owner]
                raise Dry::Struct::Error, "source.owner is required"
              end
              
              # Valid owner values
              valid_owners = ['AWS', 'AWS_CONFIG_RULE', 'CUSTOM_LAMBDA', 'CUSTOM_POLICY']
              unless valid_owners.include?(source[:owner])
                raise Dry::Struct::Error, "source.owner must be one of: #{valid_owners.join(', ')}"
              end
              
              # Validate based on owner type
              case source[:owner]
              when 'AWS'
                unless source[:source_identifier]
                  raise Dry::Struct::Error, "source.source_identifier is required for AWS managed rules"
                end
              when 'CUSTOM_LAMBDA'
                unless source[:source_identifier]
                  raise Dry::Struct::Error, "source.source_identifier (Lambda ARN) is required for custom Lambda rules"
                end
                # Validate Lambda ARN format
                unless source[:source_identifier].match?(/\Aarn:aws:lambda:[^:]+:\d{12}:function:/)
                  raise Dry::Struct::Error, "source.source_identifier must be a valid Lambda function ARN for custom Lambda rules"
                end
              when 'CUSTOM_POLICY'
                unless source[:source_detail] && source[:source_detail].is_a?(Array)
                  raise Dry::Struct::Error, "source.source_detail is required for custom policy rules"
                end
              end
            end
            
            # Validate maximum execution frequency if provided
            if attrs[:maximum_execution_frequency]
              valid_frequencies = [
                'One_Hour', 'Three_Hours', 'Six_Hours', 'Twelve_Hours', 'TwentyFour_Hours'
              ]
              unless valid_frequencies.include?(attrs[:maximum_execution_frequency])
                raise Dry::Struct::Error, "maximum_execution_frequency must be one of: #{valid_frequencies.join(', ')}"
              end
            end
            
            # Validate scope if provided
            if attrs[:scope].is_a?(Hash)
              scope = attrs[:scope]
              
              if scope[:compliance_resource_types] && !scope[:compliance_resource_types].is_a?(Array)
                raise Dry::Struct::Error, "scope.compliance_resource_types must be an array"
              end
              
              if scope[:tag_key] && !scope[:tag_key].is_a?(String)
                raise Dry::Struct::Error, "scope.tag_key must be a string"
              end
              
              if scope[:tag_value] && !scope[:tag_value].is_a?(String)
                raise Dry::Struct::Error, "scope.tag_value must be a string"
              end
              
              if scope[:compliance_resource_id] && !scope[:compliance_resource_id].is_a?(String)
                raise Dry::Struct::Error, "scope.compliance_resource_id must be a string"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_aws_managed?
            source[:owner] == 'AWS'
          end
          
          def is_custom_lambda?
            source[:owner] == 'CUSTOM_LAMBDA'
          end
          
          def is_custom_policy?
            source[:owner] == 'CUSTOM_POLICY'
          end
          
          def has_scope?
            !scope.nil? && !scope.empty?
          end
          
          def has_resource_type_scope?
            has_scope? && scope[:compliance_resource_types].is_a?(Array) && !scope[:compliance_resource_types].empty?
          end
          
          def has_tag_scope?
            has_scope? && (scope[:tag_key] || scope[:tag_value])
          end
          
          def has_periodic_execution?
            !maximum_execution_frequency.nil?
          end
          
          def estimated_monthly_cost_usd
            # AWS Config rule evaluation costs
            # Base cost for rule evaluation: $0.001 per evaluation
            
            base_evaluations = if has_periodic_execution?
                                # Periodic rules based on execution frequency
                                case maximum_execution_frequency
                                when 'One_Hour' then 30 * 24
                                when 'Three_Hours' then 30 * 8
                                when 'Six_Hours' then 30 * 4
                                when 'Twelve_Hours' then 30 * 2
                                else 30 # TwentyFour_Hours
                                end
                              else
                                # Configuration change triggered rules
                                100 # Estimate based on resource change frequency
                              end
            
            # Scale based on resource scope
            if has_resource_type_scope?
              # Multiple resource types increase evaluation count
              resource_multiplier = [scope[:compliance_resource_types].length / 5.0, 1.0].max
              evaluations = (base_evaluations * resource_multiplier).to_i
            else
              evaluations = base_evaluations
            end
            
            # Rule evaluation cost
            evaluation_cost = evaluations * 0.001
            
            # Custom Lambda rules have additional Lambda execution costs
            lambda_cost = if is_custom_lambda?
                           # Estimate Lambda execution cost
                           lambda_executions = evaluations
                           execution_time_ms = 5000 # 5 seconds average
                           memory_mb = 128
                           
                           # Lambda pricing: $0.0000166667 per GB-second
                           gb_seconds = (memory_mb / 1024.0) * (execution_time_ms / 1000.0) * lambda_executions
                           gb_seconds * 0.0000166667
                         else
                           0.0
                         end
            
            total_cost = evaluation_cost + lambda_cost
            total_cost.round(4) # More precision for small costs
          end
          
          def to_h
            hash = {
              name: name,
              source: source,
              tags: tags
            }
            
            hash[:description] = description if description
            hash[:input_parameters] = input_parameters if input_parameters
            hash[:maximum_execution_frequency] = maximum_execution_frequency if maximum_execution_frequency
            hash[:scope] = scope if has_scope?
            hash[:depends_on] = depends_on if depends_on.any?
            
            hash.compact
          end
        end
      end
    end
  end
end