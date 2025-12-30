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
      module S3Bucket
        # Builds lifecycle and CORS rule blocks for S3 buckets
        module LifecycleBuilder
          module_function

          def build_lifecycle_rules(context, rules)
            rules.each { |rule_config| build_lifecycle_rule(context, rule_config) }
          end

          def build_lifecycle_rule(context, rule_config)
            context.lifecycle_rule do
              id rule_config[:id]
              enabled rule_config[:enabled]
              prefix rule_config[:prefix] if rule_config[:prefix]

              build_lifecycle_tags(self, rule_config[:tags]) if rule_config[:tags]
              build_transitions(self, rule_config[:transition]) if rule_config[:transition]
              build_expiration(self, rule_config[:expiration]) if rule_config[:expiration]
              build_noncurrent_transitions(self, rule_config[:noncurrent_version_transition])
              build_noncurrent_expiration(self, rule_config[:noncurrent_version_expiration])
            end
          end

          def build_lifecycle_tags(context, tags)
            context.tags do
              tags.each { |key, value| public_send(key, value) }
            end
          end

          def build_transitions(context, transitions)
            transitions.each do |transition_config|
              context.transition do
                days transition_config[:days]
                storage_class transition_config[:storage_class]
              end
            end
          end

          def build_expiration(context, expiration)
            context.expiration do
              days expiration[:days] if expiration[:days]
              expired_object_delete_marker expiration[:expired_object_delete_marker] if expiration.key?(:expired_object_delete_marker)
            end
          end

          def build_noncurrent_transitions(context, transitions)
            return unless transitions

            transitions.each do |nv_transition|
              context.noncurrent_version_transition do
                days nv_transition[:days]
                storage_class nv_transition[:storage_class]
              end
            end
          end

          def build_noncurrent_expiration(context, expiration)
            return unless expiration

            context.noncurrent_version_expiration do
              days expiration[:days]
            end
          end

          def build_cors_rules(context, cors_rules)
            cors_rules.each { |cors_config| build_cors_rule(context, cors_config) }
          end

          def build_cors_rule(context, cors_config)
            context.cors_rule do
              allowed_headers cors_config[:allowed_headers] if cors_config[:allowed_headers]
              allowed_methods cors_config[:allowed_methods]
              allowed_origins cors_config[:allowed_origins]
              expose_headers cors_config[:expose_headers] if cors_config[:expose_headers]
              max_age_seconds cors_config[:max_age_seconds] if cors_config[:max_age_seconds]
            end
          end
        end
      end
    end
  end
end
