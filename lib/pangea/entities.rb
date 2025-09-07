# frozen_string_literal: true
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


require 'pangea/types'
require 'pangea/entities/namespace'
require 'pangea/entities/project'
require 'pangea/entities/module_definition'
require 'pangea/entities/template'

module Pangea
  # Domain entities for Pangea
  module Entities
    # Custom error for validation failures
    class ValidationError < StandardError; end
  end
end