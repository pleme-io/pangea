#!/usr/bin/env ruby

require_relative '../lib/pangea/compilation/template_compiler'

puts "Testing multiple template workspaces..."

# Mock config to avoid dependency issues
module Pangea
  def self.config; nil; end
end

file_path = 'multi_template_infrastructure.rb'

# Test 1: Detect all templates
puts "=== Test 1: Detect All Templates ==="
compiler = Pangea::Compilation::TemplateCompiler.new(namespace: 'development')
result = compiler.compile_file(file_path)

if result.success
  puts "✅ Found #{result.template_count} templates"
  puts "Templates: #{result.template_name}"
  puts "Each template will be a separate workspace with separate plan/apply"
else
  puts "❌ Error: #{result.errors.join(', ')}"
end

# Test 2: Compile each template individually (simulating separate workspaces)
templates = ['networking', 'compute', 'storage']
workspace_results = {}

puts "\n=== Test 2: Individual Template Workspaces ==="
templates.each do |template_name|
  puts "\n--- Workspace: #{template_name} ---"
  
  template_compiler = Pangea::Compilation::TemplateCompiler.new(
    namespace: 'development',
    template_name: template_name
  )
  
  template_result = template_compiler.compile_file(file_path)
  
  if template_result.success
    puts "✅ Template: #{template_result.template_name}"
    puts "JSON length: #{template_result.terraform_json.length} chars"
    
    # Save to workspace-specific file
    workspace_file = "workspace_#{template_name}.tf.json"
    File.write(workspace_file, template_result.terraform_json)
    puts "📁 Saved to: #{workspace_file}"
    
    # Count resources in this workspace
    json_data = JSON.parse(template_result.terraform_json)
    resource_count = json_data['resource']&.values&.map(&:size)&.sum || 0
    output_count = json_data['output']&.size || 0
    
    puts "📊 Resources: #{resource_count}, Outputs: #{output_count}"
    workspace_results[template_name] = {
      resources: resource_count,
      outputs: output_count,
      json_size: template_result.terraform_json.length
    }
  else
    puts "❌ Error: #{template_result.errors.join(', ')}"
  end
end

# Test 3: Summary
puts "\n=== Test 3: Workspace Summary ==="
puts "Total workspaces created: #{workspace_results.size}"
workspace_results.each do |workspace, stats|
  puts "#{workspace}: #{stats[:resources]} resources, #{stats[:outputs]} outputs (#{stats[:json_size]} chars)"
end

total_resources = workspace_results.values.map { |s| s[:resources] }.sum
total_outputs = workspace_results.values.map { |s| s[:outputs] }.sum
puts "\nOverall: #{total_resources} total resources, #{total_outputs} total outputs across #{workspace_results.size} separate workspaces"