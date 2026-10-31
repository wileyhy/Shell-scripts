#!/bin/sh
# candr.sh / canonicalize-dir.sh
#  hellcheck disable=SC2319,SC2292
#
#   Script is unfinished - 29 Oct 2026 WY
#
#
#   Manual canonicalization of directories. Output can be in brief or
# verbose formats; brief is default. Script accepts multiple operands.
#
#   Written for any POSIX-2008 compliant shell. This script can be
# executed successfully in resticted mode.
#   (c) Wiley Young 2026
#
#   Both \realpath\ and \readlink\ weren\t specified in POSIX until
# 2024, so it\s likely that there are numerous systems which do not
# offer any utilities which canonicalize file paths.
#
# Tested:
#
# Test strings:
#   /dev/qwertyuiop
#
# Note, you can\t put redirection operators in parameter expansions.



  #> Debug
  reset; clear #>
  set -x #>
  set -e #>
  set -u #>
  : #>
  : "pound: $#" #>
  : "ampersand:" "${@:-}" #>
  : "\$0: <$0>, <${0#./}> "
  : "\$1: ${1:-}" #>
  : "\$2: ${2:-}" #>
  :
  :


: "List of commands"
command -v \
  ":" \
  "awk" \
  "break" \
  "cd" \
  "clear" \
  "command" \
  "continue" \
  "dirname" \
  "echo" \
  "exit" \
  "file" \
  "find" \
  "getconf" \
  "grep" \
  "pathchk" \
  "pwd" \
  "printf" \
  "reset" \
  "sed" \
  "set" \
  "sh" \
  "shift" \
  "test" \
  "true" \
  "unalias"


# Use \unalias\, as POSIX suggests. On older systems, who knows?
unalias -a


# Use \strings\
for aA
do
  bB=$( printf '%s' "${aA}" | strings -n 1 )
  if test "${aA}" = "${bB}"
  then
    : "t:0"
  else
    : "f:$?"
    printf 'Input contains a non-printable string(s); exiting.\n'
    exit 1
  fi
done


: "Environment Variables"
# Use \getconf\.
# See man pages under POSIX 2008


: "Script Variables"
global_return_code=0
output_verbose_on=
nsfod="(No such file or directory)"
usage_msg="Usage: the first argument may be an option flag.
    candr.sh [-b|-v] [FILE] ..."
:
  #set -x #>
  #echo stdout #>
  #echo stderr 1>&2 #>
:
:
: "Input required."
if test "$#" -eq 0
then
  : "t:0:${LINENO}" #>
  # Print the \usage_msg\ to STDERR and \exit\ with return code 1.
  printf '%s\n' "${usage_msg:?}" 1>&2
  exit 1
else : "f:$?:${LINENO}" #>
fi
:
:
: "Determine per-run printing format."
:
: "\\case\\ on posparm 1."
case "$1" in
  -v | --verbose )
    : "\\case\\ branch: \\--verbose\\."
    output_verbose_on=yes
    shift
    ;;
  -b | --brief )
    : "\\case\\ branch: \\--brief\\."
    output_verbose_on=no
    shift
    ;;
  * )
    : "\\case\\ branch: no options: use default: \\--brief\\."
    output_verbose_on=no
    # No \shift\ command.
    ;;
esac
:
:

# Pseudocode re function __print_output__
#
# GL-scriptnm = defined
# GL-printformat=[-b|-v]          (per execution)
# GL-rtncde=0                     (per execution)
#
# GL-majloop-input-1 = defined    (per line)
#
#   GL-minloop-canpth = [exists/dne]
#
#     exists  .'. GL-minloop-STDo/e = STDOUT
#             .'. GL-rtncode = no change
#
#       _print_output_
#
#           verbose
#             echo GL-scriptnm: GL-majloop-input: [GL-minloop-canpth GL-minloop-STDo/e]
#
#           brief
#             echo                                [GL-minloop-canpth GL-minloop-STDo/e]
#
#
#     dne     .'. GL-minloop-STDo/e = STDERR
#             .'. GL-rtncode = 1
#
#       _print_output_
#
#         GL-printformat
#           verbose
#             echo GL-scriptnm: GL-majloop-input: [GL-minloop-NSFOD GL-minloop-STDo/e]
#
#           brief
#             echo                                [GL-minloop-NSFOD GL-minloop-STDo/e]
#
#
# exit GL-rtncode


