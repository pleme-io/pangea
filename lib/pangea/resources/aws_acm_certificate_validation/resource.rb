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
require 'pangea/resources/aws_acm_certificate_validation/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ACM Certificate Validation resource with type-safe attributes
      #
      # This resource waits for certificate validation to complete and is typically used
      # after creating DNS validation records for ACM certificates.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Certificate validation attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_acm_certificate_validation(name, attributes = {})
        # Validate attributes using dry-struct
        validation_attrs = Types::Types::AcmCertificateValidationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_acm_certificate_validation, name) do
          certificate_arn validation_attrs.certificate_arn
          
          # Add validation record FQDNs if provided (for DNS validation)
          if validation_attrs.validation_record_fqdns&.any?
            validation_record_fqdns validation_attrs.validation_record_fqdns
          end
          
          # Configure timeouts if specified
          if validation_attrs.timeouts
            timeouts do
              if validation_attrs.timeouts[:create]
                create validation_attrs.timeouts[:create]
              end
              if validation_attrs.timeouts[:update]
                update validation_attrs.timeouts[:update]
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_acm_certificate_validation',
          name: name,
          resource_attributes: validation_attrs.to_h,
          outputs: {
            id: "${aws_acm_certificate_validation.#{name}.id}",
            certificate_arn: "${aws_acm_certificate_validation.#{name}.certificate_arn}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)