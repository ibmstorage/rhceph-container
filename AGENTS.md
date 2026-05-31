# rhceph-container

Builds Red Hat Ceph Storage (RHCS) 9.2 container images on UBI 10 (RHEL 10).

## Branch

`release-9.2` — fork from `release-9.1`, updated to Ceph 9.2 / UBI 10.

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Container build definition. FROM `ubi10/ubi-minimal:latest`, `DOWNSTREAM_VERSION=9.2.0`, codename `tentacle` |
| `packages-ceph.txt` | Ceph + NFS-Ganesha RPMs to install |
| `packages-os.txt` | OS-level tooling RPMs |
| `rpms.in.yaml` | Input for `rpm-lockfile-prototype`: defines repos + package list for lockfile generation |
| `rpms.lock.yaml` | Generated lockfile pinning exact RPM URLs/checksums for all 4 arches |
| `compose.repo` | Brew compose YUM repo definition (`ceph-9.2-rhel-10-pending`) |
| `compose.json` | ODCS compose metadata for the current Brew compose |
| `rpms.repo` | RHEL 10 BaseOS/AppStream/CRB YUM repo definitions |
| `get-compose` | Script: run `odcs create-tag` from `ceph-9.2-rhel-10-candidate` |
| `update-rpm-lockfile` | Script: regenerate `rpms.lock.yaml` from `rpms.in.yaml` |
| `retag-build.sh` | Utility: retag Brew builds from 9.1→9.2 candidate |

## Tekton/Konflux Pipelines (`.tekton/`)

- `rhceph-container-9-2-pull-request.yaml` — Triggered on PRs to `release-9.2`
- `rhceph-container-9-2-push.yaml` — Triggered on pushes to `release-9.2`

Both build multi-arch images (x86_64, arm64, s390x, ppc64le) with hermetic RPM prefetch via Cachi2, full security scanning, and push to `quay.io/rhceph-ci/rhceph`.

## Build Workflow

1. Update `get-compose` with right brew tag + package list
2. Run `bash get-compose` → generates ODCS compose
3. Copy `.repo` contents into `compose.repo`
4. Run `bash update-rpm-lockfile` → regenerates `rpms.lock.yaml`
5. Commit `rpms.lock.yaml`, `compose.repo`, `get-compose`

## Lockfile Generation (Common Pitfalls)

### ODCS compose only includes explicitly listed packages

`odcs create-tag <tag> <pkg1> <pkg2> ...` creates a YUM repo containing ONLY the
named packages (and their runtime deps from the tag). It does NOT include all
packages tagged into the source tag.

If a dependency (e.g. `gdisk`, `python-cherrypy`, `libntirpc`) isn't in
`packages-ceph.txt`, it won't be in the compose repo even if it's tagged.

**Fix:** Add the package name to `packages-ceph.txt`, then regenerate the
compose.

### Missing RPMs in RHEL 10 repos

Some packages used by Ceph (e.g. `gdisk`, `python3-kubernetes`,
`python3-cherrypy`, `libntirpc`) are not in RHEL 10 BaseOS/AppStream/CRB.
They're custom `el10cp` builds from the `ceph-9.X-rhel-10-candidate` Brew tag.

If the solver says `missing packages: <name>`, check:
1. Is it tagged into the Brew tag? (`brew list-tagged --latest ceph-9.2-rhel-10-candidate | grep <name>`)
2. Is it listed in `packages-ceph.txt` so ODCS includes it?
3. If neither: retag from the 9.1 tag and add to `packages-ceph.txt`

### Dependency packages must be tagged before compose creation

The ODCS compose is a snapshot of the tag at a point in time. If dependency
packages (Python libs, libntirpc, etc.) aren't tagged BEFORE creating the
compose, they won't be in the compose repo.

**Workflow for a new minor version:**
1. `brew tag-build ceph-9.2-rhel-10-candidate <nvr>` — retag all non-ceph
   dependency packages from previous release's candidate tag
2. Create ODCS compose (includes all deps now)
3. Run lockfile generator

### ODCS auth

The `get-compose` script uses a container with OIDC auth. The native `odcs`
CLI works with kerberos (`kinit`) and can be used directly instead:

```
odcs --redhat --quiet create-tag \
  --sigkey "none" --arch "x86_64" \
  ceph-9.2-rhel-10-candidate \
  $(cat packages-ceph.txt)
```

### Tagging permissions

- Tagging into `-pending` tags requires `trusted` permission (usually denied).
- Tagging into `-candidate` tags works with standard permissions.
- `brew tag-build` creates async tasks; they complete nearly instantly.

### Arch constraints

`rpms.in.yaml` arches must match what the compose supports. For RHEL 10,
only `x86_64` has packages. Non-x86_64 arches will cause solver failures.

`get-compose` uses `--arch x86_64` (update if more arches are needed).

### Lockfile solver warnings

"No sources found" warnings for SRPMs are normal and non-fatal. The solver
pins binary RPMs correctly even without source RPM metadata.

## Brew Tags

- Pending: `ceph-9.2-rhel-10-pending`
- Candidate: `ceph-9.2-rhel-10-candidate`
- RHEL 9 variant: `ceph-9.2-rhel-9-pending`, `ceph-9.2-rhel-9-candidate`

## Architectures

- UBI 10 / RHEL 10: x86_64 only (initial; may expand)
- Pipeline still builds for: x86_64, aarch64, ppc64le, s390x

## Notes

- Hermetic builds: all RPMs must be pre-resolved in `rpms.lock.yaml`
- Base image is UBI10, RHEL 8 dropped per 9.2 release conventions
- NFS-Ganesha packages included for multi-protocol gateway support
