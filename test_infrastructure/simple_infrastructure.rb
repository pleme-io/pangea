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

# Simple infrastructure file for testing Pangea without provisioners

template :local_resources do
  # Random resources for testing without AWS credentials
  resource :random_id, :test do
    byte_length 8
  end
  
  resource :random_string, :password do
    length 16
    special true
  end
  
  resource :random_pet, :server do
    length 2
    separator "-"
  end
  
  # Local file resource
  resource :local_file, :test do
    content "Hello from Pangea!\nRandom ID: ${random_id.test.hex}\nPet Name: ${random_pet.server.id}\n"
    filename "./pangea-test-output.txt"
  end
  
  # Outputs
  output :random_hex do
    value "${random_id.test.hex}"
    description "Random hex value for unique identification"
  end
  
  output :pet_name do
    value "${random_pet.server.id}"
    description "Random pet name"
  end
  
  output :file_path do
    value "${local_file.test.filename}"
    description "Path to generated file"
  end
end

template :simple_aws do
  provider :aws do
    region "us-east-1"
  end
  
  # Random suffix for unique naming
  resource :random_id, :bucket_suffix do
    byte_length 4
  end
  
  # S3 bucket (one of the simplest AWS resources)
  resource :aws_s3_bucket, :test do
    bucket "pangea-test-${random_id.bucket_suffix.hex}"
    
    tags do
      Name "pangea-test-bucket"
      Environment "test"
      ManagedBy "pangea"
    end
  end
  
  # Outputs
  output :bucket_name do
    value "${aws_s3_bucket.test.id}"
    description "Name of the test bucket"
  end
end