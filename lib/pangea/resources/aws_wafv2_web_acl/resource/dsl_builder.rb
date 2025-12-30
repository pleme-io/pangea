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

require_relative 'dsl_builder/default_action'
require_relative 'dsl_builder/rules'
require_relative 'dsl_builder/statements'
require_relative 'dsl_builder/field_to_match'

module Pangea
  module Resources
    module AWS
      module WafV2WebAcl
        # DSL Builder for WAF v2 Web ACL resource
        class DSLBuilder
          include DefaultAction
          include Rules
          include Statements
          include FieldToMatch

          attr_reader :attrs

          def initialize(web_acl_attrs)
            @attrs = web_acl_attrs
          end
        end
      end
    end
  end
end
