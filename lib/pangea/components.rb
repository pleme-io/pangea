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


require 'pangea/components/base'
require 'pangea/components/types'

require 'pangea/components/secure_vpc/component'
require 'pangea/components/public_private_subnets/component'
require 'pangea/components/vpc_with_subnets/component'

module Pangea
  module Components
    include SecureVpc
    include PublicPrivateSubnets
    include VpcWithSubnets
  end
end