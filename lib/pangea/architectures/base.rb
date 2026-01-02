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

require_relative 'base/vpc_networking'
require_relative 'base/architecture_reference'

module Pangea
  module Architectures
    # Base module for architecture patterns - provides common functionality
    module Base
      include Base::VpcNetworking

      # Creates a new ArchitectureReference for the architecture
      def create_architecture_reference(type, name, **options)
        Base::ArchitectureReference.new(type: type, name: name, **options)
      end

      # Generate base tags for architecture resources
      def architecture_tags(arch_ref, additional_tags = {})
        {
          Architecture: arch_ref.type,
          ArchitectureName: arch_ref.name.to_s,
          ManagedBy: 'Pangea'
        }.merge(additional_tags)
      end

      # Generate resource name for architecture
      def architecture_resource_name(arch_name, resource_suffix)
        "#{arch_name}_#{resource_suffix}".to_sym
      end
    end

    # Factory method for creating architecture references
    def self.create_reference(type, name, **options)
      Base::ArchitectureReference.new(type: type, name: name, **options)
    end
  end
end
