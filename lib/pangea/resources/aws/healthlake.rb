# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require_relative 'healthlake/fhir_datastore'
require_relative 'healthlake/fhir_export_job'
require_relative 'healthlake/fhir_import_job'

module Pangea
  module Resources
    module AWS
      # Amazon HealthLake resources for healthcare data management
      module HealthLake
        include FHIRDatastore
        include FHIRExportJob
        include FHIRImportJob
      end
    end
  end
end