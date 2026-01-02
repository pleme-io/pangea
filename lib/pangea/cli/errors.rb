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
  module CLI
    # Base error class for all Pangea CLI errors
    class PangeaError < StandardError; end

    # Raised when template compilation fails
    class CompilationError < PangeaError; end

    # Raised when Terraform execution fails
    class TerraformError < PangeaError
      attr_accessor :phase, :output

      def initialize(message, phase: nil, output: nil)
        super(message)
        @phase = phase
        @output = output
      end
    end

    # Raised when network operations fail
    class NetworkError < PangeaError
      attr_accessor :service, :timeout

      def initialize(message, service: nil, timeout: nil)
        super(message)
        @service = service
        @timeout = timeout
      end
    end

    # Raised when validation fails
    class ValidationError < PangeaError
      attr_accessor :field, :value

      def initialize(message, field: nil, value: nil)
        super(message)
        @field = field
        @value = value
      end
    end
  end
end
