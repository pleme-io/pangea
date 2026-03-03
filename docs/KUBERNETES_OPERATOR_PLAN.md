# Pangea Kubernetes Operator: Continuous Drift Detection & Reconciliation

## Executive Summary

This document outlines the architecture, implementation plan, and testing strategy for transforming Pangea into a Kubernetes-native, continuous drift detection and reconciliation system. The solution combines the strengths of Go-based Kubernetes operators with Pangea's Ruby infrastructure-as-code capabilities to provide automated, perpetual infrastructure management.

**Status:** Research Complete → Ready for Implementation
**Last Updated:** 2025-11-06
**Version:** 1.1 (Build System Integration)

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Solution Architecture](#solution-architecture)
3. [Component Specifications](#component-specifications)
4. [Build System Architecture](#build-system-architecture)
5. [CRD Definitions](#crd-definitions)
6. [Reconciliation Strategy](#reconciliation-strategy)
7. [Testing Framework Integration](#testing-framework-integration)
8. [Implementation Roadmap](#implementation-roadmap)
9. [Task Breakdown for Agents](#task-breakdown-for-agents)
10. [Success Metrics](#success-metrics)

---

## Problem Statement

### Current State

Pangea currently operates as a CLI tool requiring manual invocation:
- Infrastructure changes require human intervention
- Drift detection happens only when `pangea plan` is run
- No continuous monitoring of infrastructure state
- Manual remediation required when drift is detected
- Limited integration with Kubernetes-native workflows

### Desired State

Transform Pangea into a **Kubernetes-native, continuous infrastructure reconciliation system**:
- Automatic drift detection with configurable intervals
- Automatic remediation of detected drift
- Kubernetes-native API via Custom Resource Definitions (CRDs)
- Continuous compliance monitoring with InSpec integration
- Event-driven architecture responding to changes in real-time
- GitOps workflow integration
- Comprehensive testing with RSpec and InSpec

### 2025 Industry Trends

Based on research, the infrastructure management landscape in 2025 emphasizes:
- **Continuous reconciliation** over periodic manual checks
- **Immediate drift detection** via queryable state graphs
- **Automated remediation** rather than notification-only systems
- **Kubernetes-native** infrastructure management patterns
- **Compliance as code** with continuous validation

---

## Solution Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                 Pangea Operator (Go)                      │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │  │
│  │  │  CRD Watch  │  │ Reconciler   │  │  Event Handler │  │  │
│  │  │   Manager   │→│    Loop      │→│   & Queue      │  │  │
│  │  └─────────────┘  └──────────────┘  └────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                            ↓                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Pangea Executor (Ruby Pod)                   │  │
│  │  ┌──────────┐  ┌────────────┐  ┌───────────────────────┐ │  │
│  │  │ Template │  │  Drift     │  │   InSpec Validator   │ │  │
│  │  │ Compiler │  │  Detector  │  │                       │ │  │
│  │  └──────────┘  └────────────┘  └───────────────────────┘ │  │
│  │  ┌──────────┐  ┌────────────┐  ┌───────────────────────┐ │  │
│  │  │  Tofu    │  │   State    │  │   Metrics Exporter   │ │  │
│  │  │ Executor │  │  Manager   │  │                       │ │  │
│  │  └──────────┘  └────────────┘  └───────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
│                            ↓                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                 Cloud Provider APIs                       │  │
│  │        (AWS, GCP, Azure - via Terraform/OpenTofu)        │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

External Integrations:
├─ Git Repository (GitOps source)
├─ S3/DynamoDB (Terraform state backend)
├─ Prometheus (Metrics & Monitoring)
└─ Slack/Webhooks (Alerting)
```

### Architectural Decisions

#### 1. Hybrid Go + Ruby Architecture

**Decision:** Use Go for the Kubernetes operator, Ruby for infrastructure operations

**Rationale:**
- Go is the standard for Kubernetes operators (controller-runtime, client-go)
- Ruby Kubernetes client is unmaintained as of 2025
- Pangea's core logic is already in Ruby and well-tested
- Clear separation of concerns: K8s orchestration (Go) vs. IaC execution (Ruby)

**Implementation:**
- Go operator handles CRD watching, reconciliation loop, and K8s API interactions
- Go operator spawns/manages Ruby executor pods
- Communication via Kubernetes Job API and ConfigMaps/Secrets

#### 2. Template-Level CRDs

**Decision:** Each Pangea template becomes a Kubernetes custom resource

**Rationale:**
- Aligns with Pangea's existing template isolation model
- Enables independent reconciliation and drift detection per template
- Allows fine-grained RBAC and lifecycle management
- Matches the Kubernetes controller pattern (one reconciler per resource type)

#### 3. Continuous Reconciliation Model

**Decision:** Implement event-driven + periodic reconciliation

**Rationale:**
- Event-driven: React immediately to CRD changes (GitOps updates)
- Periodic: Detect external drift at configurable intervals
- Hybrid approach provides both responsiveness and drift detection

**Configuration:**
```yaml
spec:
  reconciliation:
    mode: hybrid  # event-driven | periodic | hybrid
    interval: 5m  # For periodic/hybrid mode
    driftDetection: true
    autoRemediate: true
```

#### 4. Declarative Drift Remediation

**Decision:** Make remediation behavior declarative via CRD spec

**Rationale:**
- Users explicitly opt-in to auto-remediation
- Different policies per environment (auto-remediate dev, alert-only prod)
- Audit trail via Kubernetes events

---

## Component Specifications

### 1. Pangea Operator (Go)

**Location:** `pkgs/operators/pangea-operator/`

**Responsibilities:**
- Watch `PangeaTemplate` and `PangeaStack` custom resources
- Implement reconciliation loop (target: <1s reconciliation time)
- Manage executor pod lifecycle
- Handle drift detection scheduling
- Emit Kubernetes events and metrics
- Update resource status with reconciliation results

**Dependencies:**
- `controller-runtime` v0.17+
- `client-go` v0.29+
- `kubebuilder` v3.14+ (scaffolding only)

**Key Interfaces:**
```go
type TemplateReconciler struct {
    client.Client
    Scheme *runtime.Scheme
    Executor *PangeaExecutor
    DriftDetector *DriftDetector
}

func (r *TemplateReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error)
```

### 2. Pangea Executor (Ruby)

**Location:** `pkgs/operators/pangea-executor/`

**Responsibilities:**
- Execute `pangea plan` and `pangea apply` operations
- Perform drift detection via `terraform plan`
- Run InSpec compliance tests
- Report results back to operator via status updates
- Manage Terraform/OpenTofu state

**Container Image:**
- Base: `ruby:3.3-alpine`
- Includes: pangea gem, terraform/tofu, inspec
- Size target: <200MB

**Entry Points:**
```ruby
# Main executor script
class PangeaExecutor
  def plan(template_spec) -> PlanResult
  def apply(template_spec) -> ApplyResult
  def detect_drift(template_spec) -> DriftReport
  def validate_compliance(template_spec) -> ComplianceReport
end
```

### 3. Drift Detector

**Location:** `lib/pangea/drift/detector.rb`

**Responsibilities:**
- Compare desired state (template) with actual state (cloud resources)
- Generate drift reports with resource-level detail
- Classify drift severity (critical, warning, info)
- Track drift history for trending

**Algorithm:**
```ruby
def detect_drift(template:, namespace:)
  # 1. Compile template to Terraform JSON
  compiled = compile_template(template)

  # 2. Generate plan (shows drift)
  plan_result = execute_plan(compiled, namespace)

  # 3. Parse plan output for changes
  drift_report = parse_drift(plan_result)

  # 4. Classify and enrich
  classify_drift_severity(drift_report)

  # 5. Return structured report
  drift_report
end
```

### 4. Compliance Validator (InSpec Integration)

**Location:** `lib/pangea/compliance/validator.rb`

**Responsibilities:**
- Run InSpec profiles against deployed infrastructure
- Generate compliance reports
- Track compliance over time
- Integrate with Pangea's resource metadata

**InSpec Profile Structure:**
```ruby
# Example InSpec profile for Pangea template
control 'aws-vpc-compliance' do
  impact 1.0
  title 'VPC Security Configuration'
  desc 'Ensure VPC meets security standards'

  # Use template metadata
  template_spec = attribute('pangea_template_spec')

  describe aws_vpc(template_spec[:vpc_id]) do
    it { should exist }
    its('cidr_block') { should eq template_spec[:cidr_block] }
    it { should_not have_default_security_group_with_full_access }
  end
end
```

---

## Build System Architecture

All components in the Pangea operator system follow the Nexus monorepo's standardized Nix build patterns, ensuring reproducible builds, efficient caching, and consistent deployment workflows across the entire platform.

### Build Philosophy

**CRITICAL REQUIREMENT**: All operator components MUST use nix-lib and nexus-deploy, following the same patterns as existing Rust services and web products. This ensures:

- **Reproducible Builds**: Nix flakes guarantee identical builds across environments
- **Efficient Caching**: Attic cache integration for fast CI/CD
- **Multi-Architecture Support**: AMD64 and ARM64 builds out of the box
- **Layered Container Images**: Optimal Docker layer caching via `pkgs.dockerTools.buildLayeredImage`
- **Standardized Deployment**: nexus-deploy handles build → push → deploy workflows
- **GitOps Integration**: Automatic manifest updates and FluxCD reconciliation

### Component Build Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Nix Flake Build Architecture                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────┐         ┌─────────────────────────────┐  │
│  │ Pangea Operator (Go) │         │ Pangea Executor (Ruby)      │  │
│  ├──────────────────────┤         ├─────────────────────────────┤  │
│  │ flake.nix            │         │ flake.nix                   │  │
│  │  ↓                   │         │  ↓                          │  │
│  │ nix-lib/             │         │ nix-lib/                    │  │
│  │   go-service.nix     │         │   ruby-tool.nix             │  │
│  │  ↓                   │         │  ↓                          │  │
│  │ buildGoModule        │         │ bundlerApp                  │  │
│  │  ↓                   │         │  ↓                          │  │
│  │ buildLayeredImage    │         │ buildLayeredImage           │  │
│  │  ↓                   │         │  ↓                          │  │
│  │ ghcr.io/pleme-io/    │         │ ghcr.io/pleme-io/           │  │
│  │   pangea-operator    │         │   pangea-executor           │  │
│  └──────────────────────┘         └─────────────────────────────┘  │
│           ↓                                    ↓                    │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │              nexus-deploy (Rust CLI Tool)                  │    │
│  │  • Build: nix build + Attic cache push                     │    │
│  │  • Push: skopeo with retries → GHCR                        │    │
│  │  • Deploy: Update K8s manifests → Git push → FluxCD        │    │
│  │  • Rollout: Monitor pod status in real-time                │    │
│  └────────────────────────────────────────────────────────────┘    │
│           ↓                                    ↓                    │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                  Kubernetes Cluster (FluxCD)               │    │
│  │  nix/k8s/clusters/orion/infrastructure/pangea/             │    │
│  │    ├── operator-deployment.yaml                            │    │
│  │    ├── executor-rbac.yaml                                  │    │
│  │    └── crds/                                               │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### 1. Pangea Operator (Go) Build Configuration

**Location:** `pkgs/operators/pangea-operator/flake.nix`

**Strategy:** Create `go-service.nix` helper in nix-lib (similar to existing `rust-service.nix`)

#### flake.nix Structure

```nix
{
  description = "Pangea Kubernetes Operator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nexus.url = "path:../../..";
    nix-lib.url = "path:../../../nix/lib";
  };

  outputs = { nixpkgs, flake-utils, nexus, nix-lib, ... }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (
      system:
        let
          # Import go-service.nix builder (to be created)
          goService = import "${nix-lib}/go-service.nix" {
            inherit system nixpkgs;
            nixLib = nix-lib;
            nexusDeploy = nexus.packages.${system}.nexus-deploy;
          };
        in
          goService {
            serviceName = "pangea-operator";
            src = ./.;
            description = "Pangea Kubernetes Operator for continuous drift detection";

            # Go-specific configuration
            goVersion = "1.23";
            vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update after first build

            # Build configuration
            buildInputs = [];  # Add any C dependencies if needed
            ldflags = [
              "-s"
              "-w"
              "-X main.version=\${version}"
            ];

            # Container configuration
            containerPorts = {
              metrics = 8080;
              health = 8081;
            };

            # Deployment configuration
            productName = "infrastructure";
            namespace = "pangea-system";
            cluster = "orion";
          }
    );
}
```

#### go-service.nix Implementation

**Location:** `nix/lib/go-service.nix` (to be created)

```nix
# ============================================================================
# GO SERVICE BUILDER - High-Level Abstraction for Go Microservices
# ============================================================================
# Mirrors the pattern of rust-service.nix for Go-based services
#
# Usage in service flake.nix:
#   let goService = import "${nix-lib}/go-service.nix" {
#     inherit system nixpkgs;
#     nixLib = nix-lib;
#     nexusDeploy = nexus.packages.${system}.nexus-deploy;
#   };
#   in goService {
#     serviceName = "pangea-operator";
#     src = ./.;
#     goVersion = "1.23";
#   }
#
{ nixpkgs, system, nixLib, nexusDeploy }: {
  serviceName,
  src,
  description ? "${serviceName} - Go Service",
  goVersion ? "1.23",
  vendorHash,
  buildInputs ? [],
  ldflags ? [],
  containerPorts ? {
    metrics = 8080;
    health = 8081;
  },
  productName ? "infrastructure",
  namespace ? "${productName}-staging",
  cluster ? "orion",
}: let
  pkgs = import nixpkgs { inherit system; };

  # Build the Go binary using buildGoModule
  goBinary = pkgs.buildGoModule {
    pname = serviceName;
    version = "0.1.0";
    inherit src vendorHash;

    inherit buildInputs ldflags;

    # Use specified Go version
    nativeBuildInputs = [ pkgs."go_${builtins.replaceStrings ["."] ["_"] goVersion}" ];

    # Standard Go build flags
    CGO_ENABLED = if buildInputs == [] then "0" else "1";
  };

  # Build multi-arch Docker images
  mkDockerImage = arch: pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/pleme-io/${serviceName}";
    tag = "latest";
    architecture = arch;

    contents = [
      goBinary
      pkgs.cacert  # For HTTPS
      pkgs.tzdata  # For timezone support
    ];

    config = {
      Cmd = [ "${goBinary}/bin/${serviceName}" ];
      ExposedPorts = builtins.mapAttrs (name: port: {}) containerPorts;
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  };

  dockerImage-amd64 = mkDockerImage "amd64";
  dockerImage-arm64 = mkDockerImage "arm64";

  # Deployment manifest path
  manifestPath = "../../nix/k8s/clusters/${cluster}/${namespace}/${serviceName}/deployment.yaml";

in {
  # Package outputs
  packages = {
    default = goBinary;
    inherit dockerImage-amd64 dockerImage-arm64;
  };

  # Development shell
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      go
      gopls
      gotools
      go-tools
      golangci-lint
      kubectl
      kubernetes-helm
    ] ++ buildInputs;

    shellHook = ''
      echo "Go ${goVersion} development environment for ${serviceName}"
      echo "Available commands:"
      echo "  go build -o bin/${serviceName} ."
      echo "  go test ./..."
      echo "  golangci-lint run"
    '';
  };

  # Apps for CI/CD workflow
  apps = {
    default = {
      type = "app";
      program = "${goBinary}/bin/${serviceName}";
    };

    # Build both images and push to Attic cache
    build = {
      type = "app";
      program = toString (pkgs.writeShellScript "build-${serviceName}" ''
        set -euo pipefail
        echo "Building ${serviceName} for amd64 and arm64..."
        nix build .#dockerImage-amd64
        nix build .#dockerImage-arm64
        echo "✅ Build complete"
      '');
    };

    # Push images to GHCR using nexus-deploy
    push = {
      type = "app";
      program = toString (pkgs.writeShellScript "push-${serviceName}" ''
        set -euo pipefail
        ${nexusDeploy}/bin/nexus-deploy push \
          --registry ghcr.io/pleme-io/${serviceName} \
          --retries 10 \
          --tag $(git rev-parse HEAD)
        echo "✅ Pushed to GHCR"
      '');
    };

    # Full deployment workflow using nexus-deploy
    deploy = {
      type = "app";
      program = toString (pkgs.writeShellScript "deploy-${serviceName}" ''
        set -euo pipefail
        ${nexusDeploy}/bin/nexus-deploy deploy \
          --manifest ${manifestPath} \
          --registry ghcr.io/pleme-io/${serviceName} \
          --watch \
          --timeout 10m
        echo "✅ Deployment complete"
      '');
    };

    # Complete release: build + push + deploy
    release = {
      type = "app";
      program = toString (pkgs.writeShellScript "release-${serviceName}" ''
        set -euo pipefail
        echo "🚀 Releasing ${serviceName}..."
        nix run .#build
        nix run .#push
        nix run .#deploy
        echo "✅ Release complete"
      '');
    };
  };
}
```

### 2. Pangea Executor (Ruby) Build Configuration

**Location:** `pkgs/operators/pangea-executor/flake.nix`

**Strategy:** Create `ruby-tool.nix` helper in nix-lib (similar to `rust-tool.nix`)

#### flake.nix Structure

```nix
{
  description = "Pangea Executor - Ruby infrastructure executor for Kubernetes operator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nexus.url = "path:../../..";
    nix-lib.url = "path:../../../nix/lib";
  };

  outputs = { nixpkgs, flake-utils, nexus, nix-lib, ... }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (
      system:
        let
          # Import ruby-tool.nix builder (to be created)
          rubyTool = import "${nix-lib}/ruby-tool.nix" {
            inherit system nixpkgs;
            nixLib = nix-lib;
            nexusDeploy = nexus.packages.${system}.nexus-deploy;
          };
        in
          rubyTool {
            toolName = "pangea-executor";
            src = ./.;
            description = "Pangea infrastructure executor with Terraform/OpenTofu and InSpec";

            # Ruby version
            rubyVersion = "3.3";

            # Include Pangea gem and dependencies
            gemfile = ./Gemfile;
            gemset = ./gemset.nix;  # Generated via bundix

            # Additional runtime dependencies
            runtimeDependencies = pkgs: with pkgs; [
              opentofu      # Infrastructure executor
              inspec        # Compliance testing
              git           # For GitOps
              awscli2       # Cloud provider CLI
            ];

            # Entry point script
            entryPoint = "bin/pangea-executor";

            # Container configuration
            containerUser = "pangea";
            containerWorkdir = "/workspace";

            # Deployment configuration
            productName = "infrastructure";
            namespace = "pangea-system";
            cluster = "orion";
          }
    );
}
```

#### ruby-tool.nix Implementation

**Location:** `nix/lib/ruby-tool.nix` (to be created)

```nix
# ============================================================================
# RUBY TOOL BUILDER - High-Level Abstraction for Ruby CLI Tools
# ============================================================================
# Mirrors the pattern of rust-tool.nix for Ruby-based tools
#
# Usage in tool flake.nix:
#   let rubyTool = import "${nix-lib}/ruby-tool.nix" {
#     inherit system nixpkgs;
#     nixLib = nix-lib;
#     nexusDeploy = nexus.packages.${system}.nexus-deploy;
#   };
#   in rubyTool {
#     toolName = "pangea-executor";
#     src = ./.;
#     rubyVersion = "3.3";
#   }
#
{ nixpkgs, system, nixLib, nexusDeploy }: {
  toolName,
  src,
  description ? "${toolName} - Ruby CLI Tool",
  rubyVersion ? "3.3",
  gemfile,
  gemset,
  runtimeDependencies ? pkgs: [],
  entryPoint ? "bin/${toolName}",
  containerUser ? "app",
  containerWorkdir ? "/app",
  productName ? "infrastructure",
  namespace ? "${productName}-staging",
  cluster ? "orion",
}: let
  pkgs = import nixpkgs { inherit system; };

  # Select Ruby version
  ruby = pkgs."ruby_${builtins.replaceStrings ["."] ["_"] rubyVersion}";

  # Build Ruby application with bundlerApp
  rubyApp = pkgs.bundlerApp {
    pname = toolName;
    inherit gemfile gemset;
    exes = [ toolName ];
    inherit ruby;
  };

  # Collect runtime dependencies
  allRuntimeDeps = [ rubyApp ruby ] ++ (runtimeDependencies pkgs);

  # Build multi-arch Docker images
  mkDockerImage = arch: pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/pleme-io/${toolName}";
    tag = "latest";
    architecture = arch;

    contents = allRuntimeDeps ++ (with pkgs; [
      cacert
      tzdata
      coreutils
      bash
    ]);

    config = {
      Cmd = [ "${rubyApp}/bin/${toolName}" ];
      WorkingDir = containerWorkdir;
      User = containerUser;
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "PATH=/bin:/usr/bin"
      ];
    };

    # Create non-root user
    extraCommands = ''
      mkdir -p ${containerWorkdir}
      mkdir -p etc
      echo "${containerUser}:x:1000:1000::/home/${containerUser}:/bin/bash" > etc/passwd
      echo "${containerUser}:x:1000:" > etc/group
    '';
  };

  dockerImage-amd64 = mkDockerImage "amd64";
  dockerImage-arm64 = mkDockerImage "arm64";

  # Deployment manifest path
  manifestPath = "../../nix/k8s/clusters/${cluster}/${namespace}/${toolName}/deployment.yaml";

in {
  # Package outputs
  packages = {
    default = rubyApp;
    inherit dockerImage-amd64 dockerImage-arm64;
  };

  # Development shell
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      ruby
      bundler
      bundix  # For generating gemset.nix
    ] ++ (runtimeDependencies pkgs);

    shellHook = ''
      echo "Ruby ${rubyVersion} development environment for ${toolName}"
      echo "Available commands:"
      echo "  bundle install"
      echo "  bundle exec ${toolName}"
      echo "  bundix  # Update gemset.nix after Gemfile changes"
    '';
  };

  # Apps for CI/CD workflow (same pattern as Go service)
  apps = {
    default = {
      type = "app";
      program = "${rubyApp}/bin/${toolName}";
    };

    build = {
      type = "app";
      program = toString (pkgs.writeShellScript "build-${toolName}" ''
        set -euo pipefail
        echo "Building ${toolName} for amd64 and arm64..."
        nix build .#dockerImage-amd64
        nix build .#dockerImage-arm64
        echo "✅ Build complete"
      '');
    };

    push = {
      type = "app";
      program = toString (pkgs.writeShellScript "push-${toolName}" ''
        set -euo pipefail
        ${nexusDeploy}/bin/nexus-deploy push \
          --registry ghcr.io/pleme-io/${toolName} \
          --retries 10 \
          --tag $(git rev-parse HEAD)
        echo "✅ Pushed to GHCR"
      '');
    };

    deploy = {
      type = "app";
      program = toString (pkgs.writeShellScript "deploy-${toolName}" ''
        set -euo pipefail
        ${nexusDeploy}/bin/nexus-deploy deploy \
          --manifest ${manifestPath} \
          --registry ghcr.io/pleme-io/${toolName} \
          --watch \
          --timeout 10m
        echo "✅ Deployment complete"
      '');
    };

    release = {
      type = "app";
      program = toString (pkgs.writeShellScript "release-${toolName}" ''
        set -euo pipefail
        echo "🚀 Releasing ${toolName}..."
        nix run .#build
        nix run .#push
        nix run .#deploy
        echo "✅ Release complete"
      '');
    };
  };
}
```

### 3. Kubernetes Manifests Integration

All operator components deploy to the Orion cluster via GitOps with FluxCD.

**Manifest Location:** `nix/k8s/clusters/orion/infrastructure/pangea/`

```
nix/k8s/clusters/orion/infrastructure/pangea/
├── namespace.yaml                    # pangea-system namespace
├── crds/
│   ├── pangeatemplate-crd.yaml      # Generated from operator
│   └── pangeastack-crd.yaml         # Generated from operator
├── operator/
│   ├── deployment.yaml              # Operator deployment
│   ├── service.yaml                 # Metrics service
│   ├── rbac.yaml                    # ClusterRole and binding
│   └── serviceaccount.yaml          # Service account
├── executor/
│   ├── configmap.yaml               # Executor configuration
│   ├── rbac.yaml                    # Executor RBAC
│   └── serviceaccount.yaml          # Service account for jobs
└── monitoring/
    ├── servicemonitor.yaml          # Prometheus ServiceMonitor
    └── grafana-dashboard.yaml       # Grafana dashboard ConfigMap
```

### 4. CI/CD Workflow with nexus-deploy

**GitHub Actions Workflow:** `.github/workflows/operator-release.yml`

```yaml
name: Release Pangea Operator

on:
  push:
    branches: [main]
    paths:
      - 'pkgs/operators/**'

jobs:
  release-operator:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@v13

      - name: Setup Nix Cache
        uses: DeterminateSystems/magic-nix-cache-action@v7

      - name: Build Operator
        working-directory: pkgs/operators/pangea-operator
        run: nix run .#build

      - name: Push Operator
        working-directory: pkgs/operators/pangea-operator
        run: nix run .#push
        env:
          GHCR_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Deploy Operator
        working-directory: pkgs/operators/pangea-operator
        run: nix run .#deploy
        env:
          KUBECONFIG: ${{ secrets.ORION_KUBECONFIG }}

  release-executor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@v13

      - name: Setup Nix Cache
        uses: DeterminateSystems/magic-nix-cache-action@v7

      - name: Build Executor
        working-directory: pkgs/operators/pangea-executor
        run: nix run .#build

      - name: Push Executor
        working-directory: pkgs/operators/pangea-executor
        run: nix run .#push
        env:
          GHCR_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Deploy Executor
        working-directory: pkgs/operators/pangea-executor
        run: nix run .#deploy
        env:
          KUBECONFIG: ${{ secrets.ORION_KUBECONFIG }}
```

### 5. Local Development Workflow

**Build and test locally:**

```bash
# Operator development
cd pkgs/operators/pangea-operator
nix develop                     # Enter dev shell
go build -o bin/manager .       # Build locally
go test ./...                   # Run tests
nix build .#dockerImage-amd64   # Build container
nix run .#build                 # Build both architectures

# Executor development
cd pkgs/operators/pangea-executor
nix develop                     # Enter dev shell with Ruby + Terraform + InSpec
bundle install                  # Install gems
bundle exec rspec               # Run tests
bundix                          # Update gemset.nix after Gemfile changes
nix build .#dockerImage-amd64   # Build container

# Test against local kind cluster
kind create cluster --name pangea-test
nix run .#deploy                # Deploy to kind cluster
kubectl apply -f examples/simple-template.yaml
```

### 6. Benefits of Nix Build System

This architecture provides:

1. **Reproducible Builds**: Same inputs → same outputs, always
2. **Efficient Caching**: Attic cache prevents rebuilding unchanged layers
3. **Multi-Architecture**: Single flake builds for AMD64 and ARM64
4. **Fast CI/CD**: Cached layers = fast builds (30s instead of 5min)
5. **Consistent Tooling**: Same pattern as all Nexus services
6. **Type Safety**: Nix catches configuration errors at build time
7. **Zero Shell Scripts**: All automation in type-safe Rust (nexus-deploy)
8. **GitOps Native**: nexus-deploy handles manifest updates automatically

---

## CRD Definitions

### PangeaTemplate CRD

**Purpose:** Represents a single Pangea template to be continuously reconciled

```yaml
apiVersion: pangea.io/v1alpha1
kind: PangeaTemplate
metadata:
  name: novaskyn-production-dns
  namespace: infrastructure
spec:
  # Source configuration
  source:
    type: git  # git | configmap | inline
    git:
      repository: https://github.com/pleme-io/nexus
      path: infrastructure/pangea/novaskyn/novaskyn_production_dns.rb
      ref: main
      authSecretRef:
        name: git-credentials

  # Pangea-specific configuration
  pangea:
    namespace: production  # Pangea namespace
    template: production_dns
    autoApprove: true

  # Reconciliation configuration
  reconciliation:
    mode: hybrid  # event-driven | periodic | hybrid
    interval: 5m
    timeout: 10m

  # Drift detection configuration
  driftDetection:
    enabled: true
    interval: 10m
    autoRemediate: true
    remediationPolicy: immediate  # immediate | manual | scheduled
    notifications:
      - type: slack
        channel: "#infrastructure-alerts"
        secretRef:
          name: slack-webhook
      - type: email
        recipients: ["oncall@example.com"]

  # Compliance configuration
  compliance:
    enabled: true
    profiles:
      - name: aws-security-baseline
        source:
          git: https://github.com/dev-sec/cis-aws-benchmark
      - name: custom-compliance
        source:
          configMap: custom-inspec-profile
    interval: 1h
    failOnNonCompliance: false

  # Health checks
  healthCheck:
    enabled: true
    interval: 1m
    checks:
      - type: terraform-state
        description: "Verify state file is accessible"
      - type: resource-health
        description: "Check cloud resources are healthy"

status:
  # Reconciliation status
  conditions:
    - type: Ready
      status: "True"
      lastTransitionTime: "2025-11-06T10:30:00Z"
      reason: ReconciliationSucceeded
      message: "Template successfully reconciled"

  # Current state
  observedGeneration: 5
  lastReconcileTime: "2025-11-06T10:30:00Z"
  lastSuccessfulReconcileTime: "2025-11-06T10:30:00Z"
  reconciliationDuration: "15s"

  # Resource summary
  resources:
    total: 4
    created: 4
    modified: 0
    deleted: 0

  # Drift status
  drift:
    detected: false
    lastCheckTime: "2025-11-06T10:29:00Z"
    nextCheckTime: "2025-11-06T10:39:00Z"
    resources: []

  # Compliance status
  compliance:
    status: Compliant
    lastCheckTime: "2025-11-06T09:00:00Z"
    nextCheckTime: "2025-11-06T10:00:00Z"
    passedControls: 15
    failedControls: 0
    score: 100
```

### PangeaStack CRD

**Purpose:** Represents a collection of related templates (multi-template orchestration)

```yaml
apiVersion: pangea.io/v1alpha1
kind: PangeaStack
metadata:
  name: novaskyn-production
  namespace: infrastructure
spec:
  templates:
    - name: novaskyn-vpc
      templateRef:
        name: novaskyn-production-vpc
    - name: novaskyn-dns
      templateRef:
        name: novaskyn-production-dns
      dependsOn:
        - novaskyn-vpc
    - name: novaskyn-compute
      templateRef:
        name: novaskyn-production-compute
      dependsOn:
        - novaskyn-vpc
        - novaskyn-dns

  reconciliation:
    mode: sequential  # sequential | parallel
    continueOnError: false

status:
  phase: Ready  # Pending | Running | Ready | Failed
  templatesReady: 3
  templatesTotal: 3
  lastReconcileTime: "2025-11-06T10:30:00Z"
```

---

## Reconciliation Strategy

### Reconciliation Loop Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  Reconciliation Trigger                      │
│  (CRD change | Periodic timer | Manual trigger)             │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Fetch PangeaTemplate Resource                           │
│    - Get current spec                                       │
│    - Read generation number                                 │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Validate Specification                                   │
│    - Check source accessibility (Git/ConfigMap)            │
│    - Validate Pangea namespace exists                      │
│    - Verify credentials                                     │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Create/Update Executor Job                              │
│    - Prepare ConfigMap with template source                │
│    - Mount credentials (AWS, Git, etc.)                    │
│    - Set environment variables                              │
│    - Launch Kubernetes Job                                  │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Execute Pangea Plan                                      │
│    - Compile template to Terraform JSON                    │
│    - Run `terraform plan` / `tofu plan`                    │
│    - Capture output and parse changes                      │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
                     ┌─────────────┐
                     │  Changes?   │
                     └──────┬──────┘
                   Yes ←────┴────→ No
                    ↓              ↓
    ┌──────────────────────────┐  │
    │ 5a. Drift Detected       │  │
    │  - Log drift details     │  │
    │  - Emit K8s event        │  │
    │  - Send notifications    │  │
    └──────────┬───────────────┘  │
               ↓                  ↓
    ┌──────────────────────────┐ │
    │ 6. Check Auto-Remediate  │ │
    └──────────┬───────────────┘ │
      Enabled  │  Disabled       │
          ↓    ↓                 ↓
    ┌─────────────────────┐ ┌───────────────┐
    │ 7a. Execute Apply   │ │ 7b. Update    │
    │  - Run pangea apply │ │     Status    │
    │  - Update resources │ │  - Mark drift │
    │  - Log changes      │ │  - Requeue    │
    └──────────┬──────────┘ └───────┬───────┘
               ↓                    ↓
    ┌──────────────────────────────────────┐
    │ 8. Run Compliance Checks (If Enabled)│
    │  - Execute InSpec profiles           │
    │  - Generate compliance report        │
    └──────────┬───────────────────────────┘
               ↓
    ┌──────────────────────────────────────┐
    │ 9. Update Status Conditions          │
    │  - Set Ready/Failed condition        │
    │  - Update observedGeneration         │
    │  - Record metrics                    │
    │  - Update resource counts            │
    └──────────┬───────────────────────────┘
               ↓
    ┌──────────────────────────────────────┐
    │ 10. Schedule Next Reconciliation     │
    │  - Requeue based on interval         │
    │  - Or wait for next trigger          │
    └──────────────────────────────────────┘
```

### Reconciliation Timing

| Mode | Trigger | Requeue Interval |
|------|---------|------------------|
| **Event-Driven** | CRD spec change | On change only |
| **Periodic** | Timer | Configurable (default: 5m) |
| **Hybrid** | Both | On change + periodic |

### Error Handling & Retries

```go
// Reconciliation result determines requeue behavior
type ReconcileResult struct {
    Requeue      bool
    RequeueAfter time.Duration
}

// Exponential backoff for errors
func (r *TemplateReconciler) handleError(err error, attempt int) ReconcileResult {
    if attempt > maxRetries {
        // Give up after max retries
        return ReconcileResult{Requeue: false}
    }

    backoff := calculateBackoff(attempt) // 1s, 2s, 4s, 8s, 16s...

    return ReconcileResult{
        Requeue:      true,
        RequeueAfter: backoff,
    }
}
```

---

## Testing Framework Integration

### Three-Layer Testing Strategy

#### Layer 1: RSpec Unit & Integration Tests

**Purpose:** Test Ruby components and Pangea integration logic

**Location:** `spec/operators/`

**Test Categories:**

1. **Executor Tests** (`spec/operators/executor_spec.rb`)
```ruby
RSpec.describe PangeaExecutor do
  describe '#plan' do
    it 'generates valid plan output' do
      executor = PangeaExecutor.new
      result = executor.plan(template_spec)

      expect(result).to be_success
      expect(result.changes).to be_a(Hash)
      expect(result.terraform_json).to be_valid_json
    end

    it 'handles template compilation errors' do
      executor = PangeaExecutor.new
      invalid_spec = build(:invalid_template_spec)

      result = executor.plan(invalid_spec)

      expect(result).to be_failure
      expect(result.error).to include('compilation failed')
    end
  end

  describe '#detect_drift' do
    it 'detects infrastructure drift accurately' do
      executor = PangeaExecutor.new

      # Setup: Deploy infrastructure
      executor.apply(template_spec)

      # Simulate external change (out-of-band modification)
      simulate_external_change

      # Test: Drift detection
      drift = executor.detect_drift(template_spec)

      expect(drift.detected?).to be true
      expect(drift.resources).to include(
        type: 'aws_route53_record',
        name: 'www',
        drift: 'records changed'
      )
    end
  end
end
```

2. **Drift Detector Tests** (`spec/drift/detector_spec.rb`)
```ruby
RSpec.describe Pangea::Drift::Detector do
  describe '#detect' do
    context 'when infrastructure matches template' do
      it 'reports no drift' do
        detector = described_class.new
        report = detector.detect(template: template, namespace: 'production')

        expect(report.drift_detected?).to be false
        expect(report.resources_changed).to be_empty
      end
    end

    context 'when infrastructure has drifted' do
      it 'identifies specific resource changes' do
        detector = described_class.new

        # Modify infrastructure externally
        modify_resource_externally('aws_s3_bucket.example',
          attribute: 'versioning',
          value: 'Disabled'
        )

        report = detector.detect(template: template, namespace: 'production')

        expect(report.drift_detected?).to be true
        expect(report.drifted_resources).to include(
          resource: 'aws_s3_bucket.example',
          attribute: 'versioning',
          expected: 'Enabled',
          actual: 'Disabled'
        )
      end

      it 'classifies drift severity correctly' do
        detector = described_class.new

        # Critical drift: security group opened
        modify_security_group('sg-12345', ingress: '0.0.0.0/0')

        report = detector.detect(template: template, namespace: 'production')

        expect(report.severity).to eq(:critical)
        expect(report.requires_immediate_action?).to be true
      end
    end
  end
end
```

3. **Compliance Validator Tests** (`spec/compliance/validator_spec.rb`)
```ruby
RSpec.describe Pangea::Compliance::Validator do
  describe '#validate' do
    it 'runs InSpec profiles against infrastructure' do
      validator = described_class.new

      result = validator.validate(
        template_spec: template_spec,
        profiles: ['aws-security-baseline']
      )

      expect(result.controls_passed).to eq(15)
      expect(result.controls_failed).to eq(0)
      expect(result.compliance_score).to eq(100)
    end

    it 'reports failed compliance controls' do
      validator = described_class.new

      # Create non-compliant infrastructure
      create_insecure_bucket('test-bucket')

      result = validator.validate(
        template_spec: template_spec,
        profiles: ['aws-security-baseline']
      )

      expect(result.compliance_score).to be < 100
      expect(result.failed_controls).to include(
        control_id: 's3-bucket-encryption',
        severity: 'critical',
        resource: 'aws_s3_bucket.test-bucket'
      )
    end
  end
end
```

#### Layer 2: InSpec Infrastructure Tests

**Purpose:** Validate deployed infrastructure compliance and security

**Location:** `spec/compliance/profiles/`

**Profile Structure:**
```
spec/compliance/profiles/
├── aws-baseline/
│   ├── controls/
│   │   ├── vpc_controls.rb
│   │   ├── s3_controls.rb
│   │   └── iam_controls.rb
│   └── inspec.yml
├── kubernetes-baseline/
│   ├── controls/
│   │   ├── rbac_controls.rb
│   │   └── pod_security_controls.rb
│   └── inspec.yml
└── pangea-template/
    ├── controls/
    │   └── template_compliance.rb
    └── inspec.yml
```

**Example InSpec Profile:**
```ruby
# spec/compliance/profiles/aws-baseline/controls/s3_controls.rb

control 's3-bucket-encryption' do
  impact 1.0
  title 'S3 Bucket Encryption'
  desc 'All S3 buckets must have encryption enabled'

  # Get bucket IDs from Pangea template metadata
  template_spec = attribute('pangea_template_spec')
  s3_buckets = template_spec.dig(:resources, :s3_buckets) || []

  s3_buckets.each do |bucket_name|
    describe aws_s3_bucket(bucket_name) do
      it { should exist }
      it { should have_default_encryption_enabled }
      its('bucket_encryption_algorithm') { should eq 'AES256' }
    end
  end
end

control 's3-bucket-versioning' do
  impact 0.8
  title 'S3 Bucket Versioning'
  desc 'Production S3 buckets should have versioning enabled'

  template_spec = attribute('pangea_template_spec')
  environment = template_spec.dig(:namespace)

  only_if { environment == 'production' }

  s3_buckets = template_spec.dig(:resources, :s3_buckets) || []

  s3_buckets.each do |bucket_name|
    describe aws_s3_bucket(bucket_name) do
      it { should have_versioning_enabled }
    end
  end
end

control 's3-bucket-public-access' do
  impact 1.0
  title 'S3 Bucket Public Access Block'
  desc 'S3 buckets must block all public access'

  template_spec = attribute('pangea_template_spec')
  s3_buckets = template_spec.dig(:resources, :s3_buckets) || []

  s3_buckets.each do |bucket_name|
    describe aws_s3_bucket(bucket_name) do
      it { should have_access_logging_enabled }
      it { should_not be_public }
      its('bucket_acl.grants') { should_not include(grantee_type: 'AllUsers') }
    end
  end
end
```

**Running InSpec Tests:**
```bash
# Run InSpec profile against deployed infrastructure
inspec exec spec/compliance/profiles/aws-baseline \
  --input-file template-metadata.json \
  --reporter json:compliance-report.json cli

# Automated execution via executor pod
ruby -r pangea/compliance/validator -e '
  validator = Pangea::Compliance::Validator.new
  result = validator.validate(
    template_spec: load_template_spec,
    profiles: ["aws-baseline", "pangea-template"]
  )

  puts JSON.pretty_generate(result.to_h)
'
```

#### Layer 3: End-to-End Operator Tests

**Purpose:** Test complete operator behavior in Kubernetes

**Location:** `spec/operators/e2e/`

**Test Framework:** Go testing + Ruby RSpec

**Test Scenarios:**

1. **Reconciliation Tests** (`spec/operators/e2e/reconciliation_test.go`)
```go
func TestTemplateReconciliation(t *testing.T) {
    // Setup test cluster
    testEnv := setupTestEnvironment(t)
    defer testEnv.Cleanup()

    // Create PangeaTemplate resource
    template := &pangeav1alpha1.PangeaTemplate{
        ObjectMeta: metav1.ObjectMeta{
            Name:      "test-template",
            Namespace: "default",
        },
        Spec: pangeav1alpha1.PangeaTemplateSpec{
            Source: pangeav1alpha1.SourceSpec{
                Type: "configmap",
                ConfigMap: &pangeav1alpha1.ConfigMapSource{
                    Name: "test-template-source",
                },
            },
            Pangea: pangeav1alpha1.PangeaSpec{
                Namespace: "development",
                Template:  "web_server",
            },
            Reconciliation: pangeav1alpha1.ReconciliationSpec{
                Mode: "event-driven",
            },
        },
    }

    err := testEnv.Client.Create(context.TODO(), template)
    assert.NoError(t, err)

    // Wait for reconciliation
    Eventually(func() bool {
        var updated pangeav1alpha1.PangeaTemplate
        err := testEnv.Client.Get(context.TODO(),
            types.NamespacedName{Name: "test-template", Namespace: "default"},
            &updated)

        if err != nil {
            return false
        }

        return updated.Status.Conditions[0].Type == "Ready" &&
               updated.Status.Conditions[0].Status == "True"
    }, timeout, interval).Should(BeTrue())

    // Verify resources were created
    var updated pangeav1alpha1.PangeaTemplate
    err = testEnv.Client.Get(context.TODO(),
        types.NamespacedName{Name: "test-template", Namespace: "default"},
        &updated)
    assert.NoError(t, err)
    assert.Equal(t, 4, updated.Status.Resources.Total)
    assert.Equal(t, 4, updated.Status.Resources.Created)
}
```

2. **Drift Detection Tests** (`spec/operators/e2e/drift_detection_test.go`)
```go
func TestDriftDetectionAndRemediation(t *testing.T) {
    testEnv := setupTestEnvironment(t)
    defer testEnv.Cleanup()

    // Create template with drift detection enabled
    template := createTemplateWithDrift(t, testEnv, &pangeav1alpha1.DriftDetectionSpec{
        Enabled:       true,
        Interval:      metav1.Duration{Duration: 1 * time.Minute},
        AutoRemediate: true,
    })

    // Wait for initial reconciliation
    waitForTemplateReady(t, testEnv, template)

    // Simulate external drift (modify infrastructure outside of Pangea)
    simulateExternalDrift(t, template.Spec.Pangea.Namespace)

    // Wait for drift detection
    Eventually(func() bool {
        var updated pangeav1alpha1.PangeaTemplate
        testEnv.Client.Get(context.TODO(),
            types.NamespacedName{Name: template.Name, Namespace: template.Namespace},
            &updated)

        return updated.Status.Drift.Detected == true
    }, timeout, interval).Should(BeTrue())

    // Wait for auto-remediation
    Eventually(func() bool {
        var updated pangeav1alpha1.PangeaTemplate
        testEnv.Client.Get(context.TODO(),
            types.NamespacedName{Name: template.Name, Namespace: template.Namespace},
            &updated)

        return updated.Status.Drift.Detected == false
    }, timeout, interval).Should(BeTrue())

    // Verify infrastructure was corrected
    verifyInfrastructureState(t, template)
}
```

3. **Compliance Validation Tests** (`spec/operators/e2e/compliance_validation_spec.rb`)
```ruby
RSpec.describe 'Compliance Validation E2E' do
  let(:k8s_client) { Kubernetes::Client.new }
  let(:template_name) { 'compliance-test-template' }

  before(:all) do
    # Create test template with compliance enabled
    create_template_with_compliance
  end

  after(:all) do
    # Cleanup
    delete_template(template_name)
  end

  it 'runs compliance checks on schedule' do
    # Wait for first compliance check
    sleep 65 # Wait for 1-minute interval

    # Fetch template status
    template = k8s_client.get_resource(
      'PangeaTemplate',
      template_name,
      'infrastructure'
    )

    expect(template.status.compliance.status).to eq('Compliant')
    expect(template.status.compliance.passedControls).to be > 0
    expect(template.status.compliance.score).to eq(100)
  end

  it 'detects non-compliant infrastructure' do
    # Create non-compliant resource
    create_insecure_s3_bucket('test-insecure-bucket')

    # Trigger compliance check
    trigger_compliance_check(template_name)

    # Wait for check completion
    sleep 30

    # Fetch updated status
    template = k8s_client.get_resource(
      'PangeaTemplate',
      template_name,
      'infrastructure'
    )

    expect(template.status.compliance.status).to eq('NonCompliant')
    expect(template.status.compliance.failedControls).to be > 0
    expect(template.status.compliance.score).to be < 100

    # Verify Kubernetes event was emitted
    events = k8s_client.get_events(
      field_selector: "involvedObject.name=#{template_name}"
    )

    expect(events).to include(
      reason: 'ComplianceCheckFailed',
      message: /s3-bucket-encryption/
    )
  end
end
```

### Testing Pipeline

```yaml
# .github/workflows/operator-tests.yml
name: Operator Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
      - name: Run RSpec unit tests
        run: |
          bundle install
          rspec spec/operators/ \
            --exclude-pattern "spec/operators/e2e/**"

  inspec-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    steps:
      - uses: actions/checkout@v4
      - name: Setup InSpec
        run: |
          curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
      - name: Validate InSpec profiles
        run: |
          inspec check spec/compliance/profiles/aws-baseline
          inspec check spec/compliance/profiles/kubernetes-baseline

  e2e-tests:
    runs-on: ubuntu-latest
    needs: [unit-tests, inspec-tests]
    steps:
      - uses: actions/checkout@v4
      - name: Setup kind cluster
        uses: helm/kind-action@v1
      - name: Build operator image
        run: |
          make docker-build
          kind load docker-image pangea-operator:test
      - name: Deploy operator
        run: |
          make deploy IMG=pangea-operator:test
      - name: Run E2E tests
        run: |
          go test ./test/e2e/... -v -timeout 30m
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

**Goal:** Build core operator infrastructure

**Tasks:**
1. ✅ Create Go operator scaffold with Kubebuilder
2. ✅ Define PangeaTemplate CRD
3. ✅ Implement basic reconciliation loop
4. ✅ Create executor pod specification
5. ✅ Set up development environment (kind cluster)

**Deliverables:**
- Operator watches PangeaTemplate CRDs
- Spawns executor pods
- Basic status updates
- Local development workflow

**Success Criteria:**
- Operator can create/delete executor pods
- CRD spec is validated
- Status conditions are updated

### Phase 2: Drift Detection (Weeks 3-4)

**Goal:** Implement continuous drift detection

**Tasks:**
1. ✅ Implement drift detector in Ruby
2. ✅ Integrate drift detection into reconciliation loop
3. ✅ Add drift scheduling (periodic checks)
4. ✅ Implement drift reporting and status updates
5. ✅ Add Kubernetes events for drift detection

**Deliverables:**
- Automated drift detection on schedule
- Detailed drift reports in status
- Event emission for drift
- Drift history tracking

**Success Criteria:**
- Detects drift within 1 minute of external change
- Accurate drift classification
- Clear status reporting

### Phase 3: Auto-Remediation (Weeks 5-6)

**Goal:** Implement automatic drift remediation

**Tasks:**
1. ✅ Implement remediation policies (immediate, manual, scheduled)
2. ✅ Add safety checks and validation before remediation
3. ✅ Implement notification system (Slack, email, webhooks)
4. ✅ Add audit logging for all remediation actions
5. ✅ Create emergency override mechanisms

**Deliverables:**
- Configurable auto-remediation
- Multi-channel notifications
- Audit trail
- Safety mechanisms

**Success Criteria:**
- Auto-remediation works correctly
- No false positives in production
- Clear audit trail

### Phase 4: Compliance Integration (Weeks 7-8)

**Goal:** Integrate InSpec for continuous compliance

**Tasks:**
1. ✅ Create InSpec wrapper in Ruby
2. ✅ Implement compliance validator
3. ✅ Create baseline InSpec profiles
4. ✅ Add compliance reporting to CRD status
5. ✅ Integrate compliance into reconciliation

**Deliverables:**
- Automated compliance checks
- Pre-built compliance profiles
- Compliance dashboard data
- Compliance-as-code examples

**Success Criteria:**
- Compliance checks run on schedule
- Accurate compliance scoring
- Clear non-compliance reporting

### Phase 5: Testing & Hardening (Weeks 9-10)

**Goal:** Comprehensive testing and production readiness

**Tasks:**
1. ✅ Write RSpec unit tests (>80% coverage)
2. ✅ Create InSpec profiles for all resource types
3. ✅ Build E2E test suite
4. ✅ Performance testing and optimization
5. ✅ Security audit and hardening

**Deliverables:**
- Complete test suite
- Performance benchmarks
- Security documentation
- Production deployment guide

**Success Criteria:**
- >80% test coverage
- All E2E tests pass
- Security audit complete
- Documentation complete

### Phase 6: Production Deployment (Weeks 11-12)

**Goal:** Deploy to production clusters

**Tasks:**
1. ✅ Create Helm chart
2. ✅ Set up monitoring and alerting
3. ✅ Create runbooks and documentation
4. ✅ Gradual rollout to production
5. ✅ Post-deployment validation

**Deliverables:**
- Production Helm chart
- Monitoring dashboards
- Operational runbooks
- Production deployment

**Success Criteria:**
- Operator running in production
- Zero downtime deployment
- Monitoring operational
- Documentation complete

---

## Task Breakdown for Agents

This section provides detailed, step-by-step tasks that an AI agent can execute without losing context. Each task is atomic, testable, and includes clear success criteria.

### Phase 1 Tasks

#### Task 1.1: Initialize Operator Project with Nix Build System

**Objective:** Create Go operator scaffold with Nix flake for reproducible builds

**Steps:**
1. Install kubebuilder v3.14+
   ```bash
   curl -L -o kubebuilder https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)
   chmod +x kubebuilder
   sudo mv kubebuilder /usr/local/bin/
   ```

2. Initialize new operator project
   ```bash
   mkdir -p pkgs/operators/pangea-operator
   cd pkgs/operators/pangea-operator
   kubebuilder init --domain pangea.io --repo github.com/pleme-io/nexus/pkgs/operators/pangea-operator
   ```

3. Create API scaffold
   ```bash
   kubebuilder create api --group pangea --version v1alpha1 --kind PangeaTemplate
   # Answer 'y' to both prompts
   ```

4. **NEW: Create Nix flake for operator**
   ```bash
   # Create flake.nix (see Build System Architecture section for complete example)
   cat > flake.nix <<'EOF'
   {
     description = "Pangea Kubernetes Operator";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
       flake-utils.url = "github:numtide/flake-utils";
       nexus.url = "path:../../..";
       nix-lib.url = "path:../../../nix/lib";
     };

     outputs = { nixpkgs, flake-utils, nexus, nix-lib, ... }:
       flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (
         system:
           let
             goService = import "${nix-lib}/go-service.nix" {
               inherit system nixpkgs;
               nixLib = nix-lib;
               nexusDeploy = nexus.packages.${system}.nexus-deploy;
             };
           in
             goService {
               serviceName = "pangea-operator";
               src = ./.;
               description = "Pangea Kubernetes Operator for continuous drift detection";
               goVersion = "1.23";
               vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
               buildInputs = [];
               ldflags = ["-s" "-w" "-X main.version=\${version}"];
               containerPorts = { metrics = 8080; health = 8081; };
               productName = "infrastructure";
               namespace = "pangea-system";
               cluster = "orion";
             }
       );
   }
   EOF
   ```

5. **NEW: Create go-service.nix helper in nix-lib**
   ```bash
   # Navigate to nix-lib directory
   cd ../../../nix/lib

   # Create go-service.nix (see Build System Architecture section for complete implementation)
   # This file mirrors the pattern of rust-service.nix for Go services
   ```

6. Verify scaffold and Nix build
   ```bash
   cd pkgs/operators/pangea-operator

   # Traditional Go build
   make manifests
   make generate
   go build -o bin/manager main.go

   # Nix build (generates vendorHash on first run)
   go mod vendor
   nix-hash --type sha256 --sri --base64 <(tar -c vendor)  # Update vendorHash in flake.nix
   nix build .#default  # Build the operator binary
   nix build .#dockerImage-amd64  # Build container image
   ```

7. **NEW: Test Nix development shell**
   ```bash
   nix develop
   # Verify you have: go, gopls, gotools, golangci-lint, kubectl, helm
   go version  # Should show Go 1.23
   ```

**Success Criteria:**
- Project builds without errors (both `go build` and `nix build`)
- CRD manifests generated in `config/crd/bases/`
- Controller code exists in `controllers/pangeatemplate_controller.go`
- Nix flake builds successfully: `nix build .#default`
- Docker image builds: `nix build .#dockerImage-amd64`
- Development shell works: `nix develop`

