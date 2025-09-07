#!/usr/bin/env ruby
require 'json'
require 'time'
require_relative '../lib/pangea/quality/resource_auditor'

vpc_resources = Dir.glob('lib/pangea/resources/aws_vpc*').first(10)
results = []

vpc_resources.each do |resource_path|
  auditor = Pangea::Quality::ResourceAuditor.new(resource_path)
  results << auditor.audit
end

File.write('audit_results/vpc_resources_audit.json', JSON.pretty_generate({
  timestamp: Time.now.iso8601,
  total_resources: results.length,
  average_score: results.empty? ? 0 : results.sum { |r| r[:percentage] } / results.length,
  failing_resources: results.select { |r| r[:percentage] < 70 },
  results: results
}))

puts "Audit complete. Results in audit_results/vpc_resources_audit.json"