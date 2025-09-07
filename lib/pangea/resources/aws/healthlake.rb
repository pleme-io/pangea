# frozen_string_literal: true

require_relative 'healthlake/fhir_datastore'

module Pangea
  module Resources
    module AWS
      # Amazon HealthLake resources for healthcare data management
      module HealthLake
        include FHIRDatastore
      end
    end
  end
end