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

module Pangea
  module Resources
    module AWS
      module CloudFrontDistribution
        # Builds resource references for CloudFront distributions
        module ReferenceBuilder
          TERRAFORM_OUTPUTS = %i[id arn domain_name hosted_zone_id etag status trusted_signers trusted_key_groups].freeze

          COMPUTED_PROPERTIES = %i[
            total_origins_count total_behaviors_count has_custom_ssl? uses_cloudfront_ssl?
            has_custom_domain? has_geographic_restrictions? has_custom_error_pages?
            has_origin_shield? has_lambda_at_edge? has_cloudfront_functions? supports_http2?
            ipv6_enabled? estimated_cost_tier s3_origins_count custom_origins_count
            primary_domain security_profile
          ].freeze

          module_function

          def build_reference(name, distribution_attrs)
            ref = ResourceReference.new(
              type: 'aws_cloudfront_distribution',
              name: name,
              resource_attributes: distribution_attrs.to_h,
              outputs: build_outputs(name)
            )

            add_computed_properties(ref, distribution_attrs)
            ref
          end

          def build_outputs(name)
            TERRAFORM_OUTPUTS.each_with_object({}) do |output, hash|
              hash[output] = "${aws_cloudfront_distribution.#{name}.#{output}}"
            end
          end

          def add_computed_properties(ref, distribution_attrs)
            COMPUTED_PROPERTIES.each do |prop|
              ref.define_singleton_method(prop) { distribution_attrs.public_send(prop) }
            end
          end
        end
      end
    end
  end
end
