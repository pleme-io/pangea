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