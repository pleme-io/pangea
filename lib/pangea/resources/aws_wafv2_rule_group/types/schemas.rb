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

require 'dry-types'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Shared WAF v2 schemas for reuse across rule definitions
        module WafV2Schemas
          include Dry.Types()

          # Header name/value pair schema
          HeaderSchema = Hash.schema(
            name: String,
            value: String
          )

          # Custom request handling with header insertion
          CustomRequestHandlingSchema = Hash.schema(
            insert_headers: Array.of(HeaderSchema)
          ).optional

          # Custom response configuration for block actions
          CustomResponseSchema = Hash.schema(
            response_code: Integer.constrained(gteq: 200, lteq: 599),
            custom_response_body_key?: String.optional,
            response_headers?: Array.of(HeaderSchema).optional
          ).optional

          # Visibility config for CloudWatch metrics
          VisibilityConfigSchema = Hash.schema(
            cloudwatch_metrics_enabled: Resources::Types::Bool,
            metric_name: String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/),
            sampled_requests_enabled: Resources::Types::Bool
          )

          # Immunity time configuration for captcha/challenge
          ImmunityTimeSchema = Hash.schema(
            immunity_time_property: Hash.schema(
              immunity_time: Integer.constrained(gteq: 60, lteq: 259_200)
            )
          ).optional

          # Rule label schema
          RuleLabelSchema = Hash.schema(
            name: String.constrained(format: /\A[a-zA-Z0-9_:-]{1,1024}\z/)
          )

          # Custom response body definition
          CustomResponseBodySchema = Hash.schema(
            content: String.constrained(max_size: 10_240),
            content_type: String.enum('TEXT_PLAIN', 'TEXT_HTML', 'APPLICATION_JSON')
          )
        end
      end
    end
  end
end
