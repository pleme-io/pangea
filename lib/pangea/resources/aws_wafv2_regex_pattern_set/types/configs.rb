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
        # Common WAFv2 regex pattern set configurations
        module WafV2RegexPatternSetConfigs
          def self.xss_protection_patterns(scope = 'REGIONAL')
            {
              name: 'xss-protection-patterns',
              description: 'Regex patterns to detect XSS attempts',
              scope: scope,
              regular_expression: [
                { regex_string: '<script[^>]*>.*</script>' },
                { regex_string: 'javascript:' },
                { regex_string: 'on\w+\s*=' },
                { regex_string: '<iframe[^>]*>' },
                { regex_string: 'eval\s*\(' }
              ],
              tags: {
                Purpose: 'XSS Protection',
                SecurityType: 'input_validation'
              }
            }
          end

          def self.sql_injection_patterns(scope = 'REGIONAL')
            {
              name: 'sql-injection-patterns',
              description: 'Regex patterns to detect SQL injection attempts',
              scope: scope,
              regular_expression: [
                { regex_string: '(\bUNION\b|\bSELECT\b|\bINSERT\b|\bDELETE\b|\bUPDATE\b)\s' },
                { regex_string: '(\bOR\b|\bAND\b)\s+\d+\s*=\s*\d+' },
                { regex_string: '(\bDROP\b|\bALTER\b|\bTRUNCATE\b)\s+\bTABLE\b' },
                { regex_string: '--\s' },
                { regex_string: '/\*.*\*/' }
              ],
              tags: {
                Purpose: 'SQL Injection Protection',
                SecurityType: 'database_security'
              }
            }
          end

          def self.path_traversal_patterns(scope = 'REGIONAL')
            {
              name: 'path-traversal-patterns',
              description: 'Regex patterns to detect path traversal attempts',
              scope: scope,
              regular_expression: [
                { regex_string: '\.\./.*\.\.' },
                { regex_string: '\.\.\\.*\.\.' },
                { regex_string: '/etc/passwd' },
                { regex_string: '/proc/self/' },
                { regex_string: 'WEB-INF/' }
              ],
              tags: {
                Purpose: 'Path Traversal Protection',
                SecurityType: 'file_system_security'
              }
            }
          end

          def self.user_agent_filtering_patterns(scope = 'REGIONAL')
            {
              name: 'user-agent-filtering-patterns',
              description: 'Regex patterns to filter suspicious user agents',
              scope: scope,
              regular_expression: [
                { regex_string: 'sqlmap/' },
                { regex_string: 'nikto/' },
                { regex_string: 'nmap/' },
                { regex_string: 'masscan/' },
                { regex_string: 'python-requests/' }
              ],
              tags: {
                Purpose: 'User Agent Filtering',
                SecurityType: 'bot_protection'
              }
            }
          end

          def self.custom_application_patterns(application_name, patterns, scope = 'REGIONAL')
            {
              name: "#{application_name.downcase.gsub(/[^a-z0-9]/, '-')}-custom-patterns",
              description: "Custom regex patterns for #{application_name}",
              scope: scope,
              regular_expression: patterns.map { |pattern| { regex_string: pattern } },
              tags: {
                Application: application_name,
                Purpose: 'Custom Application Protection',
                SecurityType: 'application_specific'
              }
            }
          end
        end
      end
    end
  end
end
