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

module Pangea
  module CLI
    module Commands
      # Analyzes Terraform JSON to extract resource information for Import command
      module ImportResourceAnalyzer
          module_function

          def analyze_resources(terraform_json)
            config = JSON.parse(terraform_json)
            resources = []

            return resources unless config['resource']

            config['resource'].each do |resource_type, instances|
              instances.each do |resource_name, resource_config|
                resources << {
                  type: resource_type,
                  name: resource_name,
                  address: "#{resource_type}.#{resource_name}",
                  attributes: extract_key_attributes(resource_type, resource_config),
                  config: resource_config
                }
              end
            end

            resources
          end

          def extract_key_attributes(resource_type, config)
            case resource_type
            when 'aws_route53_zone'
              {
                name: config['name'],
                comment: config['comment']
              }
            when 'aws_route53_record'
              {
                name: config['name'],
                type: config['type'],
                ttl: config['ttl'],
                records: config['records']&.join(', ')
              }
            else
              # Generic attributes
              {
                name: config['name'],
                id: config['id']
              }.compact
            end
          end
        end
      end
    end
  end
