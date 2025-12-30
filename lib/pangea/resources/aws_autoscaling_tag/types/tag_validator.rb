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
      module Types
        # Validation logic for Auto Scaling Group tags
        module TagValidator
          def self.validate_group_name(group_name)
            if group_name.nil? || group_name.strip.empty?
              raise Dry::Struct::Error, "Auto Scaling Group name cannot be empty"
            end

            if group_name.length > 255
              raise Dry::Struct::Error, "Auto Scaling Group name cannot exceed 255 characters: #{group_name}"
            end
          end

          def self.validate_tags(tags)
            return unless tags.is_a?(Array)

            tag_keys = []

            tags.each do |tag|
              tag_hash = tag.is_a?(Hash) ? tag : {}
              validate_tag(tag_hash, tag_keys)
            end

            validate_tag_count(tags)
          end

          def self.validate_tag(tag_hash, tag_keys)
            key = tag_hash[:key] || tag_hash['key']
            validate_tag_key(key)
            validate_tag_value(tag_hash, key)
            validate_unique_key(key, tag_keys)
            tag_keys << key
            validate_propagate_at_launch(tag_hash, key)
          end

          def self.validate_tag_key(key)
            if key.nil? || key.strip.empty?
              raise Dry::Struct::Error, "Tag key cannot be empty"
            end

            if key.length > 128
              raise Dry::Struct::Error, "Tag key cannot exceed 128 characters: #{key}"
            end

            if key.start_with?('aws:')
              raise Dry::Struct::Error, "Tag key cannot start with 'aws:' prefix: #{key}"
            end
          end

          def self.validate_tag_value(tag_hash, key)
            value = tag_hash[:value] || tag_hash['value']

            if value.nil?
              raise Dry::Struct::Error, "Tag value cannot be nil for key: #{key}"
            end

            if value.length > 256
              raise Dry::Struct::Error, "Tag value cannot exceed 256 characters for key '#{key}': #{value}"
            end
          end

          def self.validate_unique_key(key, tag_keys)
            if tag_keys.include?(key)
              raise Dry::Struct::Error, "Duplicate tag key not allowed: #{key}"
            end
          end

          def self.validate_propagate_at_launch(tag_hash, key)
            propagate = tag_hash[:propagate_at_launch] || tag_hash['propagate_at_launch']

            unless [true, false].include?(propagate)
              raise Dry::Struct::Error, "propagate_at_launch must be true or false for tag key: #{key}"
            end
          end

          def self.validate_tag_count(tags)
            if tags.length > 50
              raise Dry::Struct::Error, "Cannot exceed 50 tags per Auto Scaling Group (provided: #{tags.length})"
            end
          end
        end
      end
    end
  end
end
