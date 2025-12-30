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
          # Statement building methods
          module Statements
            def build_statement(ctx, stmt)
              if stmt.byte_match_statement
                build_byte_match(ctx, stmt.byte_match_statement)
              elsif stmt.sqli_match_statement
                build_match_statement(ctx, :sqli_match_statement, stmt.sqli_match_statement)
              elsif stmt.xss_match_statement
                build_match_statement(ctx, :xss_match_statement, stmt.xss_match_statement)
              elsif stmt.size_constraint_statement
                build_size_constraint(ctx, stmt.size_constraint_statement)
              elsif stmt.geo_match_statement
                build_geo_match(ctx, stmt.geo_match_statement)
              elsif stmt.ip_set_reference_statement
                build_ip_set_reference(ctx, stmt.ip_set_reference_statement)
              elsif stmt.rule_group_reference_statement
                build_rule_group_reference(ctx, stmt.rule_group_reference_statement)
              elsif stmt.managed_rule_group_statement
                build_managed_rule_group(ctx, stmt.managed_rule_group_statement)
              elsif stmt.rate_based_statement
                build_rate_based(ctx, stmt.rate_based_statement)
              elsif stmt.and_statement
                build_logical_statement(ctx, :and_statement, stmt.and_statement[:statements])
              elsif stmt.or_statement
                build_logical_statement(ctx, :or_statement, stmt.or_statement[:statements])
              elsif stmt.not_statement
                build_not_statement(ctx, stmt.not_statement[:statement])
              end
            end

            private

            def build_byte_match(ctx, config)
              builder = self
              ctx.byte_match_statement do
                positional_constraint config[:positional_constraint]
                search_string config[:search_string]
                field_to_match { builder.build_field_to_match(self, config[:field_to_match]) }
                builder.build_text_transformations(self, config[:text_transformations])
              end
            end

            def build_match_statement(ctx, type, config)
              builder = self
              ctx.public_send(type) do
                field_to_match { builder.build_field_to_match(self, config[:field_to_match]) }
                builder.build_text_transformations(self, config[:text_transformations])
              end
            end

            def build_size_constraint(ctx, config)
              builder = self
              ctx.size_constraint_statement do
                comparison_operator config[:comparison_operator]
                size config[:size]
                field_to_match { builder.build_field_to_match(self, config[:field_to_match]) }
                builder.build_text_transformations(self, config[:text_transformations])
              end
            end

            def build_geo_match(ctx, config)
              ctx.geo_match_statement do
                country_codes config[:country_codes]
                next unless config[:forwarded_ip_config]

                forwarded_ip_config do
                  header_name config[:forwarded_ip_config][:header_name]
                  fallback_behavior config[:forwarded_ip_config][:fallback_behavior]
                end
              end
            end

            def build_ip_set_reference(ctx, config)
              ctx.ip_set_reference_statement do
                arn config[:arn]
                next unless config[:ip_set_forwarded_ip_config]

                ip_set_forwarded_ip_config do
                  header_name config[:ip_set_forwarded_ip_config][:header_name]
                  fallback_behavior config[:ip_set_forwarded_ip_config][:fallback_behavior]
                  position config[:ip_set_forwarded_ip_config][:position]
                end
              end
            end

            def build_rule_group_reference(ctx, config)
              ctx.rule_group_reference_statement do
                arn config[:arn]
                config[:excluded_rules]&.each { |rule| excluded_rule { name rule[:name] } }
              end
            end

            def build_managed_rule_group(ctx, config)
              builder = self
              ctx.managed_rule_group_statement do
                vendor_name config[:vendor_name]
                name config[:name]
                version config[:version] if config[:version]
                config[:excluded_rules]&.each { |rule| excluded_rule { name rule[:name] } }
                next unless config[:scope_down_statement]

                scope_down_statement { builder.build_statement(self, config[:scope_down_statement]) }
              end
            end

            def build_rate_based(ctx, config)
              builder = self
              ctx.rate_based_statement do
                limit config[:limit]
                aggregate_key_type config[:aggregate_key_type]
                if config[:forwarded_ip_config]
                  forwarded_ip_config do
                    header_name config[:forwarded_ip_config][:header_name]
                    fallback_behavior config[:forwarded_ip_config][:fallback_behavior]
                  end
                end
                next unless config[:scope_down_statement]

                scope_down_statement { builder.build_statement(self, config[:scope_down_statement]) }
              end
            end

            def build_logical_statement(ctx, type, statements)
              builder = self
              ctx.public_send(type) do
                statements.each { |sub| statement { builder.build_statement(self, sub) } }
              end
            end

            def build_not_statement(ctx, stmt)
              builder = self
              ctx.not_statement { statement { builder.build_statement(self, stmt) } }
            end

            def build_text_transformations(ctx, transforms)
              transforms.each do |t|
                ctx.text_transformation { priority t[:priority]; type t[:type] }
              end
            end
          end
        end
      end
    end
  end
end
