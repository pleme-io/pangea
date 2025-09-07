#!/usr/bin/env ruby

require 'json'

class ResourceAnalyzer
  def self.analyze_resource(resource_path)
    content = File.read(resource_path)
    
    {
      name: extract_resource_name(resource_path),
      function_name: extract_function_name(content),
      has_types_file: has_types_file?(resource_path),
      has_validation: has_validation?(content),
      required_attributes: extract_required_attributes(content),
      optional_attributes: extract_optional_attributes(content),
      outputs: extract_outputs(content),
      complexity: assess_complexity(content)
    }
  end
  
  def self.extract_resource_name(path)
    File.dirname(path).split('/').last
  end
  
  def self.extract_function_name(content)
    match = content.match(/def (aws_\w+)\(/)
    match ? match[1] : nil
  end
  
  def self.has_types_file?(resource_path)
    types_path = File.join(File.dirname(resource_path), 'types.rb')
    File.exist?(types_path)
  end
  
  def self.has_validation?(content)
    content.include?('validate') || content.include?('Dry::Struct')
  end
  
  def self.extract_required_attributes(content)
    # Simple heuristic - look for attributes without defaults
    attributes = []
    content.scan(/attribute\s+:(\w+)(?!\s*,.*default)/) do |match|
      attributes << match[0]
    end
    attributes
  end
  
  def self.extract_optional_attributes(content)
    attributes = []
    content.scan(/attribute\s+:(\w+).*default/) do |match|
      attributes << match[0]
    end
    attributes
  end
  
  def self.extract_outputs(content)
    outputs = []
    content.scan(/["'](\w+)["']\s*=>\s*["`]\$\{.*?\}["`]/) do |match|
      outputs << match[0]
    end
    outputs
  end
  
  def self.assess_complexity(content)
    score = 0
    score += 1 if content.include?('if')
    score += 1 if content.include?('case')
    score += 1 if content.include?('each')
    score += 1 if content.include?('merge')
    score += content.scan(/def /).length
    
    case score
    when 0..2 then :simple
    when 3..5 then :medium
    else :complex
    end
  end
  
  def self.analyze_all_resources
    results = []
    
    Dir.glob("lib/pangea/resources/*/resource.rb").each do |resource_path|
      begin
        analysis = analyze_resource(resource_path)
        results << analysis
      rescue => e
        puts "Error analyzing #{resource_path}: #{e.message}"
      end
    end
    
    results
  end
  
  def self.generate_analysis_report
    analyses = analyze_all_resources
    
    # Group by complexity
    complexity_groups = analyses.group_by { |a| a[:complexity] }
    
    puts "Resource Analysis Report:"
    complexity_groups.each do |complexity, resources|
      puts "\n#{complexity.to_s.upcase} (#{resources.length}):"
      resources.first(5).each { |r| puts "  - #{r[:name]}" }
      puts "  ... (#{resources.length - 5} more)" if resources.length > 5
    end
    
    analyses
  end
end

if __FILE__ == $0
  ResourceAnalyzer.generate_analysis_report
end