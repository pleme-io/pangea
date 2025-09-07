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
require 'pangea/resources/aws_s3_object_lambda_access_point/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Object Lambda Access Point with type-safe attributes
      #
      # S3 Object Lambda Access Points allow you to add your own code to S3 GET,
      # HEAD, and LIST requests to modify and process data as it is returned to
      # applications. You can use Object Lambda to present different views of the
      # same data to multiple applications.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 object lambda access point attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_object_lambda_access_point(name, attributes = {})
        # Validate attributes using dry-struct
        ol_attrs = S3ObjectLambdaAccessPoint::Types::S3ObjectLambdaAccessPointAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_object_lambda_access_point, name) do
          # Access point name
          name ol_attrs.name
          
          # Configuration block
          configuration do
            # Supporting access point ARN
            supporting_access_point ol_attrs.configuration[:supporting_access_point]
            
            # Transformation configurations
            ol_attrs.configuration[:transformation_configuration].each do |transform|
              transformation_configuration do
                # Supported actions
                actions transform[:actions]
                
                # Content transformation with Lambda function
                content_transformation do
                  aws_lambda do
                    function_arn transform[:content_transformation][:aws_lambda][:function_arn]
                    if transform[:content_transformation][:aws_lambda][:function_payload]
                      function_payload transform[:content_transformation][:aws_lambda][:function_payload]
                    end
                  end
                end
              end
            end
          end
          
          # Optional account ID
          account_id ol_attrs.account_id if ol_attrs.account_id
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_object_lambda_access_point',
          name: name,
          resource_attributes: ol_attrs.to_h,
          outputs: {
            id: "${aws_s3_object_lambda_access_point.#{name}.id}",
            arn: "${aws_s3_object_lambda_access_point.#{name}.arn}",
            alias: "${aws_s3_object_lambda_access_point.#{name}.alias}",
            domain_name: "${aws_s3_object_lambda_access_point.#{name}.domain_name}"
          },
          computed: {
            supporting_access_point: ol_attrs.supporting_access_point,
            transformation_count: ol_attrs.transformation_count,
            lambda_functions: ol_attrs.lambda_functions,
            supported_actions: ol_attrs.supported_actions,
            has_payload: ol_attrs.has_payload?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)