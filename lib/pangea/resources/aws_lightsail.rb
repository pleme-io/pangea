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

require_relative 'aws_lightsail/compute'
require_relative 'aws_lightsail/storage'
require_relative 'aws_lightsail/networking'
require_relative 'aws_lightsail/load_balancer'
require_relative 'aws_lightsail/database'

module Pangea
  module Resources
    module AWS
      # AWS Lightsail - Simple virtual private servers and containers
      # Lightsail provides easy-to-use cloud platform that offers everything
      # needed to build an application or website

      include Lightsail::Compute
      include Lightsail::Storage
      include Lightsail::Networking
      include Lightsail::LoadBalancer
      include Lightsail::Database

      private

      def validate_required_attrs!(required_attrs, attrs)
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless attrs.key?(attr)
        end
      end
    end
  end
end
