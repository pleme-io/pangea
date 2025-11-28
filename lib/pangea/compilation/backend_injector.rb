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
  module Compilation
    # Handles backend configuration injection
    module BackendInjector
      # Inject backend configuration for a template
      def inject_backend_config(template_name)
        return unless @namespace && defined?(Pangea.config)

        begin
          namespace_entity = Pangea.config.namespace(@namespace)
        rescue => e
          @logger&.error("Failed to load namespace", namespace: @namespace, error: e.message) if defined?(@logger)
          return
        end

        unless namespace_entity
          @logger&.warn("Namespace not found", namespace: @namespace) if defined?(@logger)
          return
        end

        begin
          backend_config = prepare_backend_config(namespace_entity, template_name)
        rescue => e
          @logger&.error("Failed to prepare backend config", error: e.message, namespace: @namespace) if defined?(@logger)
          raise
        end

        @synthesizer.synthesize do
          terraform { backend(backend_config) }
        end
      end
      
      private
      
      # Prepare backend configuration for specific template
      def prepare_backend_config(namespace_entity, template_name)
        config = namespace_entity.to_terraform_backend

        case config.keys.first
        when :s3
          base_key = config[:s3][:key]
          if base_key.nil? || base_key.empty?
            raise "S3 backend key is nil or empty for namespace. Check your pangea.yml configuration."
          end
          config[:s3][:key] = "#{base_key}/#{template_name}/terraform.tfstate"
        when :local
          config[:local][:path] = "#{template_name}.tfstate"
        end

        config
      end
    end
  end
end