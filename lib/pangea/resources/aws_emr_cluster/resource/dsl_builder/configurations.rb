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
    module AWS
      module EmrCluster
        class DSLBuilder
          # Configuration building methods for EMR clusters
          module Configurations
            def build_applications(ctx)
              return unless attrs.applications.any?

              attrs.applications.each do |app|
                ctx.applications app
              end
            end

            def build_configurations(ctx)
              attrs.configurations.each do |config|
                build_single_configuration(ctx, config)
              end
            end

            private

            def build_single_configuration(ctx, config)
              builder = self
              ctx.configurations do
                classification config[:classification]
                builder.send(:build_nested_configurations, self, config[:configurations])
                builder.send(:build_properties, self, config[:properties])
              end
            end

            def build_nested_configurations(ctx, configurations)
              return unless configurations

              builder = self
              configurations.each do |sub_config|
                ctx.configurations do
                  classification sub_config[:classification] if sub_config[:classification]
                  builder.send(:build_properties, self, sub_config[:properties])
                end
              end
            end

            def build_properties(ctx, properties)
              return unless properties&.any?

              ctx.properties do
                properties.each do |key, value|
                  public_send(key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, value)
                end
              end
            end
          end
        end
      end
    end
  end
end
