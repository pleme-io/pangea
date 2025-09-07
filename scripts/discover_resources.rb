#!/usr/bin/env ruby

class ResourceDiscoverer
  def self.discover_all_resources
    resources = []
    
    # Find all resource.rb files
    Dir.glob("lib/pangea/resources/*/resource.rb").each do |file|
      resource_name = extract_resource_name(file)
      resources << {
        name: resource_name,
        file_path: file,
        test_dir: "spec/resources/#{resource_name}",
        function_name: resource_name
      }
    end
    
    resources.sort_by { |r| r[:name] }
  end
  
  def self.extract_resource_name(file_path)
    File.dirname(file_path).split('/').last
  end
  
  def self.generate_task_list
    resources = discover_all_resources
    
    puts "Found #{resources.length} resources to test:"
    resources.each_with_index do |resource, index|
      puts "#{index + 1}. #{resource[:name]}"
    end
    
    resources
  end
end

if __FILE__ == $0
  ResourceDiscoverer.generate_task_list
end