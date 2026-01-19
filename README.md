# Generating a Compose for RHCEPH-9.0

- make sure ./get-compose is using the right brew tag and package list
- run `bash get-compose`
- from generated repo file, copy contents into `./compose.repo`
- run `bash update-rpm-lockfile`
- commit new `rpms.lock.yaml`, `compose.repo` and `get-compose` and push
