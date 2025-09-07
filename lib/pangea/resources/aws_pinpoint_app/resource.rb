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
    module AwsPinpointApp
      # Resource-specific methods for AWS Pinpoint App
      module Resource
        def self.validate(definition)
          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {
            limits: {
              daily: 0,  # 0 means unlimited
              maximum_duration: 3600,  # 1 hour default
              messages_per_second: 20000,
              total: 0  # 0 means unlimited
            }
          }
        end

        def self.required_attributes
          %i[name]
        end

        def self.compute_attributes(definition)
          attrs = {
            application_id: ref(definition[:name], :application_id),
            arn: ref(definition[:name], :arn),
            name: ref(definition[:name], :name)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_pinpoint_app.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_pinpoint_app(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_pinpoint_app, name do
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