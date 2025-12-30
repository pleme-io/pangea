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

require_relative '../base'
require_relative '../types'
require_relative 'types'
require_relative 'architecture/component_creation'
require_relative 'architecture/resource_creation'
require_relative 'architecture/fallback_resources'
require_relative 'architecture/outputs'
require_relative 'architecture/cost_estimation'
require_relative 'architecture/helpers'
require 'pangea/architecture_registry'

module Pangea
  module Architectures
    module WebApplicationArchitecture
      # Web application architecture builder
      class Architecture
        include ComponentCreation
        include ResourceCreation
        include FallbackResources
        include Outputs
        include CostEstimation
        include Helpers

        def self.build(name, attributes = {})
          new.build(name, attributes)
        end

        def build(name, attributes = {})
          arch_attrs = Types::Input.new(attributes)
          defaults = Pangea::Architectures::Types.defaults_for_environment(arch_attrs.environment)
          merged_attrs = defaults.merge(arch_attrs.to_h)

          components = create_components(name, merged_attrs)
          resources = create_resources(name, merged_attrs, components)
          outputs = calculate_outputs(name, merged_attrs, components, resources)

          Pangea::Architectures::ArchitectureReference.new(
            type: 'web_application_architecture',
            name: name,
            architecture_attributes: arch_attrs.to_h,
            components: components,
            resources: resources,
            outputs: outputs
          )
        end
      end
    end

    # Architecture module for auto-registration
    module WebApplicationArchitectureModule
      def web_application_architecture(name, attributes = {})
        WebApplicationArchitecture::Architecture.build(name, attributes)
      end
    end
  end
end

# Auto-register this architecture module when it's loaded
Pangea::ArchitectureRegistry.register_architecture(Pangea::Architectures::WebApplicationArchitectureModule)
