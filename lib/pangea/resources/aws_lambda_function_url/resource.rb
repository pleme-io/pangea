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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_lambda_function_url/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Lambda Function URL with type-safe attributes
      #
      # Function URLs provide a dedicated HTTP(S) endpoint for Lambda functions.
      # You can configure function URLs with CORS, authorization settings, and
      # streaming responses for real-time applications.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Lambda function URL attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lambda_function_url(name, attributes = {})
        # Validate attributes using dry-struct
        url_attrs = LambdaFunctionUrl::Types::LambdaFunctionUrlAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lambda_function_url, name) do
          # Required attributes
          authorization_type url_attrs.authorization_type
          function_name url_attrs.function_name
          
          # Optional attributes
          qualifier url_attrs.qualifier if url_attrs.qualifier
          invoke_mode url_attrs.invoke_mode if url_attrs.invoke_mode
          
          # CORS configuration
          if url_attrs.cors
            cors do
              allow_credentials url_attrs.cors[:allow_credentials] if url_attrs.cors.key?(:allow_credentials)
              allow_headers url_attrs.cors[:allow_headers] if url_attrs.cors[:allow_headers]
              allow_methods url_attrs.cors[:allow_methods] if url_attrs.cors[:allow_methods]
              allow_origins url_attrs.cors[:allow_origins] if url_attrs.cors[:allow_origins]
              expose_headers url_attrs.cors[:expose_headers] if url_attrs.cors[:expose_headers]
              max_age url_attrs.cors[:max_age] if url_attrs.cors[:max_age]
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_lambda_function_url',
          name: name,
          resource_attributes: url_attrs.to_h,
          outputs: {
            id: "${aws_lambda_function_url.#{name}.id}",
            function_url: "${aws_lambda_function_url.#{name}.function_url}",
            url_id: "${aws_lambda_function_url.#{name}.url_id}",
            creation_time: "${aws_lambda_function_url.#{name}.creation_time}"
          },
          computed: {
            has_cors_configuration: url_attrs.has_cors_configuration?,
            allows_credentials: url_attrs.allows_credentials?,
            public_access: url_attrs.public_access?,
            iam_protected: url_attrs.iam_protected?,
            has_qualifier: url_attrs.has_qualifier?,
            streaming_enabled: url_attrs.streaming_enabled?,
            cors_methods: url_attrs.cors_methods,
            cors_origins: url_attrs.cors_origins
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)