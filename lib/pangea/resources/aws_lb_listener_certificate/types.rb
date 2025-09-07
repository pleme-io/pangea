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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Load Balancer Listener Certificate resources
      class LoadBalancerListenerCertificateAttributes < Dry::Struct
        # The ARN of the listener to attach the certificate to
        attribute :listener_arn, Resources::Types::String.constrained(
          format: /\Aarn:aws:elasticloadbalancing:[a-z0-9-]+:\d{12}:listener\/[a-zA-Z0-9\/-]+\z/
        )
        
        # The ARN of the SSL certificate to attach
        attribute :certificate_arn, Resources::Types::String.constrained(
          format: /\Aarn:aws:acm:[a-z0-9-]+:\d{12}:certificate\/[a-f0-9-]+\z/
        )

        # Custom validation for certificate-listener compatibility
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Extract regions from ARNs for validation
          listener_region = attrs.listener_arn.split(':')[3]
          cert_region = attrs.certificate_arn.split(':')[3]
          
          if listener_region != cert_region
            raise Dry::Struct::Error, "Certificate region (#{cert_region}) must match listener region (#{listener_region})"
          end

          attrs
        end
      end
    end
      end
    end
  end
end