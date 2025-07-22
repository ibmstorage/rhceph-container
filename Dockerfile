# CEPH DAEMON BASE IMAGE

FROM registry.redhat.io/ubi8/ubi-minimal:latest

ENV I_AM_IN_A_CONTAINER 1

# Who is the maintainer ?
LABEL maintainer="Guillaume Abrioux <gabrioux@redhat.com>"

# Is a ceph container ?
LABEL ceph="True"

# What is the actual release ? If not defined, this equals the git branch name
LABEL RELEASE="main"

# What was the url of the git repository
LABEL GIT_REPO="https://github.com/ceph/ceph-container.git"

# What was the git branch used to build this container
LABEL GIT_BRANCH="main"

# What was the commit ID of the current HEAD
LABEL GIT_COMMIT="e150ad9dd6aa1e402d78863e3e960e9007c4f01a"

# Was the repository clean when building ?
LABEL GIT_CLEAN="True"

# What CEPH_POINT_RELEASE has been used ?
LABEL CEPH_POINT_RELEASE=""

ENV CEPH_VERSION pacific
ENV CEPH_POINT_RELEASE ""
ENV CEPH_DEVEL false
ENV CEPH_REF pacific
ENV OSD_FLAVOR default

#======================================================
# Install ceph and dependencies, and clean up
#======================================================

RUN rm -f /etc/yum.repos.d/ubi.repo

# Editing /etc/redhat-storage-server release file
RUN echo "Red Hat Ceph Storage Server 5 (Container)" > /etc/redhat-storage-release

EXPOSE 6789 6800 6801 6802 6803 6804 6805 80 5000

# Atomic specific labels
LABEL version="5"

# Build specific labels
LABEL com.redhat.component="rhceph-container"
LABEL name="rhceph"
LABEL description="Red Hat Ceph Storage 5"
LABEL summary="Provides the latest Red Hat Ceph Storage 5 on RHEL 8 in a fully featured and supported base image."
LABEL io.k8s.display-name="Red Hat Ceph Storage 5 on RHEL 8"
LABEL io.openshift.tags="rhceph ceph"

# Escape char after immediately after RUN allows comment in first line
RUN \
    # Install all components for the image, whether from packages or web downloads.
    # Typical workflow: add new repos; refresh repos; install packages; package-manager clean;
    #   download and install packages from web, cleaning any files as you go.
    # Installs should support install of ganesha for luminous
    microdnf update -y --setopt=install_weak_deps=0 --nodocs && \
microdnf install -y --setopt=install_weak_deps=0 --nodocs wget unzip util-linux python3-saml python3-setuptools udev device-mapper \
        ca-certificates \
        e2fsprogs \
        ceph-common  \
        ceph-mon  \
        ceph-osd \
        ceph-mds \
cephfs-mirror \
        rbd-mirror  \
        ceph-mgr \
ceph-mgr-cephadm \
ceph-mgr-dashboard \
ceph-mgr-diskprediction-local \
ceph-mgr-k8sevents \
ceph-mgr-rook\
        ceph-grafana-dashboards \
        kmod \
        lvm2 \
        gdisk \
        smartmontools \
        nvme-cli \
        libstoragemgmt \
        systemd-udev \
        sg3_utils \
         \
        ceph-radosgw libradosstriper1 \
        nfs-ganesha nfs-ganesha-ceph nfs-ganesha-rgw nfs-ganesha-rados-grace nfs-ganesha-rados-urls sssd-client \
        tcmu-runner ceph-iscsi \
         \
         \
        ceph-immutable-object-cache \
         \
         \
         && \
