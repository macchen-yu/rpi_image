#!/bin/sh
#
# Copyright OpenEmbedded Contributors
#
# SPDX-License-Identifier: GPL-2.0-only
#
# Used to find files installed in sysroot which are not tracked by sstate manifest

# Global vars
tmpdir=

usage () {
  cat << EOF
Welcome to sysroot cruft finding utility.
$0 <OPTION>

Options:
  -h, --help
        Display this help and exit.

  --tmpdir=<tmpdir>
        Specify tmpdir, will use the environment variable TMPDIR if it is not specified.
	Something like /OE/oe-core/tmp-eglibc (no / at the end).

  --whitelist=<whitelist-file>
        Text file, each line is regular expression for paths we want to ignore in resulting diff.
        You can use diff file from the script output, if it contains only expected exceptions.
        '#' is used as regexp delimiter, so you don't need to prefix forward slashes in paths.
        ^ and $ is automatically added, so provide only the middle part.
        Lines starting with '#' are ignored as comments.
        All paths are relative to "sysroots" directory.
        Directories don't end with forward slash.
EOF
}

# Print error information and exit.
echo_error () {
  echo "ERROR: $1" >&2
  exit 1
}

while [ -n "$1" ]; do
  case $1 in
    --tmpdir=*)
      tmpdir=`echo $1 | sed -e 's#^--tmpdir=##' | xargs readlink -e`
      [ -d "$tmpdir" ] || echo_error "Invalid argument to --tmpdir"
      shift
        ;;
    --whitelist=*)
      fwhitelist=`echo $1 | sed -e 's#^--whitelist=##' | xargs readlink -e`
      [ -f "$fwhitelist" ] || echo_error "Invalid argument to --whitelist"
      shift
        ;;
    --help|-h)
      usage
      exit 0
        ;;
    *)
      echo "Invalid arguments $*"
      echo_error "Try '$0 -h' for more information."
        ;;
  esac
done

# sstate cache directory, use environment variable TMPDIR
# if it was not specified, otherwise, error.
[ -n "$tmpdir" ] || tmpdir=$TMPDIR
[ -n "$tmpdir" ] || echo_error "No tmpdir found!"
[ -d "$tmpdir" ] || echo_error "Invalid tmpdir \"$tmpdir\""

OUTPUT=${tmpdir}/sysroot.cruft.`date "+%s"`

# top level directories
WHITELIST="[^/]*"

# generated by base-passwd recipe
WHITELIST="${WHITELIST} \
  .*/etc/group-\? \
  .*/etc/passwd-\? \
"
# generated by pseudo-native
WHITELIST="${WHITELIST} \
  .*/var/pseudo \
  .*/var/pseudo/[^/]* \
"

# generated by package.bbclass:SHLIBSDIRS = "${PKGDATA_DIR}/${MLPREFIX}shlibs"
WHITELIST="${WHITELIST} \
  .*/shlibs \
  .*/pkgdata \
"

# generated by python
WHITELIST="${WHITELIST} \
  .*\.pyc \
  .*\.pyo \
  .*/__pycache__ \
"

# generated by lua
WHITELIST="${WHITELIST} \
  .*\.luac \
"

# generated by sgml-common-native
WHITELIST="${WHITELIST} \
  .*/etc/sgml/sgml-docbook.bak \
"

# generated by php
WHITELIST="${WHITELIST} \
  .*/usr/lib/php5/php/.channels \
  .*/usr/lib/php5/php/.channels/.* \
  .*/usr/lib/php5/php/.registry \
  .*/usr/lib/php5/php/.registry/.* \
  .*/usr/lib/php5/php/.depdb \
  .*/usr/lib/php5/php/.depdblock \
  .*/usr/lib/php5/php/.filemap \
  .*/usr/lib/php5/php/.lock \
"

# generated by toolchain
WHITELIST="${WHITELIST} \
  [^/]*-tcbootstrap/lib \
"

# generated by useradd.bbclass
WHITELIST="${WHITELIST} \
  [^/]*/home \
  [^/]*/home/xuser \
  [^/]*/home/xuser/.bashrc \
  [^/]*/home/xuser/.profile \
  [^/]*/home/builder \
  [^/]*/home/builder/.bashrc \
  [^/]*/home/builder/.profile \
"

# generated by image.py for WIC
# introduced in oe-core commit 861ce6c5d4836df1a783be3b01d2de56117c9863
WHITELIST="${WHITELIST} \
  [^/]*/imgdata \
  [^/]*/imgdata/[^/]*\.env \
"

# generated by fontcache.bbclass
WHITELIST="${WHITELIST} \
  .*/var/cache/fontconfig/ \
"

SYSROOTS="`readlink -f ${tmpdir}`/sysroots/"

mkdir ${OUTPUT}
find ${tmpdir}/sstate-control -name \*.populate-sysroot\* -o -name \*.populate_sysroot\* -o -name \*.package\* | xargs cat | grep sysroots | \
  sed 's#/$##g; s#///*#/#g' | \
  # work around for paths ending with / for directories and multiplied // (e.g. paths to native sysroot)
  sort | sed "s#^${SYSROOTS}##g" > ${OUTPUT}/master.list.all.txt
sort -u ${OUTPUT}/master.list.all.txt > ${OUTPUT}/master.list.txt # -u because some directories are listed for more recipes
find ${tmpdir}/sysroots/ | \
  sort | sed "s#^${SYSROOTS}##g" > ${OUTPUT}/sysroot.list.txt

diff ${OUTPUT}/master.list.all.txt ${OUTPUT}/master.list.txt > ${OUTPUT}/duplicates.txt
diff ${OUTPUT}/master.list.txt ${OUTPUT}/sysroot.list.txt > ${OUTPUT}/diff.all.txt

grep "^> ." ${OUTPUT}/diff.all.txt | sed 's/^> //g' > ${OUTPUT}/diff.txt
for item in ${WHITELIST}; do
  sed -i "\\#^${item}\$#d" ${OUTPUT}/diff.txt;
  echo "${item}" >> ${OUTPUT}/used.whitelist.txt
done

if [ -s "$fwhitelist" ] ; then
  cat $fwhitelist >> ${OUTPUT}/used.whitelist.txt
  cat $fwhitelist | grep -v '^#' | while read item; do
    sed -i "\\#^${item}\$#d" ${OUTPUT}/diff.txt;
  done
fi
# too many false positives for directories
# echo "Following files are installed in sysroot at least twice"
# cat ${OUTPUT}/duplicates

RESULT=`cat ${OUTPUT}/diff.txt | wc -l`

if [ "${RESULT}" != "0" ] ; then
  echo "ERROR: ${RESULT} issues were found."
  echo "ERROR: Following files are installed in sysroot, but not tracked by sstate:"
  cat ${OUTPUT}/diff.txt
else
  echo "INFO: All files are tracked by sstate or were explicitly ignored by this script"
fi

echo "INFO: Output written in: ${OUTPUT}"
exit ${RESULT}
