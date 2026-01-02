# frozen_string_literal: true

module Pangea
  module CLI
    module Commands
      module Agent
        # Dependency analysis
        module Dependencies
          def analyze_dependencies(file, template: nil, namespace: nil)
            return { error: 'File required' } unless file

            compiler = Compilation::TemplateCompiler.new
            templates = compiler.extract_templates(file)

            all_deps = { internal: {}, external: {}, graph: [] }

            templates.each do |t|
              deps = extract_dependencies(t[:content])

              deps[:internal_refs].each do |ref|
                all_deps[:graph] << {
                  from: t[:name],
                  to: ref[:name],
                  type: 'resource_ref',
                  attribute: ref[:attribute]
                }
              end

              all_deps[:internal][t[:name]] = deps
            end

            all_deps
          end

          def extract_dependencies(content)
            deps = {
              internal_refs: [],
              data_refs: [],
              module_refs: [],
              remote_state_refs: []
            }

            content.scan(/ref\(:(\w+),\s*:(\w+),\s*:(\w+)\)/) do |type, name, attr|
              deps[:internal_refs] << { type: type, name: name, attribute: attr }
            end

            content.scan(/data\.(\w+)\.(\w+)\.(\w+)/) do |type, name, attr|
              deps[:data_refs] << { type: type, name: name, attribute: attr }
            end

            content.scan(/module\.(\w+)\.(\w+)/) do |name, output|
              deps[:module_refs] << { module: name, output: output }
            end

            content.scan(/remote_state\(:(\w+)\)/) do |name|
              deps[:remote_state_refs] << { name: name[0] }
            end

            deps
          end
        end
      end
    end
  end
end
