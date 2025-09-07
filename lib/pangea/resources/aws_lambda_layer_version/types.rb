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
        # Lambda layer version attributes with validation
        class LambdaLayerVersionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :layer_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 140,
            format: /\A[a-zA-Z0-9_-]+\z/
          )
          
          # Code source - either filename or s3
          attribute :filename, Resources::Types::String.optional
          attribute :s3_bucket, Resources::Types::String.optional
          attribute :s3_key, Resources::Types::String.optional
          attribute :s3_object_version, Resources::Types::String.optional
          
          # Optional attributes
          attribute :compatible_runtimes, Resources::Types::Array.of(Resources::Types::LambdaRuntime).default([].freeze)
          attribute :compatible_architectures, Resources::Types::Array.of(Resources::Types::LambdaArchitecture).default([].freeze)
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :license_info, Resources::Types::String.constrained(max_size: 512).optional
          attribute :source_code_hash, Resources::Types::String.optional
          attribute :skip_destroy, Resources::Types::Bool.default(false)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate code source
            if attrs[:filename].nil? && attrs[:s3_bucket].nil?
              raise Dry::Struct::Error, "Either filename or s3_bucket/s3_key must be specified"
            end
            
            if attrs[:s3_bucket] && attrs[:s3_key].nil?
              raise Dry::Struct::Error, "s3_key is required when s3_bucket is specified"
            end
            
            if attrs[:filename] && attrs[:s3_bucket]
              raise Dry::Struct::Error, "Cannot specify both filename and s3_bucket"
            end
            
            # Validate compatible architectures
            if attrs[:compatible_architectures] && attrs[:compatible_architectures].size > 2
              raise Dry::Struct::Error, "Lambda layers support at most 2 architectures"
            end
            
            # Validate runtime and architecture compatibility
            if attrs[:compatible_runtimes] && attrs[:compatible_architectures]
              validate_runtime_architecture_compatibility(
                attrs[:compatible_runtimes],
                attrs[:compatible_architectures]
              )
            end
            
            super(attrs)
          end
          
          # Validate runtime and architecture compatibility
          def self.validate_runtime_architecture_compatibility(runtimes, architectures)
            # Some older runtimes don't support arm64
            arm64_incompatible_runtimes = %w[
              nodejs12.x nodejs10.x
              python3.6 python3.7
              ruby2.5 ruby2.7
              java8 
              dotnetcore2.1 dotnetcore3.1
              go1.x
            ]
            
            if architectures.include?('arm64')
              incompatible = runtimes & arm64_incompatible_runtimes
              unless incompatible.empty?
                raise Dry::Struct::Error, "Runtime(s) #{incompatible.join(', ')} do not support arm64 architecture"
              end
            end
          end
          
          # Computed properties
          def estimated_size_mb
            # Layers can be up to 50MB zipped, 250MB unzipped
            50 # Default estimate
          end
          
          def supports_all_architectures?
            compatible_architectures.empty? || 
            compatible_architectures.sort == ['arm64', 'x86_64']
          end
          
          def runtime_families
            return [] if compatible_runtimes.empty?
            
            families = Set.new
            compatible_runtimes.each do |runtime|
              case runtime
              when /^python/ then families << 'python'
              when /^nodejs/ then families << 'nodejs'
              when /^java/ then families << 'java'
              when /^dotnet/ then families << 'dotnet'
              when /^ruby/ then families << 'ruby'
              when /^go/ then families << 'go'
              when /^provided/ then families << 'custom'
              end
            end
            families.to_a.sort
          end
          
          def is_architecture_specific?
            !compatible_architectures.empty? && compatible_architectures.size == 1
          end
          
          def is_runtime_specific?
            !compatible_runtimes.empty?
          end
          
          def layer_type
            if compatible_runtimes.any? { |r| r.include?('python') }
              if layer_name.include?('pandas') || layer_name.include?('numpy') || 
                 layer_name.include?('scipy') || layer_name.include?('sklearn')
                'data-science'
              else
                'runtime-dependencies'
              end
            elsif layer_name.include?('aws-sdk')
              'aws-sdk'
            elsif layer_name.include?('monitoring') || layer_name.include?('observability')
              'monitoring'
            else
              'general'
            end
          end
        end
      end
    end
  end
end