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


require 'pangea/resources/aws/cloudformation/stack_set'
require 'pangea/resources/aws/cloudformation/stack_set_instance'
require 'pangea/resources/aws/cloudformation/stack_instances'
require 'pangea/resources/aws/cloudformation/type'
require 'pangea/resources/aws/cloudformation/type_activation'
require 'pangea/resources/aws/cloudformation/publisher'
require 'pangea/resources/aws/cloudformation/public_type_version'
require 'pangea/resources/aws/cloudformation/resource_version'
require 'pangea/resources/aws/cloudformation/resource_default_version'
require 'pangea/resources/aws/cloudformation/hook_default_version'

module Pangea
  module Resources
    module AWS
      # AWS CloudFormation resources module
      # Provides advanced CloudFormation resource management including stack sets,
      # type registration, and resource versioning for enterprise-scale deployments.
      module CloudFormation
        include StackSet
        include StackSetInstance
        include StackInstances
        include Type
        include TypeActivation
        include Publisher
        include PublicTypeVersion
        include ResourceVersion
        include ResourceDefaultVersion
        include HookDefaultVersion
      end
    end
  end
end