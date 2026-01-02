# frozen_string_literal: true

module Pangea
  module Architectures
    module Base
      class ArchitectureReference
        # Cost estimation
        module Cost
          def cost_breakdown
            component_costs = components.transform_values do |component|
              component.respond_to?(:estimated_monthly_cost) ? component.estimated_monthly_cost : 0.0
            end

            resource_costs = resources.transform_values do |resource|
              resource.respond_to?(:estimated_monthly_cost) ? resource.estimated_monthly_cost : 0.0
            end

            total = component_costs.values.sum + resource_costs.values.sum

            { components: component_costs, resources: resource_costs, total: total }
          end

          def estimated_monthly_cost
            cost_breakdown[:total]
          end
        end
      end
    end
  end
end