ln -s /usr/share/ceph/mgr/dashboard/frontend/dist-redhat /usr/share/ceph/mgr/dashboard/frontend/dist && \
    # Clean container, starting with record of current size (strip / from end)
    INITIAL_SIZE="$(bash -c 'sz="$(du -sm --exclude=/proc /)" ; echo "${sz%*/}"')" && \
    #
    #
    # Perform any final cleanup actions like package manager cleaning, etc.
    echo 'Postinstall cleanup' && \
 ( microdnf clean all && \
   rpm -q \
        ca-certificates \
        e2fsprogs \
        ceph-common  \
        ceph-mon  \
        ceph-osd \
        ceph-mds \
cephfs-mirror \
        rbd-mirror  \
        ceph-mgr \
ceph-mgr-cephadm \
ceph-mgr-dashboard \
ceph-mgr-diskprediction-local \
ceph-mgr-k8sevents \
ceph-mgr-rook\
        ceph-grafana-dashboards \
        kmod \
        lvm2 \
        gdisk \
        smartmontools \
        nvme-cli \
        libstoragemgmt \
        systemd-udev \
        sg3_utils \
         \
        ceph-radosgw libradosstriper1 \
        nfs-ganesha nfs-ganesha-ceph nfs-ganesha-rgw nfs-ganesha-rados-grace nfs-ganesha-rados-urls sssd-client \
        tcmu-runner ceph-iscsi \
         \
         \
        ceph-immutable-object-cache \
         \
         \
         && \
   rm -f /etc/profile.d/lang.sh ) && \
    # Tweak some configuration files on the container system
    # disable sync with udev since the container can not contact udev
sed -i -e 's/udev_rules = 1/udev_rules = 0/' -e 's/udev_sync = 1/udev_sync = 0/' -e 's/obtain_device_list_from_udev = 1/obtain_device_list_from_udev = 0/' /etc/lvm/lvm.conf && \
# validate the sed command worked as expected
grep -sqo "udev_sync = 0" /etc/lvm/lvm.conf && \
grep -sqo "udev_rules = 0" /etc/lvm/lvm.conf && \
grep -sqo "obtain_device_list_from_udev = 0" /etc/lvm/lvm.conf && \
mkdir -p /var/run/ganesha && \
    # Clean common files like /tmp, /var/lib, etc.
    # We don't clean RHEL
find /var/log/ -type f -exec truncate -s 0 {} \; && \
    #
    #
    # Report size savings (strip / from end)
    FINAL_SIZE="$(bash -c 'sz="$(du -sm --exclude=/proc /)" ; echo "${sz%*/}"')" && \
    REMOVED_SIZE=$((INITIAL_SIZE - FINAL_SIZE)) && \
    echo "Cleaning process removed ${REMOVED_SIZE}MB" && \
    echo "Dropped container size from ${INITIAL_SIZE}MB to ${FINAL_SIZE}MB" && \
    #
    # Verify that the packages installed haven't been accidentally cleaned
    rpm -q \
        ca-certificates \
        e2fsprogs \
        ceph-common  \
        ceph-mon  \
        ceph-osd \
        ceph-mds \
cephfs-mirror \
        rbd-mirror  \
        ceph-mgr \
ceph-mgr-cephadm \
ceph-mgr-dashboard \
ceph-mgr-diskprediction-local \
ceph-mgr-k8sevents \
ceph-mgr-rook\
        ceph-grafana-dashboards \
        kmod \
        lvm2 \
        gdisk \
        smartmontools \
        nvme-cli \
        libstoragemgmt \
        systemd-udev \
        sg3_utils \
         \
        ceph-radosgw libradosstriper1 \
        nfs-ganesha nfs-ganesha-ceph nfs-ganesha-rgw nfs-ganesha-rados-grace nfs-ganesha-rados-urls sssd-client \
        tcmu-runner ceph-iscsi \
         \
         \
        ceph-immutable-object-cache \
         \
         \
         && echo 'Packages verified successfully'
#======================================================
# Add ceph-container files
#======================================================

# Add templates for confd
ADD ./files/confd/templates/* /etc/confd/templates/
ADD ./files/confd/conf.d/* /etc/confd/conf.d/

# Add bootstrap script, ceph defaults key/values for KV store
ADD files/*.sh files/check_zombie_mons.py files/osd_scenarios/* files/entrypoint.sh.in files/disabled_scenario /opt/ceph-container/bin/
ADD files/ceph.defaults /opt/ceph-container/etc/
# ADD *.sh ceph.defaults check_zombie_mons.py ./osd_scenarios/* entrypoint.sh.in disabled_scenario /

# Modify the entrypoint
RUN bash "/opt/ceph-container/bin/generate_entrypoint.sh" && \
  rm -f /opt/ceph-container/bin/generate_entrypoint.sh && \
  bash -n /opt/ceph-container/bin/*.sh

# Execute the entrypoint
WORKDIR /
ENTRYPOINT ["/opt/ceph-container/bin/entrypoint.sh"]
