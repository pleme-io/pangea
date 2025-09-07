# lib/pangea/utilities/cost.rb
module Pangea
  module Utilities
    module Cost
      autoload :Calculator, 'pangea/utilities/cost/calculator'
      autoload :Optimizer, 'pangea/utilities/cost/optimizer'
      autoload :Report, 'pangea/utilities/cost/report'
      autoload :ResourcePricing, 'pangea/utilities/cost/resource_pricing'
      
      def self.calculate(template_name, namespace = nil)
        Calculator.new.calculate_template_cost(template_name, namespace)
      end
    end
  end
end