# frozen_string_literal: true

module Pangea
  module Components
    module ApiGatewayMicroservices
      # Service resources, methods, and integrations
      module Resources
        def create_service_resources(name, api_ref, component_attrs, validator_ref, vpc_links)
          @current_name = name
          service_resources = {}
          service_methods = {}
          service_integrations = {}

          component_attrs.service_endpoints.each do |endpoint|
            result = create_endpoint_resources(
              name, api_ref, endpoint, component_attrs, validator_ref, vpc_links
            )
            service_resources[endpoint.name.to_sym] = result[:resources]
            service_methods[endpoint.name.to_sym] = result[:methods]
            service_integrations[endpoint.name.to_sym] = result[:integrations]
          end

          {
            service_resources: service_resources,
            service_methods: service_methods,
            service_integrations: service_integrations
          }
        end

        private

        def create_endpoint_resources(name, api_ref, endpoint, component_attrs, validator_ref, vpc_links)
          resources = {}
          methods = {}
          integrations = {}

          base_resource_ref = create_base_resource(name, api_ref, endpoint)
          resources[:base] = base_resource_ref

          add_cors_to_resource(api_ref, base_resource_ref, endpoint.base_path, component_attrs.cors, methods, integrations)

          version_resources = create_version_resources(name, api_ref, base_resource_ref, endpoint, component_attrs)
          resources.merge!(version_resources[:resources]) if version_resources

          methods.merge!(version_resources[:methods]) if version_resources
          integrations.merge!(version_resources[:integrations]) if version_resources

          create_endpoint_methods(
            name, api_ref, endpoint, component_attrs, validator_ref, vpc_links,
            base_resource_ref, version_resources&.dig(:refs), resources, methods, integrations
          )

          { resources: resources, methods: methods, integrations: integrations }
        end

        def create_base_resource(name, api_ref, endpoint)
          aws_api_gateway_resource(
            component_resource_name(name, :resource, endpoint.name.to_sym),
            {
              rest_api_id: api_ref.id,
              parent_id: api_ref.root_resource_id,
              path_part: endpoint.base_path.gsub('/', '')
            }
          )
        end

        def add_cors_to_resource(api_ref, resource_ref, path_part, cors_config, methods, integrations)
          return unless cors_config.enabled

          cors_refs = create_cors_preflight(api_ref, resource_ref, path_part, cors_config)
          return unless cors_refs

          methods["#{path_part}_cors".to_sym] = cors_refs[:method]
          integrations["#{path_part}_cors".to_sym] = {
            integration: cors_refs[:integration],
            response: cors_refs[:response],
            integration_response: cors_refs[:integration_response]
          }
        end

        def create_version_resources(name, api_ref, base_resource_ref, endpoint, component_attrs)
          return nil unless component_attrs.versioning.strategy == 'PATH'

          refs = {}
          resources = {}
          methods = {}
          integrations = {}

          component_attrs.versioning.versions.each do |version|
            version_ref = aws_api_gateway_resource(
              component_resource_name(name, :resource, "#{endpoint.name}_#{version}".to_sym),
              {
                rest_api_id: api_ref.id,
                parent_id: base_resource_ref.id,
                path_part: version
              }
            )
            refs[version] = version_ref
            resources["#{endpoint.name}_#{version}".to_sym] = version_ref

            add_cors_to_resource(api_ref, version_ref, "#{endpoint.base_path}_#{version}", component_attrs.cors, methods, integrations)
          end

          { refs: refs, resources: resources, methods: methods, integrations: integrations }
        end

        def create_endpoint_methods(name, api_ref, endpoint, component_attrs, validator_ref, vpc_links,
                                     base_resource_ref, version_refs, resources, methods, integrations)
          endpoint.methods.each do |method_config|
            parent_resource = determine_parent_resource(component_attrs, version_refs, base_resource_ref)
            method_resource_ref = create_method_resource(name, api_ref, endpoint, method_config, parent_resource, component_attrs, resources, methods, integrations)

            create_method_and_integration(
              name, api_ref, endpoint, method_config, method_resource_ref,
              component_attrs, validator_ref, vpc_links, methods, integrations
            )
          end
        end

        def determine_parent_resource(component_attrs, version_refs, base_resource_ref)
          if component_attrs.versioning.strategy == 'PATH' && version_refs
            version_refs[component_attrs.versioning.default_version] || base_resource_ref
          else
            base_resource_ref
          end
        end

        def create_method_resource(name, api_ref, endpoint, method_config, parent_resource, component_attrs, resources, methods, integrations)
          return parent_resource if method_config.path == '/' || method_config.path == ''

          path_parts = method_config.path.gsub(%r{^/}, '').split('/')
          current_parent = parent_resource

          path_parts.each_with_index do |part, index|
            resource_name = "#{endpoint.name}_#{path_parts[0..index].join('_')}".gsub('{', '').gsub('}', '')
            resource_ref = aws_api_gateway_resource(
              component_resource_name(name, :resource, resource_name.to_sym),
              {
                rest_api_id: api_ref.id,
                parent_id: current_parent.id,
                path_part: part
              }
            )
            current_parent = resource_ref
            resources[resource_name.to_sym] = resource_ref

            add_cors_to_resource(api_ref, resource_ref, resource_name, component_attrs.cors, methods, integrations)
          end

          current_parent
        end
      end
    end
  end
end
