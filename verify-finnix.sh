#! /bin/sh
# verify-finnix.sh
# shellcheck disable=SC2292
#
#   Script is finished - 12 Sept 2026 WY
#
# Relevant websites, c. Oct. 2026
#   https://www.finnix.org
#   https://github.com/finnix/finnix-docs
#   https://github.com/finnix/finnix-docs/releases
#   https://github.com/finnix/finnix-docs/blob/main/checksums-signatures.md
#   https://github.com/finnix/finnix-docs/blob/main/releases/251.json
#   https://ftp-osl.osuosl.org/pub/finnix/current
#
# List of required files
#   Available at mirrors
#     finnix-<version-number>.iso
#       finnix-251.iso
#     finnix-<version-number>.iso.gpg
#       finnix-251.iso.gpg
#    Available at finnix-docs/releases
#     <version-number>.json
#       251.json


#> Debugging
#set -x #>
set -e
set -u
set -C


# Header / help message
if   ls ./*.iso  >/dev/null \
  && ls ./*.gpg  >/dev/null \
  && ls ./*.json >/dev/null
then
  : "t:0:${LINENO}"
else
  printf '#\n# Verify Finnix: \n#   This script is intended to be run '
  printf 'from the directory where the Finnix\n# ISO files, etc. have '
  printf 'been downloaded.\n#\n\n'
  sleep 3
  exit 1
fi


# Variables
hash_ff=checksums.txt
ssh_key='AAAAC3NzaC1lZDI1NTE5AAAAIJQEw5EJeL+lHS9Dq8iU8vgVgU6VAb+sVsitQU8tHl38'
ssh_eml='file-signing@finnix.org'


# Functions
#
: "Define function: __error_exit__"
#
# Usage:    __error_exit__ [line number] [message string]
#           __error_exit__ "${LINENO}" "Message."
#
__error_exit__ ()
{
  printf 'Error: line %d:\t' "${1:?}"
  printf '%s\nExiting.\n' "${2:?}"
  exit 1
}

: "Define function: __get_files__"
#
# Usage:    __get_files__ [file extension]
#           __get_files__ "iso"
#
__get_files__ ()
{
  output_0_fn_getfiles=
  set -- ./*."${1:?}"
  case "$#" in
    0) printf 'No files found with an \.%s\ extension; exiting.' \
        "$1"
      exit 2
      ;;
    1) output_0_fn_getfiles=$1
      ;;
    *) printf 'Multiple files found with an \.%s\ extension; exiting.' \
        "$1"
      exit 3
      ;;
  esac
}


# List of required commands
command_list=
set -- awk file gpg grep jq md5sum sha256sum sha512sum ssh-keygen
  #> codeblocks

for cM
do
  if command -v "${cM}" >/dev/null
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    command_list="${command_list} ${cM} "
  fi
done

: "Does \\command_list\\ have a non-zero length?"
if [ -n "${command_list}" ]
then
  : "t:0:${LINENO}" #>
  __error_exit__ "${LINENO}" "Command(s) not found: ${command_list}"
else
  : "f:$?:${LINENO}" #>
fi
unset command_list cM
:
  #exit "${LINENO}" #>
  #set -x #>
  :
  :
# Identify the files in the CWD

# Identify ISO file
__get_files__ "iso"
:
iso_relpth=$( printf '%s' "${output_0_fn_getfiles}" \
  | grep -xEe '.*[fF]innix.*\.iso'$ 2>/dev/null \
  ||:
)
iso_abspth=$( realpath -e -- "${iso_relpth}" 2>/dev/null \
  ||:
  )
:
: "Does \\iso_abspth\\ have a non-zero length?"
if [ -n "${iso_abspth}" ]
then
  : "t:0:${LINENO}" #>
  string_0_iso=": ISO 9660 "

  if file "${iso_abspth}" \
    | grep "${string_0_iso}" >/dev/null
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" "String not found: ${string_0_iso}"
  fi
else
  : "f:$?:${LINENO}" #>
__error_exit__ "${LINENO}" "ISO file not found."
fi
:
  #exit "${LINENO}" #>
  #set -x #>
  :
  :
# Identify PGP file
__get_files__ "iso.gpg"
:
gpg_relpth=$( printf '%s' "${output_0_fn_getfiles}" \
  | grep -xEe '.*[fF]innix.*\.iso\.gpg'$ 2>/dev/null \
  ||:
)
gpg_abspth=$( realpath -e -- "${gpg_relpth}" 2>/dev/null \
  ||:
 )
 :
 : "Does \\gpg_abspth\\ have a non-zero length?"
if [ -n "${gpg_abspth}" ]
then
  : "t:0:${LINENO}" #>
  string_1_gpg=": PGP signature "

  if file "${gpg_abspth}" \
    | grep "${string_1_gpg}" >/dev/null
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" \
      "String not found: ${string_1_gpg}."
  fi
else
  : "f:$?:${LINENO}" #>
  __error_exit__ "${LINENO}" "PGP file not found."
fi
:
  #exit "${LINENO}" #>
  #set -x #>
  :
  :
# Identify OS major version of ISO file
maj_vers=$( printf '%s' "${gpg_relpth}" \
  | sed -e 's,^\(\./\)\?finnix-,,' -e 's,.iso.*$,,' \
  | sort -u
)
if [ -n "${maj_vers}" ]
then
  : "t:0:${LINENO}" #>
  :
  if printf '%d' "${maj_vers}" \
    | grep -qxEe '[0-9]{3,}'
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" "Major version info not identified."
  fi
else
  : "f:$?:${LINENO}" #>
  __error_exit__ "${LINENO}" "Data not found"
fi
:
  #exit "${LINENO}" #>
  #set -x #>
  :
  :
# Identify JSON file
__get_files__ "json"
:
jsn_relpth=$( printf '%s' "${output_0_fn_getfiles}" \
  | grep -xEe '(./)?'"${maj_vers}"'\.json' 2>/dev/null \
  ||:
)
jsn_abspth=$( realpath -e -- "${jsn_relpth}" 2>/dev/null \
  ||:
)
:
: "Does \\jsn_abspth\\ have a non-zero length?"
if [ -n "${jsn_abspth}" ]
then
  : "t:0:${LINENO}" #>
  string_2_jsn=": JSON text data"

  if file "${jsn_abspth}" \
    | grep "${string_2_jsn}"$ >/dev/null
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" \
      "Per \\file\\: \\${string_2_jsn}\\ file not found."
  fi
else
  : "f:$?:${LINENO}" #>
  __error_exit__ "${LINENO}" "File not found"
fi
:
  #exit "${LINENO}" #>
  #set -x #>
  :
  :
# Identify current PGP cryptographic key from output of \gpg --verify\
output_1_gpg=$( gpg --verify -- "${gpg_abspth}" "${iso_abspth}" 2>&1 \
  ||:
)
string_3_gpg="gpg: Signature made"
output_2_gpg=$( printf '%s' "${output_1_gpg}" \
  | grep -e ^"${string_3_gpg}" \
  ||:
)
:
# Some output must exist
: "Does \\output_1_gpg\\ have a non-zero length?"
if [ -n "${output_1_gpg}" ]
then
  : "t:0:${LINENO}" #>
  :
  # A \signature\ must exist
  : "Does \\output_2_gpg\\ have a non-zero length?"
  if [ -n "${output_2_gpg}" ]
  then
    : "t:0:${LINENO}" #>

    # Get the RSA key
    string_4_gpg=" using RSA key "
    output_3_gpg=$( printf '%s' "${output_1_gpg}" \
      | grep -e "${string_4_gpg}" \
      | grep -iEe '[0-9a-f]{40}' \
      ||:
    )
    :
    # An RSA key must exist
    if [ -n "${output_3_gpg}" ]
    then
      : "t:0:${LINENO}" #>
      :
      # Print the full 40 character PGP key identifier
      output_4_gpg=$( printf '%s' "${output_3_gpg}" \
        | awk '{ split($0,arr); for (xx in arr) {
            if (arr[xx] ~ /[0-9a-fA-F]{40}/) {
              print arr[xx]
              }
            }
          }' \
        ||:
        )
    else
      : "f:$?:${LINENO}" #>
      __error_exit__ "${LINENO}" "String not found: \\${string_4_gpg}\\."
    fi
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" "String not found: \\${string_3_gpg}\\."
  fi
else
  : "f:$?:${LINENO}" #>
  __error_exit__ "${LINENO}" "Data not found"
fi
:
  # Review data
  #exit "${LINENO}" #>
  #set -x #>
  :;:;:
  : "gpg_relpth:            ${gpg_relpth}"
  : "gpg_abspth:            ${gpg_abspth}"
  : "iso_relpth:            ${iso_relpth}"
  : "iso_abspth:            ${iso_abspth}"
  : "jsn_relpth:            ${jsn_relpth}"
  : "jsn_abspth:            ${jsn_abspth}"
  : "maj_vers:              ${maj_vers}"
  : "output_0_fn_getfiles:  ${output_0_fn_getfiles}"
  : "output_1_gpg:          ${output_1_gpg}"
  : "output_2_gpg:          ${output_2_gpg}"
  : "output_3_gpg:          ${output_3_gpg}"
  : "output_4_gpg:          ${output_4_gpg}"
  : "string_0_iso:          ${string_0_iso}"
  : "string_1_gpg:          ${string_1_gpg}"
  : "string_2_jsn:          ${string_2_jsn}"
  : "string_3_gpg:          ${string_3_gpg}"
  : "string_4_gpg:          ${string_4_gpg}"
  #set +x
  #exit "${LINENO}" #>
  #set -x
  :
  # Bug, add \||:\ in comsubs which are in assignment stmts bc errexit.

  :
# Obtain an updated copy of the PGP public signing key from online
if [ -n "${output_4_gpg}" ]
then
  : "t:0:${LINENO}" #>
  :
  # Contact keyserver
  output_5_gpg=$( gpg --receive-keys -- "${output_4_gpg}" 2>&1 )
  :
  : "Does \\output_5_gpg\\ have a non-zero length?"
  if [ -n "${output_5_gpg}" ]
  then
    : "t:0:${LINENO}" #>
    :
    # Receive least one PGP key
    output_6_gpg=$( printf '%s' "${output_5_gpg}" \
      | awk '/^gpg: Total number processed: / {
        print $NF
      }'
    )
    if [ -n "${output_6_gpg}" ]
    then
      : "t:0:${LINENO}" #>

      if [ "${output_6_gpg}" -ne 0 ]
      then
        : "t:0:${LINENO}" #>
        printf 'PGP key received\n'
      else
        : "f:$?:${LINENO}" #>
        printf 'Zero PGP keys processed.\n'
        :
        if gpg --list-keys \
          | grep "${output_4_gpg}" >/dev/null
        then
          : "t:0:${LINENO}" #>
        else
          : "f:$?:${LINENO}" #>
          __error_exit__ "${LINENO}" "Zero keys received, and the key is not on disk."
        fi
      fi
    else
      : "f:$?:${LINENO}" #>
      __error_exit__ "${LINENO}" "Data not found"
    fi
  else
    : "f:$?:${LINENO}" #>
  fi

  # Bug, 
  #   There really should be a second identical \gpg --verify\ command
  # as output_7_gpg, because the --receive-keys was run between the two:
  # the outputs may have changed.

  # Verify the ISO file using PGP
  output_8_awk=$( printf '%s' "${output_1_gpg}" \
    | awk '/^gpg: Good signature from/ {
      if (/[Ff]innix/) {
        print "Good"
      } else {
        print "Not so good"
      }
    }'
  )
  if [ "${output_8_awk}" = Good ]
  then
    : "t:0:${LINENO}" #>
    printf 'Good signature from Finnix\n'

    # Optional
    output_9_sed=$( printf '%s' "${output_1_gpg}" \
      | grep 'Primary key fingerprint: ' \
      | sed 's,^Primary key fingerprint: ,,'
    )
    printf 'PGP Fingerprint: %s\n' "${output_9_sed}"
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" "Data not found"
  fi
else
  : "f:$?:${LINENO}" #>
fi
:
  #set -x
  :;:;:
  : "output_5_gpg:        ${output_5_gpg}"
  : "output_6_gpg:        ${output_6_gpg}"
  : "output_1_gpg:        ${output_1_gpg}"
  : "output_8_awk:        ${output_8_awk}"
  : "output_9_sed:        ${output_9_sed}"
  #set +x
  #exit "${LINENO}" #>
  #set -x
  :
  :
# Verify the checksums listed in the the JSON file
for HH in md5 sha256 sha512
do
  unset value
  jq '.finnix .releases ."'"${maj_vers}"'" .architectures .amd64
      .files ."finnix-251.iso" .checksums .'"${HH}" \
      ./"${maj_vers}.json" \
    | tee "${hash_ff}" >/dev/null
  sleep .1

  value=$( command "${HH}sum" -- "${iso_abspth}" \
    | awk '{ print $1 }'
  )
  if grep -qe "${value}" "${hash_ff}"
  then
    : "t:0:${LINENO}" #>
    printf '%s hash sum verified\n' "${HH}"
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" "Data not found"
  fi
done
unset HH
  :;:;:
  #set -x
  : ": value: ${value}"
  #exit "${LINENO}" #>
  #set -x


# Verify the cryptographic signatures listed in the JSON file

# GPG data
local_pgp_ff=${gpg_abspth}2

  #exit "${LINENO}" #>

pgp_sig=$( jq '.finnix .releases ."'"${maj_vers}"'" .architectures .amd64 .files ."finnix-'"${maj_vers}"'.iso" .signatures[] | select(.type == "openpgp") | .signature' "${jsn_abspth}"
)
pgp_sig=${pgp_sig#'"'}
pgp_sig=${pgp_sig%'"'}

if [ -n "${pgp_sig}" ]
then
  : "t:0:${LINENO}" #>

  # Write secondary gpg signature to disk
  printf '%b\n' "${pgp_sig}" \
    | tee "${local_pgp_ff}" >/dev/null

  # Verify the two GPG files are identical
  if diff "${gpg_abspth}" "${local_pgp_ff}"
  then
    : "t:0:${LINENO}" #>
    printf 'Secondary GPG data: verified\n'
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" "Data does not match"
  fi
else
  : "f:$?:${LINENO}" #>
  __error_exit__ "${LINENO}" "Data not found"
fi

  # Bug, remove the secondary file from disk, \local_pgp_ff\; 
  #   Also \hash_ff\ and \local_ssh_ff\.

  # Bug, hardcoded file.

local_ssh_ff=finnix-251.iso.sig
ssh_sig=$( jq '.finnix .releases ."251" .architectures .amd64 .files
  ."finnix-251.iso" .signatures[]
  | select(.type == "ssh")
  | .signature' "${jsn_abspth}"
)
ssh_sig=${ssh_sig#'"'}
ssh_sig=${ssh_sig%'"'}

if [ -n "${ssh_sig}" ]
then
  : "t:0:${LINENO}" #>
  printf '%b' "${ssh_sig}" \
    | tee "${local_ssh_ff}" >/dev/null

  # Data from Github wiki page
  printf '%s %s %s %s\n' "${ssh_eml}" 'ssh-ed25519' "${ssh_key}" \
    'Finnix file-signing' \
    | tee ./authorized_signers >/dev/null

  if ssh-keygen -Y verify -f ./authorized_signers -I "${ssh_eml}" \
    -n file -s ./"finnix-${maj_vers}.iso.sig" \
    < ./"finnix-${maj_vers}.iso"
  then
    : "t:0:${LINENO}" #>
    printf 'SSH signature verified\n'
  else
    : "f:$?:${LINENO}" #>
    __error_exit__ "${LINENO}" 'SSH signature verification failed.\n'
  fi
else
  : "f:$?:${LINENO}" #>
  __error_exit__ "${LINENO}" "Data not found"
fi

# Done
printf 'Script is exiting normally.\n'
exit 00

