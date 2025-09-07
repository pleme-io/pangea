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
require 'pangea/resources/aws_lambda_layer_version/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Lambda layer version for sharing code and libraries
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Lambda layer version attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lambda_layer_version(name, attributes = {})
        # Validate attributes using dry-struct
        layer_attrs = Types::Types::LambdaLayerVersionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lambda_layer_version, name) do
          layer_name layer_attrs.layer_name
          
          # Code source
          if layer_attrs.filename
            filename layer_attrs.filename
          elsif layer_attrs.s3_bucket
            s3_bucket layer_attrs.s3_bucket
            s3_key layer_attrs.s3_key
            s3_object_version layer_attrs.s3_object_version if layer_attrs.s3_object_version
          end
          
          # Optional attributes
          compatible_runtimes layer_attrs.compatible_runtimes if layer_attrs.compatible_runtimes.any?
          compatible_architectures layer_attrs.compatible_architectures if layer_attrs.compatible_architectures.any?
          description layer_attrs.description if layer_attrs.description
          license_info layer_attrs.license_info if layer_attrs.license_info
          source_code_hash layer_attrs.source_code_hash if layer_attrs.source_code_hash
          skip_destroy layer_attrs.skip_destroy if layer_attrs.skip_destroy
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_lambda_layer_version',
          name: name,
          resource_attributes: layer_attrs.to_h,
          outputs: {
            # Core outputs
            id: "${aws_lambda_layer_version.#{name}.id}",
            arn: "${aws_lambda_layer_version.#{name}.arn}",
            layer_arn: "${aws_lambda_layer_version.#{name}.layer_arn}",
            version: "${aws_lambda_layer_version.#{name}.version}",
            created_date: "${aws_lambda_layer_version.#{name}.created_date}",
            source_code_hash: "${aws_lambda_layer_version.#{name}.source_code_hash}",
            source_code_size: "${aws_lambda_layer_version.#{name}.source_code_size}",
            signing_job_arn: "${aws_lambda_layer_version.#{name}.signing_job_arn}",
            signing_profile_version_arn: "${aws_lambda_layer_version.#{name}.signing_profile_version_arn}",
            
            # Computed properties
            supports_all_architectures: layer_attrs.supports_all_architectures?,
            runtime_families: layer_attrs.runtime_families,
            is_architecture_specific: layer_attrs.is_architecture_specific?,
            is_runtime_specific: layer_attrs.is_runtime_specific?,
            layer_type: layer_attrs.layer_type,
            estimated_size_mb: layer_attrs.estimated_size_mb
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)