# Multi-template infrastructure file to test separate workspaces
# This Ruby code outside templates is NOT compiled

region = "us-east-1"
common_tags = { managed_by: "pangea", environment: "test" }

template :networking do
  # WORKSPACE: networking/
  # This template creates VPC and networking resources
  
  resource :random_id, :vpc_suffix do
    byte_length 4
  end
  
  resource :local_file, :vpc_config do
    content "VPC Configuration\nRegion: us-east-1\nVPC ID: ${random_id.vpc_suffix.hex}"
    filename "./networking-config.txt"
  end
  
  resource :random_pet, :vpc_name do
    length 2
    separator "-"
    prefix "vpc"
  end
  
  output :vpc_identifier do
    value "${random_id.vpc_suffix.hex}"
    description "Unique VPC identifier"
  end
  
  output :vpc_name do
    value "${random_pet.vpc_name.id}"
    description "Generated VPC name"
  end
end

template :compute do
  # WORKSPACE: compute/  
  # This template creates compute resources
  
  resource :random_string, :instance_password do
    length 32
    special true
    upper true
    lower true
    numeric true
  end
  
  resource :random_id, :instance_suffix do
    byte_length 6
  end
  
  resource :local_file, :instance_userdata do
    content "#!/bin/bash\necho 'Instance ID: ${random_id.instance_suffix.hex}' > /tmp/instance-info.txt\necho 'Password: ${random_string.instance_password.result}' > /tmp/password.txt\nchmod 600 /tmp/password.txt"
    filename "./compute-userdata.sh"
    file_permission "0755"
  end
  
  resource :random_pet, :instance_name do
    length 3
    separator "-"
    prefix "web"
  end
  
  output :instance_id do
    value "${random_id.instance_suffix.hex}"
    description "Unique instance identifier"
  end
  
  output :instance_name do
    value "${random_pet.instance_name.id}"
    description "Generated instance name"
  end
  
  output :userdata_file do
    value "${local_file.instance_userdata.filename}"
    description "Path to userdata script"
  end
end

template :storage do
  # WORKSPACE: storage/
  # This template creates storage resources
  
  resource :random_id, :bucket_id do
    byte_length 16
  end
  
  resource :random_string, :encryption_key do
    length 64
    special false
    upper true
    lower true
    numeric true
  end
  
  resource :local_file, :storage_manifest do
    content "{\"bucket_id\": \"${random_id.bucket_id.hex}\", \"encryption_key\": \"${random_string.encryption_key.result}\", \"created_at\": \"2025-09-03T19:00:00Z\", \"storage_type\": \"test\"}"
    filename "./storage-manifest.json"
  end
  
  output :bucket_identifier do
    value "${random_id.bucket_id.hex}"
    description "Unique bucket identifier"
  end
  
  output :manifest_file do
    value "${local_file.storage_manifest.filename}"
    description "Storage configuration manifest"
  end
end