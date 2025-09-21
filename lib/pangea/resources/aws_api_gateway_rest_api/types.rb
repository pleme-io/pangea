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
        # API Gateway REST API attributes with validation
        class ApiGatewayRestApiAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :name, Pangea::Resources::Types::String
          attribute :description, Pangea::Resources::Types::String.optional
          
          # API type - EDGE (CloudFront), REGIONAL, or PRIVATE
          attribute :endpoint_configuration, Pangea::Resources::Types::Hash.optional do
            attribute :types, Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::String.constrained(included_in: ['EDGE', 'REGIONAL', 'PRIVATE'])
            ).default(['REGIONAL'].freeze)
            attribute :vpc_endpoint_ids, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
          end
          
          # API versioning
          attribute :version, Pangea::Resources::Types::String.optional
          attribute :clone_from, Pangea::Resources::Types::String.optional
          
          # Binary media types for file uploads
          attribute :binary_media_types, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          
          # Minimum TLS version
          attribute :minimum_tls_version, Pangea::Resources::Types::String.constrained(included_in: ['TLS_1_0', 'TLS_1_2']).default('TLS_1_2')
          
          # Compression settings
          attribute :minimum_compression_size, Pangea::Resources::Types::Coercible::Integer.optional
          
          # API Key source for authentication
          attribute :api_key_source, Pangea::Resources::Types::String.constrained(included_in: ['HEADER', 'AUTHORIZER']).default('HEADER')
          
          # Policy document for resource policies
          attribute :policy, Pangea::Resources::Types::String.optional
          
          # OpenAPI/Swagger specification
          attribute :body, Pangea::Resources::Types::String.optional
          
          # Disable execute API endpoint
          attribute :disable_execute_api_endpoint, Pangea::Resources::Types::Bool.default(false)
          
          # Custom domain settings
          attribute :custom_domain_name, Pangea::Resources::Types::String.optional
          
          # Tags
          attribute :tags, Pangea::Resources::Types::Hash.default({}.freeze)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate name follows API Gateway naming conventions
            if attrs[:name] && !attrs[:name].match?(/^[a-zA-Z0-9._-]+$/)
              raise Dry::Struct::Error, "API name must contain only alphanumeric characters, hyphens, underscores, and periods"
            end
            
            # Validate VPC endpoint IDs are provided for PRIVATE APIs
            if attrs[:endpoint_configuration] && 
               attrs[:endpoint_configuration][:types]&.include?('PRIVATE') &&
               attrs[:endpoint_configuration][:vpc_endpoint_ids].to_a.empty?
              raise Dry::Struct::Error, "VPC endpoint IDs must be provided for PRIVATE API type"
            end
            
            # Validate compression size is reasonable
            if attrs[:minimum_compression_size] && 
               (attrs[:minimum_compression_size] < 0 || attrs[:minimum_compression_size] > 10485760)
              raise Dry::Struct::Error, "Minimum compression size must be between 0 and 10485760 bytes (10MB)"
            end
            
            # Validate binary media types format
            if attrs[:binary_media_types]
              attrs[:binary_media_types].each do |media_type|
                unless media_type.match?(%r{^[\w\-\+\.]+/[\w\-\+\.]+$})
                  raise Dry::Struct::Error, "Invalid binary media type format: #{media_type}. Expected format: type/subtype"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_edge_optimized?
            endpoint_configuration&.fetch(:types, [])&.include?('EDGE')
          end
          
          def is_regional?
            endpoint_configuration&.fetch(:types, [])&.include?('REGIONAL')
          end
          
          def is_private?
            endpoint_configuration&.fetch(:types, [])&.include?('PRIVATE')
          end
          
          def supports_binary_content?
            !binary_media_types.empty?
          end
          
          def has_custom_domain?
            !custom_domain_name.nil?
          end
          
          def estimated_monthly_cost
            # API Gateway pricing (rough estimates)
            # $3.50 per million API calls for REST APIs
            # Plus data transfer costs
            
            base_cost = 0.0
            
            # Base charge for REST API (assumed 1M calls/month for estimate)
            base_cost += 3.50
            
            # Cache costs if enabled (not directly configurable here but common)
            # $0.02 per GB-hour for 0.5 GB cache = ~$7.20/month
            
            # Data transfer costs vary by region
            # Rough estimate: $0.09/GB for first 10TB
            
            base_cost
          end
          
          # Common binary media types for APIs
          def self.common_binary_types
            [
              'image/png',
              'image/jpeg',
              'image/gif',
              'application/pdf',
              'application/octet-stream',
              'application/zip',
              'multipart/form-data'
            ]
          end
        end
      end
    end
  end
end