**Output Files:**
- `PROJECT` (kubebuilder project file)
- `Makefile` (kubebuilder makefile)
- `main.go` (operator entry point)
- `api/v1alpha1/pangeatemplate_types.go` (CRD types)
- `controllers/pangeatemplate_controller.go` (reconciler)
- `flake.nix` (Nix build configuration)
- `flake.lock` (Nix dependency lock file)
- `go.mod` and `go.sum` (Go dependencies)
- `vendor/` (Go vendored dependencies for Nix)
- `nix/lib/go-service.nix` (Go service builder helper)

#### Task 1.2: Define PangeaTemplate CRD Spec

**Objective:** Implement complete CRD specification

**File to Edit:** `api/v1alpha1/pangeatemplate_types.go`

**Steps:**
1. Add import statements
   ```go
   import (
       metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
       corev1 "k8s.io/api/core/v1"
   )
   ```

2. Define source specification
   ```go
   type SourceSpec struct {
       // Type of source (git, configmap, inline)
       // +kubebuilder:validation:Enum=git;configmap;inline
       Type string `json:"type"`

       // Git source configuration
       // +optional
       Git *GitSource `json:"git,omitempty"`

       // ConfigMap source configuration
       // +optional
       ConfigMap *ConfigMapSource `json:"configMap,omitempty"`

       // Inline template content
       // +optional
       Inline *string `json:"inline,omitempty"`
   }

   type GitSource struct {
       Repository string `json:"repository"`
       Path       string `json:"path"`
       Ref        string `json:"ref"`

       // +optional
       AuthSecretRef *corev1.LocalObjectReference `json:"authSecretRef,omitempty"`
   }

   type ConfigMapSource struct {
       Name string `json:"name"`
       Key  string `json:"key,omitempty"`
   }
   ```

