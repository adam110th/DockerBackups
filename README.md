# dockerbackup

A simple shell script to back up Docker containers, images, and volumes.

## Usage

```bash
./dockerbackup.sh /path/to/backup/directory [--include_images]
```

- `/path/to/backup/directory`: The directory where the backup files will be stored. This is a required argument.
- `[--include_images]`: An optional argument to include Docker images in the backup.

## What it backs up

- **Docker Containers**: Exports all containers (both running and stopped) as `.tar` files.
- **Docker Images**: If the `--include_images` flag is provided, it saves all Docker images as `.tar` files.
- **Docker Volumes**: Backs up all Docker volumes as `.tar.gz` files.

## Prerequisites

- Docker must be installed and running on the system where you run the script.
- The script uses the `busybox` image to back up volumes. If you don't have it, Docker will pull it automatically.
