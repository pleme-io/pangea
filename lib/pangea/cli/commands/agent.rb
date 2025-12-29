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

require 'json'
require 'pangea/cli/commands/base_command'
require 'pangea/cli/commands/agent/analysis'
require 'pangea/cli/commands/agent/complexity'
require 'pangea/cli/commands/agent/dependencies'
require 'pangea/cli/commands/agent/validation'
require 'pangea/cli/commands/agent/cost'
require 'pangea/cli/commands/agent/security'
require 'pangea/cli/commands/agent/suggestions'
require 'pangea/cli/commands/agent/explanation'
require 'pangea/compilation/template_compiler'
require 'pangea/execution/terraform_executor'

module Pangea
  module CLI
    module Commands
      # Agent command for AI/automation-friendly operations
      class Agent < BaseCommand
        include Agent::Analysis
        include Agent::Complexity
        include Agent::Dependencies
        include Agent::Validation
        include Agent::Cost
        include Agent::Security
        include Agent::Suggestions
        include Agent::Explanation

        AVAILABLE_ACTIONS = %w[analyze validate diff cost security dependencies suggest explain].freeze

        def run(action, target = nil, **options)
          response = dispatch_action(action, target, **options)

          puts JSON.pretty_generate({
            action: action,
            target: target,
            options: options,
            timestamp: Time.now.iso8601,
            response: response
          })
        rescue StandardError => e
          puts JSON.pretty_generate({
            action: action,
            target: target,
            error: e.message,
            error_class: e.class.name,
            backtrace: e.backtrace.first(5)
          })
        end

        private

        def dispatch_action(action, target, **options)
          case action
          when 'analyze' then analyze_infrastructure(target, **options)
          when 'validate' then validate_infrastructure(target, **options)
          when 'diff' then diff_infrastructure(target, **options)
          when 'cost' then estimate_cost(target, **options)
          when 'security' then security_scan(target, **options)
          when 'dependencies' then analyze_dependencies(target, **options)
          when 'suggest' then suggest_improvements(target, **options)
          when 'explain' then explain_infrastructure(target, **options)
          else
            { error: "Unknown agent action: #{action}", available_actions: AVAILABLE_ACTIONS }
          end
        end
      end
    end
  end
end