: "Define function: __print_output__."
#
# Usage:    __print_output__ [Script input] [canpth|nsfod] [redirection]
# Usage:    __print_output__ "${dD}" "${canpth}"      # normal output to STOUT
# Usage:    __print_output__ "${dD}" "${nsfod}" >&2   # redirect output to STDOUT
#
__print_output__()
{
    #set -x #>
    : #>
    : "pound: $#" #>
    : "ampersand:" "$@" #>
    : "\$1: $1"
    : "\$global_return_code: ${global_return_code}" #>
    : "\$output_verbose_on: ${output_verbose_on}" #>
    #exit "${LINENO}" #>
    : #>
    : #>

  : "\\case\\ on \\output_verbose_on\\."
  case "${output_verbose_on}" in
    yes )
      : "Case branch: \\yes\\."
      printf '%s: %b%s%b -> %s\n' "${0#./}" "\x27" "$1" "\x27" "$2"
      ;;
    no )
      : "Case branch: \\no\\."
      printf '%s\n' "$2"
      ;;
    * ) echo "Unreachable code."; exit "${LINENO}";; #>
  esac

    #exit "${LINENO}" #>
}
:
  #exit "${LINENO}" #>
  set -x #>
  :
  :
: "Major loop"
# Note, for testing purposes, a list of some of the common temporary
# directories in use in Linux.


for dD
  #/dev/shm /var/tmp /usr/tmp /usr/local/tmp "${XDG_RUNTIME_DIR:=}/tmp" /tmp ~/tmp ~ #>
do
  :
  : "Per major loop variables."
  posparm_original_string=${dD}
  :
  :
  : "The given path must exist in the filesystem."
  if test -e "${dD}"
  then
    : "t:0:${LINENO}" #>
    : "Path exists."
  else
    : "f:$?:${LINENO}" #>
    global_return_code=1
    __print_output__ "${dD}" "${nsfod}" >&2
    continue 1
  fi

    #exit "${LINENO}" #>
    set -x #>


  # Use \pathchk\.


  :
  : "Minor loop A: Use \\file\\ to resolve any symlinks."
  while true
  do
    # String matching; the possibilities are endless, ie, not good.

    # Case if input is \/\, single forward slash, FS root.
    if test "${dD}" = '/' \
      || test "${dD}" = '//' \
      || test "${dD}" = '///'
    then
      : "t:0:${LINENO}" #>
      canpth=/
      __print_output__ "$1" "${canpth}"
      : exit "\${global_return_code}"
      exit "${global_return_code}"
    else
      : "f:$?:${LINENO}" #>
    fi

    #   Case if input is \.\, single period, CWD.
    #   Case if input begins with \./\, anchoring file in CWD.
    if test "${dD}" = '.' \
      || test "${dD}" = './' \
      || test "${dD}" = './/'
    then
      : "t:0:${LINENO}" #>
      canpth=$( pwd )
      __print_output__ "$1" "${canpth}"
      : exit "\${global_return_code}"
      exit "${global_return_code}"
    else
      : "f:$?:${LINENO}" #>
    fi

    for zZ in '/' '//' '.' './' '..' '../'
    do
      __test_for_string__ "${zZ}"
    done

      exit "${LINENO}" #>
      set -x #>

    #   Case if input is \..\, double period, aka, \dirname\.
    #   Case if input begins with \../, anchoring file in \dirname\.
    #   Case if ....

    :
    : "Get output of \\file\\."
    output_0_file=$( file "${dD}" )

      exit "${LINENO}" #>
      set -x #>


    : "Remove trailing forward slashes if doing so won\\t empty the var."
    # Note, defining directories with a trailing f\orward slash will
    #   effect whether \[[\, \test\, \[\ and \stat\ dereference
    #   symlinks. However, \realpath -e\ will still resolve such
    #   strings correctly.



    :
    : "See whether \\file\\ says \\symbolic link\\."
    if printf '%s' "${output_0_file}" \
      | grep -qEe ': symbolic link to [/\.a-z]'
    then
      : "t:0:${LINENO}" #>

      :
      : "If so, then use \\sed\\ to get the resolved path."
      output_1_sed=$(
        printf '%s' "${output_0_file}" \
          | sed 's,.*: symbolic link to ,,'
        )

      :
      : "...and redefine \\dD\\ for the next iteration."
      dD=${output_1_sed}
    else
      : "f:$?:${LINENO}" #>

      :
      : "...otherwise, test if \\directory\\ is present in the string."
      if printf '%s' "${output_0_file}" \
        | sed 's,.*: ,,' \
        | grep -q "directory"
      then
        : "t:0:${LINENO}" #>

        :
        : "If it is, then \\break\\ this loop."
        break 1
      else
        : "f:$?:${LINENO}" #>

        :
        : "If it\\s neither a symlink nor a directory, that\\s an error."
        echo Error 1>&2
        exit "${LINENO}"
      fi
    fi
  done

    exit "${LINENO}" #>
    set -x #>

  :
  : "Record what aught to be the correct, canonicalized absolute path."
  canpth=${dD}

  # Note, it\s something of an assumption at this time that \file\ will
  #   remove any symlinks from the interior of the absolute pathname --
  #   hence minor loop B.

  :
  : "Define a variable \\eE\\ that can be re-defined within a loop."
  eE=${canpth}

    exit "${LINENO}" #>
    set -x #>

  :
  : "Minor loop B: Make sure every dir. in the abs. path is not a sym."
  while true
  do
    :
    : "If \\eE\\ is a directory..."
    if test -d "${eE}"
    then
      : "t:0:${LINENO}" #>

      :
      : "Then get the \\dirname\\ of \\eE\\."
      eE=$( dirname "${eE}" )

      :
      : "If the \\dirname\\ of \\eE\\ is also a directory..."
      if test -d "${eE}"
      then
        : "t:0:${LINENO}" #>

        :
        : "Then, if the new \\eE\\ is the filesystem root, \\/\\..."
        if test "${eE}" = "/"
        then
          : "t:0:${LINENO}" #>

          :
          : "Then double-check it using \\grep\\."
          if printf '%s\n' "${eE}" \
            | grep -qEe '^/$'
          then
            : "t:0:${LINENO}" #>
            :
            : "\\grep\\ succeeded, so \\break\\ this loop."
            __print_output__
            break 1
          else
            : "f:$?:${LINENO}" #>

            :
            : "\\test\\ passed but \\grep\\ failed. Error. Exiting."
            exit "${LINENO}"
          fi
        else
          : "f:$?:${LINENO}" #>

          :
          : "The new \\eE\\ is not the FS root directory; next iteration."
          continue 1
        fi
      else
        : "f:$?:${LINENO}" #>

        :
        : "The \\dirname\\ of \\eE\\ is not a directory."
        exit "${LINENO}"
      fi
    else
      : "f:$?:${LINENO}" #>

      :
      : "Error: \\eE\\ is not a directory. Exiting."
      exit "${LINENO}"
    fi
  done
