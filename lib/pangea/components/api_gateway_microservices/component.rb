# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/api_gateway_microservices/types'
require 'pangea/resources/aws'
require 'json'

module Pangea
  module Components
    # API Gateway with multiple microservice integrations, advanced routing, and enterprise features
    # Creates a complete API Gateway setup with rate limiting, versioning, CORS, and transformations
    def api_gateway_microservices(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = ApiGatewayMicroservices::ApiGatewayMicroservicesAttributes.new(attributes)
      component_attrs.validate!
      
      # Generate component-specific tags
      component_tag_set = component_tags('ApiGatewayMicroservices', name, component_attrs.tags)
      
      resources = {}
      
      # Create REST API
      api_attrs = {
        name: component_attrs.api_name,
        description: component_attrs.api_description,
        endpoint_configuration: {
          types: [component_attrs.endpoint_type],
          vpc_endpoint_ids: component_attrs.vpc_endpoint_ids.empty? ? nil : component_attrs.vpc_endpoint_ids
        }.compact,
        binary_media_types: component_attrs.binary_media_types,
        minimum_compression_size: component_attrs.minimum_compression_size,
        api_key_source: component_attrs.api_key_source,
        tags: component_tag_set
      }.compact
      
      api_ref = aws_api_gateway_rest_api(component_resource_name(name, :api), api_attrs)
      resources[:api] = api_ref
      
      # Create request validator
      validator_ref = aws_api_gateway_request_validator(
        component_resource_name(name, :validator),
        {
          name: "#{name}-validator",
          rest_api_id: api_ref.id,
          validate_request_body: true,
          validate_request_parameters: true
        }
      )
      resources[:validator] = validator_ref
      
      # Create VPC Links for private integrations
      vpc_links = {}
      component_attrs.service_endpoints.each do |endpoint|
        if endpoint.vpc_link_ref && !vpc_links[endpoint.vpc_link_ref]
          vpc_link_ref = aws_api_gateway_vpc_link(
            component_resource_name(name, :vpc_link, endpoint.name.to_sym),
            {
              name: "#{name}-#{endpoint.name}-link",
              description: "VPC link for #{endpoint.name} service",
              target_arns: [endpoint.nlb_ref.arn]
            }
          )
          vpc_links[endpoint.vpc_link_ref] = vpc_link_ref
        end
      end
      resources[:vpc_links] = vpc_links unless vpc_links.empty?
      
      # Create resources and methods for each service endpoint
      service_resources = {}
      service_methods = {}
      service_integrations = {}
      
      # Add CORS preflight OPTIONS method helper
      create_cors_method = lambda do |parent_resource, path_part|
        if component_attrs.cors.enabled
          cors_method_ref = aws_api_gateway_method(
            component_resource_name(name, :method, "#{path_part}_options".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: parent_resource.id,
              http_method: "OPTIONS",
              authorization: "NONE"
            }
          )
          
          # Mock integration for OPTIONS
          cors_integration_ref = aws_api_gateway_integration(
            component_resource_name(name, :integration, "#{path_part}_options".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: parent_resource.id,
              http_method: "OPTIONS",
              type: "MOCK",
              request_templates: {
                "application/json" => '{"statusCode": 200}'
              }
            }
          )
          
          # CORS response
          cors_response_ref = aws_api_gateway_method_response(
            component_resource_name(name, :response, "#{path_part}_options".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: parent_resource.id,
              http_method: "OPTIONS",
              status_code: "200",
              response_parameters: {
                "method.response.header.Access-Control-Allow-Headers" => true,
                "method.response.header.Access-Control-Allow-Methods" => true,
                "method.response.header.Access-Control-Allow-Origin" => true,
                "method.response.header.Access-Control-Max-Age" => true,
                "method.response.header.Access-Control-Allow-Credentials" => component_attrs.cors.allow_credentials
              }
            }
          )
          
          cors_integration_response_ref = aws_api_gateway_integration_response(
            component_resource_name(name, :integration_response, "#{path_part}_options".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: parent_resource.id,
              http_method: "OPTIONS",
              status_code: "200",
              response_parameters: {
                "method.response.header.Access-Control-Allow-Headers" => "'#{component_attrs.cors.allow_headers.join(',')}'" ,
                "method.response.header.Access-Control-Allow-Methods" => "'#{component_attrs.cors.allow_methods.join(',')}'",
                "method.response.header.Access-Control-Allow-Origin" => "'#{component_attrs.cors.allow_origins.first}'",
                "method.response.header.Access-Control-Max-Age" => "'#{component_attrs.cors.max_age}'",
                "method.response.header.Access-Control-Allow-Credentials" => "'#{component_attrs.cors.allow_credentials}'"
              }
            }
          )
          
          return {
            method: cors_method_ref,
            integration: cors_integration_ref,
            response: cors_response_ref,
            integration_response: cors_integration_response_ref
          }
        end
        nil
      end
      
      component_attrs.service_endpoints.each do |endpoint|
        endpoint_resources = {}
        endpoint_methods = {}
        endpoint_integrations = {}
        
        # Create base resource for service
        base_resource_ref = aws_api_gateway_resource(
          component_resource_name(name, :resource, endpoint.name.to_sym),
          {
            rest_api_id: api_ref.id,
            parent_id: api_ref.root_resource_id,
            path_part: endpoint.base_path.gsub('/', '')
          }
        )
        endpoint_resources[:base] = base_resource_ref
        
        # Add CORS to base resource
        if cors_refs = create_cors_method.call(base_resource_ref, endpoint.base_path)
          endpoint_methods[:base_cors] = cors_refs[:method]
          endpoint_integrations[:base_cors] = {
            integration: cors_refs[:integration],
            response: cors_refs[:response],
            integration_response: cors_refs[:integration_response]
          }
        end
        
        # Create API version resources if using path versioning
        version_resource_refs = {}
        if component_attrs.versioning.strategy == 'PATH'
          component_attrs.versioning.versions.each do |version|
            version_ref = aws_api_gateway_resource(
              component_resource_name(name, :resource, "#{endpoint.name}_#{version}".to_sym),
              {
                rest_api_id: api_ref.id,
                parent_id: base_resource_ref.id,
                path_part: version
              }
            )
            version_resource_refs[version] = version_ref
            
            # Add CORS to version resource
            if cors_refs = create_cors_method.call(version_ref, "#{endpoint.base_path}_#{version}")
              endpoint_methods["#{version}_cors".to_sym] = cors_refs[:method]
              endpoint_integrations["#{version}_cors".to_sym] = {
                integration: cors_refs[:integration],
                response: cors_refs[:response],
                integration_response: cors_refs[:integration_response]
              }
            end
          end
        end
        
        # Create method resources and integrations
        endpoint.methods.each do |method_config|
          # Determine parent resource based on versioning strategy
          parent_resource = if component_attrs.versioning.strategy == 'PATH'
            version_resource_refs[component_attrs.versioning.default_version] || base_resource_ref
          else
            base_resource_ref
          end
          
          # Create resource for method path if needed
          method_resource_ref = if method_config.path != "/" && method_config.path != ""
            path_parts = method_config.path.gsub(/^\//, '').split('/')
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
              endpoint_resources[resource_name.to_sym] = resource_ref
              
              # Add CORS to each path resource
              if cors_refs = create_cors_method.call(resource_ref, resource_name)
                endpoint_methods["#{resource_name}_cors".to_sym] = cors_refs[:method]
                endpoint_integrations["#{resource_name}_cors".to_sym] = {
                  integration: cors_refs[:integration],
                  response: cors_refs[:response],
                  integration_response: cors_refs[:integration_response]
                }
              end
            end
            
            current_parent
          else
            parent_resource
          end
          
          # Create API method
          method_ref = aws_api_gateway_method(
            component_resource_name(name, :method, "#{endpoint.name}_#{method_config.method.downcase}".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: method_resource_ref.id,
              http_method: method_config.method,
              authorization: component_attrs.authorizer_ref ? "CUSTOM" : method_config.authorization,
              authorizer_id: component_attrs.authorizer_ref&.id,
              api_key_required: method_config.api_key_required || component_attrs.require_api_key,
              request_validator_id: method_config.request_validator || validator_ref.id,
              request_models: method_config.request_models.empty? ? nil : method_config.request_models,
              request_parameters: method_config.request_parameters.empty? ? nil : method_config.request_parameters
            }.compact
          )
          endpoint_methods[method_config.method.downcase.to_sym] = method_ref
          
          # Create integration
          integration_uri = endpoint.integration.uri
          if endpoint.integration.connection_type == 'VPC_LINK'
            # Replace service URL with NLB DNS for VPC Link
            integration_uri = integration_uri.gsub(/https?:\/\/[^\/]+/, "http://#{endpoint.nlb_ref.dns_name}")
          end
          
          integration_attrs = {
            rest_api_id: api_ref.id,
            resource_id: method_resource_ref.id,
            http_method: method_config.method,
            type: endpoint.integration.type,
            integration_http_method: endpoint.integration.http_method,
            uri: integration_uri,
            connection_type: endpoint.integration.connection_type,
            connection_id: endpoint.vpc_link_ref ? vpc_links[endpoint.vpc_link_ref].id : endpoint.integration.connection_id,
            timeout_in_millis: endpoint.integration.timeout_milliseconds,
            content_handling: endpoint.integration.content_handling,
            passthrough_behavior: endpoint.integration.passthrough_behavior,
            cache_key_parameters: endpoint.integration.cache_key_parameters.empty? ? nil : endpoint.integration.cache_key_parameters,
            cache_namespace: endpoint.integration.cache_namespace,
            request_templates: endpoint.transformation.request_templates.empty? ? nil : endpoint.transformation.request_templates,
            request_parameters: endpoint.transformation.response_parameters.empty? ? nil : endpoint.transformation.response_parameters
          }.compact
          
          integration_ref = aws_api_gateway_integration(
            component_resource_name(name, :integration, "#{endpoint.name}_#{method_config.method.downcase}".to_sym),
            integration_attrs
          )
          
          # Create method response
          method_response_ref = aws_api_gateway_method_response(
            component_resource_name(name, :response, "#{endpoint.name}_#{method_config.method.downcase}".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: method_resource_ref.id,
              http_method: method_config.method,
              status_code: "200",
              response_models: endpoint.transformation.response_models.empty? ? nil : endpoint.transformation.response_models,
              response_parameters: component_attrs.cors.enabled ? {
                "method.response.header.Access-Control-Allow-Origin" => true
              } : nil
            }.compact
          )
          
          # Create integration response
          integration_response_ref = aws_api_gateway_integration_response(
            component_resource_name(name, :integration_response, "#{endpoint.name}_#{method_config.method.downcase}".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: method_resource_ref.id,
              http_method: method_config.method,
              status_code: "200",
              response_templates: endpoint.transformation.response_templates.empty? ? nil : endpoint.transformation.response_templates,
              response_parameters: component_attrs.cors.enabled ? {
                "method.response.header.Access-Control-Allow-Origin" => "'#{component_attrs.cors.allow_origins.first}'"
              } : nil
            }.compact
          )
          
          endpoint_integrations[method_config.method.downcase.to_sym] = {
            integration: integration_ref,
            response: method_response_ref,
            integration_response: integration_response_ref
          }
        end
        
        service_resources[endpoint.name.to_sym] = endpoint_resources
        service_methods[endpoint.name.to_sym] = endpoint_methods
        service_integrations[endpoint.name.to_sym] = endpoint_integrations
      end
      
      resources[:service_resources] = service_resources
      resources[:service_methods] = service_methods
      resources[:service_integrations] = service_integrations
      
      # Create API deployment
      deployment_ref = aws_api_gateway_deployment(
        component_resource_name(name, :deployment),
        {
          rest_api_id: api_ref.id,
          description: component_attrs.deployment_description || "Deployment for #{component_attrs.api_name}",
          stage_description: "Stage: #{component_attrs.stage_name}",
          # Depends on all methods and integrations
          depends_on: service_methods.values.flat_map { |methods| methods.values.map(&:terraform_address) } +
                     service_integrations.values.flat_map { |integrations| integrations.values.map { |i| i[:integration].terraform_address } }
        }
      )
      resources[:deployment] = deployment_ref
      
      # Create stage with logging and caching
      stage_attrs = {
        deployment_id: deployment_ref.id,
        rest_api_id: api_ref.id,
        stage_name: component_attrs.stage_name,
        xray_tracing_enabled: component_attrs.xray_tracing_enabled,
        cache_cluster_enabled: component_attrs.cache_cluster_enabled,
        cache_cluster_size: component_attrs.cache_cluster_enabled ? component_attrs.cache_cluster_size : nil,
        description: "Production stage for #{component_attrs.api_name}",
        tags: component_tag_set
      }.compact
      
      # Add access logging if configured
      if component_attrs.access_log_destination_arn
        stage_attrs[:access_log_settings] = {
          destination_arn: component_attrs.access_log_destination_arn,
          format: component_attrs.access_log_format || JSON.generate({
            requestId: '$context.requestId',
            extendedRequestId: '$context.extendedRequestId',
            ip: '$context.identity.sourceIp',
            caller: '$context.identity.caller',
            user: '$context.identity.user',
            requestTime: '$context.requestTime',
            httpMethod: '$context.httpMethod',
            resourcePath: '$context.resourcePath',
            status: '$context.status',
            protocol: '$context.protocol',
            responseLength: '$context.responseLength'
          })
        }
      end
      
      stage_ref = aws_api_gateway_stage(
        component_resource_name(name, :stage),
        stage_attrs
      )
      resources[:stage] = stage_ref
      
      # Create method settings for the stage
      method_settings_ref = aws_api_gateway_method_settings(
        component_resource_name(name, :method_settings),
        {
          rest_api_id: api_ref.id,
          stage_name: stage_ref.stage_name,
          method_path: "*/*",
          settings: {
            metrics_enabled: component_attrs.metrics_enabled,
            logging_level: component_attrs.logging_level,
            data_trace_enabled: component_attrs.data_trace_enabled,
            throttling_burst_limit: component_attrs.rate_limit.burst_limit,
            throttling_rate_limit: component_attrs.rate_limit.rate_limit,
            caching_enabled: component_attrs.cache_cluster_enabled,
            cache_ttl_in_seconds: component_attrs.cache_ttl,
            cache_data_encrypted: component_attrs.cache_cluster_enabled
          }
        }
      )
      resources[:method_settings] = method_settings_ref
      
      # Create usage plan with API key if rate limiting is enabled
      if component_attrs.rate_limit.enabled
        usage_plan_ref = aws_api_gateway_usage_plan(
          component_resource_name(name, :usage_plan),
          {
            name: "#{name}-usage-plan",
            description: "Usage plan for #{component_attrs.api_name}",
            api_stages: [{
              api_id: api_ref.id,
              stage: stage_ref.stage_name
            }],
            throttle: {
              burst_limit: component_attrs.rate_limit.burst_limit,
              rate_limit: component_attrs.rate_limit.rate_limit
            },
            quota: component_attrs.rate_limit.quota_limit ? {
              limit: component_attrs.rate_limit.quota_limit,
              period: component_attrs.rate_limit.quota_period
            } : nil,
            tags: component_tag_set
          }.compact
        )
        resources[:usage_plan] = usage_plan_ref
        
        # Create API key
        api_key_ref = aws_api_gateway_api_key(
          component_resource_name(name, :api_key),
          {
            name: "#{name}-api-key",
            description: "API key for #{component_attrs.api_name}",
            enabled: true,
            tags: component_tag_set
          }
        )
        resources[:api_key] = api_key_ref
        
        # Associate API key with usage plan
        usage_plan_key_ref = aws_api_gateway_usage_plan_key(
          component_resource_name(name, :usage_plan_key),
          {
            key_id: api_key_ref.id,
            key_type: "API_KEY",
            usage_plan_id: usage_plan_ref.id
          }
        )
        resources[:usage_plan_key] = usage_plan_key_ref
      end
      
      # Create CloudWatch alarms
      alarms = {}
      
      # 4XX error rate alarm
      alarm_4xx_ref = aws_cloudwatch_metric_alarm(
        component_resource_name(name, :alarm_4xx),
        {
          alarm_name: "#{name}-api-4xx-errors",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "2",
          metric_name: "4XXError",
          namespace: "AWS/ApiGateway",
          period: "300",
          statistic: "Sum",
          threshold: "100",
          alarm_description: "API Gateway 4XX errors are high",
          dimensions: {
            ApiName: api_ref.name,
            Stage: stage_ref.stage_name
          },
          tags: component_tag_set
        }
      )
      alarms[:errors_4xx] = alarm_4xx_ref
      
      # 5XX error rate alarm
      alarm_5xx_ref = aws_cloudwatch_metric_alarm(
        component_resource_name(name, :alarm_5xx),
        {
          alarm_name: "#{name}-api-5xx-errors",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "1",
          metric_name: "5XXError",
          namespace: "AWS/ApiGateway",
          period: "60",
          statistic: "Sum",
          threshold: "10",
          alarm_description: "API Gateway 5XX errors detected",
          dimensions: {
            ApiName: api_ref.name,
            Stage: stage_ref.stage_name
          },
          tags: component_tag_set
        }
      )
      alarms[:errors_5xx] = alarm_5xx_ref
      
      # Latency alarm
      latency_alarm_ref = aws_cloudwatch_metric_alarm(
        component_resource_name(name, :alarm_latency),
        {
          alarm_name: "#{name}-api-high-latency",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "2",
          metric_name: "Latency",
          namespace: "AWS/ApiGateway",
          period: "300",
          statistic: "Average",
          threshold: "1000",
          alarm_description: "API Gateway latency is high",
          dimensions: {
            ApiName: api_ref.name,
            Stage: stage_ref.stage_name
          },
          tags: component_tag_set
        }
      )
      alarms[:latency] = latency_alarm_ref
      
      resources[:alarms] = alarms
      
      # Associate WAF ACL if configured
      if component_attrs.waf_acl_ref
        waf_association_ref = aws_wafv2_web_acl_association(
          component_resource_name(name, :waf_association),
          {
            resource_arn: stage_ref.arn,
            web_acl_arn: component_attrs.waf_acl_ref.arn
          }
        )
        resources[:waf_association] = waf_association_ref
      end
      
      # Calculate outputs
      outputs = {
        api_id: api_ref.id,
        api_name: api_ref.name,
        api_endpoint: "https://#{api_ref.id}.execute-api.${AWS::Region}.amazonaws.com/#{stage_ref.stage_name}",
        stage_name: stage_ref.stage_name,
        
        service_endpoints: component_attrs.service_endpoints.map do |endpoint|
          {
            name: endpoint.name,
            base_url: "https://#{api_ref.id}.execute-api.${AWS::Region}.amazonaws.com/#{stage_ref.stage_name}/#{endpoint.base_path}"
          }
        end,
        
        features: [
          ("Rate Limiting" if component_attrs.rate_limit.enabled),
          ("API Versioning (#{component_attrs.versioning.strategy})" if component_attrs.versioning),
          ("CORS Enabled" if component_attrs.cors.enabled),
          ("Request Validation" if resources[:validator]),
          ("Caching" if component_attrs.cache_cluster_enabled),
          ("X-Ray Tracing" if component_attrs.xray_tracing_enabled),
          ("WAF Protection" if component_attrs.waf_acl_ref),
          ("VPC Link Integration" if resources[:vpc_links]&.any?)
        ].compact,
        
        api_key_id: resources[:api_key]&.id,
        usage_plan_id: resources[:usage_plan]&.id,
        
        estimated_monthly_cost: estimate_api_gateway_cost(component_attrs)
      }
      
      create_component_reference(
        'api_gateway_microservices',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def estimate_api_gateway_cost(attrs)
      cost = 0.0
      
      # REST API requests (per million)
      estimated_requests_per_month = 10_000_000
      cost += (estimated_requests_per_month / 1_000_000) * 3.50
      
      # Cache cluster cost
      if attrs.cache_cluster_enabled
        cache_costs = {
          '0.5' => 18.0,
          '1.6' => 144.0,
          '6.1' => 500.0,
          '13.5' => 1000.0,
          '28.4' => 2000.0,
          '58.2' => 4000.0,
          '118' => 7000.0,
          '237' => 14000.0
        }
        cost += cache_costs[attrs.cache_cluster_size] || 18.0
      end
      
      # Data transfer (estimated)
      cost += 20.0
      
      # CloudWatch Logs (if enabled)
      cost += 5.0 if attrs.access_log_destination_arn
      
      # X-Ray tracing (if enabled)
      cost += 5.0 if attrs.xray_tracing_enabled
      
      cost.round(2)
    end
  end
end