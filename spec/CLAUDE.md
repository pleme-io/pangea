# Pangea Testing Framework

## Overview

Pangea's testing framework provides comprehensive test coverage for all three abstraction layers: resources, components, and archs. The testing system emphasizes real synthesis validation to ensure that all generated Terraform configurations are valid and prod-ready.

## Testing Arch Principles

## 1. Directory-Per-Entity Rule
CRITICAL REQUIREMENT: Each resource function, component, and arch MUST have its own dedicated testing directory.

## 2. Real Synthesis Testing Requirement
MANDATORY: All resource tests MUST utilize the terraform-synthesizer and test with real synthesis. No mocking or stubbing of the synthesis process is permitted for resource-level tests.

- Resource Tests: Must generate actual Terraform JSON and validate structure
- Component Tests: Must synthesize all underlying resources and validate composition
- Arch Tests: Must synthesize complete infra stacks and validate orchestration

## 3. Test Dev Methodology
CRITICAL REQUIREMENT: When developing tests, each resource, component, or arch must be fully tested one by one before moving on to the next. Do not attempt to test multiple entities simultaneously.

- Sequential Dev: Complete all tests for a single resource/component/arch before starting the next
- Full Coverage Per Entity: Each entity must have all required test files (resourcespec.rb, synthesisspec.rb, integrationspec.rb) fully implemented
- Validation Before Progression: Ensure all tests pass for the current entity before moving to the next
- No Parallel Dev: Avoid developing tests for multiple entities concurrently

This approach ensures:
- Complete test coverage for each entity
- Easier debugging when issues arise
- Clear understanding of each entity's behavior
- Consistent quality across all tests

## 4. Test File Structure per Directory

Each entity directory follows a consistent structure:

- Resource Function Directories

- Component Directories

- Arch Directories

## Testing Levels and Requirements

## Level 1: Resource Function Testing

Purpose: Validate individual resource functions generate correct Terraform configurations

Requirements:
1. Real Synthesis: Must use `TerraformSynthesizer` to generate actual Terraform JSON
2. Structure Validation: Verify generated Terraform structure matches expected format
3. Attribute Validation: Ensure all resource attributes are correctly mapped
4. Reference Validation: Test resource reference generation and usage
5. Type Safety: Validate dry-struct attribute validation works correctly

Example Test Structure:

## Level 2: Component Testing

Purpose: Validate component composition and resource orchestration

Requirements:
1. Component Behavior: Test component function logic and composition
2. Resource Synthesis: Verify all underlying resources synthesize correctly
3. Reference Composition: Test resource reference passing between resources
4. Override Testing: Validate component override capabilities
5. Integration: Test component-to-component integration

Example Test Structure:

## Level 3: Arch Testing

Purpose: Validate complete infra arch deploy

Requirements:
1. Arch Orchestration: Test arch composition and configuration
2. Complete Synthesis: Validate entire arch synthesizes to valid Terraform
3. Env Testing: Test env-specific defaults and configurations
4. Override System: Validate arch override and extension capabilities
5. Cost Estimation: Test cost calculation accuracy
6. Security Scoring: Validate security compliance scoring
7. Multi-Arch Integration: Test arch-to-arch composition

Example Test Structure:

## Test Categories and Specifications

## Synthesis Tests (`synthesisspec.rb`)
Purpose: Validate Terraform JSON generation and structure

Requirements:
- Use real `TerraformSynthesizer` instance
- Generate actual Terraform JSON output
- Validate JSON structure matches Terraform specification
- Test all configuration parameters are correctly mapped
- Verify resource dependencies and references are correctly generated

## Integration Tests (`integrationspec.rb`)
Purpose: Validate cross-entity interactions and dependencies

Requirements:
- Test resource-to-resource references
- Validate component-to-component composition
- Test arch-to-arch integration
- Verify dependency ordering in generated Terraform
- Test override and extension mechanisms

## Scenario Tests (`scenariospec.rb` - Archs only)
Purpose: Validate real-world deploy scenarios

Requirements:
- Test complete env deploys (dev, staging, prod)
- Validate multi-arch compositions
- Test disaster recovery scenarios
- Verify scaling and performance configurations
- Test security and compliance configurations

## Test Helpers and Utilities

## Synthesis Test Helpers

## Component Test Helpers

## Arch Test Helpers

## Test Organization and Naming

## File Naming Conventions
- `resourcespec.rb`: Resource function behavior tests
- `synthesisspec.rb`: Terraform synthesis validation tests
- `integrationspec.rb`: Cross-entity integration tests
- `scenariospec.rb`: Real-world scenario tests (archs only)

## Test Group Organization

## Test Data and Fixtures

## Test Config Files

## Terraform Validation Fixtures

## Continuous Integration Requirements

## Test Execution Order
1. Resource Synthesis Tests: Validate individual resource generation
2. Component Synthesis Tests: Validate component composition
3. Arch Synthesis Tests: Validate complete arch orchestration
4. Integration Tests: Validate cross-entity interactions
5. Scenario Tests: Validate real-world deploy patterns

## Coverage Requirements
- Resource Functions: 100% synthesis validation coverage
- Components: 100% component behavior and synthesis coverage
- Archs: 100% arch orchestration and synthesis coverage
- Integration: All documented integration patterns must be tested

## Performance Requirements
- Resource Tests: Must complete within 5 seconds per resource
- Component Tests: Must complete within 15 seconds per component
- Arch Tests: Must complete within 30 seconds per arch
- Full Test Suite: Must complete within 10 minutes

## Testing Best Practices

## 1. Real Synthesis Validation
- Always use actual `TerraformSynthesizer` instances
- Never mock synthesis behavior for resource tests
- Validate actual generated Terraform JSON structure
- Test with realistic configuration values

## 2. Comprehensive Coverage
- Test all documented configuration parameters
- Test error conditions and edge cases
- Validate type safety and attribute validation
- Test override and extension mechanisms

## 3. Env Testing
- Test env-specific defaults (dev, staging, prod)
- Validate env-appropriate resource sizing
- Test env-specific security configurations
- Validate cost implications across envs

## 4. Integration Validation
- Test resource reference passing
- Validate component composition patterns
- Test arch-to-arch integration
- Verify dependency ordering in generated configurations

## 5. Performance and Scalability
- Test with realistic resource counts
- Validate synthesis performance with complex archs
- Test memory usage with large configurations
- Validate concurrent synthesis operations

This testing framework ensures that every resource function, component, and arch in Pangea is thoroughly validated with real synthesis testing, providing confidence that all generated Terraform configurations are prod-ready and correctly structured.