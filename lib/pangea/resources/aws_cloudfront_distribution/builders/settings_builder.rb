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
        # Builds distribution settings blocks for CloudFront distributions
        module SettingsBuilder
          module_function

          def build_basic_settings(context, attrs)
            context.instance_eval do
              comment attrs.comment
              default_root_object attrs.default_root_object if attrs.default_root_object
              enabled attrs.enabled
              http_version attrs.http_version
              is_ipv6_enabled attrs.is_ipv6_enabled
              price_class attrs.price_class
              aliases attrs.aliases if attrs.aliases.any?
              web_acl_id attrs.web_acl_id if attrs.web_acl_id
              retain_on_delete attrs.retain_on_delete
              wait_for_deployment attrs.wait_for_deployment
            end
          end

          def build_custom_error_responses(context, error_responses)
            error_responses.each do |error_response|
              context.custom_error_response do
                error_code error_response[:error_code]
                response_code error_response[:response_code] if error_response[:response_code]
                response_page_path error_response[:response_page_path] if error_response[:response_page_path]
                error_caching_min_ttl error_response[:error_caching_min_ttl] if error_response[:error_caching_min_ttl]
              end
            end
          end

          def build_restrictions(context, restrictions)
            context.restrictions do
              geo_restriction do
                restriction_type restrictions[:geo_restriction][:restriction_type]
                locations restrictions[:geo_restriction][:locations] if restrictions[:geo_restriction][:locations].any?
              end
            end
          end

          def build_viewer_certificate(context, cert)
            context.viewer_certificate do
              acm_certificate_arn cert[:acm_certificate_arn] if cert[:acm_certificate_arn]
              iam_certificate_id cert[:iam_certificate_id] if cert[:iam_certificate_id]
              cloudfront_default_certificate cert[:cloudfront_default_certificate] if cert.key?(:cloudfront_default_certificate)
              ssl_support_method cert[:ssl_support_method] if cert[:ssl_support_method]
              minimum_protocol_version cert[:minimum_protocol_version] if cert[:minimum_protocol_version]
            end
          end

          def build_tags(context, tags)
            return unless tags.any?

            context.tags do
              tags.each { |key, value| public_send(key, value) }
            end
          end
        end
      end
    end
  end
end
