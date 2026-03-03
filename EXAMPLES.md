# Pangea Examples: Infrastructure as Code Patterns

This directory contains comprehensive examples demonstrating Pangea's power for infrastructure management. From simple single-resource deployments to complex enterprise architectures, these examples showcase how Pangea's template-level isolation, type safety, and Ruby DSL enable scalable, maintainable infrastructure.

## 🎯 Quick Start Examples

### [simple.rb](examples/simple.rb)
**The simplest possible Pangea template**
- Single S3 bucket with basic configuration
- Perfect for understanding template syntax
- Demonstrates basic resource creation

```bash
pangea apply examples/simple.rb
```

### [basic-web-app/](examples/basic-web-app/) ⭐ **New**
**Complete web application in one template**
- VPC with public/private subnets
- EC2 instance with security groups
- Application load balancer
- Shows cross-resource references
- Includes `pangea.yaml` for multi-environment management

```bash
cd examples/basic-web-app
pangea apply infrastructure.rb
```

### [multi-tier-architecture/](examples/multi-tier-architecture/) ⭐ **New**
**Three-tier application with database**
- Web tier with load balancer
- Application tier with auto-scaling
- Database tier with RDS
- Demonstrates template isolation benefits
- Three separate templates with cross-template communication

```bash
cd examples/multi-tier-architecture
pangea apply infrastructure.rb --template networking
pangea apply infrastructure.rb --template database
pangea apply infrastructure.rb --template application
```

## 🏢 Enterprise Examples

### [scalable_infrastructure.rb](examples/scalable_infrastructure.rb)
**Multi-template scalable architecture**
- Foundation template for networking
- Application template for compute
- Database template for persistent storage
- Shows incremental deployment patterns

### [microservices-platform/](examples/microservices-platform/) ⭐ **New**
**Complete microservices platform**
- Container orchestration with ECS
- Service discovery and mesh
- API Gateway integration
- Event-driven architecture patterns
- Includes complete Pangea repository structure

```bash
cd examples/microservices-platform
pangea apply infrastructure.rb --template platform
pangea apply infrastructure.rb --template services
```

### [advanced_global_infrastructure.rb](examples/advanced_global_infrastructure.rb)
**Global multi-region deployment**
- Cross-region VPC peering
- Global load balancing
- Disaster recovery setup
- Advanced networking patterns

### [comprehensive_database_platform.rb](examples/comprehensive_database_platform.rb)
**Database-as-a-Service platform**
- Multiple database engines
- Backup and monitoring
- Performance optimization
- High availability setup

## 🚀 Specialized Examples

### [advanced_ml_healthcare_infrastructure.rb](examples/advanced_ml_healthcare_infrastructure.rb)
**Healthcare ML platform**
- FHIR datastores for clinical data
- SageMaker training pipelines
- Compliance-ready security
- HIPAA-compliant architecture

### [ml-platform/](examples/ml-platform/) ⭐ **New**
**Production ML platform**
- Data lake infrastructure
- Feature store implementation
- Model training and serving
- MLOps pipeline automation

### [gaming_infrastructure.rb](examples/gaming_infrastructure.rb)
**Game backend infrastructure**
- GameLift fleet management
- Real-time multiplayer support
- Player data storage
- Scalable game sessions

### [robotics_and_specialized_services.rb](examples/robotics_and_specialized_services.rb)
**IoT and robotics platform**
- IoT device management
- RoboMaker integration
- Edge computing setup
- Telemetry processing

## 🔧 Integration Examples

### [api_gateway_complete.rb](examples/api_gateway_complete.rb)
**Complete API management**
- REST and WebSocket APIs
- Authentication integration
- Rate limiting and caching
- Multi-stage deployment

### [cicd-pipeline/](examples/cicd-pipeline/) ⭐ **New**
**CI/CD pipeline infrastructure**
- CodeBuild projects
- CodePipeline setup
- Artifact management
- Multi-environment promotion

### [messaging_example.rb](examples/messaging_example.rb)
**Event-driven messaging**
- SQS/SNS integration
- Dead letter queues
- Event processing patterns
- Scalable message handling

### [data-processing/](examples/data-processing/) ⭐ **New**
**Big data processing pipeline**
- Kinesis streaming
- EMR clusters for batch processing
- Glue ETL jobs
- Data lake storage patterns

