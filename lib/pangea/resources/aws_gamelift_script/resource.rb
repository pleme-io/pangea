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
    module AwsGameliftScript
      # Resource-specific methods for AWS GameLift Script
      module Resource
        def self.validate(definition)
          # Must have either storage_location or zip_file
          unless definition[:storage_location] || definition[:zip_file]
            raise ArgumentError, "Either storage_location or zip_file must be specified for GameLift script"
          end

          # Both cannot be specified
          if definition[:storage_location] && definition[:zip_file]
            raise ArgumentError, "Cannot specify both storage_location and zip_file for GameLift script"
          end

          # Validate S3 location if specified
          if definition[:storage_location]
            unless definition[:storage_location][:bucket] && definition[:storage_location][:key]
              raise ArgumentError, "S3 storage_location must specify bucket and key"
            end
          end

          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {
            version: "1.0"
          }
        end

        def self.required_attributes
          %i[name]
        end

        def self.compute_attributes(definition)
          attrs = {
            id: ref(definition[:name], :id),
            arn: ref(definition[:name], :arn),
            name: ref(definition[:name], :name),
            creation_time: ref(definition[:name], :creation_time),
            size_on_disk: ref(definition[:name], :size_on_disk),
            version: ref(definition[:name], :version)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamelift_script.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamelift_script(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamelift_script, name do
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