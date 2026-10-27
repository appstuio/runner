# ARC deployment

The two App Studio scale sets intentionally share one immutable runner image:

- `byo` is the normal lane. It has no Docker daemon or Docker startup wait.
- `byo-large` is the Docker-capable lane. It retains the DinD sidecar.

The values files preserve the GitHub configuration secret, work volume, and
large-runner DinD settings. The runner
image is public and pinned by digest, so no registry credential is needed.

## Capacity

The 15 GiB host is capped at four normal runners and one Docker-capable runner.
Each runner container requests and is limited to 2 GiB. The Docker sidecar retains
its 2 GiB request and 2.5 GiB limit, making the maximum combined workload memory
limits 12.5 GiB. This leaves roughly 2.5 GiB for K3s, the operating system, and
controllers; other host workloads must also fit within that headroom. The 2 GiB
runner limit is a trial increase above the observed 1.5 GiB OOM boundary,
not yet proof that the failing dependency installations fit.

ARC scales each pool with assigned jobs up to its own cap. Kubernetes schedules
pods against declared CPU and memory requests and node allocatable resources,
so actual simultaneous jobs can be lower. These caps do not automatically lend
unused capacity between pools or resize containers based on current free RAM.

The previous 1.5 GiB runner limit caused cgroup OOM kills during Bun dependency
installation, including the runner agent itself. More free memory on the host
cannot compensate for a container reaching its own hard limit.

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
