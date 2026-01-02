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
  module Resources
    # Composite reference for VPC with subnets
    class CompositeVpcReference
      attr_accessor :vpc, :internet_gateway, :public_route_table
      attr_reader :name_prefix, :public_subnets, :private_subnets, :nat_gateways, :private_route_tables

      def initialize(name_prefix)
        @name_prefix = name_prefix
        @public_subnets = []
        @private_subnets = []
        @nat_gateways = []
        @private_route_tables = []
      end

      # Helper methods for accessing subnet collections
      def public_subnet_ids
        @public_subnets.map(&:id)
      end

      def private_subnet_ids
        @private_subnets.map(&:id)
      end

      def all_subnet_ids
        public_subnet_ids + private_subnet_ids
      end

      # Access subnets by AZ
      def public_subnet_in_az(az)
        @public_subnets.find { |subnet| subnet.resource_attributes[:availability_zone] == az }
      end

      def private_subnet_in_az(az)
        @private_subnets.find { |subnet| subnet.resource_attributes[:availability_zone] == az }
      end

      # Get all resources for tracking
      def all_resources
        resources = []
        resources << @vpc if @vpc
        resources << @internet_gateway if @internet_gateway
        resources << @public_route_table if @public_route_table
        resources.concat(@public_subnets)
        resources.concat(@private_subnets)
        resources.concat(@nat_gateways)
        resources.concat(@private_route_tables)
        resources
      end

      # Resource counts
      def availability_zone_count
        @public_subnets.length
      end
    end
  end
end
