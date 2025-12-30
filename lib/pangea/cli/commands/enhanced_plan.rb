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

require 'pangea/cli/commands/base_command'

require_relative 'enhanced_plan/template_operations'
require_relative 'enhanced_plan/plan_generation'
require_relative 'enhanced_plan/metrics'

module Pangea
  module CLI
    module Commands
      # Enhanced Plan command showcasing beautiful UI components
      class EnhancedPlan < BaseCommand
        include TemplateOperations
        include PlanGeneration
        include Metrics

        def run(file_path, namespace:, template: nil, show_compiled: false)
          start_time = Time.now

          namespace_entity = load_namespace(namespace)
          return unless namespace_entity

          ui.namespace_info(namespace_entity)
          puts

          templates = parse_templates_with_progress(file_path, template)
          return if templates.empty?

          compiled_templates = compile_templates_with_progress(templates)
          plan_results = generate_plan_with_progress(compiled_templates, namespace_entity)
          display_plan_results(plan_results)

          total_duration = Time.now - start_time
          show_performance_metrics(total_duration, compiled_templates, plan_results)

          ui.celebration("Plan completed successfully!")
        rescue StandardError => e
          banner.error("Plan failed", e.message, [
                         "Check your template syntax",
                         "Verify namespace configuration",
                         "Run with --debug for more details"
                       ])
          exit 1
        end
      end
    end
  end
end
