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

module Pangea
  module Resources
    module AWS
      module LambdaFunctionUrl
        # Common types for Lambda Function URL configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # Lambda Function Name constraint
          FunctionName = String.constrained(
            min_size: 1,
            max_size: 64,
            format: /\A[a-zA-Z0-9\-_]+\z/
          )
          
          # Authorization type for function URL
          AuthorizationType = String.enum('AWS_IAM', 'NONE')
          
          # HTTP method
          HttpMethod = String.enum('*', 'GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH')
          
          # Origin for CORS
          Origin = String.constrained(format: /\A\*|https?:\/\/.+\z/)
          
          # CORS Configuration
          CorsConfiguration = Hash.schema({
            allow_credentials?: Bool.optional,
            allow_headers?: Array.of(String).optional,
            allow_methods?: Array.of(HttpMethod).optional,
            allow_origins?: Array.of(Origin).optional,
            expose_headers?: Array.of(String).optional,
            max_age?: Integer.constrained(gteq: 0, lteq: 86400).optional
          })
        end

        # Lambda Function URL attributes with comprehensive validation
        class LambdaFunctionUrlAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :authorization_type, AuthorizationType
          attribute :function_name, FunctionName
          
          # Optional attributes
          attribute? :cors, CorsConfiguration.optional
          attribute? :qualifier, String.optional
          attribute? :invoke_mode, String.enum('BUFFERED', 'RESPONSE_STREAM').optional
          
          # Computed properties
          def has_cors_configuration?
            !cors.nil?
          end
          
          def allows_credentials?
            cors && cors[:allow_credentials] == true
          end
          
          def public_access?
            authorization_type == 'NONE'
          end
          
          def iam_protected?
            authorization_type == 'AWS_IAM'
          end
          
          def has_qualifier?
            !qualifier.nil?
          end
          
          def streaming_enabled?
            invoke_mode == 'RESPONSE_STREAM'
          end
          
          def cors_methods
            cors&.dig(:allow_methods) || []
          end
          
          def cors_origins
            cors&.dig(:allow_origins) || []
          end
        end
      end
    end
  end
end