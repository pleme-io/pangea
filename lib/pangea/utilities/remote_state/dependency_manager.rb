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

# lib/pangea/utilities/remote_state/dependency_manager.rb
require 'tsort'
require 'set'

module Pangea
  module Utilities
    module RemoteState
      class DependencyManager
        def initialize
          @dependencies = {}
          @templates = Set.new
        end
        
        def add_dependency(source_template, target_template, outputs = [])
          @templates.add(source_template.to_s)
          @templates.add(target_template.to_s)
          
          @dependencies[source_template.to_s] ||= {}
          @dependencies[source_template.to_s][target_template.to_s] = {
            outputs: Array(outputs).map(&:to_s),
            added_at: Time.now
          }
        end
        
        def get_execution_order(templates = nil)
          templates ||= @templates.to_a
          
          # Create a temporary graph for topological sorting
          graph = {}
          templates.each do |template|
            # Dependencies point FROM source TO target, but for execution order
            # we need to reverse this - targets must execute before sources
            dependents = []
            @dependencies.each do |source, targets|
              if targets.key?(template) && templates.include?(source)
                dependents << source
              end
            end
            graph[template] = dependents
          end
          
          # Use instance method version of tsort
          sorted = tsort_each_node(graph.keys) { |node|
            graph[node] || []
          }.to_a
          
          sorted
        end
        
        private
        
        def tsort_each_node(nodes, &block)
          TSort.tsort_each(
            -> (&b) { nodes.each(&b) },
            -> (n, &b) { yield(n).each(&b) }
          )
        end
        
        def depends_on?(source, target)
          return false unless @dependencies[source.to_s]
          @dependencies[source.to_s].key?(target.to_s)
        end
        
        def get_dependencies(template)
          @dependencies[template.to_s]&.keys || []
        end
        
        def get_dependents(template)
          dependents = []
          @dependencies.each do |source, targets|
            dependents << source if targets.key?(template.to_s)
          end
          dependents
        end
        
        def to_h
          {
            templates: @templates.to_a,
            dependencies: @dependencies
          }
        end
      end
    end
  end
end