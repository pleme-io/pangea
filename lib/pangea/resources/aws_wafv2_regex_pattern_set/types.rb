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
require_relative 'types/helpers'
require_relative 'types/configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS WAFv2 Regex Pattern Set resources
        class WafV2RegexPatternSetAttributes < Dry::Struct
          include WafV2RegexPatternSetHelpers

          # Name for the regex pattern set
          attribute :name, Resources::Types::String

          # Description of the regex pattern set
          attribute :description, Resources::Types::String.optional.default(nil)

          # Scope of the regex pattern set (CLOUDFRONT or REGIONAL)
          attribute :scope, Resources::Types::String.enum('CLOUDFRONT', 'REGIONAL')

          # List of regular expression patterns
          attribute :regular_expression, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              regex_string: Resources::Types::String
            )
          )

          # Tags to apply to the regex pattern set
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_name_format(attrs)
            validate_regex_patterns(attrs)
            attrs = set_default_description(attrs)

            attrs
          end

          class << self
            private

            def validate_name_format(attrs)
              return if attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)

              raise Dry::Struct::Error,
                    'Regex pattern set name must be 1-128 characters and contain only alphanumeric, hyphens, and underscores'
            end

            def validate_regex_patterns(attrs)
              validate_pattern_count(attrs)
              validate_each_pattern(attrs)
            end

            def validate_pattern_count(attrs)
              if attrs.regular_expression.empty?
                raise Dry::Struct::Error, 'Regex pattern set must contain at least one regular expression'
              end

              return unless attrs.regular_expression.length > 10

              raise Dry::Struct::Error, 'Regex pattern set cannot contain more than 10 regular expressions'
            end

            def validate_each_pattern(attrs)
              attrs.regular_expression.each_with_index do |pattern, index|
                validate_regex_syntax(pattern, index)
                validate_not_overly_broad(pattern, index)
              end
            end

            def validate_regex_syntax(pattern, index)
              Regexp.new(pattern[:regex_string])
            rescue RegexpError => e
              raise Dry::Struct::Error, "Invalid regex pattern at index #{index}: #{e.message}"
            end

            def validate_not_overly_broad(pattern, index)
              return unless pattern[:regex_string] == '.*' || pattern[:regex_string] == '.+'

              raise Dry::Struct::Error,
                    "Overly broad regex pattern at index #{index} - avoid .* or .+ patterns"
            end

            def set_default_description(attrs)
              return attrs if attrs.description

              attrs.new(description: "Regex pattern set #{attrs.name} with #{attrs.regular_expression.length} pattern(s)")
            end
          end
        end
      end
    end
  end
end
