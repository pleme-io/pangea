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
        # ECR Replication Configuration resource attributes with validation
        class ECRReplicationConfigurationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :replication_configuration, Resources::Types::Hash.schema(
            rule: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                destination: Resources::Types::Array.of(
                  Resources::Types::Hash.schema(
                    region: Resources::Types::String,
                    registry_id?: Resources::Types::String.optional
                  )
                )
              )
            )
          )
          
          # Validate attributes
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate replication configuration structure
            if attrs[:replication_configuration]
              config = attrs[:replication_configuration]
              
              unless config[:rule] && config[:rule].is_a?(Array)
                raise Dry::Struct::Error, "replication_configuration must contain a rule array"
              end
              
              if config[:rule].empty?
                raise Dry::Struct::Error, "replication_configuration must contain at least one rule"
              end
              
              # Validate each rule
              config[:rule].each_with_index do |rule, idx|
                unless rule[:destination] && rule[:destination].is_a?(Array)
                  raise Dry::Struct::Error, "Rule[#{idx}] must contain a destination array"
                end
                
                if rule[:destination].empty?
                  raise Dry::Struct::Error, "Rule[#{idx}] must contain at least one destination"
                end
                
                # Validate each destination
                rule[:destination].each_with_index do |dest, dest_idx|
                  unless dest[:region]
                    raise Dry::Struct::Error, "Rule[#{idx}] destination[#{dest_idx}] must specify region"
                  end
                  
                  # Validate region format
                  unless dest[:region].match?(/^[a-z]{2}-[a-z]+-\d+$/) || dest[:region].match?(/^\$\{/)
                    raise Dry::Struct::Error, "Rule[#{idx}] destination[#{dest_idx}] region must be a valid AWS region or terraform reference"
                  end
                  
                  # Validate registry_id format if provided
                  if dest[:registry_id] && !dest[:registry_id].empty?
                    unless dest[:registry_id].match?(/^\d{12}$/) || dest[:registry_id].match?(/^\$\{/)
                      raise Dry::Struct::Error, "Rule[#{idx}] destination[#{dest_idx}] registry_id must be a 12-digit AWS account ID or terraform reference"
                    end
                  end
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def rule_count
            replication_configuration[:rule].size
          end
          
          def destination_count
            replication_configuration[:rule].sum { |rule| rule[:destination].size }
          end
          
          def destination_regions
            regions = []
            replication_configuration[:rule].each do |rule|
              rule[:destination].each do |dest|
                regions << dest[:region] unless dest[:region].match?(/^\$\{/)
              end
            end
            regions.uniq.sort
          end
          
          def destination_accounts
            accounts = []
            replication_configuration[:rule].each do |rule|
              rule[:destination].each do |dest|
                if dest[:registry_id] && !dest[:registry_id].match?(/^\$\{/)
                  accounts << dest[:registry_id]
                end
              end
            end
            accounts.uniq.sort
          end
          
          def has_cross_account_replication?
            replication_configuration[:rule].any? do |rule|
              rule[:destination].any? { |dest| dest[:registry_id] && !dest[:registry_id].empty? }
            end
          end
          
          def has_cross_region_replication?
            destination_regions.size > 1
          end
          
          def is_same_account_replication?
            !has_cross_account_replication?
          end
          
          def all_destinations_have_registry_id?
            replication_configuration[:rule].all? do |rule|
              rule[:destination].all? { |dest| dest[:registry_id] && !dest[:registry_id].empty? }
            end
          end
          
          def replication_scope
            if has_cross_account_replication? && has_cross_region_replication?
              :cross_account_cross_region
            elsif has_cross_account_replication?
              :cross_account
            elsif has_cross_region_replication?
              :cross_region
            else
              :single_region
            end
          end
          
          def estimated_monthly_cost_multiplier
            # Rough estimate: each destination adds ~1x cost
            destination_count
          end
          
          def to_h
            {
              replication_configuration: replication_configuration
            }
          end
        end
      end
    end
  end
end