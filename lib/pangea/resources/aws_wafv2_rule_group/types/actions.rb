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
require_relative 'schemas'

module Pangea
  module Resources
    module AWS
      module Types
        # WAF v2 rule action type definitions
        module WafV2Actions
          include Dry.Types()

          # Allow action with optional custom request handling
          AllowActionSchema = Hash.schema(
            custom_request_handling?: WafV2Schemas::CustomRequestHandlingSchema
          ).optional

          # Block action with optional custom response
          BlockActionSchema = Hash.schema(
            custom_response?: WafV2Schemas::CustomResponseSchema
          ).optional

          # Count action with optional custom request handling
          CountActionSchema = Hash.schema(
            custom_request_handling?: WafV2Schemas::CustomRequestHandlingSchema
          ).optional

          # Captcha action with optional custom request handling
          CaptchaActionSchema = Hash.schema(
            custom_request_handling?: WafV2Schemas::CustomRequestHandlingSchema
          ).optional

          # Challenge action with optional custom request handling
          ChallengeActionSchema = Hash.schema(
            custom_request_handling?: WafV2Schemas::CustomRequestHandlingSchema
          ).optional

          # Combined action schema with validation
          ACTION_TYPES = %i[allow block count captcha challenge].freeze

          ActionSchema = Hash.schema(
            allow?: AllowActionSchema,
            block?: BlockActionSchema,
            count?: CountActionSchema,
            captcha?: CaptchaActionSchema,
            challenge?: ChallengeActionSchema
          ).constructor do |attrs|
            provided_actions = ACTION_TYPES.select { |type| attrs.key?(type) }

            if provided_actions.empty?
              raise Dry::Types::ConstraintError, 'Rule action must specify exactly one action type'
            elsif provided_actions.size > 1
              raise Dry::Types::ConstraintError,
                    "Rule action must specify exactly one action type, got: #{provided_actions.join(', ')}"
            end

            attrs
          end
        end
      end
    end
  end
end
