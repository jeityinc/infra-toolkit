# JEITY infra-toolkit

Pinned Linux/amd64 CI image for `jeity-infra`.

## Included

- Node.js 22.20.0
- Terraform 1.16.5
- TFLint 0.59.1
- TFLint AWS ruleset 0.43.0
- AWS CLI 2.37.3
- Python 3
- Ruby
- Git
- jq
- curl
- unzip
- pre-warmed Terraform provider cache:
  - hashicorp/aws 6.63.0
  - cloudflare/cloudflare 5.24.0
  - hashicorp/archive 2.8.0
  - hashicorp/time 0.14.2

Target image:

```text
ghcr.io/jeityinc/infra-toolkit:latest
```

## Publish through GitHub Actions

Create this repository under the `jeityinc` GitHub organization and push to `master`.

The workflow uses the repository's built-in `GITHUB_TOKEN`, so no PAT is required
for normal GitHub Actions publishing.

After the first image is published, open the package settings and set the
package visibility to **Public** if Bitbucket should pull it anonymously.

## Build locally

```bash
docker build -t ghcr.io/jeityinc/infra-toolkit:latest .
docker run --rm ghcr.io/jeityinc/infra-toolkit:latest infra-toolkit-verify
```

## Manual GHCR push

A local/manual push requires a GitHub Personal Access Token (classic) with
`write:packages`.

```bash
export CR_PAT='...'

echo "$CR_PAT" | docker login ghcr.io \
  -u YOUR_GITHUB_USERNAME \
  --password-stdin

docker push ghcr.io/jeityinc/infra-toolkit:latest
```

## Important: jeity-infra follow-up

Using this image alone will not eliminate all installation work yet.

Current `jeity-infra` scripts still explicitly install/download some tools:

- `scripts/bitbucket-pr-validate.sh` always runs apt installation and downloads
  Terraform/TFLint.
- Platform/Staging common scripts still download Terraform into a temporary
  directory on every run.

After publishing this image, update those scripts to:

1. verify and reuse the preinstalled Terraform/TFLint/tool versions when they
   match the pinned versions;
2. fail if an unexpected version is present rather than silently upgrading;
3. retain the existing download/install path only as an explicit fallback if
   desired;
4. preserve `TF_PLUGIN_CACHE_DIR=/opt/terraform/plugin-cache`.

That follow-up is what produces the large build-minute savings.

## Releases

A successful push to `master` automatically publishes a new patch release.

The release workflow:

1. finds the latest `vMAJOR.MINOR.PATCH` Git tag;
2. increments the patch version;
3. builds and publishes the GHCR image;
4. publishes exact-version, major/minor, SHA, and `latest` tags;
5. creates the corresponding annotated Git tag only after the image publish succeeds.

The first successful release is `v1.0.0`. Subsequent releases become
`v1.0.1`, `v1.0.2`, and so on.

For example, `v1.0.4` publishes:

```text
ghcr.io/jeityinc/infra-toolkit:1.0.4
ghcr.io/jeityinc/infra-toolkit:1.0
ghcr.io/jeityinc/infra-toolkit:latest
ghcr.io/jeityinc/infra-toolkit:sha-<commit>
```

Downstream CI should pin the exact version:

```yaml
image: ghcr.io/jeityinc/infra-toolkit:1.0.4
```

Do not use `latest` for `jeity-infra`.
