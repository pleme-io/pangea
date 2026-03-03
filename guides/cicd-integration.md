# CI/CD Integration: Automating Infrastructure with Pangea

Pangea is built for automation from day one. Its non-interactive design, auto-approval capabilities, and template isolation make it perfect for CI/CD pipelines. This guide shows how to integrate Pangea with popular CI/CD platforms and implement best practices for automated infrastructure deployment.

## Why Pangea Excels in CI/CD

### Automation-First Design

**Traditional Terraform in CI/CD:**
```bash
# Requires complex pipeline configuration
terraform init
terraform plan -out=tfplan
# Manual approval step required
terraform apply tfplan
```

**Pangea in CI/CD:**
```bash
# Simple, automation-friendly commands
pangea plan infrastructure.rb
pangea apply infrastructure.rb  # Auto-approves by default
```

### Key Automation Advantages

1. **Non-Interactive Operations**: No prompts or manual confirmations by default
2. **Template Isolation**: Deploy specific infrastructure components independently
3. **Environment Management**: Same code works across all environments via namespaces
4. **Built-in State Management**: No manual backend configuration
5. **Type Safety**: Catch errors before deployment, preventing pipeline failures

## GitHub Actions Integration

### Basic Pipeline Setup

```yaml
# .github/workflows/infrastructure.yml
name: Infrastructure Deployment

on:
  push:
    branches: [main, develop]
    paths: ['infrastructure/**']
  pull_request:
    branches: [main]
    paths: ['infrastructure/**']

env:
  AWS_REGION: us-east-1

jobs:
  plan:
    name: Plan Infrastructure Changes
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.3'
        bundler-cache: true
        
    - name: Install Pangea
      run: gem install pangea
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Plan infrastructure changes
      run: |
        cd infrastructure
        pangea plan infrastructure.rb --namespace development
        
    - name: Comment PR with plan
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const planOutput = fs.readFileSync('plan-output.txt', 'utf8');
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## Infrastructure Plan\n\`\`\`\n${planOutput}\n\`\`\``
          });

  deploy-development:
    name: Deploy to Development
    runs-on: ubuntu-latest
    needs: plan
    if: github.ref == 'refs/heads/develop'
    
    environment: development
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.3'
        bundler-cache: true
        
    - name: Install Pangea
      run: gem install pangea
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Deploy to development
      run: |
        cd infrastructure
        pangea apply infrastructure.rb --namespace development

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: deploy-development
    if: github.ref == 'refs/heads/main'
    
    environment: production
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.3'
        
    - name: Install Pangea
      run: gem install pangea
      
    - name: Configure AWS credentials (production)
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.PROD_AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.PROD_AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Plan production deployment
      run: |
        cd infrastructure
        pangea plan infrastructure.rb --namespace production
        
    - name: Deploy to production (with confirmation)
      run: |
        cd infrastructure
        # Use --no-auto-approve for production safety
        echo "yes" | pangea apply infrastructure.rb --namespace production --no-auto-approve
```

### Advanced Template-Specific Deployment

```yaml
# .github/workflows/template-deployment.yml
name: Template-Specific Deployment

on:
  push:
    paths:
      - 'infrastructure/**'

