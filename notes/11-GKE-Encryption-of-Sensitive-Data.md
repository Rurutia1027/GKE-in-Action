# Control Encryption of Sensitive Data on GKE 

## Overview 
Google Kubernentes Engine (GKE) is a managed Kubernetes service on Google Cloude. Sensitive data, such as secrets, credentials, and personal information, must be encrypted both at rest and in transit to meet security and compliance requirements. 

Encryption in GKE involves multiple layers: 
- **Encryption at rest**: Data stored in etcd, psersistent volumes (PV), and secrets.
- **Encryption in transit**: Data moving between nodes, pods, and external services. 

## Encryption at Rest 
### Kubernetes Secrets 
- By default: GKE stores secrets in etcd in base64-encoded form (not encrypted)
- Recommended: Enable envelope encryption to use customer-managed encryption keys (CMEK)

Steps for Envelop Encryption: 

- Create a Cloud KMS key: 
```bash 
gcloud kms keyrings create my-keyring --location global 
gcloud kms keys create my-key --location global --key-ring my-keyring --purpose encryption
```

- Enable encryption at the **cluster elvel**
```bash 
gcloud container clusters update CLUSTER_NAME \
--update-addons=EncryptionAtRest \
--encryption-key=my-key
```

- All secrets stored in etcd are now encrypted with CMEK


### Persistent Volumes (PV)
- Default: Google Cloud Storage (GCE Persistent Disk) automatically encrypts data
- Option: Use Customer-Supplied Encryption Keys (CSEK) or (CMEK) for additional control.

### etcd Encryption 
- etcd is the Kubernetes backing store for all cluster data
- Steps: 
> Enable encryptionConfig in cluster YAML
> Define the resources (secrets, configmaps) that need encryption 

Example YAML snippet: 
```yaml 
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - kms:
          name: gcp-kms
          keyName: projects/PROJECT_ID/locations/global/keyRings/my-keyring/cryptoKeys/my-key
      - identity: {}
```

## Encryption in Transit 
### Pod-to-Pod Communication 
- Use TLS encryption for all internal traffic 
- Options: 
> **Service Mesh** e.g., Istion, Anthos Service Mesh to enforce mTLS.
> **Network Policies** to restrict access between pods. 

### Node-to-Node and Node-to-External Communication 
- GKE automatically encrypts traffic to Google APIs with TLS.
- For custom communication, ensure: 
> TLS/SSL certificates for services
> Use HTTPs endpoints for external APIs

### API Server Communication 
- API server endpoints use HTTPs by default
- Restrict API access to authorize IPs
- Optionally, use private clusters to avoid public endpoints


## Best Practices
- Always use CMEK for sensitive secrets
- Restrict access to Cloud KMS keys: 
> Use IAM roles (roles/cloudkms.cryptoKeyEncrypterDecrypter) for authorized service accounts. 

- Audit logs: 
> Enable Cloud Audit Logging to monitor key usage and secret access. 
- Rotate encryption keys periodically.
- Use network policies and service meshes to ensure in-transit encryption between pods. 
- Do  not store secrets in plaintext in container images or env variables. 


## References
- [GKE Encryption at Rest](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets)
- [Cloud KMS](https://cloud.google.com/kms/docs/)
- [Kubernetes Secrets Encryption](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
