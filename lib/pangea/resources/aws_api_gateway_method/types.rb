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
        # API Gateway Method attributes with validation
        class ApiGatewayMethodAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :rest_api_id, Pangea::Resources::Types::String
          attribute :resource_id, Pangea::Resources::Types::String
          attribute :http_method, Pangea::Resources::Types::String.constrained(included_in: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'PATCH', 'ANY'])
          
          # Authorization
          attribute :authorization, Pangea::Resources::Types::String.default('NONE').constrained(included_in: ['NONE', 'AWS_IAM', 'CUSTOM', 'COGNITO_USER_POOLS'])
          attribute :authorizer_id, Pangea::Resources::Types::String.optional.default(nil)
          attribute :authorization_scopes, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          
          # API Key requirement
          attribute :api_key_required, Pangea::Resources::Types::Bool.default(false)
          
          # Request parameters and headers
          attribute :request_parameters, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::Bool
          ).default({}.freeze)
          
          # Request models for validation
          attribute :request_models, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)
          
          # Request validator
          attribute :request_validator_id, Pangea::Resources::Types::String.optional.default(nil)
          
          # Operation name for SDK generation
          attribute :operation_name, Pangea::Resources::Types::String.optional.default(nil)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate authorizer_id is provided for CUSTOM and COGNITO_USER_POOLS
            if attrs[:authorization] && ['CUSTOM', 'COGNITO_USER_POOLS'].include?(attrs[:authorization])
              if attrs[:authorizer_id].nil? || attrs[:authorizer_id].empty?
                raise Dry::Struct::Error, "authorizer_id is required when authorization is #{attrs[:authorization]}"
              end
            end
            
            # Validate authorization_scopes only used with COGNITO_USER_POOLS
            if attrs[:authorization_scopes] && !attrs[:authorization_scopes].empty?
              if attrs[:authorization] != 'COGNITO_USER_POOLS'
                raise Dry::Struct::Error, "authorization_scopes can only be used with COGNITO_USER_POOLS authorization"
              end
            end
            
            # Validate request parameters format
            if attrs[:request_parameters]
              attrs[:request_parameters].each do |param_name, _required|
                unless param_name.match?(/^method\.request\.(path|querystring|header|multivalueheader|multivalue querystring)\..+/)
                  raise Dry::Struct::Error, "Invalid request parameter format: #{param_name}. Expected format: method.request.{location}.{name}"
                end
              end
            end
            
            # Validate request models format
            if attrs[:request_models]
              attrs[:request_models].each do |content_type, _model|
                unless content_type.match?(%r{^[\w\-\+]+/[\w\-\+\.]+$})
                  raise Dry::Struct::Error, "Invalid content type format: #{content_type}"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def requires_authorization?
            authorization != 'NONE'
          end
          
          def is_cognito_authorized?
            authorization == 'COGNITO_USER_POOLS'
          end
          
          def is_iam_authorized?
            authorization == 'AWS_IAM'
          end
          
          def is_custom_authorized?
            authorization == 'CUSTOM'
          end
          
          def has_request_validation?
            !request_models.empty? || !request_validator_id.nil?
          end
          
          def cors_enabled?
            http_method == 'OPTIONS'
          end
          
          # Helper to build request parameter
          def self.build_request_parameter(location, name, required = false)
            valid_locations = ['path', 'querystring', 'header', 'multivalueheader', 'multivaluequerystring']
            unless valid_locations.include?(location)
              raise ArgumentError, "Invalid location: #{location}. Must be one of: #{valid_locations.join(', ')}"
            end
            
            ["method.request.#{location}.#{name}", required]
          end
          
          # Common request parameters
          def self.common_request_parameters
            {
              # Headers
              authorization: build_request_parameter('header', 'Authorization', true),
              content_type: build_request_parameter('header', 'Content-Type', true),
              accept: build_request_parameter('header', 'Accept', false),
              api_key: build_request_parameter('header', 'x-api-key', true),
              user_agent: build_request_parameter('header', 'User-Agent', false),
              
              # Query strings
              page: build_request_parameter('querystring', 'page', false),
              limit: build_request_parameter('querystring', 'limit', false),
              sort: build_request_parameter('querystring', 'sort', false),
              filter: build_request_parameter('querystring', 'filter', false),
              search: build_request_parameter('querystring', 'q', false),
              
              # Path parameters
              id: build_request_parameter('path', 'id', true),
              user_id: build_request_parameter('path', 'userId', true),
              resource_id: build_request_parameter('path', 'resourceId', true)
            }
          end
          
          # Common content types
          def self.common_content_types
            {
              json: 'application/json',
              xml: 'application/xml',
              form: 'application/x-www-form-urlencoded',
              multipart: 'multipart/form-data',
              text: 'text/plain',
              html: 'text/html',
              csv: 'text/csv',
              pdf: 'application/pdf'
            }
          end
        end
      end
    end
  end
end