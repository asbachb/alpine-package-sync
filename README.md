# alpine-package-sync
This bash script is used to create something like https://snapshot.debian.org/ but for alpine linux packges.
It 
1. Syncs the configured alpine linux repository with a local one which contains all packages for a release and repository combination (e.g. 3.9 main)
1. Creates a repository snapshot with a timestamp of latest APKINDEX date

## Configuration
Create a copy of `alpine-package-sync.example.conf` according your needs e.g. `sync.conf`.

## Usage
`sh alpine-package-sync.sh -c ./sync.conf` 
