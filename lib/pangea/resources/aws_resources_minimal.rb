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


# Minimal AWS resources for networking template
require 'pangea/resources/base'
require 'pangea/resources/aws_vpc/resource'
require 'pangea/resources/aws_subnet/resource'
require 'pangea/resources/aws_route_table/resource'
require 'pangea/resources/aws_route_table_association/resource'
require 'pangea/resources/aws_s3_bucket/resource'

module Pangea
  module Resources
    # AWS resource functions module with minimal required resources
    module AWS
      include Base
    end
  end
end