jobs:
  detect-changes:
    name: Detect Changed Templates
    runs-on: ubuntu-latest
    outputs:
      templates: ${{ steps.changes.outputs.templates }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
        
    - name: Detect changed templates
      id: changes
      run: |
        # Analyze git changes to determine which templates need deployment
        changed_files=$(git diff --name-only HEAD~1)
        
        templates=()
        
        # Check if networking-related changes
        if echo "$changed_files" | grep -q "networking\|vpc\|subnet"; then
          templates+=("networking")
        fi
        
        # Check if compute-related changes
        if echo "$changed_files" | grep -q "compute\|instance\|autoscaling"; then
          templates+=("compute")
        fi
        
        # Check if database-related changes
        if echo "$changed_files" | grep -q "database\|rds\|dynamodb"; then
          templates+=("database")
        fi
        
        # Convert to JSON array
        template_json=$(printf '%s\n' "${templates[@]}" | jq -R . | jq -s .)
        echo "templates=$template_json" >> $GITHUB_OUTPUT

  deploy-templates:
    name: Deploy Templates
    runs-on: ubuntu-latest
    needs: detect-changes
    if: needs.detect-changes.outputs.templates != '[]'
    
    strategy:
      matrix:
        template: ${{ fromJSON(needs.detect-changes.outputs.templates) }}
        environment: [development, staging, production]
      
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.3'
        
    - name: Install Pangea
      run: gem install pangea
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets[format('{0}_AWS_ACCESS_KEY_ID', matrix.environment)] }}
        aws-secret-access-key: ${{ secrets[format('{0}_AWS_SECRET_ACCESS_KEY', matrix.environment)] }}
        aws-region: us-east-1
        
    - name: Deploy template to environment
      run: |
        cd infrastructure
        pangea apply infrastructure.rb \
          --template ${{ matrix.template }} \
          --namespace ${{ matrix.environment }}
```

## GitLab CI Integration

### GitLab CI Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - plan
  - deploy-dev
  - deploy-staging
  - deploy-prod

variables:
  AWS_REGION: us-east-1
  RUBY_VERSION: "3.3"

# Base configuration for Ruby + Pangea
.pangea_base:
  image: ruby:${RUBY_VERSION}
  before_script:
    - gem install pangea
    - cd infrastructure

validate:
  extends: .pangea_base
  stage: validate
  script:
    - ruby -c infrastructure.rb  # Syntax check
    - pangea plan infrastructure.rb --namespace development --dry-run
  only:
    changes:
      - infrastructure/**/*

plan_development:
  extends: .pangea_base
  stage: plan
  script:
    - pangea plan infrastructure.rb --namespace development
  artifacts:
    reports:
      terraform: plan-output.json
    expire_in: 1 week
  only:
    - merge_requests
    - develop
    - main

deploy_development:
  extends: .pangea_base
  stage: deploy-dev
  environment:
    name: development
    url: https://dev.myapp.com
  script:
    - pangea apply infrastructure.rb --namespace development
  only:
    - develop
  when: on_success

deploy_staging:
  extends: .pangea_base
  stage: deploy-staging
  environment:
    name: staging
    url: https://staging.myapp.com
  script:
    - pangea apply infrastructure.rb --namespace staging
  only:
    - main
  when: manual  # Require manual approval for staging

deploy_production:
  extends: .pangea_base
  stage: deploy-prod
  environment:
    name: production
    url: https://myapp.com
  script:
    # Production requires explicit approval
    - pangea apply infrastructure.rb --namespace production --no-auto-approve < /dev/null || true
    - echo "Production deployment requires manual confirmation"
    - read -p "Deploy to production? (yes/no): " confirm
    - if [ "$confirm" = "yes" ]; then pangea apply infrastructure.rb --namespace production; fi
  only:
    - main
  when: manual
  allow_failure: false
```

### Multi-Project GitLab Setup

```yaml
# Parent pipeline for multiple infrastructure projects
# .gitlab-ci.yml (root)
include:
  - local: 'infrastructure/networking/.gitlab-ci.yml'
  - local: 'infrastructure/applications/.gitlab-ci.yml'
  - local: 'infrastructure/security/.gitlab-ci.yml'

stages:
  - validate
  - plan
  - deploy-foundation
  - deploy-applications
  - deploy-security

# infrastructure/networking/.gitlab-ci.yml
networking_plan:
  extends: .pangea_base
  stage: plan
  script:
    - pangea plan networking.rb --namespace $ENVIRONMENT

networking_deploy:
  extends: .pangea_base
  stage: deploy-foundation
  script:
    - pangea apply networking.rb --namespace $ENVIRONMENT
  parallel:
    matrix:
      - ENVIRONMENT: [development, staging, production]

# infrastructure/applications/.gitlab-ci.yml  
applications_deploy:
  extends: .pangea_base
  stage: deploy-applications
  dependencies:
    - networking_deploy
  script:
    - pangea apply applications.rb --namespace $ENVIRONMENT
  parallel:
    matrix:
      - ENVIRONMENT: [development, staging, production]
```

