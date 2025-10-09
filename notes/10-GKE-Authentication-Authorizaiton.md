# GKE Authentication & Authorization 

In Google Kubernetes Engine (GKE), authentication and authorization determine who can access your cluster and what they can do once they're inside. 

These are two distinct but related of security: 

- **Authentication**: Who are you ? -> Verifying the identity of a user, service account, or workload. 
- **Authorization**: What are you allowed to do ? -> Granting or denying permissions for specific actions inside the cluster. 

## Authentication in GKE 
Authentication in GKE happens in two main contexts: 
- Cluster Access Authentication 
This is used when connecting to the GKE control plane (e.g., using kubectl)

- In-Cluster Authentication 
Used for workloads (pods, controllers, etc) communicating within the cluster or with Google Cloud APIs. 


### Cluster Access Authentication 
When you run:

```bash 
gcloud container clusters get-credentials <cluster-name>
```

This command:
- Fetches the cluster endpoint and credentials
- Writes them to your local `~/.kube/config` file.
- Lets you use `kubectl` authentication through your **Google identity** (your Google account or service account).

GKE uses **Google Cloud IAM** to verify your identity when you connect to the cluster. 

### Types of Identities That Can Authenticate 
#### Google Cloud User Account 
- A human identity (like your Google Workspace or Gmail account)

#### Service Account (GCP)
- A non-human identity used by apps or automation tools (CI/CD, Terraform, etc.)

#### Kubernetes Service Account
- Used by pods running inside the cluster to authenticate to the Kubernetes API or GCP APIs

### Workload Identity (Best Practice)
Workload Identity is a **secure way** to let your GKE workloads use **Google Cloud IAM** credentials without storing service account keys in pods. 
- Maps a **Kubernetes Service Account(KSA)** to a **Google Cloud Service Account**(GSA)
- Workloads can then call GCP APIs using their Kubernetes identity, securely and automatically.

Example mapping: 
```
gcloud iam service-accounts add-iam-policy-binding \
    my-gcp-sa@my-project.iam.gserviceaccount.com \
    --member="serviceAccount:my-project.svc.id.goog[default/my-k8s-sa]" \
    --role="roles/iam.workloadIdentityUser"
```

## Authorization in GKE 
Once you're authenticated, Kubernetes needs to decide **what actions** you're allowed to perform. 

That's handled by **Authorization mechanisms**.

### Role-Based Access Control (RBAC)
RBAC is the main authorization system in Kubernetes. 

### RBAC Components & Descriptions 
- **Role**: A set of permissions(verbs) within a namespace.
- **ClusterRole**: A set of permissions cluster-wide.
- **RoleBinding**: Assigns a Role to a user, group, or service account within a namespace.
- **ClusterRoleBinding**: Assigns a ClusterRole cluster-wide.

```yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
  namespace: dev
subjects:
- kind: User
  name: alice@example.com
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Predefined GKE IAM Roles

Google Cloud IAM also controls who can access the cluster itself and who can mange GKE resources. 


#### IAM Role & Scope 
`roles/container.admin`: Full control over GKE resources and clusters
`roles/container.clusterViewer`: Read-only access to clusters
`roles/container.developer`: Can deploy workloads but not manage cluster settings. 

- IAM = access to GCP-level resources (like the cluster)
- RBAC = access to Kubernentes-level resources (like pods, services)

They work together: IAM gets you into the cluster, and RBAC controls what you can do inside it. 

### Authorization Modes
GKE supports multiple authorization modes. The most common ones: 
- **RBAC**: Role-Based Access Control (default and recommended)
- **ABAC**: Attribute-Based Access Control (kegacy)
- **Webhook**: Custom external authorization (for acdvanced use cases)


## Visulization of Concetps 
```
          Google Cloud IAM
                │
                ▼
   ┌─────────────────────────┐
   │  Authentication Layer   │   ← verifies identity
   └─────────────────────────┘
                │
                ▼
   ┌─────────────────────────┐
   │  Authorization Layer    │   ← checks permissions (RBAC/IAM)
   └─────────────────────────┘
                │
                ▼
         Cluster Resources
 (Pods, Deployments, Services, etc.)
```

## Best Practices for GKE Authentication & Authorization 
- Use Workload Identity instead of service account keys.
- Use IAM for cluster acces and RBAC for in-cluster permissions. 
- Follow **least privilege** principles--grant only necessary roles.
- Keep IAM users and service accounts organizaed with naming conventions.
- Regularly auidt RBAC and IAM bindings (`kubectl` get `rolebinding`, `gcloud projects get-iam-policy`).

## Summary 

### Layer: Authentication
- Tool: IAM, OICE
- Purpose: Verify who is accessing
- Example: `gcloud container clusters get-credentials`  


### Layer: Authorization 
- Tool: RBAC
- Purpose: Define what actions are allowed
- Example: Roles, ClusterRoles, RoleBindings

### Layer: Workload Identity 
- Tool: IAM + KSA mapping 
- Purpose: Secure workload access to GCP APIs
- Example: `serviceAccount:svc.id.goog` mapping 
