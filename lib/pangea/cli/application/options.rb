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
  module CLI
    module Application
      # TTY::Option definitions for the main CLI application
      module Options
        def self.included(base)
          base.class_eval do
            usage do
              program 'pangea'

              desc 'Beautiful infrastructure management with OpenTofu'

              example 'Plan infrastructure changes',
                      '  $ pangea plan infrastructure.rb --namespace production'

              example 'Apply infrastructure changes',
                      '  $ pangea apply infrastructure.rb'

              example 'Plan specific template',
                      '  $ pangea plan infrastructure.rb --template web_server'

              example 'Apply to specific namespace',
                      '  $ pangea apply infrastructure.rb --namespace production'

              example 'Destroy with confirmation prompt',
                      '  $ pangea destroy infrastructure.rb --no-auto-approve'

              example 'Import existing resources',
                      '  $ pangea import infrastructure.rb --namespace production --resource aws_route53_zone.main --id Z1234567890ABC'
            end

            argument :command do
              desc 'Command to execute'
              permit %w[init plan apply destroy inspect agent import]
            end

            argument :file do
              desc 'Infrastructure file to process'
              required
              validate ->(f) { File.exist?(f) }
            end

            flag :help do
              short '-h'
              long '--help'
              desc 'Print help information'
            end

            flag :version do
              short '-v'
              long '--version'
              desc 'Print version information'
            end

            option :namespace do
              short '-n'
              long '--namespace string'
              desc 'Target namespace (uses default_namespace from config if not specified)'
              default ENV.fetch('PANGEA_NAMESPACE', nil)
            end

            option :debug do
              long '--debug'
              desc 'Enable debug output'
            end

            option :no_auto_approve do
              long '--no-auto-approve'
              desc 'Require explicit confirmation (default is auto-approve)'
            end

            option :template do
              short '-t'
              long '--template string'
              desc 'Target specific template within file'
            end

            option :show_compiled do
              long '--show-compiled'
              desc 'Show compiled Terraform JSON output (plan command only)'
            end

            option :json do
              long '--json'
              desc 'Output results in JSON format (agent-friendly)'
            end

            option :type do
              long '--type string'
              desc 'Type for inspect command (all|templates|resources|architectures|components|namespaces|config|state|render)'
              default 'all'
            end

            option :format do
              long '--format string'
              desc 'Output format (json|yaml|text)'
              default 'json'
            end

            option :resource do
              long '--resource string'
              desc 'Resource address for import (e.g., aws_route53_zone.staging_zone)'
            end

            option :id do
              long '--id string'
              desc 'Resource ID to import (e.g., Z1234567890ABC)'
            end
          end
        end
      end
    end
  end
end
