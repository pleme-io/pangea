#!/usr/bin/env ruby
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


require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'
require 'yaml'

# Analyzer for Terraform AWS Provider documentation
class TerraformDocsAnalyzer
  BASE_URL = 'https://registry.terraform.io/providers/hashicorp/aws/latest/docs'
  
  attr_reader :resource_name, :options

  def initialize(resource_name, options = {})
    @resource_name = resource_name
    @options = options
  end

  def analyze!
    puts "📚 Analyzing Terraform documentation for #{resource_name}..."
    
    doc_url = "#{BASE_URL}/resources/#{resource_name.gsub('aws_', '')}"
    puts "🔗 Fetching: #{doc_url}"
    
    begin
      html = fetch_documentation(doc_url)
      data = parse_documentation(html)
      
      if options[:output]
        save_analysis(data)
      else
        display_analysis(data)
      end
      
      data
    rescue => e
      puts "❌ Error: #{e.message}"
      nil
    end
  end

  private

  def fetch_documentation(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      response.body
    else
      raise "Failed to fetch documentation (HTTP #{response.code})"
    end
  end

  def parse_documentation(html)
    doc = Nokogiri::HTML(html)
    
    {
      resource_name: resource_name,
      description: extract_description(doc),
      arguments: extract_arguments(doc),
      attributes: extract_attributes(doc),
      examples: extract_examples(doc),
      import_syntax: extract_import_syntax(doc)
    }
  end

  def extract_description(doc)
    # Try to find the main description
    desc_elem = doc.css('div.markdown-body > p').first
    desc_elem ? desc_elem.text.strip : "No description found"
  end

  def extract_arguments(doc)
    arguments = {}
    
    # Find the Arguments Reference section
    args_section = doc.css('h2').find { |h| h.text =~ /Argument Reference/i }
    return arguments unless args_section
    
    current = args_section.next_element
    while current && !current.name.start_with?('h')
      if current.name == 'ul'
        current.css('li').each do |li|
          parse_argument(li.text, arguments)
        end
      end
      current = current.next_element
    end
    
    arguments
  end

  def parse_argument(text, arguments)
    # Parse argument text like "name - (Required) The name of the resource"
    if text =~ /^`?(\w+)`?\s*-\s*\((\w+)\)\s*(.+)$/
      name = $1
      requirement = $2
      description = $3
      
      arguments[name] = {
        required: requirement.downcase == 'required',
        description: description.strip,
        type: infer_type_from_description(description)
      }
    end
  end

  def extract_attributes(doc)
    attributes = {}
    
    # Find the Attributes Reference section
    attrs_section = doc.css('h2').find { |h| h.text =~ /Attributes Reference/i }
    return attributes unless attrs_section
    
    current = attrs_section.next_element
    while current && !current.name.start_with?('h')
      if current.name == 'ul'
        current.css('li').each do |li|
          if li.text =~ /^`?(\w+)`?\s*-\s*(.+)$/
            attributes[$1] = $2.strip
          end
        end
      end
      current = current.next_element
    end
    
    attributes
  end

  def extract_examples(doc)
    examples = []
    
    # Find code blocks that look like HCL
    doc.css('pre code').each do |code|
      text = code.text.strip
      if text.include?('resource') && text.include?(resource_name)
        examples << text
      end
    end
    
    examples
  end

  def extract_import_syntax(doc)
    # Find the Import section
    import_section = doc.css('h2').find { |h| h.text =~ /Import/i }
    return nil unless import_section
    
    current = import_section.next_element
    while current && !current.name.start_with?('h')
      if current.name == 'pre'
        return current.text.strip
      end
      current = current.next_element
    end
    
    nil
  end

  def infer_type_from_description(description)
    case description.downcase
    when /list of/i, /array/i
      'Array'
    when /map/i, /object/i, /block/i
      'Hash'
    when /number/i, /integer/i, /count/i
      'Integer'
    when /boolean/i, /true.*false/i
      'Boolean'
    else
      'String'
    end
  end

  def display_analysis(data)
    puts "\n📋 Resource: #{data[:resource_name]}"
    puts "📝 Description: #{data[:description]}"
    
    puts "\n🔧 Arguments:"
    data[:arguments].each do |name, details|
      req = details[:required] ? 'Required' : 'Optional'
      puts "  - #{name} (#{req}, #{details[:type]}): #{details[:description]}"
    end
    
    puts "\n📤 Attributes:"
    data[:attributes].each do |name, description|
      puts "  - #{name}: #{description}"
    end
    
    if data[:import_syntax]
      puts "\n📥 Import Syntax:"
      puts "  #{data[:import_syntax]}"
    end
    
    if data[:examples].any?
      puts "\n💡 Example Usage:"
      puts data[:examples].first
    end
  end

  def save_analysis(data)
    filename = "#{resource_name}_analysis.yaml"
    File.write(filename, data.to_yaml)
    puts "✅ Analysis saved to: #{filename}"
  end
end

# Generate enhanced resource implementation from analysis
class EnhancedResourceGenerator
  def self.generate_from_analysis(analysis_file)
    data = YAML.load_file(analysis_file)
    
    # Generate enhanced types.rb content
    types_content = generate_types_from_analysis(data)
    
    # Generate enhanced resource.rb content
    resource_content = generate_resource_from_analysis(data)
    
    {
      types: types_content,
      resource: resource_content,
      readme_params: generate_readme_params(data)
    }
  end

  private

  def self.generate_types_from_analysis(data)
    attributes = data[:arguments].map do |name, details|
      type_def = case details[:type]
                 when 'Array'
                   "Types::Array.of(Types::String)"
                 when 'Hash'
                   "Types::Hash"
                 when 'Integer'
                   "Types::Integer"
                 when 'Boolean'
                   "Types::Bool"
                 else
                   "Types::String"
                 end
      
      if details[:required]
        "attribute :#{name}, #{type_def}"
      else
        "attribute? :#{name}, #{type_def}.optional"
      end
    end.join("\n              ")
    
    <<~RUBY
      # Type definitions based on Terraform documentation
      class #{data[:resource_name].split('_').map(&:capitalize).join}Attributes < Dry::Struct
        #{attributes}
        
        # Tags
        attribute :tags, Types::AwsTags.default({})
      end
    RUBY
  end

  def self.generate_resource_from_analysis(data)
    attribute_mappings = data[:arguments].keys.map do |attr|
      "#{attr} attrs.#{attr} if attrs.#{attr}"
    end.join("\n                ")
    
    outputs = data[:attributes].keys.map do |attr|
      "#{attr}: \"${#{data[:resource_name]}.#{name}.#{attr}}\""
    end.join(",\n                  ")
    
    <<~RUBY
      # Resource implementation based on Terraform documentation
      resource(:#{data[:resource_name]}, name) do
        #{attribute_mappings}
      end
      
      # Outputs from Terraform documentation
      outputs: {
        #{outputs}
      }
    RUBY
  end

  def self.generate_readme_params(data)
    rows = data[:arguments].map do |name, details|
      req = details[:required] ? '**Yes**' : 'No'
      desc = details[:description].gsub('|', '\\|')
      "| `#{name}` | #{details[:type]} | #{req} | - | #{desc} |"
    end.join("\n")
    
    <<~MARKDOWN
      ## Parameters

      | Parameter | Type | Required | Default | Description |
      |-----------|------|----------|---------|-------------|
      #{rows}
      | `tags` | Hash | No | `{}` | Resource tags |
    MARKDOWN
  end
end

# CLI Interface
if __FILE__ == $0
  require 'optparse'
  
  options = {}
  
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: analyze_terraform_docs.rb RESOURCE_NAME [options]"
    
    opts.on("-o", "--output", "Save analysis to YAML file") do
      options[:output] = true
    end
    
    opts.on("-g", "--generate FILE", "Generate enhanced resource from analysis file") do |file|
      options[:generate] = file
    end
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end
  
  parser.parse!
  
  if options[:generate]
    unless File.exist?(options[:generate])
      puts "❌ Analysis file not found: #{options[:generate]}"
      exit 1
    end
    
    result = EnhancedResourceGenerator.generate_from_analysis(options[:generate])
    
    puts "\n📝 Enhanced types.rb content:"
    puts result[:types]
    
    puts "\n📝 Enhanced resource.rb content:"
    puts result[:resource]
    
    puts "\n📝 README parameters section:"
    puts result[:readme_params]
  elsif ARGV.empty?
    puts parser
    exit 1
  else
    resource_name = ARGV[0]
    analyzer = TerraformDocsAnalyzer.new(resource_name, options)
    analyzer.analyze!
  end
end