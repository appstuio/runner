# ARC deployment

The two App Studio scale sets intentionally share one immutable runner image:

- `byo` is the normal lane. It has no Docker daemon or Docker startup wait.
- `byo-large` is the Docker-capable lane. It retains the DinD sidecar.

The values files preserve the existing scale limits, resource sizing, GitHub
configuration secret, work volume, and large-runner DinD settings. The runner
image is public and pinned by digest, so no registry credential is needed.

## Deploy

On the K3s host, first set the cluster configuration:

```sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

Deploy the checked-in values with the same chart version already installed on
the host:

```sh
helm upgrade byo \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
  --namespace arc-runners \
  --version 0.14.2 \
  --values deploy/byo-values.yaml \
  --wait \
  --timeout 10m

helm upgrade byo-large \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
  --namespace arc-runners \
  --version 0.14.2 \
  --values deploy/byo-large-values.yaml \
  --wait \
  --timeout 10m
```

These upgrades affect newly created ephemeral runners. They do not forcibly
interrupt jobs already executing on existing runner pods.

## Verify

```sh
helm get values byo -n arc-runners
helm get values byo-large -n arc-runners

kubectl get pods -n arc-runners \
  -o custom-columns='NAME:.metadata.name,READY:.status.containerStatuses[*].ready,IMAGES:.spec.containers[*].image,CONTAINERS:.spec.containers[*].name'
```

After a normal and a large job have started on fresh pods, `byo` should list
only `runner`; `byo-large` should list `runner,dind`. Both runner containers
should use the pinned `ghcr.io/appstuio/runner@sha256:...` digest.
