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

# lib/pangea/utilities/cost/calculator.rb
require 'json'

module Pangea
  module Utilities
    module Cost
      class Calculator
        def calculate_template_cost(template_name, namespace = nil)
          workspace_path = get_workspace_path(template_name, namespace)
          
          unless File.exist?(File.join(workspace_path, 'terraform.tfstate'))
            return CostReport.new(template_name, { error: "State file not found" })
          end
          
          # Parse state file
          state = JSON.parse(File.read(File.join(workspace_path, 'terraform.tfstate')))
          resources = extract_resources_from_state(state)
          
          # Calculate costs
          resource_costs = resources.map do |resource|
            calculate_resource_cost(resource)
          end
          
          CostReport.new(template_name, {
            resources: resource_costs,
            total_hourly: resource_costs.sum { |r| r[:hourly] },
            total_monthly: resource_costs.sum { |r| r[:monthly] },
            calculated_at: Time.now
          })
        end
        
        def calculate_all_templates(namespace = nil)
          templates = discover_templates(namespace)
          
          reports = templates.map do |template|
            calculate_template_cost(template, namespace)
          end
          
          {
            namespace: namespace || 'default',
            templates: reports,
            total_hourly: reports.sum { |r| r.total_hourly },
            total_monthly: reports.sum { |r| r.total_monthly }
          }
        end
        
        private
        
        def get_workspace_path(template_name, namespace)
          namespace ||= 'default'
          File.expand_path("~/.pangea/workspaces/#{namespace}/#{template_name}")
        end
        
        def extract_resources_from_state(state)
          resources = []
          
          return resources unless state['resources']
          
          state['resources'].each do |resource|
            next unless resource['mode'] == 'managed'
            
            resource['instances'].each do |instance|
              resources << {
                type: resource['type'],
                name: resource['name'],
                attributes: instance['attributes']
              }
            end
          end
          
          resources
        end
        
        def calculate_resource_cost(resource)
          pricing = ResourcePricing.get_price(resource[:type], resource[:attributes])
          
          {
            type: resource[:type],
            name: resource[:name],
            hourly: pricing[:hourly],
            monthly: pricing[:monthly],
            attributes: extract_cost_relevant_attributes(resource)
          }
        end
        
        def extract_cost_relevant_attributes(resource)
          case resource[:type]
          when 'aws_instance'
            {
              instance_type: resource[:attributes]['instance_type'],
              state: resource[:attributes]['instance_state']
            }
          when 'aws_db_instance'
            {
              instance_class: resource[:attributes]['instance_class'],
              engine: resource[:attributes]['engine'],
              allocated_storage: resource[:attributes]['allocated_storage']
            }
          else
            {}
          end
        end
        
        def discover_templates(namespace)
          namespace ||= 'default'
          workspace_dir = File.expand_path("~/.pangea/workspaces/#{namespace}")
          
          return [] unless Dir.exist?(workspace_dir)
          
          Dir.entries(workspace_dir).select do |entry|
            File.directory?(File.join(workspace_dir, entry)) && entry !~ /^\./
          end
        end
      end
      
      class CostReport
        attr_reader :template_name, :data
        
        def initialize(template_name, data)
          @template_name = template_name
          @data = data
        end
        
        def error?
          @data.key?(:error)
        end
        
        def total_hourly
          @data[:total_hourly] || 0
        end
        
        def total_monthly
          @data[:total_monthly] || 0
        end
        
        def resources
          @data[:resources] || []
        end
        
        def to_h
          {
            template_name: @template_name,
            total_hourly: total_hourly,
            total_monthly: total_monthly,
            resource_count: resources.length,
            resources: resources
          }
        end
        
        def to_s
          if error?
            "Error calculating cost for #{@template_name}: #{@data[:error]}"
          else
            "#{@template_name}: $#{'%.2f' % total_hourly}/hour, $#{'%.2f' % total_monthly}/month (#{resources.length} resources)"
          end
        end
      end
    end
  end
end