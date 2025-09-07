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

# lib/pangea/utilities/remote_state/reference.rb
module Pangea
  module Utilities
    module RemoteState
      class Reference
        attr_reader :namespace, :template, :output
        
        def initialize(namespace, template, output)
          @namespace = namespace.to_s
          @template = template.to_s
          @output = output.to_s
          validate!
        end
        
        def to_terraform
          data_source_name = "#{@template}_state"
          
          {
            data: {
              terraform_remote_state: {
                data_source_name => {
                  backend: backend_type,
                  config: backend_config
                }
              }
            },
            reference: "${data.terraform_remote_state.#{data_source_name}.outputs.#{@output}}"
          }
        end
        
        def data_source_name
          "#{@template}_state"
        end
        
        def reference_string
          "${data.terraform_remote_state.#{data_source_name}.outputs.#{@output}}"
        end
        
        private
        
        def validate!
          raise ArgumentError, "Namespace cannot be empty" if @namespace.empty?
          raise ArgumentError, "Template cannot be empty" if @template.empty?
          raise ArgumentError, "Output cannot be empty" if @output.empty?
        end
        
        def backend_type
          # TODO: Read from pangea.yaml configuration
          "s3"
        end
        
        def backend_config
          # TODO: Read from pangea.yaml and adjust for template
          {
            bucket: "terraform-state-#{@namespace}",
            key: "pangea/#{@namespace}/#{@template}/terraform.tfstate",
            region: "us-east-1"
          }
        end
      end
    end
  end
end