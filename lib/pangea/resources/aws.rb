# frozen_string_literal: true

require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/aws_vpc/resource'
require 'pangea/resources/aws_subnet/resource'
require 'pangea/resources/aws_route_table/resource'
require 'pangea/resources/aws_route_table_association/resource'
require 'pangea/resources/aws_internet_gateway/resource'
require 'pangea/resources/aws_security_group/resource'
require 'pangea/resources/aws_eip/resource'
require 'pangea/resources/aws_route/resource'
# require 'pangea/resources/aws_nat_gateway/resource' if File.exist?("#{__dir__}/aws_nat_gateway/resource.rb")
# require 'pangea/resources/aws_db_subnet_group/resource' if File.exist?("#{__dir__}/aws_db_subnet_group/resource.rb")
# require 'pangea/resources/aws_db_instance/resource' if File.exist?("#{__dir__}/aws_db_instance/resource.rb")
# require 'pangea/resources/aws_launch_template/resource' if File.exist?("#{__dir__}/aws_launch_template/resource.rb")
# require 'pangea/resources/aws_autoscaling_group/resource' if File.exist?("#{__dir__}/aws_autoscaling_group/resource.rb")
# require 'pangea/resources/aws_autoscaling_attachment/resource' if File.exist?("#{__dir__}/aws_autoscaling_attachment/resource.rb")
# require 'pangea/resources/aws_lb/resource' if File.exist?("#{__dir__}/aws_lb/resource.rb")
# require 'pangea/resources/aws_lb_target_group/resource' if File.exist?("#{__dir__}/aws_lb_target_group/resource.rb")
# require 'pangea/resources/aws_lb_listener/resource' if File.exist?("#{__dir__}/aws_lb_listener/resource.rb")
# require 'pangea/resources/aws_cloudwatch_log_group/resource'
# require 'pangea/resources/aws_cloudwatch_dashboard/resource'

module Pangea
  module Resources
    module AWS
      include Base
      include AwsVpc
      include AwsSubnet
      include AwsInternetGateway if defined?(AwsInternetGateway)
      # Route table functions are defined directly in AWS module by the require statements
    end
  end
end