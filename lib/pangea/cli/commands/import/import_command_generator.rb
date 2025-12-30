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
    module Commands
      module Import
        # Generates import commands for different resource types
        module ImportCommandGenerator
          module_function

          def generate_import_commands(resources)
            commands = []

            resources.each do |resource|
              commands << build_command(resource)
            end

            commands
          end

          def build_command(resource)
            case resource[:type]
            when 'aws_route53_zone'
              build_route53_zone_command(resource)
            when 'aws_route53_record'
              build_route53_record_command(resource)
            else
              build_generic_command(resource)
            end
          end

          def build_route53_zone_command(resource)
            zone_name = resource[:attributes][:name]
            {
              command: "tofu import #{resource[:address]} ZONE_ID",
              help: "Find zone ID: aws route53 list-hosted-zones --query 'HostedZones[?Name==`#{zone_name}.`].Id'"
            }
          end

          def build_route53_record_command(resource)
            record_name = resource[:attributes][:name]
            record_type = resource[:attributes][:type]
            {
              command: "tofu import #{resource[:address]} ZONE_ID_#{record_name}_#{record_type}",
              help: "Format: ZONEID_RECORDNAME_TYPE (e.g., Z123_example.com_A)"
            }
          end

          def build_generic_command(resource)
            {
              command: "tofu import #{resource[:address]} RESOURCE_ID",
              help: "Find the resource ID in AWS console or CLI"
            }
          end
        end
      end
    end
  end
end
