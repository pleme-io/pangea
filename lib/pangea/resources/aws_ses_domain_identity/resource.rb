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
require 'pangea/resources/aws_ses_domain_identity/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS SES Domain Identity for email sending
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Domain identity attributes
      # @option attributes [String] :domain The domain name to verify
      # @return [ResourceReference] Reference object with outputs
      def aws_ses_domain_identity(name, attributes = {})
        # Validate attributes using dry-struct
        identity_attrs = Types::Types::SesDomainIdentityAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_ses_domain_identity, name) do
          domain identity_attrs.domain
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_ses_domain_identity',
          name: name,
          resource_attributes: identity_attrs.to_h,
          outputs: {
            domain: "${aws_ses_domain_identity.#{name}.domain}",
            arn: "${aws_ses_domain_identity.#{name}.arn}",
            verification_token: "${aws_ses_domain_identity.#{name}.verification_token}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)