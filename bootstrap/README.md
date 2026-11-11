# Bootstrap

This is the path `terraform/foundation` points Flux at (`flux_bootstrap_path`,
default `./bootstrap`). Flux reconciles these manifests, which:

1. Create the `argocd` namespace.
2. Install ArgoCD via a Flux `HelmRelease` (from the official argo-helm chart).
3. Create an ArgoCD `Application` ("app-of-apps") pointing at `gitops/` in
   this repo, this is how ArgoCD takes over for the example workloads.

Flux's own access to this repo (the SSH deploy key from
`terraform/foundation`) is separate from ArgoCD's. ArgoCD needs its own
credentials before step 3 can sync.

## Before this works end to end

**1. Update the placeholders**

`app-of-apps.yaml` has `repoURL: git@github.com:your-org/your-repo.git` and
`targetRevision: main`, change these to match your actual repo and branch
(same values as `flux_git_repository_url` / `flux_git_branch` in
`terraform/foundation`).

**2. Wait for Flux to reconcile this path**

```bash
az aks get-credentials --resource-group <rg> --name <aks_cluster_name>
kubectl get pods -n argocd
```

Give it a few minutes for the ArgoCD pods to come up.

**3. One-time: give ArgoCD its own read access to this repo**

ArgoCD's repo-server needs git credentials, stored as a labelled Kubernetes
Secret. Generate a second deploy key (separate from Flux's, smaller blast
radius if one leaks):

```bash
ssh-keygen -t ed25519 -f ./argocd-deploy-key -N "" -C "argocd-aks-demo"
```

Add `argocd-deploy-key.pub` as a second **read-only** deploy key on this
repo, then create the secret (do not commit `argocd-deploy-key`):

```bash
kubectl create secret generic repo-demo -n argocd \
  --from-literal=type=git \
  --from-literal=url=git@github.com:your-org/your-repo.git \
  --from-file=sshPrivateKey=./argocd-deploy-key

kubectl label secret repo-demo -n argocd argocd.argoproj.io/secret-type=repository
```

ArgoCD's repo-server picks this up automatically, no restart needed. Once
it's in place, the `app-of-apps` Application in the ArgoCD UI should move
from "Unknown"/error to "Synced".

> Later, once the Key Vault Secrets Store CSI driver is wired into a
> namespace (see `terraform/foundation`'s Key Vault notes), this private key
> could instead be stored in Key Vault and synced into this secret via a
> `SecretProviderClass`, removing the manual `kubectl create secret` step.
> Not done here to keep this bootstrap layer minimal, flagging it as a
> natural next step if you want one fewer manual step in the demo.

## Accessing the ArgoCD UI

```bash
# admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# port-forward (server.insecure is set, so plain HTTP)
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Then open `http://localhost:8080`, log in as `admin` with the password above.

The solution deploys argocd service as a loadbalancer service.
You can run 
```bash
kubectl get svc -n argocd
```
to get the public IP to access it as well. 
