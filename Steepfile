# Steepfile - Configuration for Steep type checker

target :lib do
  signature "sig"
  
  check "lib"                    # Type check lib directory
  check "exe"                    # Type check executables
  
  # Standard library signatures
  stdlib_path "sig/stdlib"
  
  # Configure library signatures
  library "tty"
  library "aws-sdk-s3"
  library "aws-sdk-dynamodb"
  library "dry-types"
  library "dry-struct"
  library "dry-validation"
  library "toml-rb"
  
  # Ignore vendor and generated files
  ignore "vendor"
  ignore "spec"
  ignore "sig/gems"
end

target :spec do
  signature "sig"
  
  check "spec"
  
  library "rspec"
end