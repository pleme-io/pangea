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
require 'pangea/validation/validators/aws_network_validators'
require 'pangea/validation/validators/aws_compute_validators'
require 'pangea/validation/validators/aws_database_validators'

module Pangea
  module Validation
    # Main entry point for resource validation
    module ResourceValidator
      # Re-export the Registry for backward compatibility
      Registry = BaseValidator::Registry
      
      # Re-export validators under the Validation namespace for backward compatibility
      VpcValidator = Validators::VpcValidator
      SubnetValidator = Validators::SubnetValidator
      SecurityGroupValidator = Validators::SecurityGroupValidator
      InstanceValidator = Validators::InstanceValidator
      DbInstanceValidator = Validators::DbInstanceValidator
    end
  end
end