# frozen_string_literal: true

module Pangea
  module Components
    module ServiceMeshObservability
      # Log aggregation and metric filters
      module Logging
        def create_log_groups(name, component_attrs, component_tag_set)
          return {} unless component_attrs.log_aggregation.enabled

          log_groups = {}

          component_attrs.services.each do |service|
            log_groups[service.name.to_sym] = aws_cloudwatch_log_group(
              component_resource_name(name, :log_group, service.name.to_sym),
              {
                name: "/ecs/#{service.name}",
                retention_in_days: component_attrs.log_aggregation.retention_days,
                tags: component_tag_set
              }
            )
          end

          log_groups
        end

        def create_metric_filters(name, component_attrs, log_groups)
          return {} unless component_attrs.log_aggregation.enabled && component_attrs.log_aggregation.filter_patterns.any?

          metric_filters = {}

          component_attrs.log_aggregation.filter_patterns.each_with_index do |filter, index|
            metric_filters["filter#{index}".to_sym] = aws_cloudwatch_log_metric_filter(
              component_resource_name(name, :metric_filter, "filter#{index}".to_sym),
              {
                name: filter[:name] || "#{name}-filter-#{index}",
                log_group_name: filter[:log_group] || log_groups.values.first.name,
                pattern: filter[:pattern],
                metric_transformation: {
                  name: filter[:metric_name],
                  namespace: filter[:namespace] || "#{component_attrs.mesh_name}/CustomMetrics",
                  value: filter[:value] || '1',
                  default_value: filter[:default_value]
                }
              }
            )
          end

          metric_filters
        end

        def create_insights_queries(name, component_attrs, log_groups)
          return {} unless component_attrs.log_aggregation.enabled && component_attrs.log_aggregation.insights_queries.any?

          insights_queries = {}

          component_attrs.log_aggregation.insights_queries.each_with_index do |query, index|
            insights_queries["query#{index}".to_sym] = aws_cloudwatch_query_definition(
              component_resource_name(name, :insights_query, "query#{index}".to_sym),
              {
                name: query[:name] || "#{name}-query-#{index}",
                query_string: query[:query],
                log_group_names: query[:log_groups] || log_groups.values.map(&:name)
              }
            )
          end

          insights_queries
        end
      end
    end
  end
end
