#!/bin/bash

while getopts c: opt
do
   case $opt in
       c) CONFIG_FILE=$OPTARG;;
   esac
done

if [ -z "$CONFIG_FILE" ]; then
	echo "Please provide a config file with parameter \"-c PATH_TO_CONFIG_FILE\""
	exit 1
fi
if [ ! -f "$CONFIG_FILE" ]; then
	echo "Configured config file does not exist: $CONFIG_FILE" 
	exit 1
fi

. $CONFIG_FILE

for version in ${VERSIONS[*]}
do
	for repository in ${REPOSITORY[*]}
	do
		for architecture in ${ARCHITECTURES[*]}
		do
			echo "Syncing $version $repository $architecture..."
			
			REPOSITORY_TARGET=$REPOSITORY_ALL/$version/$repository/$architecture
			RSYNC_URL=$RSYNC_SUFFIX/$version/$repository/$architecture/
			echo "Syncing $REPOSITORY_TARGET from $RSYNC_URL..."
			if [ ! -d "$REPOSITORY_TARGET" ]; then
				echo "Performing initial sync of $REPOSITORY_TARGET..."
				mkdir -p $REPOSITORY_TARGET
			else
				echo "Syncing $REPOSITORY_TARGET to latest..."
			fi
			rsync \
        --archive \
        --update \
        --hard-links \
        --delay-updates \
        --timeout=600 \
        --exclude APKINDEX.tar.gz \
				--progress \
        "$RSYNC_URL" "$REPOSITORY_TARGET"
				
			APKINDEX_RAW=`rsync --list-only "$RSYNC_URL/APKINDEX.tar.gz"`
			if [ "$?" -ne 0 ]; then
				echo "Could not determine timestamp of latest APKINDEX.tar.gz"
				exit 1
		  fi
			APKINDEX_DATE_RAW=$( echo "$APKINDEX_RAW" |cut -d ' ' -f11,10 )
			APKINDEX_DATE=`date --date="$APKINDEX_DATE_RAW" --iso-8601=seconds`
			
			echo "APKINDEX LATEST REMOTE DATE: $APKINDEX_DATE"
			
			LATEST_LOCAL_APKINDEX_DATE=$( ls $REPOSITORY_BASE/snapshots | sort -r | head -1 )
			echo "APKINDEX LOCAL DATE: $LATEST_LOCAL_APKINDEX_DATE"
			
			if [ "$APKINDEX_DATE" = "$LATEST_LOCAL_APKINDEX_DATE" ]; then
				echo "Everything seems up to date!"
				exit 0
			else
				echo "Seems there's a new repository version: $APKINDEX_DATE"
				SNAPSHOT_TARGET=$REPOSITORY_BASE/snapshots/$APKINDEX_DATE
				mkdir $SNAPSHOT_TARGET
				
				rsync \
					--archive \
					--update \
					--hard-links \
					--delay-updates \
					--timeout=600 \
					--progress \
					"$RSYNC_URL/APKINDEX.tar.gz" "$SNAPSHOT_TARGET"
				mkdir $SNAPSHOT_TARGET/APKINDEX
				tar -xzvf $SNAPSHOT_TARGET/APKINDEX.tar.gz -C $SNAPSHOT_TARGET/APKINDEX
				PACKAGES=$( grep -oP '(?<=^[VP]\:)(.*)' $SNAPSHOT_TARGET/APKINDEX/APKINDEX | sed 'N;s/\n/-/' )
				
				echo "Creating symlinks to all repository..."
				for package in ${PACKAGES[*]}
				do
					if [ ! -f $REPOSITORY_TARGET/$package.apk ]; then
						echo "$package.apk is listed in APKINDEX file but it's not contained in $REPOSITORY_TARGET."
						echo "This means either all repository is not up to date or APKINDEX is wrongly constructed."
						echo "Deleting repository $SNAPSHOT_TARGET since it would not be complete."
						read
						rm -r $SNAPSHOT_TARGET
						exit 1
					fi
					ln -s $REPOSITORY_TARGET/$package.apk $SNAPSHOT_TARGET/$package.apk
				done
				
				rm -r $SNAPSHOT_TARGET/APKINDEX
			fi
		done
	done
done
