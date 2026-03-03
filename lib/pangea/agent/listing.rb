# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  class Agent
    # Resource and component listing methods
    module Listing
      def list_resources
        resources = []

        Dir.glob(
          File.join(
            File.dirname(__FILE__),
            '..',
            'resources',
            'aws',
            '**',
            '*.rb'
          )
        ).each do |file|
          next if file.include?('/types.rb') || file.include?('_spec.rb')

          service   = file.split('/')[-2]
          resource  = File.basename(file, '.rb')

          resources << {
            function: "aws_#{service}_#{resource}",
            service: service,
            resource: resource,
            file: file
          }
        end

        {
          total: resources.count,
          resources: resources.sort_by { |r| r[:function] }
        }
      end

      def list_architectures
        architectures = []

        Dir.glob(
          File.join(
            File.dirname(__FILE__),
            '..',
            'architectures',
            'patterns',
            '**',
            '*.rb'
          )
        ).each do |file|
          pattern = File.basename(file, '.rb')
          architectures << {
            function: "#{pattern}_architecture",
            pattern: pattern, file: file
          }
        end

        {
          total: architectures.count,
          architectures: architectures
        }
      end

      def list_components
        components = []

        Dir.glob(File.join(File.dirname(__FILE__), '..', 'components', '**/component.rb')).each do |file|
          component = File.basename(File.dirname(file))
          components << { function: "#{component}_component", component: component, directory: File.dirname(file) }
        end

        { total: components.count, components: components }
      end

      def search_resources(keyword)
        all_resources = list_resources[:resources]

        matches = all_resources.select do |r|
          r[:function].include?(keyword) || r[:service].include?(keyword) || r[:resource].include?(keyword)
        end

        {
          keyword: keyword,
          count: matches.count,
          matches: matches
        }
      end

      def get_namespaces
        {
          default: Pangea.config.default_namespace,
          namespaces: Pangea.config.namespaces.map do |ns|
            {
              name: ns.name,
              description: ns.description,
              backend: { type: ns.state.type, config: sanitize_backend_config(ns) }
            }
          end
        }
      rescue StandardError => e
        error_response(e.message)
      end
    end
  end
end