3. Define Pangea spec
   ```go
   type PangeaSpec struct {
       // Pangea namespace (not K8s namespace)
       Namespace string `json:"namespace"`

       // Template name
       Template string `json:"template"`

       // Auto-approve changes
       // +optional
       // +kubebuilder:default=true
       AutoApprove bool `json:"autoApprove,omitempty"`
   }
   ```

4. Define reconciliation spec
   ```go
   type ReconciliationSpec struct {
       // +kubebuilder:validation:Enum=event-driven;periodic;hybrid
       // +kubebuilder:default=hybrid
       Mode string `json:"mode"`

       // +optional
       // +kubebuilder:default="5m"
       Interval metav1.Duration `json:"interval,omitempty"`

       // +optional
       // +kubebuilder:default="10m"
       Timeout metav1.Duration `json:"timeout,omitempty"`
   }
   ```

5. Define drift detection spec
   ```go
   type DriftDetectionSpec struct {
       Enabled bool `json:"enabled"`

       // +optional
       // +kubebuilder:default="10m"
       Interval metav1.Duration `json:"interval,omitempty"`

       // +optional
       // +kubebuilder:default=true
       AutoRemediate bool `json:"autoRemediate,omitempty"`

       // +kubebuilder:validation:Enum=immediate;manual;scheduled
       // +kubebuilder:default=immediate
       RemediationPolicy string `json:"remediationPolicy,omitempty"`

       // +optional
       Notifications []NotificationSpec `json:"notifications,omitempty"`
   }

   type NotificationSpec struct {
       // +kubebuilder:validation:Enum=slack;email;webhook
       Type string `json:"type"`

       // +optional
       Channel string `json:"channel,omitempty"`

       // +optional
       Recipients []string `json:"recipients,omitempty"`

       // +optional
       SecretRef *corev1.LocalObjectReference `json:"secretRef,omitempty"`
   }
   ```

