#!/usr/bin/env ruby

require_relative '../lib/pangea/compilation/template_compiler'

puts 'Testing separate template workspaces...'

# Mock config to avoid dependency issues
module Pangea
  def self.config; nil; end
end

# Test 1: Multiple templates (should show template count but no combined JSON)
puts '=== Test 1: Multiple templates ==='
compiler = Pangea::Compilation::TemplateCompiler.new(namespace: 'development')
result = compiler.compile_file('simple_infrastructure.rb')

if result.success
  puts "✅ Multiple templates found: #{result.template_count}"
  puts "Template info: #{result.template_name}"
  no_json = result.terraform_json.nil?
  puts "Combined JSON: #{no_json ? 'None (separate workspaces)' : 'Present'}"
else
  puts "❌ Error: #{result.errors.join(', ')}"
end

# Test 2: Single specific template (should have JSON for that workspace)
puts ''
puts '=== Test 2: Single template workspace ==='
single_compiler = Pangea::Compilation::TemplateCompiler.new(
  namespace: 'development',
  template_name: 'local_resources'
)
single_result = single_compiler.compile_file('simple_infrastructure.rb')

if single_result.success
  puts "✅ Single template: #{single_result.template_name}"
  has_json = single_result.terraform_json != nil
  puts "Has JSON for workspace: #{has_json}"
  json_length = single_result.terraform_json ? single_result.terraform_json.length : 0
  puts "JSON length: #{json_length} chars"
  
  if single_result.terraform_json
    File.write('workspace_local_resources.tf.json', single_result.terraform_json)
    puts '✅ Saved workspace JSON to workspace_local_resources.tf.json'
  end
else
  puts "❌ Error: #{single_result.errors.join(', ')}"
end