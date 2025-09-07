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


require_relative 'types'
require 'pangea/resources/base'

module Pangea
  module Resources
    # AWS IoT Authorizer Resource
    # 
    # Custom authorizers provide flexible authentication and authorization beyond X.509 certificates,
    # enabling integration with custom tokens, JWT tokens, OAuth, or other identity providers.
    # This is essential for IoT applications requiring custom authentication patterns.
    #
    # @example Basic custom authorizer with Lambda function
    #   aws_iot_authorizer(:custom_auth, {
    #     name: "CustomTokenAuth",
    #     authorizer_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:iot-authorizer",
    #     token_key_name: "authToken",
    #     status: "ACTIVE"
    #   })
    #
    # @example Authorizer with token signing validation
    #   aws_iot_authorizer(:jwt_authorizer, {
    #     name: "JWTAuthorizer",
    #     authorizer_function_arn: jwt_validator_function.arn,
    #     token_key_name: "jwt",
    #     token_signing_public_keys: {
    #       "key1" => jwt_public_key_pem,
    #       "key2" => backup_public_key_pem
    #     },
    #     enable_caching_for_http: true,
    #     tags: {
    #       "AuthType" => "JWT",
    #       "Environment" => "Production"
    #     }
    #   })
    #
    # @example Authorizer with signing disabled (for development)
    #   aws_iot_authorizer(:dev_authorizer, {
    #     name: "DevelopmentAuth",
    #     authorizer_function_arn: dev_auth_function_arn,
    #     signing_disabled: true,
    #     token_key_name: "devToken",
    #     status: "ACTIVE"
    #   })
    module AwsIotAuthorizer
      include AwsIotAuthorizerTypes

      # Creates an AWS IoT custom authorizer for flexible authentication
      #
      # @param name [Symbol] Logical name for the authorizer resource
      # @param attributes [Hash] Authorizer configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_authorizer(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_authorizer, name do
          name validated_attributes.name
          authorizer_function_arn validated_attributes.authorizer_function_arn
          signing_disabled validated_attributes.signing_disabled if validated_attributes.signing_disabled
          status validated_attributes.status if validated_attributes.status
          token_key_name validated_attributes.token_key_name if validated_attributes.token_key_name
          token_signing_public_keys validated_attributes.token_signing_public_keys if validated_attributes.token_signing_public_keys
          enable_caching_for_http validated_attributes.enable_caching_for_http if validated_attributes.enable_caching_for_http
          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iot_authorizer,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_authorizer.#{name}.arn}",
            name: "${aws_iot_authorizer.#{name}.name}",
            id: "${aws_iot_authorizer.#{name}.id}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)