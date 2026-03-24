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

require 'open3'

module Pangea
  module AWS
    # Validates AWS SSO session is active for a given profile.
    module SSOValidator
      # Check that the AWS SSO session is valid for the given profile.
      #
      # @param profile [String] AWS profile name
      # @return [Boolean] true if session is valid
      def self.validate!(profile)
        return true if profile.nil?

        cmd = ['aws', 'sts', 'get-caller-identity', '--profile', profile]
        _stdout, _stderr, status = Open3.capture3(*cmd)

        return true if status.success?

        raise SSOSessionExpired, profile
      end

      # Set AWS_PROFILE environment variable for child processes.
      #
      # @param profile [String] AWS profile name
      # @return [void]
      def self.configure_environment!(profile)
        return if profile.nil?

        ENV['AWS_PROFILE'] = profile
      end
    end

    class SSOSessionExpired < StandardError
      def initialize(profile)
        super(
          "AWS SSO session expired for profile '#{profile}'. Run:\n\n" \
          "  aws sso login --profile #{profile}\n"
        )
      end
    end
  end
end
