# Foundation

Deploys the platform layer for the demo: resource group (or reference to an
existing one), VNet/subnet, AKS with a system node pool and an optional GPU
node pool, a Key Vault wired up to the AKS Secrets Store CSI driver addon,
and the Flux GitOps bootstrap pointing at this repo.

## What gets created

| Resource | Naming example | Notes |
|---|---|---|
| Resource group | `rg-cnandk8s-sbox-uks-01` | Only if `resource_group_name = null` |
| Virtual network | `vnet-cnandk8s-sbox-uks-01` | AVM module |
| Subnet | `snet-cnandk8s-k8snodes-sbox-uks-01` | AKS nodes |
| AKS cluster | `aks-cnandk8s-sbox-uks-01` | System + optional GPU node pool |
| Key Vault | `kv-cnandk8s-sbox-uks-xx` | Shortened + random suffix, see below |
| Flux extension/config | `flux-...` / `fluxconfig-...` | Points at `flux_bootstrap_path` |

## Before you run this

1. **Resource group**: in a case when it's already created, run `az group list -o table`
   and set `resource_group_name` in `terraform.tfvars` to the one provided.
   If you're deploying somewhere you can create your own resource groups,
   leave it as `null`.

2. **GPU quota**: check `az vm list-skus --location <region> --resource-type
   virtualMachines -o table | grep NC` against your subscription. If the
   `Standard_NC4as_T4_v3` family (or whatever you set `gpu_node_pool.vm_size`
   to) has no quota, set `gpu_node_pool_enabled = false`. The CPU-only Ollama
   example still works without a GPU pool.

3. **Flux SSH deploy key**: generate a dedicated keypair, add the public key
   as a read-only deploy key on this repo, and export the private key:

   ```bash
   ssh-keygen -t ed25519 -f ./flux-deploy-key -N "" -C "flux-aks-demo"
   # add flux-deploy-key.pub as a read-only deploy key in the repo settings
   export TF_VAR_flux_git_ssh_private_key_base64=$(base64 -w0 flux-deploy-key)
   ```
4. **Azure Service Principal**: Create a service pricipal for deployment
   The demo was tested with contributor and user access admin permissions.
   User access admin is required to manage teh managed identities.

   ```bash
   az ad sp create-for-rbac --name "sp-cnandk8s-sbox-terraform-01" --role "Contributor" --scopes "/subscriptions/132e18d5-e940-467d-9920-ae549bb634c8" --output json
   ```
   This will return something simmilar:
   ```bash 
   {
     "appId": "35122544-d113-4f47-bd6c-ba2388c0b3a0",
     "displayName": "sp-cnandk8s-sbox-terraform-01",
     "password": "hGl8Q~b1UDw6h1CVo~_5AH2hkmnsY2iVJ0SRscGX",
     "tenant": "7a150140-e743-42ea-bb45-c656a882d7e4"
   }
   ```
   
   Export the values into local variables to enable terraform authentication
   ```bash 
   export ARM_CLIENT_ID="35122544-d113-4f47-bd6c-ba2388c0b3a0"
   export ARM_CLIENT_SECRET="hGl8Q~b1UDw6h1CVo~_5AH2hkmnsY2iVJ0SRscGX"
   export ARM_TENANT_ID="7a150140-e743-42ea-bb45-c656a882d7e4"
   export ARM_SUBSCRIPTION_ID="132e18d5-e940-467d-9920-ae549bb634c8"
   ```
   Enable User Access Administrator role for the client
   ```bash
   az role assignment create   --assignee "${ARM_CLIENT_ID}"   --role "User Access Administrator"   --scope "/subscriptions/${ARM_SUBSCRIPTION_ID}"
   ```

## Running it

```bash
cd terraform/foundation
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: resource_group_name, flux_git_repository_url, etc.

terraform init
terraform plan
terraform apply
```

Expect `terraform apply` to take **20-40 minutes**, mostly the AKS cluster
and the Flux extension (which has a known 10-30 minute apply time). This is
why the demo plan pre-provisions infrastructure ahead of the live session,
the live portion starts from "cluster exists, Flux has reconciled ArgoCD".

## Resizing things

Everything you're likely to change for the demo is a variable:

- **Node pool sizes / SKUs**: `system_node_pool` and `gpu_node_pool` objects
  in `terraform.tfvars`, change `vm_size`, `min_count`, `max_count`.
- **Network layout**: `vnet_address_space` and the `subnets` map. The `aks`
  subnet key is referenced directly in `aks.tf` (`module.vnet.subnets["aks"]`),
  if you add more subnets keep that key or update `aks.tf` to match.
- **GPU pool present at all**: `gpu_node_pool_enabled`.

## GPU node pool notes

- The pool is tainted with `nvidia.com/gpu=present:NoSchedule`, only pods
  that tolerate this taint (your vLLM deployment) will be scheduled there.
- AKS auto-installs the NVIDIA driver and device plugin for this SKU on
  Ubuntu nodes. Once a GPU node is `Ready`, `kubectl describe node <name>`
  should show `nvidia.com/gpu: 1` under `Allocatable`, this is the live
  callback to "Kubernetes doesn't understand GPUs, the device plugin
  advertises them."
- `node_count` defaults to keeping one GPU node warm (`max(min_count, 1)`)
  so the live demo doesn't wait on node provisioning. Set both `min_count`
  and the initial count to `0` if you specifically want to demo
  scale-from-zero (expect 5-10 minutes for that node to appear).

## Key Vault / Secrets Store CSI driver

The AKS cluster has the `key_vault_secrets_provider` addon enabled, which
installs the Secrets Store CSI driver and the Azure Key Vault provider, and
creates a dedicated managed identity (granted `Key Vault Secrets User` on
this vault by `keyvault.tf`).

To use it later for, e.g., a Hugging Face token:

```bash
az keyvault secret set --vault-name <key_vault_name output> \
  --name hf-token --value <your-hf-token>
```

Then in the cluster, create a `SecretProviderClass` referencing
`<key_vault_name>` and the secret name, and mount it as a volume in the pod
spec, the CSI driver will sync it as a file (and optionally mirror it to a
Kubernetes Secret via `secretObjects`). This is covered in the GitOps
manifests, not this Terraform module, the Key Vault and permissions just
need to exist first.

Note: Key Vault names must be globally unique across all of Azure and are
3-24 characters. The naming-convention name is usually too long for this, so
unless `key_vault_name` is set explicitly, a shortened name plus a random
4-character suffix is generated instead.

## A note on AVM module choices

The VNet uses the AVM resource module (`avm-res-network-virtualnetwork`),
its interface is stable. AKS uses native `azurerm_kubernetes_cluster` /
`azurerm_kubernetes_cluster_node_pool` resources rather than the AKS AVM
resource module, which is still pre-1.0, has an open issue against the
current AzureRM API version for agent pool settings, and has had its
node-pool variable shape change between recent versions. For a demo you're
running live, exact and stable beats "AVM everywhere".
