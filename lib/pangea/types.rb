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

# Domain types are loaded from pangea-core via require 'pangea-core'.
# AWS-specific types (AWSTypes, ComputedTypes) are loaded from pangea-aws.
# This file adds pangea-specific types on top of the core type system.

module Pangea
  module Types
    # Registry-based type system for enhanced validation.
    # AWSTypes and ComputedTypes are registered when pangea-aws is loaded.
    def self.registry
      @registry ||= begin
        r = Registry.instance
        BaseTypes.register_all(r)
        AWSTypes.register_all(r) if defined?(AWSTypes)
        ComputedTypes.register_all(r) if defined?(ComputedTypes)
        r
      end
    end

    def self.[](name)
      registry[name]
    end

    # AWS-specific types (kept here for backward compatibility with pangea config)
    AwsRegion = Strict::String.enum(
      'us-east-1', 'us-east-2',
      'us-west-1', 'us-west-2',
      'eu-west-1', 'eu-west-2', 'eu-west-3',
      'eu-central-1', 'eu-north-1',
      'ap-southeast-1', 'ap-southeast-2',
      'ap-northeast-1', 'ap-northeast-2', 'ap-northeast-3',
      'ap-south-1', 'ap-east-1',
      'ca-central-1',
      'sa-east-1'
    )

    S3BucketName = Strict::String.constrained(
      format: /\A[a-z0-9][a-z0-9.-]*[a-z0-9]\z/,
      min_size: 3,
      max_size: 63
    )

    DynamoTableName = Strict::String.constrained(
      format: /\A[a-zA-Z0-9_.-]+\z/,
      min_size: 3,
      max_size: 255
    )
  end
end
