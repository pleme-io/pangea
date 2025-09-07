# frozen_string_literal: true

# Minimal AWS resources for networking template
require 'pangea/resources/base'
require 'pangea/resources/aws_vpc/resource'
require 'pangea/resources/aws_subnet/resource'
require 'pangea/resources/aws_route_table/resource'
require 'pangea/resources/aws_route_table_association/resource'
require 'pangea/resources/aws_s3_bucket/resource'

module Pangea
  module Resources
    # AWS resource functions module with minimal required resources
    module AWS
      include Base
    end
  end
end