6. Define complete PangeaTemplateSpec
   ```go
   type PangeaTemplateSpec struct {
       Source          SourceSpec          `json:"source"`
       Pangea          PangeaSpec          `json:"pangea"`
       Reconciliation  ReconciliationSpec  `json:"reconciliation"`
       DriftDetection  DriftDetectionSpec  `json:"driftDetection"`
       // Add more fields as needed
   }
   ```

7. Define status spec
   ```go
   type PangeaTemplateStatus struct {
       // +optional
       Conditions []metav1.Condition `json:"conditions,omitempty"`

       // +optional
       ObservedGeneration int64 `json:"observedGeneration,omitempty"`

       // +optional
       LastReconcileTime *metav1.Time `json:"lastReconcileTime,omitempty"`

       // +optional
       Resources ResourceStatus `json:"resources,omitempty"`

       // +optional
       Drift DriftStatus `json:"drift,omitempty"`
   }

   type ResourceStatus struct {
       Total    int `json:"total"`
       Created  int `json:"created"`
       Modified int `json:"modified"`
       Deleted  int `json:"deleted"`
   }

   type DriftStatus struct {
       Detected      bool         `json:"detected"`
       LastCheckTime *metav1.Time `json:"lastCheckTime,omitempty"`
       NextCheckTime *metav1.Time `json:"nextCheckTime,omitempty"`
       Resources     []DriftedResource `json:"resources,omitempty"`
   }

   type DriftedResource struct {
       Type      string `json:"type"`
       Name      string `json:"name"`
       Attribute string `json:"attribute"`
       Expected  string `json:"expected"`
       Actual    string `json:"actual"`
   }
   ```

