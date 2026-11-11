# Study Plan: AI on AKS Demo

A beginner-to-intermediate, code-along curriculum for rebuilding the `k8s-llm` project (Terraform + Flux + ArgoCD + Kubernetes AI workloads on AKS).

## Prerequisites

- Python 3.10+ and Jupyter Notebook or JupyterLab
- Terraform >= 1.9
- Azure CLI (`az`) and authenticated subscription access
- `kubectl` and `kustomize`
- Basic Git + SSH key workflow
- Optional: Docker Desktop
- Optional (for gated HF models): Hugging Face token

## How To Use

1. Install Jupyter if needed:
   ```bash
   pip install notebook
   ```
2. Start Jupyter from repository root:
   ```bash
   jupyter notebook
   ```
3. Open lessons in order and run cells top-to-bottom.
4. Complete each exercise cell marked with `# TODO:` before moving on.

## Phases And Lessons

Estimated total lesson count: **12 lessons + 1 capstone**

### Phase 1: Infra Foundations

- [Lesson 1.1 - Terraform Versioning And Providers](./phase-1-infra-foundations/lesson-1.1-terraform-versioning-and-providers.ipynb)
- [Lesson 1.2 - Variables And Naming Locals](./phase-1-infra-foundations/lesson-1.2-variables-and-naming-locals.ipynb)
- [Lesson 1.3 - Resource Group And Network Module](./phase-1-infra-foundations/lesson-1.3-resource-group-and-network-module.ipynb)

### Phase 2: Terraform Platform Layer

- [Lesson 2.1 - AKS Cluster And GPU Node Pool](./phase-2-terraform-platform/lesson-2.1-aks-cluster-and-gpu-node-pool.ipynb)
- [Lesson 2.2 - Key Vault And Kubernetes RBAC Bridge](./phase-2-terraform-platform/lesson-2.2-key-vault-and-kubernetes-rbac-bridge.ipynb)
- [Lesson 2.3 - Flux Bootstrap And Terraform Outputs](./phase-2-terraform-platform/lesson-2.3-flux-bootstrap-and-terraform-outputs.ipynb)

### Phase 3: Flux And ArgoCD Bootstrap

- [Lesson 3.1 - Bootstrap Namespaces And Helm Source](./phase-3-flux-argocd-bootstrap/lesson-3.1-bootstrap-namespaces-and-helm-source.ipynb)
- [Lesson 3.2 - Install ArgoCD With Flux HelmRelease](./phase-3-flux-argocd-bootstrap/lesson-3.2-install-argocd-with-flux-helmrelease.ipynb)
- [Lesson 3.3 - App Of Apps Wiring](./phase-3-flux-argocd-bootstrap/lesson-3.3-app-of-apps-wiring.ipynb)

### Phase 4: GitOps AI Workloads

- [Lesson 4.1 - ApplicationSet And Namespace Scaffolding](./phase-4-gitops-ai-workloads/lesson-4.1-applicationset-and-namespace-scaffolding.ipynb)
- [Lesson 4.2 - GPU Serving Stack With vLLM](./phase-4-gitops-ai-workloads/lesson-4.2-gpu-serving-stack-with-vllm.ipynb)
- [Lesson 4.3 - CPU Serving, HPA, And OpenWebUI](./phase-4-gitops-ai-workloads/lesson-4.3-cpu-serving-hpa-and-openwebui.ipynb)

### Capstone

- [Capstone Project - Rebuild AI on AKS End-to-End](./capstone/capstone-project.ipynb)
