set -x

for arg in "$@"; do
    BUILD_NVR=$(brew list-tagged --latest ceph-9.1-rhel-10-candidate | grep $arg | cut -d' ' -f1)
    brew tag-build ceph-9.2-rhel-10-candidate $BUILD_NVR
done