8. Update PangeaTemplate struct
   ```go
   // +kubebuilder:object:root=true
   // +kubebuilder:subresource:status
   // +kubebuilder:printcolumn:name="Ready",type=string,JSONPath=`.status.conditions[?(@.type=="Ready")].status`
   // +kubebuilder:printcolumn:name="Drift",type=boolean,JSONPath=`.status.drift.detected`
   // +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"
   type PangeaTemplate struct {
       metav1.TypeMeta   `json:",inline"`
       metav1.ObjectMeta `json:"metadata,omitempty"`

       Spec   PangeaTemplateSpec   `json:"spec,omitempty"`
       Status PangeaTemplateStatus `json:"status,omitempty"`
   }
   ```

9. Generate manifests and code
   ```bash
   make manifests
   make generate
   ```

**Success Criteria:**
- Code compiles without errors
- CRD YAML is generated with all fields
- Validation rules are present
- Print columns are defined

**Verification:**
```bash
cat config/crd/bases/pangea.io_pangeatemplate.yaml | grep "type:" | wc -l
# Should show multiple type definitions

make test
# Should pass
```

#### Task 1.3: Implement Basic Reconciliation Loop

**Objective:** Create functional reconciliation logic

**File to Edit:** `controllers/pangeatemplate_controller.go`

