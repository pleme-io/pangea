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

# lib/pangea/utilities/remote_state.rb
module Pangea
  module Utilities
    module RemoteState
      autoload :Reference, 'pangea/utilities/remote_state/reference'
      autoload :DependencyManager, 'pangea/utilities/remote_state/dependency_manager'
      autoload :OutputRegistry, 'pangea/utilities/remote_state/output_registry'
      
      def self.reference(namespace, template, output)
        Reference.new(namespace, template, output)
      end
    end
  end
end