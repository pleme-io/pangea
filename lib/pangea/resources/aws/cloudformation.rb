# frozen_string_literal: true

require 'pangea/resources/aws/cloudformation/stack_set'
require 'pangea/resources/aws/cloudformation/stack_set_instance'
require 'pangea/resources/aws/cloudformation/stack_instances'
require 'pangea/resources/aws/cloudformation/type'
require 'pangea/resources/aws/cloudformation/type_activation'
require 'pangea/resources/aws/cloudformation/publisher'
require 'pangea/resources/aws/cloudformation/public_type_version'
require 'pangea/resources/aws/cloudformation/resource_version'
require 'pangea/resources/aws/cloudformation/resource_default_version'
require 'pangea/resources/aws/cloudformation/hook_default_version'

module Pangea
  module Resources
    module AWS
      # AWS CloudFormation resources module
      # Provides advanced CloudFormation resource management including stack sets,
      # type registration, and resource versioning for enterprise-scale deployments.
      module CloudFormation
        include StackSet
        include StackSetInstance
        include StackInstances
        include Type
        include TypeActivation
        include Publisher
        include PublicTypeVersion
        include ResourceVersion
        include ResourceDefaultVersion
        include HookDefaultVersion
      end
    end
  end
end