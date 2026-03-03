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

# lib/pangea/utilities/visualization.rb
module Pangea
  module Utilities
    module Visualization
      autoload :Graph, 'pangea/utilities/visualization/graph'
      autoload :DependencyGraph, 'pangea/utilities/visualization/dependency_graph'
      autoload :MermaidExporter, 'pangea/utilities/visualization/mermaid_exporter'
      
      def self.generate_graph(template_name, namespace = nil)
        DependencyGraph.new(template_name, namespace).generate
      end
    end
  end
end