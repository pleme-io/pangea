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
    # Base computed attributes - common to all resources
    class BaseComputedAttributes
      attr_reader :resource_ref

      def initialize(resource_ref)
        @resource_ref = resource_ref
      end

      # Common terraform attributes available on all resources
      def id
        resource_ref.ref(:id)
      end

      def terraform_resource_name
        "#{resource_ref.type}.#{resource_ref.name}"
      end

      def tags
        resource_ref.resource_attributes[:tags] || {}
      end
    end

    # Resource reference object returned by resource functions
    # Provides access to resource attributes, outputs, and computed properties
    class ResourceReference < Dry::Struct
      attribute :type, Types::String           # aws_vpc, aws_subnet, etc.
      attribute :name, Types::Symbol           # Resource name
      attribute :resource_attributes, Types::Hash       # Original attributes passed to function
      attribute :outputs, Types::Hash.default({}.freeze)  # Available outputs for this resource type

      # Generate terraform reference for any attribute
      def ref(attribute_name)
        "${#{type}.#{name}.#{attribute_name}}"
      end

      # Alias for ref - more natural syntax
      def [](attribute_name)
        ref(attribute_name)
      end

      # Access to common outputs with friendly names
      def id
        ref(:id)
      end

      def arn
        ref(:arn)
      end

      # Resource-specific computed properties
      def computed_attributes
        @computed_attributes ||= case type
        when 'aws_vpc'
          VpcComputedAttributes.new(self)
        when 'aws_subnet'
          SubnetComputedAttributes.new(self)
        when 'aws_instance'
          InstanceComputedAttributes.new(self)
        else
          BaseComputedAttributes.new(self)
        end
      end

      # Method delegation to outputs and computed attributes
      def method_missing(method_name, *args, &block)
        # First check if this is an output
        if outputs.key?(method_name)
          outputs[method_name]
        elsif computed_attributes.respond_to?(method_name)
          computed_attributes.public_send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        outputs.key?(method_name) || computed_attributes.respond_to?(method_name, include_private) || super
      end

      # Convert to hash for terraform-synthesizer integration
      def to_h
        {
          type: type,
          name: name,
          attributes: resource_attributes,  # Use 'attributes' as key for compatibility
          outputs: outputs
        }
      end
    end
  end
end

# Require computed attributes after BaseComputedAttributes is defined
require_relative 'reference/vpc_computed_attributes'
require_relative 'reference/subnet_computed_attributes'
require_relative 'reference/instance_computed_attributes'
