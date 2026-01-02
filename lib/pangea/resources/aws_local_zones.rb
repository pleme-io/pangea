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

# AWS Local Zones - Run latency-sensitive applications closer to end users
# Local Zones provide single-digit millisecond latency to end users by bringing
# AWS compute, storage, database, and other services closer to large population centers
#
# This module is split into:
# - data_sources.rb: Query methods for local gateways and route tables
# - resources.rb: Resource methods for routes and VPC associations

require_relative 'aws_local_zones/data_sources'
require_relative 'aws_local_zones/resources'
