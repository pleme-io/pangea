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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS IoT Policy resources
      class IotPolicyAttributes < Dry::Struct
        # Policy name (required)
        attribute :name, Resources::Types::IotPolicyName
        
        # Policy document (required) 
        attribute :policy, Resources::Types::IotPolicyDocument
        
        # Tags (optional)
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        
        # Parse policy document for analysis
        def parsed_policy
          @parsed_policy ||= JSON.parse(policy)
        end
        
        # Get policy version
        def policy_version
          parsed_policy['Version'] || '2012-10-17'
        end
        
        # Get policy statements
        def policy_statements
          parsed_policy['Statement'] || []
        end
        
        # Security analysis
        def security_analysis
          analysis = {
            total_statements: policy_statements.length,
            allows_count: 0,
            denies_count: 0,
            wildcard_actions: [],
            broad_resources: [],
            security_level: 'medium'
          }
          
          policy_statements.each do |statement|
            effect = statement['Effect']&.upcase
            actions = Array(statement['Action'])
            resources = Array(statement['Resource'])
            
            case effect
            when 'ALLOW' then analysis[:allows_count] += 1
            when 'DENY' then analysis[:denies_count] += 1
            end
            
            # Check for wildcard actions
            wildcard_actions = actions.select { |action| action.include?('*') }
            analysis[:wildcard_actions].concat(wildcard_actions)
            
            # Check for broad resources
            broad_resources = resources.select { |resource| resource.include?('*') }
            analysis[:broad_resources].concat(broad_resources)
          end
          
          # Determine security level
          if analysis[:wildcard_actions].include?('*') || analysis[:broad_resources].include?('*')
            analysis[:security_level] = 'low'
          elsif analysis[:wildcard_actions].any? || analysis[:broad_resources].any?
            analysis[:security_level] = 'medium'
          else
            analysis[:security_level] = 'high'
          end
          
          analysis
        end
        
        # Common IoT actions check
        def iot_actions_analysis
          all_actions = policy_statements.flat_map { |s| Array(s['Action']) }.uniq
          
          {
            connect_actions: all_actions.grep(/iot:Connect/),
            publish_actions: all_actions.grep(/iot:Publish/),
            subscribe_actions: all_actions.grep(/iot:Subscribe/),
            receive_actions: all_actions.grep(/iot:Receive/),
            shadow_actions: all_actions.grep(/iot:.*Shadow/),
            job_actions: all_actions.grep(/iot:.*Job/),
            thing_actions: all_actions.grep(/iot:.*Thing/)
          }
        end
        
        # Policy recommendations
        def policy_recommendations
          recommendations = []
          security = security_analysis
          
          if security[:security_level] == 'low'
            recommendations << 'Consider reducing wildcard permissions (*) for better security'
          end
          
          if security[:wildcard_actions].any?
            recommendations << "Wildcard actions detected: #{security[:wildcard_actions].join(', ')}"
          end
          
          if security[:broad_resources].any?
            recommendations << "Broad resource permissions detected: #{security[:broad_resources].join(', ')}"
          end
          
          if security[:denies_count] == 0
            recommendations << 'Consider adding explicit deny statements for unused actions'
          end
          
          recommendations << 'Follow principle of least privilege' if security[:security_level] != 'high'
          
          recommendations
        end
      end
    end
      end
    end
  end
end