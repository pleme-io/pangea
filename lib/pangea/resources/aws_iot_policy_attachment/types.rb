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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    # AWS IoT Policy Attachment Types
    # 
    # Policy attachments bind IoT policies to principals (certificates) or other resources,
    # defining what actions devices can perform when they connect to AWS IoT Core.
    # This is essential for implementing principle of least privilege in IoT deployments.
    module AwsIotPolicyAttachmentTypes
      # Main attributes for IoT policy attachment resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the IoT policy to attach
        attribute :policy, Resources::Types::String

        # ARN of the target (certificate, thing group, or other principal)
        attribute :target, Resources::Types::String
      end

      # Output attributes from policy attachment resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The attachment ID (combination of policy and target)
        attribute :id, Resources::Types::String

        # The name of the attached policy
        attribute :policy, Resources::Types::String

        # The ARN of the target
        attribute :target, Resources::Types::String
      end
    end
  end
end