# GKE Ingress & Load Balancing 

## The Problem: Exposing Applications in Kubernetes 
Inside Kubernentes 
- Pods run your containers, but they are **ephemeral** -- IPs change. 
- To access apps from outside, you need to use **Services** and **Ingress** to manage how traffic enters the cluster. 

## Key Concepts 
### ClusterIP
- Default service type
- Accessible only inside the cluster
- Example: Service tyep: ClusterIP -> Only Pods inside can reach it. 

### NodePort
- Opens a static port (default range 30000 - 32767) on every node
- External users connect via NodeIP: NodePort.
- Not very flexible for production -- mainly used for testing

### LoadBalancer 
- Integrates with **GCP Load Balaner** automatically.
- GKE provisions a **Google Cloud External Load Balancer(ELB)** 
- Each Service type: LoadBalancer gets its own public IP.


**Pros of ELB**
- Simple and direct external access 
**Cons of ELB**
- Each service -> one load balancer -> more cost, limited scalability 

---

# GKE Ingress 
## What Ingress Does 
- Ingress acts as a **traffic manager/smart router** for multiple services.
- Uses a single external load balancer + single IP address 
- Routes requests to backend services based on **hostname** or **paths**

Example 
```
/api -> Service A
/web -> Service B
/shop -> Service C 
```

## In GKE 
- When you create an Ingress resource, GKE automatically: 
> Creates a **GCP HTTP(S) Load Balancer** 
> Allocates a global IP
> Creates backend services, health checks, forwarding rules
> Updates them dynamically when your Ingress YAML changes 

## Load Balancer Types in GKE 
#### External HTTP(S) Load Balancer
- Publicly exposes apps (Ingress)
- Websites, APIs

#### Internal Load Balancer (ILB)
- Private access only (inside VPC)
- Internal microservices


#### TCP/UDP Load Balancer 
- Layer 4 access via Service, type: LoadBalancer
- Databases, gRPC

#### Gateway Controller (new)
- GKE's evolution of Ingress, better control and traffic policies 
- Advanced setups


## Common YAML Resources 
#### Basic LoadBalancer Service 
```yaml 
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  type: LoadBalancer
  selector: 
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
```
- GKE automatically creates an external LB in GCP

#### Basic Ingress Example
```yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    kubernetes.io/ingress.class: "gce"
spec:
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80    
```
- GKE creates a **GCP HTTP(S) Load Balancer** for you 

## Typical Workflow 
- Deploy your app:
```bash 
kubectl apply -f deployment.yaml 
```

- Create a Service: 
```bash 
kubectl apply -f service.yaml 
```

- Create an Ingress 
```bash 
kubectl apply -f ingress.yaml 
```

- Check status: 
```bash 
kubectl get ingress
```

Then you will see an external IP assigned once GCP finishes provisioning the load balancer. 

## Terraform + GKE Integration 
Terraform can manage: 
- Static IPs (`google_compute_address`)
- DNS entries (`google_dns_record_set`)
- Backend services, forwarding rules, etc. 

But usually, the **Ingress and Services are declared in Kubernentes YAML**, not Terraform , because they live inside the cluster (Terraform doens't "see" them).



## Why Ingress Was Introduced 
Using `Service type = LoadBalancer` alone has several problems: 
- Each Service creates its own GCP Load Balancer. 
- That Means 
> High cost (each LB = extra IP, backend, forwarding rules, etc)
> Hard to manage at scale
> No centralized routing by domain or path 

So, Kubernentes introduced **Ingress** to solve those limitaitons. 


## What Is Ingress 
> **Ingress** = **A smart traffic router** that manages how HTTP/HTTPS requests reach multiple services inside a cluser. 

It: 
> Use **one Load Balancer for multiple Services** 
> Routes requests based on **hostname** or **URL path**
> Automatically creates a **Google Cloud HTTP(S) Load Balancer** in GKE
> Supports advanced features like **SSL termination**, **path rewriting**, and **hear forwarding**.


## Visual Comparision 
- Service with **LoadBalancer(Traditional way in K8S)** 
```
User → [LB1] → Service-A  
User → [LB2] → Service-B  
User → [LB3] → Service-C
```
> Every service has its **own external load balancer**
> Costly and inefficiently

- **Ingress(Modern Way supported by GKE)** 

```
User → [One HTTP(S) Load Balancer] → [Ingress Controller]
     ├── /api  → Service-A
     ├── /web  → Service-B
     └── /shop → Service-C
```
> One single global load balancer 
> Routes traffic based on path or domain 
> Lower cost, easier management, and unified routing. 

## How Ingress Works in GKE 
When you apply an Ingress YAML file:
- The **GKE Ingress Controller** detects the new ingress resource
- It automatically provisions a **Google Cloud HTTP(S) Load Balancer**
- GCP creates: 
> A global static IP 
> Backend services
> Health checks 
> URL maps and forwarding rules 

- Once ready, `kubectl get ingress` shows an external IP
- Users cna access the app through that single endpoint, and GKE handle the routing 


## Ingress Example
```yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    kubernetes.io/ingress.class: "gce"
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
```
This config means: 
- `https://myapp.example.com/` -> routes to `frontend-service`
- `https://myapp.example.com/api` -> routes to `api-service`

Behind the scenes, GKE builds **one HTTP(S) Load Balancer** to manage both. 


## In Summary 


**Ingress is an advanced, centralized version of Service type=LoadBalancer.It lets multiple services share one external entry point and routes requests based on hostname or URL path.**