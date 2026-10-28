#!/bin/sh
# benchmark-hashing-programs.sh
# shellcheck disable=SC2292
#
#   Script is finished - 28 Oct 2026 WY
#
# (c) 2025 Wiley Young, MIT license
#
# Compare hash speeds at nanoseconds per byte, averaged over
# some thousands of iterations.
#
# This script is intended to be run on bash, POSIX sh, ksh, dash and
# busybox sh.
#
#
# List of tested distros and shells:
#   Fedora 44
#     bash-5.3.9-3.fc44.x86_64
#     busybox-1.37.0-7.fc44.x86_64
#     dash-0.5.13.1-3.fc44.x86_64
#     ksh-1.0.10-8.fc44.x86_64
#     mksh-59c-15.fc44.x86_64
#     oksh-7.9-1.fc44.x86_64
#     yash-2.61-1.fc44.x86_64
#     zsh-5.9-21.fc44.x86_64
#
#
# HASH PROGRAMS   # DIGEST-LENGTH
#   sum           #   5 c
#   cksum         #   9 c
#   md5sum        #   32 c
#   sha1sum       #   40 c
#   sha224sum     #   56 c
#   sha256sum     #   64 c
#   sha384sum     #   96 c
#   b2sum         #   128 c
#   sha512sum     #   128 c


  #> Debugging
  #set -x #>
  set -e #>
  set -u #>
  set -C #>
  :
  :
# Iterations
iterations=1000
export iterations
:
:
:
set -- \
  sum cksum md5sum sha1sum sha224sum sha256sum sha384sum b2sum \
    sha512sum
:
  #> Debugging
  #:;:;: #>
  #exit "${LINENO}" #>
  #reset #>
  #set -x #>
  :
  :
# Test file
zero_ff=/tmp/block-file.zero
file_sz=4096
:
if [ -f "${zero_ff}" ]
then
  : "t:0:${LINENO}" #>
  :
  # If the test file already exists then remove it.
  if rm -f -- "${zero_ff}"
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    printf '\rm\ failed; exiting.\n'
    exit "${LINENO}"
  fi
else
  : "f:$?:${LINENO}" #>
fi
:
# (Re-)write the test file.
if dd if=/dev/zero of="${zero_ff}" bs="${file_sz}" count=1 2>/dev/null
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"
  printf '\dd\ failed; exiting.\n'
  exit "${LINENO}"
fi
:
:
# Initial output
printf '# Hashing %d bytes for %d iterations\n' "${file_sz}" "${iterations}"
:
  #exit "${LINENO}"
  #set -x #>
  :
  :
# Test each hash binary
for hH
do
  # Gather info
  out_cmd=$(
    command -v "${hH}"
  )
  out_rlpth=$(
    realpath -e "${out_cmd}"
  )
  # Note, sed RE tested against output of \rpm -qa\ on Fedora 44.
  orig_rpm=$(
    rpm -qf "${out_rlpth}" \
      | sed 's,-[0-9]\+\..*.\(x86_64\|noarch\),,g'
  )
  :
  # Binary file must exist, and must have executable bit enabled.
  if [ -n "${out_rlpth}" ] \
    && [ -x "${out_rlpth}" ]
  then
    hH=${out_rlpth}
    export hH
    :
    # Print a section header
    printf '#\t%-16s\t%s\n' "${out_rlpth}" "${orig_rpm}"
  else
    printf '#\t\tExecutable file not found: %s\n' "${hH}"
    continue
  fi
  :
  # Turn off xtrace
  [ "${-//[a-wyzA-Z0-9]}" = x ] && set +x
  :
  # (Re)set index variable
  iI=0
  export iI
  {
    # Notes,
    #   - Why is xtrace turned off? Because otherwise it skews the
    #   results, ie, the value of \tT\.
    #   - Why is \iI\ defined and exported outside of the \sh -c\
    #   command? nounset of a dynamic counter variable?
    tT=$(
      { time -p sh -c '
          while [ "${iI}" -le "${iterations}" ]
          do
            command -p "$1" "$2" >/dev/null 2>&1
            iI=$( expr "${iI}" + 1 )
          done 2>&1 \
            | tail -n 3' sh "${hH}" "${zero_ff}"
      } 2>&1
    )
  }

    #> Debugging
    #set -x
    #echo "tT: $tT" #>
    #exit "${LINENO}" #>
    #set -x #>


  real=$(
    printf '%s' "${tT}" \
      | awk '/real/ { print $2 }'
    )
  user=$(
    printf '%s' "${tT}" \
      | awk '/user/ { print $2 }'
    )
  sys=$(
    printf '%s' "${tT}" \
      | awk '/sys/  { print $2 }'
    )

    #> Debugging
    #echo "real: ${real}" #>
    #echo "user: ${user}" #>
    #echo "sys: ${sys}" #>
    #exit "${LINENO}" #>

  # Use \bc\ for floating point arithmetic. Note, \bc\ requires a
  # trailing newline.
  bc_scl=24
  elapsed_tt=${real}
  seconds=$(
    printf 'scale=%d; %s / %s\n' "${bc_scl}" "${elapsed_tt}" \
        "${iterations}" \
      | bc -s --
  )
  secs_per_byte=$(
    printf 'scale=%d; %s / %s\n' "${bc_scl}" "${seconds}" \
        "${file_sz}" \
      | bc -s --
  )
  nano_per_byte=$(
    printf 'scale=%d; %s * ( 10 ^ 9 )\n' "${bc_scl}" \
        "${secs_per_byte}" \
      | bc -s --
  )
  nano_per_byte=$( printf '%s' "${nano_per_byte}" \
    | sed -e 's,0*$,,'
  )

    #> Debugging
    #echo "elapsed_tt: ${elapsed_tt}" #>
    #echo "seconds: ${seconds}" #>
    #echo "secs_per_byte: ${secs_per_byte}" #>
    #echo "nano_per_byte: ${nano_per_byte}" #>
    #exit "${LINENO}" #>

  printf '#\t\t%-20s\telapsed time\n' "${elapsed_tt}"
  #printf '#\t\t%s seconds\n' "${seconds}" #>
  #printf '#\t\t%s seconds per byte\n' "${secs_per_byte}" #>
  #printf '#\t\t-------^^^^---\n' #>
  printf '#\t\t%-20s\tnano-seconds per byte\n' "${nano_per_byte}"
done


# Clean up
if rm -f -- "${zero_ff}"
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"
  printf '\rm\ failed; exiting.\n'
  exit "${LINENO}"
fi


# Done
printf 'Script exited normally\n' #>
exit 00

