# AI on AKS demo

Supporting repo for the "Platform Engineering for AI Workloads" session:
Terraform foundation (VNet, AKS with system + GPU node pools, Key Vault,
Flux bootstrap) handing off to ArgoCD for the example workloads.

## Components

- [x] `terraform/foundation` - VNet, AKS, Key Vault, Flux bootstrap. See its
  README for setup and run instructions.
- [x] `bootstrap/` - Flux-managed path that installs ArgoCD via HelmRelease,
  plus the app-of-apps Application pointing at `gitops/`. See its README for
  the one manual step (ArgoCD's own repo credentials).
- [ ] `gitops/` - ArgoCD Application/ApplicationSet definitions for the three
  examples (vLLM + Llama/Qwen + Open WebUI, Ollama + TinyLlama, Ollama + Qwen). 

## Repo layout (planned)

```
repo/
├── README.md
├── bootstrap # FluxCD bootstrap folder, setting up core services
│   ├── README.md
│   ├── apps # containing app-of-apps deploying all compontns from gitops folder
│   │   ├── app-of-apps.yaml
│   │   └── kustomization.yaml
│   ├── argocd-apps-kustomization.yaml
│   ├── argocd-helmrelease.yaml
│   ├── argocd-helmrepository.yaml
│   ├── kustomization.yaml
│   └── namespaces.yaml
├── gitops
│   ├── ai-demos-namespace
│   │   ├── kustomization.yaml
│   │   └── namespace.yaml
│   ├── applicationset.yaml
│   ├── kustomization.yaml
│   ├── nvidia-device-plugin # NVIDIA device plugin deployed only on GPU nodes
│   │   ├── daemonset.yaml
│   │   └── kustomization.yaml
│   ├── ollama-qwen # Deploying qwen2.5:7b with CPU inference
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   └── service.yaml
│   ├── ollama-tinyllama # Deploying tinyllama with CPU inference
│   │   ├── deployment.yaml
│   │   ├── hpa.yaml
│   │   ├── kustomization.yaml
│   │   └── service.yaml
│   ├── openwebui # OpenWebUI to interact with models
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   └── service.yaml
│   └── vllm-qwen # Deploying qwen2.5:7b with GPU
│       ├── deployment.yaml
│       ├── kustomization.yaml
│       └── service.yaml
└── terraform # Demo platform deployment 
    └── foundation
        ├── README.md
        ├── aks.tf
        ├── flux.tf
        ├── keyvault.tf
        ├── kubeconf.tf
        ├── locals.tf
        ├── network.tf
        ├── outputs.tf
        ├── providers.tf
        ├── resource_group.tf
        ├── terraform.tfvars
        ├── terraform.tfvars.example
        ├── terraform.tfvars_dk
        ├── variables.tf
        └── versions.tf

```

## Order of operations

1. Generate a Flux deploy keypair and add the public half as a read-only
   deploy key on this repo (see `terraform/foundation/README.md`).
```export TF_VAR_flux_git_ssh_private_key_base64=$(base64 -w0 ~/.ssh/id_rsa)```
2. `terraform apply` the foundation. This creates the cluster and points
   Flux at `bootstrap/`, which installs ArgoCD and creates the app-of-apps
   Application.
   Ensure terraform.tfvars is present, enable/disable GPU nodes depending
   on resource availability.
3. Follow `bootstrap/README.md`'s one manual step (a second deploy key for
   ArgoCD's own repo access).
4. Add `gitops/` Once pushed, ArgoCD's apply argocd-apps-kustomization.yaml
   picks up apps/app-of-apps.yaml and deploys the example apps.
