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


require 'pangea/types'

module Pangea
  module Backends
    # Abstract base class for state backends
    class Base
      attr_reader :config
      
      def initialize(config = {})
        @config = config
        validate_config!
      end
      
      # Initialize the backend (create resources if needed)
      def initialize!
        raise NotImplementedError, "#{self.class} must implement #initialize!"
      end
      
      # Check if backend is properly configured
      def configured?
        raise NotImplementedError, "#{self.class} must implement #configured?"
      end
      
      # Lock state for exclusive access
      def lock(lock_id:, info: {})
        raise NotImplementedError, "#{self.class} must implement #lock"
      end
      
      # Unlock state
      def unlock(lock_id:)
        raise NotImplementedError, "#{self.class} must implement #unlock"
      end
      
      # Check if state is locked
      def locked?
        raise NotImplementedError, "#{self.class} must implement #locked?"
      end
      
      # Get lock info
      def lock_info
        raise NotImplementedError, "#{self.class} must implement #lock_info"
      end
      
      # Convert to Terraform backend configuration
      def to_terraform_config
        raise NotImplementedError, "#{self.class} must implement #to_terraform_config"
      end
      
      # Get backend type
      def type
        self.class.name.split('::').last.downcase
      end
      
      protected
      
      def validate_config!
        # Override in subclasses for specific validation
      end
    end
  end
end