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
  class Configuration
    # Handles default configuration values and environment variable overrides
    module Defaults
      DEFAULT_CONFIG = {
        namespaces: {},
        modules: { path: 'modules' },
        cache: { directory: -> { File.join(Dir.home, '.pangea', 'cache') } },
        terraform: { binary: -> { ENV['TERRAFORM_BIN'] || 'tofu' } }
      }.freeze

      ENV_OVERRIDES = {
        'PANGEA_NAMESPACE' => [:default_namespace],
        'TERRAFORM_BIN' => [:terraform, :binary],
        'PANGEA_CACHE_DIR' => [:cache, :directory]
      }.freeze

      private

      def set_defaults
        DEFAULT_CONFIG.each do |key, value|
          set_config_value(key, value)
        end
      end

      def set_config_value(key, value)
        if value.is_a?(Hash)
          value.each { |k, v| @config.set(key, k, value: v.is_a?(Proc) ? v.call : v) }
        else
          @config.set(key, value: value.is_a?(Proc) ? value.call : value)
        end
      end

      def set_from_env
        ENV_OVERRIDES.each do |env_var, config_path|
          value = ENV[env_var]
          @config.set(*config_path, value: value) if value
        end
      end
    end
  end
end
