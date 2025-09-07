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


require_relative "types"

module Pangea
  module Resources
    module AwsGameliftFleet
      # Resource-specific methods for AWS GameLift Fleet
      module Resource
        def self.validate(definition)
          # Must have either build_id or script_id
          unless definition[:build_id] || definition[:script_id]
            raise ArgumentError, "Either build_id or script_id must be specified for GameLift fleet"
          end

          # Both cannot be specified
          if definition[:build_id] && definition[:script_id]
            raise ArgumentError, "Cannot specify both build_id and script_id for GameLift fleet"
          end

          # Validate scaling constraints
          if definition[:min_size] && definition[:max_size]
            if definition[:min_size] > definition[:max_size]
              raise ArgumentError, "min_size cannot be greater than max_size"
            end
          end

          if definition[:desired_ec2_instances]
            min = definition[:min_size] || 0
            max = definition[:max_size] || 1000
            desired = definition[:desired_ec2_instances]
            
            if desired < min || desired > max
              raise ArgumentError, "desired_ec2_instances must be between min_size and max_size"
            end
          end

          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {
            fleet_type: "ON_DEMAND",
            new_game_session_protection_policy: "NoProtection",
            compute_type: "EC2",
            min_size: 0,
            max_size: 1,
            desired_ec2_instances: 1,
            certificate_configuration: {
              certificate_type: "GENERATED"
            }
          }
        end

        def self.required_attributes
          %i[name ec2_instance_type]
        end

        def self.compute_attributes(definition)
          attrs = {
            id: ref(definition[:name], :id),
            arn: ref(definition[:name], :arn),
            build_arn: ref(definition[:name], :build_arn),
            creation_time: ref(definition[:name], :creation_time),
            operating_system: ref(definition[:name], :operating_system),
            status: ref(definition[:name], :status),
            log_paths: ref(definition[:name], :log_paths)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamelift_fleet.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamelift_fleet(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamelift_fleet, name do
          # Add attributes
          validated.to_h.each do |key, value|
            send(key, value) unless value.nil?
          end
        end
        
        # Return computed attributes as reference
        Resource.compute_attributes(validated.to_h.merge(name: name))
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)