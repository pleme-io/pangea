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

module Pangea
  module Architectures
    module Types
      # Common architecture configuration types
      Environment = String.enum('development', 'staging', 'production')

      Region = String.constrained(
        format: /^[a-z]{2}-[a-z]+-[0-9]$/
      )

      AvailabilityZone = String.constrained(
        format: /^[a-z]{2}-[a-z]+-[0-9][a-z]$/
      )

      DomainName = String.constrained(
        format: /^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$/
      )

      InstanceType = String.constrained(
        format: /^[a-z]+[0-9]+[a-z]*\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$/
      )

      # Database configuration types
      DatabaseEngine = String.enum(
        'mysql', 'postgresql', 'mariadb', 'aurora', 'aurora-mysql', 'aurora-postgresql'
      )

      DatabaseInstanceClass = String.constrained(
        format: /^db\.[a-z]+[0-9]+[a-z]*\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$/
      )

      # Traffic routing policies
      RoutingPolicy = String.enum('latency', 'geolocation', 'geoproximity', 'failover', 'weighted')

      # Consistency models for distributed systems
      ConsistencyModel = String.enum('strong', 'eventual', 'bounded_staleness', 'session')

      # Common tag structure
      Tags = Hash.map(Symbol, String)
    end
  end
end
