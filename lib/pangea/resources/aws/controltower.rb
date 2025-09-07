# frozen_string_literal: true

require 'pangea/resources/aws/controltower/control'
require 'pangea/resources/aws/controltower/landing_zone'
require 'pangea/resources/aws/controltower/enabled_control'

module Pangea
  module Resources
    module AWS
      # AWS Control Tower resources module
      # Includes all Control Tower resource implementations for managing
      # governance and compliance across AWS organizations.
      module ControlTower
        include Control
        include LandingZone
        include EnabledControl
      end
    end
  end
end