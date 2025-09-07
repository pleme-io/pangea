# frozen_string_literal: true

require_relative 'comprehendmedical/jobs'

module Pangea
  module Resources
    module AWS
      # Amazon Comprehend Medical resources for medical text analysis
      module ComprehendMedical
        include Jobs
      end
    end
  end
end