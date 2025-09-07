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

# lib/pangea/utilities.rb
require 'json'
require 'digest'
require 'fileutils'

module Pangea
  module Utilities
    class UtilityError < StandardError; end
    
    # Autoload utilities
    autoload :RemoteState, 'pangea/utilities/remote_state'
    autoload :Drift, 'pangea/utilities/drift'
    autoload :Cost, 'pangea/utilities/cost'
    autoload :Visualization, 'pangea/utilities/visualization'
    autoload :Analysis, 'pangea/utilities/analysis'
    autoload :Validation, 'pangea/utilities/validation'
    autoload :Backup, 'pangea/utilities/backup'
    autoload :Migration, 'pangea/utilities/migration'
    autoload :Monitoring, 'pangea/utilities/monitoring'
    
    def self.version
      "1.0.0"
    end
  end
end