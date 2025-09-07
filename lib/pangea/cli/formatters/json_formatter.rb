# frozen_string_literal: true

require 'json'

module Pangea
  module CLI
    module Formatters
      # JSON formatter for CLI output
      class JSONFormatter
        def initialize(output = $stdout)
          @output = output
        end
        
        # Format plan output as JSON
        def format_plan(result)
          json_output = {
            timestamp: Time.now.iso8601,
            success: result[:success],
            namespace: result[:namespace],
            template: result[:template],
            changes: {
              has_changes: result[:changes] || false,
              summary: extract_change_summary(result)
            }
          }
          
          if result[:resource_changes]
            json_output[:resources] = {
              create: format_resources(result[:resource_changes][:create]),
              update: format_resources(result[:resource_changes][:update]),
              delete: format_resources(result[:resource_changes][:delete]),
              replace: format_resources(result[:resource_changes][:replace])
            }
          end
          
          if result[:error]
            json_output[:error] = {
              message: result[:error],
              output: result[:output]
            }
          end
          
          output_json(json_output)
        end
        
        # Format apply output as JSON
        def format_apply(result)
          json_output = {
            timestamp: Time.now.iso8601,
            success: result[:success],
            namespace: result[:namespace],
            template: result[:template],
            applied: result[:applied] || false
          }
          
          if result[:outputs]
            json_output[:outputs] = result[:outputs]
          end
          
          if result[:resource_changes]
            json_output[:resources_created] = result[:resource_changes][:create]&.count || 0
            json_output[:resources_updated] = result[:resource_changes][:update]&.count || 0
            json_output[:resources_deleted] = result[:resource_changes][:delete]&.count || 0
          end
          
          if result[:error]
            json_output[:error] = {
              message: result[:error],
              output: result[:output]
            }
          end
          
          output_json(json_output)
        end
        
        # Format destroy output as JSON
        def format_destroy(result)
          json_output = {
            timestamp: Time.now.iso8601,
            success: result[:success],
            namespace: result[:namespace],
            template: result[:template],
            destroyed: result[:destroyed] || false
          }
          
          if result[:resources_destroyed]
            json_output[:resources_destroyed] = result[:resources_destroyed]
          end
          
          if result[:error]
            json_output[:error] = {
              message: result[:error],
              output: result[:output]
            }
          end
          
          output_json(json_output)
        end
        
        # Format compilation results
        def format_compilation(results)
          json_output = {
            timestamp: Time.now.iso8601,
            success: results.all? { |r| r[:success] },
            templates: results.map do |result|
              {
                name: result[:name],
                success: result[:success],
                error: result[:error],
                terraform_json: result[:success] ? JSON.parse(result[:json]) : nil
              }
            end
          }
          
          output_json(json_output)
        end
        
        # Format namespace list
        def format_namespaces(namespaces, default_namespace)
          json_output = {
            default: default_namespace,
            namespaces: namespaces.map do |ns|
              {
                name: ns.name,
                description: ns.description,
                backend_type: ns.state.type,
                backend_config: sanitize_backend(ns.to_terraform_backend)
              }
            end
          }
          
          output_json(json_output)
        end
        
        # Format resource list
        def format_resources(resources)
          return [] unless resources
          
          resources.map do |resource|
            parts = resource.split('.')
            {
              type: parts[0],
              name: parts[1],
              full_address: resource
            }
          end
        end
        
        private
        
        def extract_change_summary(result)
          return nil unless result[:output]
          
          # Try to parse terraform plan output for summary
          if result[:output].match(/Plan: (\d+) to add, (\d+) to change, (\d+) to destroy/)
            {
              add: $1.to_i,
              change: $2.to_i,
              destroy: $3.to_i
            }
          end
        end
        
        def sanitize_backend(backend_config)
          config = backend_config.dup
          
          if config[:s3]
            config[:s3] = config[:s3].dup
            config[:s3][:kms_key_id] = "***" if config[:s3][:kms_key_id]
          end
          
          config
        end
        
        def output_json(data)
          @output.puts JSON.pretty_generate(data)
        end
      end
    end
  end
end