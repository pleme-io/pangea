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
require 'pangea/resources/aws_wafv2_web_acl/types'
require 'pangea/resource_registry'
require_relative 'resource/dsl_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS WAF v2 Web ACL with comprehensive security configurations
      def aws_wafv2_web_acl(name, attributes = {})
        web_acl_attrs = Types::WafV2WebAclAttributes.new(attributes)
        builder = WafV2WebAcl::DSLBuilder.new(web_acl_attrs)

        resource(:aws_wafv2_web_acl, name) do
          name web_acl_attrs.name
          scope web_acl_attrs.scope.downcase
          description web_acl_attrs.description if web_acl_attrs.description

          builder.build_default_action(self)
          builder.build_rules(self)
          builder.build_visibility_config(self, web_acl_attrs.visibility_config)
          build_custom_response_bodies(self, web_acl_attrs.custom_response_bodies)
          build_token_domains(self, web_acl_attrs.token_domains)
          builder.build_challenge_config(self, web_acl_attrs.challenge_config)
          builder.build_captcha_config(self, web_acl_attrs.captcha_config)
          build_tags(self, web_acl_attrs.tags)
        end

        build_resource_reference(name, web_acl_attrs)
      end

      private

      def build_custom_response_bodies(ctx, bodies)
        bodies.each do |key, body|
          ctx.custom_response_body { key key.to_s; content body[:content]; content_type body[:content_type] }
        end
      end

      def build_token_domains(ctx, domains)
        return unless domains.any?

        domains.each { |domain| ctx.token_domains domain }
      end

      def build_tags(ctx, tags)
        return unless tags.any?

        ctx.tags { tags.each { |key, value| public_send(key, value) } }
      end

      def build_resource_reference(name, attrs)
        ResourceReference.new(
          type: 'aws_wafv2_web_acl',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_wafv2_web_acl.#{name}.id}",
            arn: "${aws_wafv2_web_acl.#{name}.arn}",
            capacity: "${aws_wafv2_web_acl.#{name}.capacity}",
            lock_token: "${aws_wafv2_web_acl.#{name}.lock_token}",
            application_integration_url: "${aws_wafv2_web_acl.#{name}.application_integration_url}"
          },
          computed: {
            total_capacity_estimate: attrs.total_capacity_units_estimate,
            has_rate_limiting: attrs.has_rate_limiting?,
            has_geo_blocking: attrs.has_geo_blocking?,
            has_managed_rules: attrs.has_managed_rules?,
            uses_custom_responses: attrs.uses_custom_responses?,
            rule_count: attrs.rules.size,
            scope: attrs.scope
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