## 🌍 Multi-Environment Examples

### [multi-environment/](examples/multi-environment/) ⭐ **New**
**Environment-aware templates**
- Development/staging/production configs
- Environment-specific resource sizing
- Namespace-driven customization
- Promotion workflow patterns

### [security-focused/](examples/security-focused/) ⭐ **New**
**Security-first architecture**
- Zero-trust networking
- VPC Flow Logs
- GuardDuty integration
- Compliance automation

### [global-multi-region/](examples/global-multi-region/) ⭐ **New**
**Global application deployment**
- Multi-region active-active
- Cross-region data replication
- Global load balancing
- Disaster recovery automation

## 📊 Monitoring Examples

### [cloudwatch_monitoring_example.rb](examples/cloudwatch_monitoring_example.rb)
**Comprehensive monitoring setup**
- Custom metrics and alarms
- Dashboard creation
- Log aggregation
- Automated alerting

### [disaster-recovery/](examples/disaster-recovery/) ⭐ **New**
**Enterprise disaster recovery**
- Cross-region backup automation
- RTO/RPO optimization
- Failover procedures
- Business continuity planning

## 🔒 Advanced Patterns

### [type_safe_infrastructure.rb](examples/type_safe_infrastructure.rb)
**Type safety demonstration**
- Resource function validation
- Compile-time error prevention
- IDE integration benefits
- Best practices for type safety

### [resource_composition_patterns.rb](examples/resource_composition_patterns.rb)
**Complex resource relationships**
- Advanced referencing patterns
- Conditional resource creation
- Dynamic configuration
- Reusable patterns

## 📋 Example Categories

### By Complexity Level

**🟢 Beginner (1-2 templates)**
- [simple.rb](examples/simple.rb)
- [basic-web-app/](examples/basic-web-app/)
- [multi-tier-architecture/](examples/multi-tier-architecture/)

**🟡 Intermediate (3-5 templates)**
- [scalable_infrastructure.rb](examples/scalable_infrastructure.rb)
- [microservices-platform/](examples/microservices-platform/)
- [cicd-pipeline/](examples/cicd-pipeline/)
- [multi-environment/](examples/multi-environment/)

**🔴 Advanced (5+ templates)**
- [advanced_global_infrastructure.rb](examples/advanced_global_infrastructure.rb)
- [advanced_ml_healthcare_infrastructure.rb](examples/advanced_ml_healthcare_infrastructure.rb)
- [ml-platform/](examples/ml-platform/)
- [global-multi-region/](examples/global-multi-region/)
- [disaster-recovery/](examples/disaster-recovery/)

### By Use Case

**🌐 Web Applications**
- [basic-web-app/](examples/basic-web-app/) - Simple web server
- [multi-tier-architecture/](examples/multi-tier-architecture/) - Full-stack application
- [scalable_infrastructure.rb](examples/scalable_infrastructure.rb) - Scalable web platform

**📱 Microservices**
- [microservices-platform/](examples/microservices-platform/) - Container platform
- [messaging_example.rb](examples/messaging_example.rb) - Event-driven services
- [api_gateway_complete.rb](examples/api_gateway_complete.rb) - API management

**🤖 Machine Learning**
- [ml-platform/](examples/ml-platform/) - Production ML platform  
- [advanced_ml_healthcare_infrastructure.rb](examples/advanced_ml_healthcare_infrastructure.rb) - Healthcare ML

**🏗️ Platform Engineering**
- [cicd-pipeline/](examples/cicd-pipeline/) - Build/deploy automation
- [security-focused/](examples/security-focused/) - Security platform
- [data-processing/](examples/data-processing/) - Big data platform

**🌍 Enterprise Architecture**
- [global-multi-region/](examples/global-multi-region/) - Global deployment
- [disaster-recovery/](examples/disaster-recovery/) - Business continuity
- [multi-environment/](examples/multi-environment/) - Environment management

## 🚀 Running the Examples

### Basic Usage

```bash
# Simple examples
pangea apply examples/simple.rb
cd examples/basic-web-app && pangea apply infrastructure.rb

# Multi-template examples (deploy in order)
pangea apply examples/scalable_infrastructure.rb --template foundation
pangea apply examples/scalable_infrastructure.rb --template application
pangea apply examples/scalable_infrastructure.rb --template database

# Environment-specific deployment
pangea apply examples/multi-environment-deployment.rb --namespace development
pangea apply examples/multi-environment-deployment.rb --namespace production
```

