#!/bin/bash

# Pangea Release Script
# Bypasses Nix/bundler conflicts for gem publishing

set -e

echo "🚀 Pangea Release Script"
echo "======================="

# Clean any existing gem files
echo "Cleaning previous builds..."
rm -f pangea-*.gem

# Build the gem
echo "Building gem..."
gem build pangea.gemspec

# Get the built gem file
GEM_FILE=$(ls pangea-*.gem | head -n1)
echo "Built: $GEM_FILE"

# Check if we're ready to publish
echo ""
echo "Ready to publish $GEM_FILE to RubyGems!"
echo ""
echo "To complete the release:"
echo "1. Get your OTP code from your authenticator app"
echo "2. Run: gem push $GEM_FILE --otp YOUR_OTP_CODE"
echo ""
echo "Or if you have OTP ready, run:"
echo "gem push $GEM_FILE --otp \$OTP_CODE"