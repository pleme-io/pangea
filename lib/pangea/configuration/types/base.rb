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

require 'dry-types'

module Pangea
  module ConfigurationTypes
    module Types
      include Dry.Types()

      # Base types
      PathString = Types::String.constrained(min_size: 1)
      BinaryPath = Types::String.constrained(format: /\A[\w\-\.\/]+\z/)
      BucketName = Types::String.constrained(format: /\A[a-z0-9][a-z0-9\-\.]*[a-z0-9]\z/)
      AwsRegion = Types::String.constrained(format: /\A[a-z]{2}-[a-z]+-\d+\z/)

      # State backend types
      StateType = Types::Symbol.enum(:local, :s3, :azurerm, :gcs, :consul, :etcd)
    end
  end
end
