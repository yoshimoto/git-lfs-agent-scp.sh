#!/bin/bash
#
# git-lfs-agent-scp.sh is a self-contained BASH script, which
# implements protocol defined in
# https://github.com/git-lfs/git-lfs/blob/main/docs/custom-transfers.md
#
# Copyright 2023 Hiromasa YOSHIMOTO
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.



git_trace() { echo "$@" >&2; }
abort() { git_trace "$@"; exit 1; }

json_value()
{
    # Extracts value from $JSON based on key specified by "$1"
    [[ $JSON =~ '"'$1'":'\s*'"'([^'"']*) ]] && echo "${BASH_REMATCH[1]}"
}

init()
{
    git_trace "init"

    printf '{}\n'
}

download()
{
    git_trace "download"

    local oid path cmd status
    oid=$(json_value oid)
    path="$TMPDIR/$oid"
    cmd=$(printf 'scp -B %q/%q %q' "$destination" "$oid" "$path")

    git_trace "$cmd"
    $cmd
    status=$?

    if [ $status -eq 0 ]; then
	printf '{"event":"complete","oid":"%q","path":"%q"}\n' "$oid" "$path"
    else
	printf '{"event":"complete","oid":"%q","error":{"code":%d,"message":"%s"}}\n' "$oid" "$status" "download error"
    fi
}

upload()
{
    git_trace "upload"

    local oid path cmd status
    oid=$(json_value oid)
    path=$(json_value path)
    cmd=$(printf 'scp -B %q %q/%q' "$path" "$destination" "$oid")

    git_trace "$cmd"
    $cmd
    status=$?

    if [ $status -eq 0 ]; then
	printf '{"event":"complete","oid":"%q"}\n' "$oid"
    else
	printf '{"event":"complete","oid":"%q","error":{"code":%d,"message":"%s"}}\n' "$oid" "$status" "upload error"
    fi
}

# Retrives TempDir variable from git-lfs's configration.
# TempDir is required to avoid the "invalid cross-device link" error
# when downloading. See also related topics below:
# - https://github.com/git-lfs/git-lfs/issues/2891
# - https://github.com/git-lfs/git-lfs/issues/2381
#
old_TMPDIR=${TMPDIR:-/tmp}
TMPDIR=$(git lfs env | grep Temp) || abort "git lfs env failed."
TMPDIR=${TMPDIR/TempDir=/}
[ -d "$TMPDIR" ] || TMPDIR="$old_TMPDIR"

destination=$1

[ -n "$destination" ] || abort "No destination specified."

while read -r JSON; do
    event=$(json_value event)
    case "$event" in
	init)
	    init
	    ;;
	download)
	    download
	    ;;
	upload)
	    upload
	    ;;
	terminate)
	    break
	    ;;
	*)
	    ;;
    esac
done

exit 0