done

  exit "${LINENO}" #>
  set -x #>


:
  : "Print warnings if the directory is not readable\/writable\/searchable."

:
  : "Verify it\\s a directory by using \\find\\."
output_2_find=$( find "${canpth}" -prune -type d )

    exit "${LINENO}" #>
    set -x #>

if test -n "${output_2_find}"
then
  : "t:0:${LINENO}" #>

  :
  : "See whether \\canpth\\ and \\output_2_find\\ are equivalent strings."
  if test "${canpth}" = "${output_2_find}"
  then
    : "t:0:${LINENO}" #>

    :
    : "See whether \\canpth\\ is a symlink."
    if test ! -L "${canpth}"
    then
      : "t:0:${LINENO}" #>
      :
      : "\\canpth\\ is not a symlink"

      # Tests in serial:

        exit "${LINENO}" #>
        set -x #>

      :
      : "See whether \\canpth\\ is searchable."
      if test -x "${canpth}"
      then
        : "t:0:${LINENO}" #>
        :
        : "\\canpth\\ is searchable."

      else
        : "f:$?:${LINENO}" #>
        :
        : "\\canpth\\ is not searchable."

        printf 'Warning: directory is not searchable.\n' 1>&2
      fi

        exit "${LINENO}" #>
        set -x #>

      :
      : "See whether \\canpth\\ is readable."
      if test -r "${canpth}"
      then
        : "t:0:${LINENO}" #>
        :
        : "\\canpth\\ is readable."

      else
        : "f:$?:${LINENO}" #>
        :
        : "\\canpth\\ is not readable."

        printf 'Warning: directory is not readable.\n' 1>&2
      fi

        exit "${LINENO}" #>
        set -x #>

      :
      : "See whether \\canpth\\ is writable."
      if test -w "${canpth}"
      then
        : "t:0:${LINENO}" #>
        :
        : "\\canpth\\ is writable."
      else
        : "f:$?:${LINENO}" #>
        :
        : "\\canpth\\ is not writable."

        printf 'Warning: directory is not writable.\n' 1>&2
      fi
        exit "${LINENO}" #>
        set -x #>

    else
      : "f:$?:${LINENO}" #>
      :
      : "\\canpth\\ is a symlink."
      echo Error 1>&2
      exit "${LINENO}"
    fi
  else
    : "f:$?:${LINENO}" #>
    :
    : "\\canpth\\ and \\output_2_find\\ are not equivalent strings."
    echo Error 1>&2
    exit "${LINENO}"
  fi
else
  : "f:$?:${LINENO}" #>
  :
  : "\\find -type d\\ did not locate the directory."
  echo Error 1>&2
  exit "${LINENO}"
fi

    exit "${LINENO}" #>
    set -x #>

exit 00
