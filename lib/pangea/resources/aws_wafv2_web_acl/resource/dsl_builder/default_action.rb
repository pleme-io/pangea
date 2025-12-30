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
      module WafV2WebAcl
        class DSLBuilder
          # Default action building methods
          module DefaultAction
            def build_default_action(ctx)
              ctx.default_action do
                if attrs.default_action.allow
                  allow { build_custom_request_handling(ctx, attrs.default_action.allow[:custom_request_handling]) }
                elsif attrs.default_action.block
                  block { build_custom_response(ctx, attrs.default_action.block[:custom_response]) }
                end
              end
            end

            def build_custom_request_handling(ctx, handling)
              return unless handling

              ctx.custom_request_handling do
                handling[:insert_headers].each do |header|
                  insert_header { name header[:name]; value header[:value] }
                end
              end
            end

            def build_custom_response(ctx, response)
              return unless response

              ctx.custom_response do
                response_code response[:response_code]
                custom_response_body_key response[:custom_response_body_key] if response[:custom_response_body_key]
                response[:response_headers]&.each do |header|
                  response_header { name header[:name]; value header[:value] }
                end
              end
            end
          end
        end
      end
    end
  end
end
