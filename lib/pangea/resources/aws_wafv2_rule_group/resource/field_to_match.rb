# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module WafV2RuleGroupDSL
        module FieldToMatch
          def build_field_to_match(config)
            return unless config
            if config[:all_query_arguments] then all_query_arguments
            elsif config[:body] then build_body_field(config[:body])
            elsif config[:method] then method
            elsif config[:query_string] then query_string
            elsif config[:single_header] then single_header { name config[:single_header][:name] }
            elsif config[:single_query_argument] then single_query_argument { name config[:single_query_argument][:name] }
            elsif config[:uri_path] then uri_path
            elsif config[:json_body] then build_json_body_field(config[:json_body])
            end
          end

          def build_body_field(config)
            body { oversize_handling config[:oversize_handling] if config[:oversize_handling] }
          end

          def build_json_body_field(config)
            json_body do
              match_scope config[:match_scope]
              match_pattern do
                if config[:match_pattern][:all]
                  all
                elsif config[:match_pattern][:included_paths]
                  config[:match_pattern][:included_paths].each { |path| included_paths path }
                end
              end
              invalid_fallback_behavior config[:invalid_fallback_behavior] if config[:invalid_fallback_behavior]
              oversize_handling config[:oversize_handling] if config[:oversize_handling]
            end
          end
        end
      end
    end
  end
end