## Jenkins Integration

### Jenkinsfile Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        RUBY_VERSION = '3.3'
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    // Install Ruby and Pangea
                    sh '''
                        rbenv install ${RUBY_VERSION} -s
                        rbenv global ${RUBY_VERSION}
                        gem install pangea
                    '''
                }
            }
        }
        
        stage('Validate') {
            steps {
                dir('infrastructure') {
                    sh 'ruby -c infrastructure.rb'
                    sh 'pangea plan infrastructure.rb --namespace development --dry-run'
                }
            }
        }
        
        stage('Plan Development') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'PR-*'
                }
            }
            steps {
                dir('infrastructure') {
                    withAWS(credentials: 'aws-dev-credentials', region: env.AWS_REGION) {
                        sh 'pangea plan infrastructure.rb --namespace development'
                    }
                }
            }
        }
        
        stage('Deploy Development') {
            when { branch 'develop' }
            steps {
                dir('infrastructure') {
                    withAWS(credentials: 'aws-dev-credentials', region: env.AWS_REGION) {
                        sh 'pangea apply infrastructure.rb --namespace development'
                    }
                }
                
                // Post-deployment tests
                sh 'curl -f https://dev.myapp.com/health'
            }
        }
        
        stage('Deploy Production') {
            when { branch 'main' }
            steps {
                // Manual approval step
                input message: 'Deploy to production?', ok: 'Deploy',
                      parameters: [choice(name: 'CONFIRM', choices: ['no', 'yes'], description: 'Confirm production deployment')]
                
                script {
                    if (params.CONFIRM == 'yes') {
                        dir('infrastructure') {
                            withAWS(credentials: 'aws-prod-credentials', region: env.AWS_REGION) {
                                sh 'pangea apply infrastructure.rb --namespace production'
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Archive plans and logs
            archiveArtifacts artifacts: 'infrastructure/**/*.log', allowEmptyArchive: true
        }
        failure {
            // Notify team of failures
            emailext (
                subject: "Infrastructure deployment failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Build failed: ${env.BUILD_URL}",
                to: "${env.TEAM_EMAIL}"
            )
        }
    }
}
```

### Multi-Branch Jenkins Strategy

```groovy
// Multibranch pipeline with environment-specific deployment
pipeline {
    agent any
    
    stages {
        stage('Deploy by Branch') {
            parallel {
                stage('Feature Branch') {
                    when {
                        not { anyOf { branch 'main'; branch 'develop' } }
                    }
                    steps {
                        script {
                            def featureName = env.BRANCH_NAME.toLowerCase().replaceAll(/[^a-z0-9-]/, '-')
                            
                            dir('infrastructure') {
                                withAWS(credentials: 'aws-dev-credentials') {
                                    // Deploy feature environment
                                    sh """
                                        export FEATURE_BRANCH=${featureName}
                                        pangea apply feature-environments.rb --namespace development
                                    """
                                }
                            }
                        }
                    }
                }
                
                stage('Development') {
                    when { branch 'develop' }
                    steps {
                        dir('infrastructure') {
                            withAWS(credentials: 'aws-dev-credentials') {
                                sh 'pangea apply infrastructure.rb --namespace development'
                            }
                        }
                    }
                }
                
                stage('Production') {
                    when { branch 'main' }
                    steps {
                        dir('infrastructure') {
                            withAWS(credentials: 'aws-prod-credentials') {
                                sh 'pangea apply infrastructure.rb --namespace production'
                            }
                        }
                    }
                }
            }
        }
    }
}
```

## Azure DevOps Integration

### Azure Pipelines YAML

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - infrastructure/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  rubyVersion: '3.3'
  awsRegion: 'us-east-1'

stages:
- stage: Validate
  jobs:
  - job: ValidateInfrastructure
    steps:
    - task: UseRubyVersion@0
      inputs:
        versionSpec: '$(rubyVersion)'
        
    - script: |
        gem install pangea
      displayName: 'Install Pangea'
      
    - script: |
        cd infrastructure
        ruby -c infrastructure.rb
        pangea plan infrastructure.rb --namespace development --dry-run
      displayName: 'Validate Infrastructure'

- stage: DeployDevelopment
  condition: eq(variables['Build.SourceBranch'], 'refs/heads/develop')
  dependsOn: Validate
  jobs:
  - deployment: DeployToDev
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: UseRubyVersion@0
            inputs:
              versionSpec: '$(rubyVersion)'
              
          - script: gem install pangea
            displayName: 'Install Pangea'
            
          - task: AWSShellScript@1
            inputs:
              awsCredentials: 'aws-dev-connection'
              regionName: '$(awsRegion)'
              scriptType: 'inline'
              inlineScript: |
                cd infrastructure
                pangea apply infrastructure.rb --namespace development

- stage: DeployProduction
  condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
  dependsOn: DeployDevelopment
  jobs:
  - deployment: DeployToProd
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: UseRubyVersion@0
            inputs:
              versionSpec: '$(rubyVersion)'
              
          - script: gem install pangea
            displayName: 'Install Pangea'
            
          - task: AWSShellScript@1
            inputs:
              awsCredentials: 'aws-prod-connection'
              regionName: '$(awsRegion)'
              scriptType: 'inline'
              inlineScript: |
                cd infrastructure
                pangea plan infrastructure.rb --namespace production
                pangea apply infrastructure.rb --namespace production --no-auto-approve < /dev/null
```

## Advanced CI/CD Patterns

### Blue-Green Deployments

```ruby
# blue-green-infrastructure.rb
template :application_blue do
  # Only deploy if DEPLOY_COLOR=blue
  next unless ENV['DEPLOY_COLOR'] == 'blue'
  
  aws_autoscaling_group(:app_blue, {
    name_prefix: "app-blue-#{namespace}-",
    min_size: ENV['MIN_SIZE']&.to_i || 2,
    max_size: ENV['MAX_SIZE']&.to_i || 5,
    desired_capacity: ENV['DESIRED_SIZE']&.to_i || 3,
    launch_template: {
      id: ref(:aws_launch_template, :app, :id),
      version: "$Latest"
    }
  })
end

template :application_green do
  # Only deploy if DEPLOY_COLOR=green
  next unless ENV['DEPLOY_COLOR'] == 'green'
  
  aws_autoscaling_group(:app_green, {
    name_prefix: "app-green-#{namespace}-",
    min_size: ENV['MIN_SIZE']&.to_i || 2,
    max_size: ENV['MAX_SIZE']&.to_i || 5,
    desired_capacity: ENV['DESIRED_SIZE']&.to_i || 3,
    launch_template: {
      id: ref(:aws_launch_template, :app, :id),
      version: "$Latest"
    }
  })
end

template :load_balancer do
  active_color = ENV['ACTIVE_COLOR'] || 'blue'
  
  # Target group points to active color
  data :aws_autoscaling_group, :active do
    filter do
      name "tag:Name"
      values ["app-#{active_color}-#{namespace}-*"]
    end
  end
  
  aws_lb_target_group(:app, {
    name_prefix: "app-#{namespace}-",
    port: 80,
    protocol: "HTTP",
    vpc_id: data(:aws_vpc, :main, :id),
    
    health_check: {
      enabled: true,
      healthy_threshold: 2,
      path: "/health"
    }
  })
end
```

CI/CD Pipeline for Blue-Green:

```yaml
# Blue-green deployment pipeline
- name: Deploy Green Version
  run: |
    export DEPLOY_COLOR=green
    export MIN_SIZE=2
    export MAX_SIZE=5
    export DESIRED_SIZE=3
    pangea apply blue-green-infrastructure.rb --template application_green --namespace production

- name: Run Integration Tests
  run: |
    # Test green deployment
    ./test-green-deployment.sh

- name: Switch Traffic to Green
  run: |
    export ACTIVE_COLOR=green
    pangea apply blue-green-infrastructure.rb --template load_balancer --namespace production

- name: Monitor and Validate
  run: |
    # Monitor application metrics
    sleep 300
    ./validate-production-health.sh

- name: Remove Blue Version
  run: |
    export DEPLOY_COLOR=blue
    pangea destroy blue-green-infrastructure.rb --template application_blue --namespace production
```

### Canary Deployments

```ruby
# canary-infrastructure.rb
template :application_stable do
  aws_autoscaling_group(:app_stable, {
    name_prefix: "app-stable-#{namespace}-",
    min_size: ENV['STABLE_MIN_SIZE']&.to_i || 8,
    max_size: ENV['STABLE_MAX_SIZE']&.to_i || 10,
    desired_capacity: ENV['STABLE_DESIRED_SIZE']&.to_i || 9,
    target_group_arns: [ref(:aws_lb_target_group, :stable, :arn)]
  })
end

template :application_canary do
  # Only deploy canary if enabled
  next unless ENV['ENABLE_CANARY'] == 'true'
  
  aws_autoscaling_group(:app_canary, {
    name_prefix: "app-canary-#{namespace}-",
    min_size: ENV['CANARY_MIN_SIZE']&.to_i || 1,
    max_size: ENV['CANARY_MAX_SIZE']&.to_i || 2,
    desired_capacity: ENV['CANARY_DESIRED_SIZE']&.to_i || 1,
    target_group_arns: [ref(:aws_lb_target_group, :canary, :arn)]
  })
end

template :load_balancer_canary do
  canary_weight = ENV['CANARY_WEIGHT']&.to_i || 10
  
  aws_lb_listener_rule(:canary_routing, {
    listener_arn: ref(:aws_lb_listener, :main, :arn),
    priority: 100,
    
    action: {
      type: "forward",
      forward: {
        target_group: [
          {
            arn: ref(:aws_lb_target_group, :stable, :arn),
            weight: 100 - canary_weight
          },
          {
            arn: ref(:aws_lb_target_group, :canary, :arn),
            weight: canary_weight
          }
        ]
      }
    },
    
    condition: {
      path_pattern: { values: ["/*"] }
    }
  })
end
```

### Progressive Deployment Pipeline

```yaml
- name: Deploy Canary (10% Traffic)
  run: |
    export ENABLE_CANARY=true
    export CANARY_WEIGHT=10
    pangea apply canary-infrastructure.rb --namespace production

- name: Monitor Canary Metrics
  run: |
    ./monitor-canary.sh --duration 600  # 10 minutes
    
- name: Increase Canary Traffic (50%)
  if: success()
  run: |
    export CANARY_WEIGHT=50
    pangea apply canary-infrastructure.rb --template load_balancer_canary --namespace production

- name: Monitor High Traffic Canary
  run: |
    ./monitor-canary.sh --duration 1200  # 20 minutes

- name: Promote Canary to Stable
  if: success()
  run: |
    # Swap stable and canary versions
    export STABLE_MIN_SIZE=10
    export STABLE_DESIRED_SIZE=10
    export ENABLE_CANARY=false
    pangea apply canary-infrastructure.rb --namespace production

- name: Rollback on Failure
  if: failure()
  run: |
    export ENABLE_CANARY=false
    pangea apply canary-infrastructure.rb --template application_canary --namespace production
```

## Security and Best Practices

### Secure Credential Management

```yaml
# GitHub Actions with secure secrets
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    role-session-name: PangeaDeployment
    role-duration-seconds: 3600
```

### Environment-Specific Access Controls

```yaml
# Use different AWS roles per environment
- name: Configure Development AWS
  if: github.ref == 'refs/heads/develop'
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/PangeaDevelopmentRole

- name: Configure Production AWS  
  if: github.ref == 'refs/heads/main'
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::987654321098:role/PangeaProductionRole
```

### State File Security

```ruby
# Ensure production state is encrypted
# pangea.yml
namespaces:
  production:
    state:
      type: s3
      bucket: "secure-terraform-state"
      key: "pangea/production/terraform.tfstate"
      encrypt: true
      kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/terraform-state-key"
      acl: "private"
```

### Drift Detection

```yaml
# Scheduled drift detection
name: Infrastructure Drift Detection

on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM

jobs:
  detect-drift:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        namespace: [development, staging, production]
    
    steps:
    - name: Check for drift
      run: |
        pangea plan infrastructure.rb --namespace ${{ matrix.namespace }}
        
        # If plan shows changes, there's drift
        if pangea plan infrastructure.rb --namespace ${{ matrix.namespace }} | grep -q "Plan:"; then
          echo "DRIFT_DETECTED=true" >> $GITHUB_ENV
        fi
        
    - name: Notify on drift
      if: env.DRIFT_DETECTED == 'true'
      uses: actions/github-script@v7
      with:
        script: |
          github.rest.issues.create({
            owner: context.repo.owner,
            repo: context.repo.repo,
            title: `Infrastructure drift detected in ${{ matrix.namespace }}`,
            body: `Drift detected in namespace: ${{ matrix.namespace }}. Please review and reconcile.`,
            labels: ['infrastructure', 'drift', '${{ matrix.namespace }}']
          });
```

## Monitoring and Observability

### Deployment Monitoring

```yaml
- name: Deploy with monitoring
  run: |
    # Start deployment monitoring
    ./start-deployment-monitor.sh &
    MONITOR_PID=$!
    
    # Deploy infrastructure
    pangea apply infrastructure.rb --namespace production
    
    # Wait for deployment to stabilize
    sleep 300
    
    # Check deployment health
    if ./check-deployment-health.sh; then
      echo "Deployment successful"
    else
      echo "Deployment failed health checks - rolling back"
      pangea destroy infrastructure.rb --template application --namespace production
      exit 1
    fi
    
    # Stop monitoring
    kill $MONITOR_PID
```

### Integration with APM Tools

```ruby
# Add monitoring resources to templates
template :monitoring do
  # DataDog integration
  aws_cloudwatch_log_group(:app_logs, {
    name: "/aws/lambda/app-#{namespace}",
    retention_in_days: 14
  })
  
  # Custom metrics for deployment tracking
  aws_cloudwatch_metric_alarm(:deployment_errors, {
    alarm_name: "deployment-errors-#{namespace}",
    comparison_operator: "GreaterThanThreshold",
    evaluation_periods: 2,
    metric_name: "DeploymentErrors",
    namespace: "Pangea/Deployments",
    period: 300,
    statistic: "Sum",
    threshold: 5,
    alarm_description: "Deployment error rate too high",
    alarm_actions: [ref(:aws_sns_topic, :alerts, :arn)]
  })
end
```

## Troubleshooting CI/CD Issues

### Common Problems and Solutions

**1. State Lock Issues**
```yaml
- name: Handle state locks
  run: |
    # Force unlock if needed (use carefully)
    pangea plan infrastructure.rb --namespace production || \
    (echo "State locked - forcing unlock" && terraform force-unlock -force LOCK_ID)
```

**2. Template Dependencies**
```yaml
- name: Deploy in dependency order
  run: |
    # Deploy foundation first
    pangea apply infrastructure.rb --template networking --namespace production
    
    # Wait for networking to be ready
    ./wait-for-networking.sh
    
    # Deploy dependent templates
    pangea apply infrastructure.rb --template compute --namespace production
    pangea apply infrastructure.rb --template database --namespace production
```

**3. Environment Variable Issues**
```yaml
- name: Debug environment
  run: |
    echo "Current namespace: ${PANGEA_NAMESPACE:-development}"
    echo "AWS Region: ${AWS_REGION}"
    echo "Ruby version: $(ruby --version)"
    pangea --version
```

## Summary

Pangea's automation-first design makes CI/CD integration straightforward:

1. **Non-Interactive Operations**: No manual prompts in automation
2. **Template Isolation**: Deploy specific infrastructure components
3. **Environment Management**: Same code across all environments
4. **Type Safety**: Catch errors before deployment
5. **State Management**: Automatic backend configuration

Key benefits for CI/CD:
- **Faster Deployments**: Template-specific deployments reduce blast radius
- **Parallel Deployment**: Multiple teams can deploy simultaneously
- **Reliable Automation**: Type safety prevents configuration errors
- **Environment Consistency**: Same templates work across all environments

Next, explore [Advanced Patterns](advanced-patterns.md) to learn sophisticated infrastructure patterns using Pangea's component and architecture systems.