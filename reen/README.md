# Reen script

Backup utility based in rsync.

This is a bash script that enable easy backups based in rsync.

## Install

```bash
curl  https://raw.githubusercontent.com/everitosan/BashScripts/main/reen/reen.sh -o /usr/local/bin/reen && chmod +X /usr/local/bin/reen
```

**Parameters**

```bash
$ reen -h

########################
# 🔧 🆁🅴🅴🅽 (script)  #
############### 1.0.0 #
-h - Show help
-d - Directory path for destiny of the backup
-s - File with directories to backup
-i - File with directories to be ignored in the backup

```


## Example of use


**Source file**
```txt
/home/evesan/Work
/home/evesan/Descargas
```


**Ignore file**
```txt
node_modules
target
```