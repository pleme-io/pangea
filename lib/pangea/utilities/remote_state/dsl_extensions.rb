# lib/pangea/utilities/remote_state/dsl_extensions.rb
module Pangea
  module Utilities
    module RemoteState
      module DSLExtensions
        def remote_state(template_name, &block)
          @remote_states ||= {}
          
          if block_given?
            config = RemoteStateConfig.new(template_name)
            config.instance_eval(&block)
            @remote_states[template_name] = config
            
            # Inject data source into synthesis
            inject_remote_state_data_source(template_name, config)
          else
            @remote_states[template_name]
          end
        end
        
        def remote_state_ref(template_name, output_name, *path)
          remote_state_config = @remote_states[template_name]
          raise "Remote state '#{template_name}' not declared" unless remote_state_config
          
          unless remote_state_config.outputs.include?(output_name)
            raise "Output '#{output_name}' not declared in remote_state :#{template_name}"
          end
          
          ref_string = "${data.terraform_remote_state.#{template_name}_state.outputs.#{output_name}}"
          
          # Handle nested path access (for lists/maps)
          if path.any?
            path.each do |segment|
              ref_string += case segment
              when Integer
                "[#{segment}]"
              when String, Symbol
                ".#{segment}"
              else
                raise "Invalid path segment: #{segment}"
              end
            end
          end
          
          ref_string
        end
        
        private
        
        def inject_remote_state_data_source(template_name, config)
          # This will be injected during synthesis
          data :terraform_remote_state, "#{template_name}_state" do
            backend config.backend_type
            config.backend_config.each do |key, value|
              send(key, value)
            end
          end
        end
        
        class RemoteStateConfig
          attr_reader :template_name, :outputs, :namespace
          
          def initialize(template_name)
            @template_name = template_name
            @outputs = []
            @namespace = nil
          end
          
          def outputs(*output_names)
            @outputs.concat(output_names.flatten.map(&:to_sym))
            @outputs.uniq!
          end
          
          def from_namespace(ns)
            @namespace = ns.to_s
          end
          
          def backend_type
            # TODO: Read from configuration
            "s3"
          end
          
          def backend_config
            # TODO: Read from configuration and build proper path
            {
              bucket: "terraform-state",
              key: "pangea/#{@namespace || 'default'}/#{@template_name}/terraform.tfstate",
              region: "us-east-1"
            }
          end
        end
      end
    end
  end
end