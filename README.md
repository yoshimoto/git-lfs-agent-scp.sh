# git-lfs-agent-scp.sh

Lightweight bash script for [`Git Large File Storage (LFS)`](https://git-lfs.github.com/) over SSH.

This is a self-contained bash script designed for seamless
installation, requiring no prerequisites. It enables to use `git-lfs` even if you can not use http/https but ssh
only.


# Install #

Copy `git-lfs-agent-scp.sh` into a directory included in your `$PATH`
environment variable.

Ensure that the script has the necessary permissions to be executed.
``` sh
chmod +x git-lfs-agent-scp.sh
```


# Usage #

Configure your local git repository as follows

```sh
$ git config lfs.standalonetransferagent scp
$ git config lfs.customtransfer.scp.path git-lfs-agent-scp.sh
$ git config lfs.customtransfer.scp.args $DESTINATION
```

`$DESTINATION` is a remote pathname to store the files. `$DESTINATION`
can be set in the form `[user@]host:[path]`. For examples,
`user@example.com:/path/to/the/directory`.

`git-lfs-agent-scp.sh` will invoke `scp file $DESTINATION` for upload
and `scp $DESTINATION file` for download internally.

# Tips #

If you encounter any issues, you can enable debugging by using `GIT_TRACE=1` as follows:
``` sh
GIT_TRACE=1 git <command>
```
Replace `<command>` with operations like pull or push.
This will provide additional information to help diagnose and resolve problems.


# Acknowledgment #

This script was inspired by the following open source
projects. Special thanks for their invaluable contributions!!

- https://github.com/tdons/git-lfs-agent-scp
- https://github.com/funatsufumiya/git-lfs-agent-scp
