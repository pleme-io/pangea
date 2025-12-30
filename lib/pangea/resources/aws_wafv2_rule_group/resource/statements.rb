# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module WafV2RuleGroupDSL
        module Statements
          def build_statement(stmt)
            return unless stmt
            if stmt[:byte_match_statement] then build_byte_match(stmt[:byte_match_statement])
            elsif stmt[:sqli_match_statement] then build_sqli_match(stmt[:sqli_match_statement])
            elsif stmt[:xss_match_statement] then build_xss_match(stmt[:xss_match_statement])
            elsif stmt[:size_constraint_statement] then build_size_constraint(stmt[:size_constraint_statement])
            elsif stmt[:geo_match_statement] then build_geo_match(stmt[:geo_match_statement])
            elsif stmt[:ip_set_reference_statement] then build_ip_set_reference(stmt[:ip_set_reference_statement])
            elsif stmt[:regex_pattern_set_reference_statement] then build_regex_pattern_set(stmt[:regex_pattern_set_reference_statement])
            elsif stmt[:rate_based_statement] then build_rate_based(stmt[:rate_based_statement])
            elsif stmt[:and_statement] then build_and_statement(stmt[:and_statement])
            elsif stmt[:or_statement] then build_or_statement(stmt[:or_statement])
            elsif stmt[:not_statement] then build_not_statement(stmt[:not_statement])
            elsif stmt[:label_match_statement] then build_label_match(stmt[:label_match_statement])
            end
          end

          def build_byte_match(config)
            byte_match_statement do
              positional_constraint config[:positional_constraint]
              search_string config[:search_string]
              field_to_match { build_field_to_match(config[:field_to_match]) }
              build_text_transformations(config[:text_transformations])
            end
          end

          def build_sqli_match(config)
            sqli_match_statement do
              field_to_match { build_field_to_match(config[:field_to_match]) }
              build_text_transformations(config[:text_transformations])
            end
          end

          def build_xss_match(config)
            xss_match_statement do
              field_to_match { build_field_to_match(config[:field_to_match]) }
              build_text_transformations(config[:text_transformations])
            end
          end

          def build_size_constraint(config)
            size_constraint_statement do
              comparison_operator config[:comparison_operator]
              size config[:size]
              field_to_match { build_field_to_match(config[:field_to_match]) }
              build_text_transformations(config[:text_transformations])
            end
          end

          def build_geo_match(config)
            geo_match_statement do
              country_codes config[:country_codes]
              if config[:forwarded_ip_config]
                forwarded_ip_config do
                  header_name config[:forwarded_ip_config][:header_name]
                  fallback_behavior config[:forwarded_ip_config][:fallback_behavior]
                end
              end
            end
          end

          def build_ip_set_reference(config)
            ip_set_reference_statement do
              arn config[:arn]
              if config[:ip_set_forwarded_ip_config]
                ip_set_forwarded_ip_config do
                  header_name config[:ip_set_forwarded_ip_config][:header_name]
                  fallback_behavior config[:ip_set_forwarded_ip_config][:fallback_behavior]
                  position config[:ip_set_forwarded_ip_config][:position]
                end
              end
            end
          end

          def build_regex_pattern_set(config)
            regex_pattern_set_reference_statement do
              arn config[:arn]
              field_to_match { build_field_to_match(config[:field_to_match]) }
              build_text_transformations(config[:text_transformations])
            end
          end

          def build_rate_based(config)
            rate_based_statement do
              limit config[:limit]
              aggregate_key_type config[:aggregate_key_type]
              if config[:forwarded_ip_config]
                forwarded_ip_config do
                  header_name config[:forwarded_ip_config][:header_name]
                  fallback_behavior config[:forwarded_ip_config][:fallback_behavior]
                end
              end
              scope_down_statement { build_statement(config[:scope_down_statement]) } if config[:scope_down_statement]
            end
          end

          def build_and_statement(config)
            and_statement { config[:statements].each { |s| statement { build_statement(s) } } }
          end

          def build_or_statement(config)
            or_statement { config[:statements].each { |s| statement { build_statement(s) } } }
          end

          def build_not_statement(config)
            not_statement { statement { build_statement(config[:statement]) } }
          end

          def build_label_match(config)
            label_match_statement do
              scope config[:scope]
              key config[:key]
            end
          end

          def build_text_transformations(transforms)
            transforms.each do |transform|
              text_transformation do
                priority transform[:priority]
                type transform[:type]
              end
            end
          end
        end
      end
    end
  end
end
