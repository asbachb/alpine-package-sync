# alpine-package-sync
A bash script which syncs apline linux package repository and create subdirectories in case of new APKINDEX releases.
These repositories can be used to create reproducable docker containers.

## Configuration
Create a copy of `alpine-package-sync.example.conf` according your needs e.g. `sync.conf`.

## Usage
`sh alpine-package-sync.sh -c ./sync.conf` 
