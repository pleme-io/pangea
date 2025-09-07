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