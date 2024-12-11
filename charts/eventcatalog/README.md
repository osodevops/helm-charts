# EventCatalog Helm Chart Instructions

This guide provides detailed instructions for deploying EventCatalog using the Helm chart. You can use the default configuration or customize the deployment to suit your needs, including examples with and without a domain.

## Table of Contents

1. [Introduction](#introduction)
2. [Adding the Helm Repository](#adding-the-helm-repository)
3. [Installing the EventCatalog Chart](#installing-the-eventcatalog-chart)
4. [Available Values to Override](#available-values-to-override)
5. [Example Configurations - values.yaml](#example-configurations---valuesyaml)
   - [Without a Domain](#without-a-domain)
   - [With a Domain](#with-a-domain)
6. [Building a Custom EventCatalog Image](#building-a-custom-eventcatalog-image)
7. [Default Image and Demo UI](#default-image-and-demo-ui)
8. [Additional Resources](#additional-resources)

## Introduction

EventCatalog helps you document, manage, and visualize the events in your microservices architecture. This guide walks you through deploying the Helm chart, configuring ingress, and setting up your instance with a default or custom image.

The deployment uses the **cert-manager** and **ingress-nginx** Helm charts for managing TLS certificates and ingress resources, respectively.

## Adding the Helm Repository

Add the Helm repository:

```bash
helm repo add oso-devops https://osodevops.github.io/helm-charts/
```

## Installing the EventCatalog Chart

Install the Helm chart using the following command:

```bash
helm install eventcatalog oso-devops/eventcatalog -f values.yaml
```

## Available Values to Override

Below are the default values provided by the Helm chart that can be overridden in your `values.yaml` file:

```yaml
replicaCount: 1

image:
  name: eventcatalog
  # Container image with static EventCatalog demo built
  repository: quay.io/osodevops/eventcatalog
  # If not specified, defaults to .Chart.AppVersion
  tag: ""
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  # Default port for the service
  port: 80

ingress:
  enabled: true
  domain: true
  ingressClass: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: example.com
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: test-eventcatalog
      hosts:
        - example.com

resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "512Mi"
    cpu: "1"
```

### Example Configurations - values.yaml
#### Without a Domain
Use the following configuration for deployments without a domain using the default demo image. The application will be accessible via a LoadBalancer:
```yaml
ingress:
  enabled: true
  domain: false
  ingressClass: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - paths:
        - path: /eventcatalog
          pathType: ImplementationSpecific
  tls: []

```

#### With a Domain
Use this configuration to deploy EventCatalog with a custom domain, using the default demo image:

```yaml
ingress:
  enabled: true
  domain: true
  ingressClass: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: example-domain.com
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: test-eventcatalog
      hosts:
        - example-domain.com
```

## Building a Custom EventCatalog Image
You can build your own EventCatalog image if required. The following example demonstrates a multi-architecture image build:

We used this to provide the default demo image.

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t quay.io/osodevops/eventcatalog:1.0.1 --push .
```

This image can then be referenced in your Helm values file for deployment.

### Default Image and Demo UI
The Helm chart uses a default EventCatalog image that provides a demo experience. The UI is expected to resemble the [EventCatalog demo](https://demo.eventcatalog.dev).

For testing locally, you can forward the service:

```bash
kubectl port-forward svc/eventcatalog 8080:80
```

## Additional Resources
- **Deployment and Hosting Documentation:** https://www.eventcatalog.dev/docs/development/deployment
- **Getting Started on GitHub:** https://github.com/event-catalog/eventcatalog
- **Create a Local Instance:** Start a local instance of EventCatalog with:

```bash
npx @eventcatalog/create-eventcatalog@latest my-catalog
```