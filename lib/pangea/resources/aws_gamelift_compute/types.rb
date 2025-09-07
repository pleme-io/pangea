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


require "dry-struct"

module Pangea
  module Resources
    module AwsGameliftCompute
      module Types
        include Dry::Types()

        class Attributes < Dry::Struct
          attribute :compute_name, String
          attribute :fleet_id, String
          attribute? :ip_address, String
          attribute? :dns_name, String
          attribute? :compute_arn, String
          attribute? :certificate_path, String
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :compute_name, String
          attribute :compute_arn, String
          attribute :fleet_id, String
          attribute :fleet_arn, String
          attribute :ip_address, String
          attribute :dns_name, String
          attribute :compute_status, String
          attribute :location, String
          attribute :creation_time, String
          attribute :operating_system, String
          attribute :type, String
        end
      end
    end
  end
end