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
    module AwsGameliftPlayerSession
      # Resource-specific methods for AWS GameLift Player Session
      module Resource
        def self.validate(definition)
          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {}
        end

        def self.required_attributes
          %i[game_session_id player_id]
        end

        def self.compute_attributes(definition)
          attrs = {
            id: ref(definition[:name], :id),
            player_session_id: ref(definition[:name], :player_session_id),
            game_session_id: ref(definition[:name], :game_session_id),
            fleet_id: ref(definition[:name], :fleet_id),
            fleet_arn: ref(definition[:name], :fleet_arn),
            player_id: ref(definition[:name], :player_id),
            ip_address: ref(definition[:name], :ip_address),
            port: ref(definition[:name], :port),
            dns_name: ref(definition[:name], :dns_name),
            status: ref(definition[:name], :status),
            creation_time: ref(definition[:name], :creation_time),
            termination_time: ref(definition[:name], :termination_time)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamelift_player_session.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamelift_player_session(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamelift_player_session, name do
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