# App Studio runner image

This repository builds the common container image used by the App Studio
Actions Runner Controller scale sets.

The image deliberately contains only fleet-wide tooling:

- the pinned GitHub Actions Runner base image
- the current supported Node.js 22 and 24 patches in `RUNNER_TOOL_CACHE`
- the current Bun release on `PATH`, plus the previous baked release for
  repositories not yet upgraded

Application dependencies do not belong in this image. Each repository remains
responsible for installing its dependencies from its lockfile.

## Published image

Merges to `main` publish:

```text
ghcr.io/appstuio/runner:latest
ghcr.io/appstuio/runner:sha-<short commit>
```

Deploy an immutable digest in ARC after validating the published image. Both
`byo` and `byo-large` use this same runner image; only the large scale set adds
the Docker-in-Docker sidecar.

The checked-in [ARC deployment values](deploy/README.md) are the source of
truth for the two scale sets.

The repository and package are public so ARC can pull the pinned image without
a long-lived registry credential. Publishing still uses the repository's
ephemeral `GITHUB_TOKEN`. Never commit credentials or bake them into the image.

## Runtime updates

The shared App Studio Renovate runner keeps the base runner image, Node.js 22,
Node.js 24, Bun, and workflow actions current. Node tool-cache release tags are
updated atomically so their version and release identifiers cannot diverge.
When Bun advances, the former primary version becomes the compatibility version.

Runtime update pull requests must pass the image build and smoke test before
merging. A merge publishes a new image; the next Renovate run updates
`deploy/byo-values.yaml` and `deploy/byo-large-values.yaml` together to its
immutable digest. Deploy-values-only changes do not rebuild the image, which
avoids a digest-update loop. Updating these source-of-truth values does not
mutate the live ARC installation: applying them to K3s remains a deliberate
deployment step.