**Steps:**
1. Update imports
   ```go
   import (
       "context"
       "fmt"
       "time"

       "k8s.io/apimachinery/pkg/runtime"
       ctrl "sigs.k8s.io/controller-runtime"
       "sigs.k8s.io/controller-runtime/pkg/client"
       "sigs.k8s.io/controller-runtime/pkg/log"

       pangeav1alpha1 "github.com/pleme-io/nexus/pkgs/operators/pangea-operator/api/v1alpha1"
   )
   ```

2. Implement Reconcile function
   ```go
   func (r *PangeaTemplateReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
       logger := log.FromContext(ctx)
       logger.Info("Reconciling PangeaTemplate", "name", req.Name, "namespace", req.Namespace)

       // 1. Fetch the PangeaTemplate resource
       var template pangeav1alpha1.PangeaTemplate
       if err := r.Get(ctx, req.NamespacedName, &template); err != nil {
           return ctrl.Result{}, client.IgnoreNotFound(err)
       }

       // 2. Initialize status if needed
       if template.Status.Conditions == nil {
           template.Status.Conditions = []metav1.Condition{}
       }

       // 3. Validate specification
       if err := r.validateSpec(&template); err != nil {
           logger.Error(err, "Invalid template specification")
           return r.updateStatusError(ctx, &template, err)
       }

       // 4. Execute reconciliation
       if err := r.reconcileTemplate(ctx, &template); err != nil {
           logger.Error(err, "Reconciliation failed")
           return r.updateStatusError(ctx, &template, err)
       }

       // 5. Update status with success
       if err := r.updateStatusSuccess(ctx, &template); err != nil {
           logger.Error(err, "Failed to update status")
           return ctrl.Result{}, err
       }

       // 6. Calculate requeue interval based on mode
       requeueAfter := r.calculateRequeueInterval(&template)

       logger.Info("Reconciliation complete", "requeueAfter", requeueAfter)
       return ctrl.Result{RequeueAfter: requeueAfter}, nil
   }
   ```

