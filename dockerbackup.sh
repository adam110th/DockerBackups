#! /bin/bash
# A simple script to back up Docker containers, images, and volumes
# --- Option parsing ---
EXCLUDE_CONTAINERS=""
EXCLUDE_IMAGES=""
EXCLUDE_VOLUMES=""
DO_IMAGES=false # Default to not backing up images
# Temp string for getopt
TEMP=$(getopt -o '' --long exclude_containers:,exclude_images:,exclude_volumes:,include_images -n 'dockerbackup.sh' -- "$@")
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
# Note the quotes around '$TEMP': they are essential!
eval set -- "$TEMP"
while true; do
  case "$1" in
    --exclude_containers )
      EXCLUDE_CONTAINERS="$2"; shift 2 ;;
    --exclude_images )
      EXCLUDE_IMAGES="$2"; shift 2 ;;
    --exclude_volumes )
      EXCLUDE_VOLUMES="$2"; shift 2 ;;
    --include_images )
      DO_IMAGES=true; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: $0 /path/to/backup/directory [--include_images] [--exclude_containers <c1,c2>] [--exclude_images <i1,i2>] [--exclude_volumes <v1,v2>]"
  exit 1
fi
mkdir -p "$BACKUP_DIR"

# Convert comma-separated strings to arrays, only if the variable is not empty
[ -n "$EXCLUDE_CONTAINERS" ] && IFS=',' read -r -a EXCLUDE_CONTAINERS_ARRAY <<< "$EXCLUDE_CONTAINERS" || EXCLUDE_CONTAINERS_ARRAY=()
[ -n "$EXCLUDE_IMAGES" ] && IFS=',' read -r -a EXCLUDE_IMAGES_ARRAY <<< "$EXCLUDE_IMAGES" || EXCLUDE_IMAGES_ARRAY=()
[ -n "$EXCLUDE_VOLUMES" ] && IFS=',' read -r -a EXCLUDE_VOLUMES_ARRAY <<< "$EXCLUDE_VOLUMES" || EXCLUDE_VOLUMES_ARRAY=()

# Helper function to check if a value is in an array
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# Backup Docker containers
CONTAINERS=$(docker ps -a -q)
for CONTAINER in $CONTAINERS; do
    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$CONTAINER")
    CONTAINER_NAME=${CONTAINER_NAME#/}
    if containsElement "$CONTAINER_NAME" "${EXCLUDE_CONTAINERS_ARRAY[@]}"; then
      echo "Skipping excluded container: $CONTAINER_NAME"
      continue
    fi
    docker export "$CONTAINER" -o "$BACKUP_DIR/${CONTAINER_NAME}_container.tar"
    echo "Backed up container: $CONTAINER_NAME"
done
# Backup Docker 
if [ "$DO_IMAGES" = true ]; then
    IMAGES=$(docker images -q | sort | uniq)
    for IMAGE in $IMAGES; do
        # This gets the repo tags, which are more user-friendly than the image ID
        IMAGE_TAGS=$(docker inspect --format='{{.RepoTags}}' "$IMAGE")
        # remove brackets
        IMAGE_TAGS=${IMAGE_TAGS//[\[\]]/}

        FIRST_TAG=""
        if [ -n "$IMAGE_TAGS" ]; then
            # handle multiple tags, using the first one for the filename
            FIRST_TAG=${IMAGE_TAGS%% *}
        fi
        # check if the image should be excluded
        if [ -n "$FIRST_TAG" ] && containsElement "$FIRST_TAG" "${EXCLUDE_IMAGES_ARRAY[@]}"; then
            echo "Skipping excluded image: $FIRST_TAG"
            continue
        fi

        IMAGE_NAME=""
        BACKUP_IMAGE_NAME=""

        if [ -n "$FIRST_TAG" ] && [ "$FIRST_TAG" != "<none>:<none>" ]; then
            # create a valid filename from the tag
            IMAGE_NAME=${FIRST_TAG//[:\/]/_}
            BACKUP_IMAGE_NAME=$FIRST_TAG
        else
            # if the image has no tags, use the image ID
            IMAGE_NAME=$IMAGE
            BACKUP_IMAGE_NAME="untagged image $IMAGE"
            echo "Image has no tags, using image ID for backup: $IMAGE"
        fi

        docker save "$IMAGE" -o "$BACKUP_DIR/${IMAGE_NAME}_image.tar"
        echo "Backed up image: $BACKUP_IMAGE_NAME"
    done
fi
# Backup Docker volumes
VOLUMES=$(docker volume ls -q)
for VOLUME in $VOLUMES; do
    if containsElement "$VOLUME" "${EXCLUDE_VOLUMES_ARRAY[@]}"; then
      echo "Skipping excluded volume: $VOLUME"
      continue
    fi
    docker run --rm -v "$VOLUME":/volume -v "$BACKUP_DIR":/backup busybox \
    tar czf /backup/"${VOLUME}_volume.tar.gz" -C /volume .
    echo "Backed up volume: $VOLUME"
done
echo "Docker backup completed. Backup files are located in $BACKUP_DIR"