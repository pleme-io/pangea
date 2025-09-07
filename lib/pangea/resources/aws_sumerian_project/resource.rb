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
    module AwsSumerianProject
      # Resource-specific methods for AWS Sumerian Project
      module Resource
        def self.validate(definition)
          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {
            template: "empty"
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
            description: ref(definition[:name], :description),
            project_id: ref(definition[:name], :project_id),
            owner: ref(definition[:name], :owner),
            creation_time: ref(definition[:name], :creation_time),
            last_updated_time: ref(definition[:name], :last_updated_time),
            state: ref(definition[:name], :state)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_sumerian_project.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_sumerian_project(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_sumerian_project, name do
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