3. Implement helper functions
   ```go
   func (r *PangeaTemplateReconciler) validateSpec(template *pangeav1alpha1.PangeaTemplate) error {
       // Validate source configuration
       if template.Spec.Source.Type == "" {
           return fmt.Errorf("source type is required")
       }

       switch template.Spec.Source.Type {
       case "git":
           if template.Spec.Source.Git == nil {
               return fmt.Errorf("git source configuration is required")
           }
           if template.Spec.Source.Git.Repository == "" {
               return fmt.Errorf("git repository is required")
           }
       case "configmap":
           if template.Spec.Source.ConfigMap == nil {
               return fmt.Errorf("configmap source configuration is required")
           }
       case "inline":
           if template.Spec.Source.Inline == nil || *template.Spec.Source.Inline == "" {
               return fmt.Errorf("inline template content is required")
           }
       default:
           return fmt.Errorf("unsupported source type: %s", template.Spec.Source.Type)
       }

       return nil
   }

   func (r *PangeaTemplateReconciler) reconcileTemplate(ctx context.Context, template *pangeav1alpha1.PangeaTemplate) error {
       logger := log.FromContext(ctx)

       // For now, just log that we would execute
       logger.Info("Would execute Pangea template",
           "namespace", template.Spec.Pangea.Namespace,
           "template", template.Spec.Pangea.Template)

       // TODO: Actually spawn executor pod and run Pangea
       // This will be implemented in later tasks

       return nil
   }

   func (r *PangeaTemplateReconciler) updateStatusSuccess(ctx context.Context, template *pangeav1alpha1.PangeaTemplate) error {
       // Update condition
       meta.SetStatusCondition(&template.Status.Conditions, metav1.Condition{
           Type:    "Ready",
           Status:  metav1.ConditionTrue,
           Reason:  "ReconciliationSucceeded",
           Message: "Template successfully reconciled",
       })

       // Update timestamps
       now := metav1.Now()
       template.Status.LastReconcileTime = &now
       template.Status.ObservedGeneration = template.Generation

       // Update status
       return r.Status().Update(ctx, template)
   }

   func (r *PangeaTemplateReconciler) updateStatusError(ctx context.Context, template *pangeav1alpha1.PangeaTemplate, err error) (ctrl.Result, error) {
       meta.SetStatusCondition(&template.Status.Conditions, metav1.Condition{
           Type:    "Ready",
           Status:  metav1.ConditionFalse,
           Reason:  "ReconciliationFailed",
           Message: err.Error(),
       })

       if updateErr := r.Status().Update(ctx, template); updateErr != nil {
           return ctrl.Result{}, updateErr
       }

       return ctrl.Result{RequeueAfter: 1 * time.Minute}, err
   }

   func (r *PangeaTemplateReconciler) calculateRequeueInterval(template *pangeav1alpha1.PangeaTemplate) time.Duration {
       switch template.Spec.Reconciliation.Mode {
       case "event-driven":
           return 0 // Don't requeue, only on events
       case "periodic":
           return template.Spec.Reconciliation.Interval.Duration
       case "hybrid":
           return template.Spec.Reconciliation.Interval.Duration
       default:
           return 5 * time.Minute
       }
   }
   ```

