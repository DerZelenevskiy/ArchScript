# ArchScript

Bash script for removing and creating backups of outdated files which exceed the size limit

### Syntax

`arch.sh [-c cap] [working-dir] [backup-dir]`

Where:

- `-c`: maximal capacity (default: 70%)
- `working-dir`: path to the working directory (default: pwd)
- `backup-dir`: path to the destination directory (default ../backup)

### Features

- Uses gzip compression by default
- To set compression mode to lzma2, set export variable `LAB1_MAX_COMPRESSION=1`