### Configuration

Most examples require a `pangea.yaml` configuration file. See [pangea.yaml.example](../pangea.yaml.example) in the root directory for a comprehensive configuration template.

### Prerequisites

- Ruby 3.1+ 
- Terraform 1.5+ or OpenTofu 1.6+
- AWS CLI configured with appropriate permissions
- Pangea installed: `gem install pangea`

## 🔧 Customizing Examples

### Environment Variables

Many examples support customization via environment variables:

```bash
# Customize instance types
export INSTANCE_TYPE=t3.large
pangea apply examples/basic-web-app.rb

# Enable additional features
export ENABLE_MONITORING=true
export ENABLE_BACKUP=true
pangea apply examples/multi-tier-architecture.rb

# Multi-region deployment
export PRIMARY_REGION=us-east-1
export SECONDARY_REGION=us-west-2
pangea apply examples/global-multi-region.rb
```

### Template Modification

Examples are designed to be educational and customizable:

1. **Copy** the example to your project
2. **Modify** resource configurations for your needs
3. **Add** additional templates as required
4. **Deploy** with confidence using template isolation

## 📚 Learning Path

### 1. Start with Basics
- Run [simple.rb](examples/simple.rb) to understand template syntax
- Explore [basic-web-app.rb](examples/basic-web-app.rb) for resource relationships
- Try [multi-tier-architecture.rb](examples/multi-tier-architecture.rb) for architecture patterns

### 2. Understand Template Isolation
- Deploy [scalable_infrastructure.rb](examples/scalable_infrastructure.rb) template by template
- See how [microservices-platform.rb](examples/microservices-platform.rb) isolates different concerns
- Practice with [multi-environment-deployment.rb](examples/multi-environment-deployment.rb)

### 3. Explore Advanced Patterns
- Study [ml-platform.rb](examples/ml-platform.rb) for complex architectures
- Examine [global-multi-region.rb](examples/global-multi-region.rb) for enterprise patterns
- Learn from [disaster-recovery-architecture.rb](examples/disaster-recovery-architecture.rb)

## 🤝 Contributing Examples

Have an interesting Pangea pattern? Add it to the examples:

1. Create a new `.rb` file in the `examples/` directory
2. Follow the existing naming pattern: `kebab-case.rb`
3. Include comprehensive comments explaining the pattern
4. Add error handling and validation
5. Update this EXAMPLES.md with your example

### Example Template

```ruby
# Copyright 2025 The Pangea Authors
# Licensed under the Apache License, Version 2.0

# Example: [Brief Description]
# This example demonstrates [key concepts]

template :example_template do
  provider :aws do
    region "us-east-1"
  end
  
  # Resource definitions with comments
  # explaining the pattern
end
```

## 🔍 Finding Examples

### By Feature
- **Template Isolation**: [scalable_infrastructure.rb](examples/scalable_infrastructure.rb)
- **Type Safety**: [type_safe_infrastructure.rb](examples/type_safe_infrastructure.rb)
- **Multi-Environment**: [multi-environment-deployment.rb](examples/multi-environment-deployment.rb)
- **Cross-Region**: [global-multi-region.rb](examples/global-multi-region.rb)

### By AWS Service
- **EC2/VPC**: [basic-web-app.rb](examples/basic-web-app.rb)
- **ECS/Fargate**: [microservices-platform.rb](examples/microservices-platform.rb)
- **RDS**: [multi-tier-architecture.rb](examples/multi-tier-architecture.rb)
- **SageMaker**: [ml-platform.rb](examples/ml-platform.rb)
- **API Gateway**: [api_gateway_complete.rb](examples/api_gateway_complete.rb)

## 📖 Additional Resources

- **[Getting Started Guide](guides/getting-started.md)** - First steps with Pangea
- **[Template Isolation Guide](guides/template-isolation.md)** - Understanding Pangea's core concept
- **[Advanced Patterns Guide](guides/advanced-patterns.md)** - Enterprise architecture patterns
- **[API Documentation](README.md)** - Complete reference

---

*These examples showcase the power of Pangea's template-level isolation, type safety, and automation-first design. Start simple, then explore the advanced patterns that make Pangea perfect for enterprise infrastructure management.*