4. Update SetupWithManager
   ```go
   func (r *PangeaTemplateReconciler) SetupWithManager(mgr ctrl.Manager) error {
       return ctrl.NewControllerManagedBy(mgr).
           For(&pangeav1alpha1.PangeaTemplate{}).
           Complete(r)
   }
   ```

5. Test compilation
   ```bash
   make build
   ```

**Success Criteria:**
- Controller compiles without errors
- Reconcile function has complete logic flow
- Status updates work correctly
- Requeue logic is implemented

**Verification:**
```bash
# Build and test
make build
make test

# Should compile and tests should pass
```

#### Task 1.4: Create Ruby Executor with Nix Build System

**Objective:** Create Pangea executor service with Nix flake for reproducible Ruby/Terraform/InSpec container builds

**Steps:**
1. **Create executor project structure**
   ```bash
   mkdir -p pkgs/operators/pangea-executor/{bin,lib,spec}
   cd pkgs/operators/pangea-executor
   ```

2. **Create Gemfile with dependencies**
   ```bash
   cat > Gemfile <<'EOF'
   source 'https://rubygems.org'

   gem 'pangea', path: '../../tools/ruby/pangea'  # Use monorepo Pangea
   gem 'thor', '~> 1.3'  # CLI framework
   gem 'tty-spinner', '~> 0.9'
   gem 'tty-table', '~> 0.12'
   gem 'pastel', '~> 0.8'
   gem 'aws-sdk-s3', '~> 1.14'
   gem 'kubeclient', '~> 4.11'

   group :test do
     gem 'rspec', '~> 3.13'
     gem 'rspec-mocks', '~> 3.13'
     gem 'webmock', '~> 3.19'
   end
   EOF
   ```

3. **Create executor binary**
   ```bash
   cat > bin/pangea-executor <<'EOF'
   #!/usr/bin/env ruby
   # frozen_string_literal: true

   require_relative '../lib/pangea_executor'

   PangeaExecutor::CLI.start(ARGV)
   EOF

   chmod +x bin/pangea-executor
   ```

4. **Create executor implementation stub**
   ```bash
   cat > lib/pangea_executor.rb <<'EOF'
   # frozen_string_literal: true

   require 'thor'
   require 'pangea'
   require 'json'

   module PangeaExecutor
     class CLI < Thor
       desc 'plan TEMPLATE_SPEC_JSON', 'Execute Pangea plan and return results'
       def plan(template_spec_json)
         spec = JSON.parse(template_spec_json, symbolize_names: true)
         # Implementation will be added in later tasks
         puts JSON.generate({ status: 'success', changes: [] })
       end

       desc 'apply TEMPLATE_SPEC_JSON', 'Execute Pangea apply and return results'
       def apply(template_spec_json)
         spec = JSON.parse(template_spec_json, symbolize_names: true)
         # Implementation will be added in later tasks
         puts JSON.generate({ status: 'success', applied: true })
       end

       desc 'drift TEMPLATE_SPEC_JSON', 'Detect infrastructure drift'
       def drift(template_spec_json)
         spec = JSON.parse(template_spec_json, symbolize_names: true)
         # Implementation will be added in later tasks
         puts JSON.generate({ status: 'success', drift_detected: false })
       end
     end
   end
   EOF
   ```

5. **Install dependencies and generate gemset.nix**
   ```bash
   bundle install
   bundix  # Generates gemset.nix for Nix build
   ```

6. **NEW: Create Nix flake for executor**
   ```bash
   cat > flake.nix <<'EOF'
   {
     description = "Pangea Executor - Ruby infrastructure executor for Kubernetes operator";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
       flake-utils.url = "github:numtide/flake-utils";
       nexus.url = "path:../../..";
       nix-lib.url = "path:../../../nix/lib";
     };

     outputs = { nixpkgs, flake-utils, nexus, nix-lib, ... }:
       flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (
         system:
           let
             rubyTool = import "${nix-lib}/ruby-tool.nix" {
               inherit system nixpkgs;
               nixLib = nix-lib;
               nexusDeploy = nexus.packages.${system}.nexus-deploy;
             };
           in
             rubyTool {
               toolName = "pangea-executor";
               src = ./.;
               description = "Pangea infrastructure executor with Terraform/OpenTofu and InSpec";
               rubyVersion = "3.3";
               gemfile = ./Gemfile;
               gemset = ./gemset.nix;
               runtimeDependencies = pkgs: with pkgs; [
                 opentofu
                 inspec
                 git
                 awscli2
               ];
               entryPoint = "bin/pangea-executor";
               containerUser = "pangea";
               containerWorkdir = "/workspace";
               productName = "infrastructure";
               namespace = "pangea-system";
               cluster = "orion";
             }
       );
   }
   EOF
   ```

7. **NEW: Create ruby-tool.nix helper in nix-lib** (if not already done in Task 1.1)
   ```bash
   # Navigate to nix-lib directory
   cd ../../../nix/lib

   # Create ruby-tool.nix (see Build System Architecture section for complete implementation)
   # This file mirrors the pattern of rust-tool.nix for Ruby tools
   ```

8. **Verify executor and Nix build**
   ```bash
   cd pkgs/operators/pangea-executor

   # Test Ruby executor locally
   bundle exec bin/pangea-executor help

   # Nix build
   nix build .#default  # Build the Ruby application
   nix build .#dockerImage-amd64  # Build container with Ruby + Terraform + InSpec

   # Test in container
   docker load < result
   docker run ghcr.io/pleme-io/pangea-executor:latest pangea-executor help
   ```

9. **NEW: Test Nix development shell**
   ```bash
   nix develop
   # Verify you have: ruby, bundler, bundix, opentofu, inspec, awscli2
   ruby --version  # Should show Ruby 3.3
   tofu --version  # Should show OpenTofu
   inspec --version  # Should show InSpec
   ```

**Success Criteria:**
- Executor runs successfully: `bundle exec bin/pangea-executor help`
- Nix flake builds successfully: `nix build .#default`
- Docker image builds with all dependencies: `nix build .#dockerImage-amd64`
- Docker image contains: Ruby 3.3, Pangea, OpenTofu, InSpec, AWS CLI
- Development shell works: `nix develop`
- CLI responds to commands: plan, apply, drift

**Output Files:**
- `Gemfile` and `Gemfile.lock` (Ruby dependencies)
- `gemset.nix` (Nix representation of Gemfile.lock)
- `bin/pangea-executor` (executable CLI)
- `lib/pangea_executor.rb` (executor implementation)
- `flake.nix` (Nix build configuration)
- `flake.lock` (Nix dependency lock file)
- `nix/lib/ruby-tool.nix` (Ruby tool builder helper)

**Verification:**
```bash
# Test locally
bundle exec bin/pangea-executor help
# Should show available commands

# Test with Nix
nix run .#default -- help
# Should show available commands

# Test Docker image size
nix build .#dockerImage-amd64
docker load < result
docker images ghcr.io/pleme-io/pangea-executor
# Should be < 500MB (Ruby + Terraform + InSpec is large but optimized)

# Verify all tools in container
docker run ghcr.io/pleme-io/pangea-executor:latest sh -c "ruby --version && tofu --version && inspec --version"
# All should work
```

---

## Success Metrics

### Operational Metrics

1. **Reconciliation Performance**
   - Time to reconcile: <30s for typical template
   - Drift detection time: <1 minute
   - Auto-remediation time: <2 minutes

2. **Reliability**
   - Reconciliation success rate: >99.9%
   - False positive drift rate: <0.1%
   - Operator uptime: >99.99%

3. **Scalability**
   - Templates per operator: >1000
   - Concurrent reconciliations: >50
   - Memory per template: <50MB

### Business Metrics

1. **Drift Reduction**
   - Mean time to detect drift: <5 minutes
   - Mean time to remediate drift: <10 minutes
   - Drift incidents per week: <5

2. **Compliance**
   - Compliance check frequency: hourly
   - Compliance score: >95%
   - Time to compliance: <1 hour

3. **Developer Experience**
   - Time to onboard new template: <30 minutes
   - Learning curve: <1 day
   - Documentation completeness: >90%

---

## Conclusion

This comprehensive plan transforms Pangea from a CLI tool into a Kubernetes-native, continuously reconciling infrastructure platform. The hybrid Go+Ruby architecture leverages the strengths of both ecosystems while maintaining Pangea's existing Ruby codebase.

The implementation is broken down into clear phases with atomic tasks that an AI agent can execute methodically. Each task has clear success criteria and verification steps to prevent loss of progress.

The integration of RSpec, InSpec, and E2E testing ensures quality at every layer, from unit tests to infrastructure compliance to full operator behavior.

**Next Steps:**
1. Review and approve this plan
2. Begin Phase 1 implementation
3. Set up development environment
4. Execute Task 1.1 (Initialize operator project)

**Questions for Clarification:**
1. Should we prioritize certain cloud providers (AWS first, then GCP/Azure)?
2. What is the target Kubernetes version (1.28+, 1.29+, 1.30+)?
3. Are there specific compliance frameworks we should support (CIS, PCI-DSS, HIPAA)?
4. What is the preferred deployment model (one operator per cluster, multi-cluster)?
