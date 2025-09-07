#!/usr/bin/env ruby
require_relative '../lib/pangea/generators/test_generator'

generator = Pangea::Generators::TestGenerator.new('vpc')
generator.generate_all

puts "Generated tests in spec/resources/aws_vpc/"