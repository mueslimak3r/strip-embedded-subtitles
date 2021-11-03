<h1 align="center">strip-embedded-subtitles</h1>
<h3 align="center">Recursively find all video files in a directory with embedded subtitles and remove them</h3>

## Usage

usage: strip_embedded_subs.sh /path/to/media/folder --TEST or --KEEP_OLD=YES/NO or --LIST/RESTORE/REMOVE_BACKUPS

--KEEP_OLD=YES/NO controls deleting the backup files containing subtitles
If you keep the backup files it will double your hard drive usage

--LIST/RESTORE/REMOVE_BACKUPS can list, restore, or remove the old files containing subtitles

--TEST runs the script without actually doing any muxing

### Dependencies

- bash
- ffmpeg
