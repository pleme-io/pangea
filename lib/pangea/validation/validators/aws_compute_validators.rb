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

require 'pangea/validation/base_validator'

module Pangea
  module Validation
    module Validators
      # EC2 Instance Validator
      InstanceValidator = BaseValidator.for_resource(:aws_instance) do
        params do
          required(:ami).filled(:string)
          required(:instance_type).filled(:string)
          optional(:key_name).filled(:string)
          optional(:subnet_id).filled(:string)
          optional(:vpc_security_group_ids).array(:string)
          optional(:associate_public_ip_address).filled(:bool)
          optional(:user_data).filled(:string)
          optional(:tags).hash
          optional(:root_block_device).hash do
            optional(:volume_type).filled(:string)
            optional(:volume_size).filled(:integer)
            optional(:delete_on_termination).filled(:bool)
            optional(:encrypted).filled(:bool)
          end
        end
        
        rule(:ami) do
          unless value.match?(/^ami-[0-9a-f]{8,17}$/)
            key.failure('must be a valid AMI ID (e.g., ami-12345678)')
          end
        end
        
        rule(:instance_type) do
          unless valid_instance_type?(value)
            key.failure('must be a valid EC2 instance type (e.g., t3.micro)')
          end
        end
        
        rule(:root_block_device) do
          if value
            if value[:volume_type] && !%w[gp2 gp3 io1 io2 st1 sc1 standard].include?(value[:volume_type])
              key.failure('volume_type must be one of: gp2, gp3, io1, io2, st1, sc1, standard')
            end
            
            if value[:volume_size] && (value[:volume_size] < 1 || value[:volume_size] > 64000)
              key.failure('volume_size must be between 1 and 64000 GB')
            end
          end
        end
      end
    end
  end
end