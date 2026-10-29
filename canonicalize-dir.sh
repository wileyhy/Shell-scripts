#!/bin/bash
# candr.sh / canonicalize-dir.sh
#  hellcheck disable=SC2319,SC2292
#
#   Script is unfinished - 29 Oct 2026 WY
#
#   Manual canonicalization of directories. Output can be in brief or
# verbose formats; brief is default. Script accepts multiple operands.
#
#   Written for any POSIX-2008 compliant shell. This script can be
# executed successfully in resticted mode. With a few adjustments,
# a list of directories can be canonicalized in the same execution.
#   (c) Wiley Young 2026
#
# Tested:
#
# Test strings:
#   /dev/qwertyuiop
#
# Note, you can\t put redirection operators in parameter expansions.

  #> Debug
  reset #>
  clear #>
  #set -x #>
  set -e #>
  set -u #>
  : #>
  : "pound: $#" #>
  : "ampersand:" "${@:-}" #>
  : "\$1: ${1:-}" #>
  : "\$2: ${2:-}" #>
  :
  :


: "Variables"
global_return_code=0
posparm_canpth_exists=
posparm_tty_output=
script_nm=candr.sh
setting_verbose_on=
string_header="${script_nm}:"
string_nsfod="(No such file or directory)"
# ^Note, String copied from STDERR of \file\.
usage_msg="Usage:
    candr.sh [-b|-v] [FILE] ..."
:
  #set -x #>
  #echo stdout #>
  #echo stderr 1>&2 #>
:
:
: "Input required."
if [ "$#" -eq 0 ]
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
    setting_verbose_on=yes
    shift
    ;;
  -b | --brief )
    : "\\case\\ branch: \\--brief\\."
    setting_verbose_on=no
    shift
    ;;
  * )
    : "\\case\\ branch: no UNIX or GNU options: \\--brief\\."
    setting_verbose_on=no
    # No \shift\ command.
    ;;
esac
:
:

# Pseudocode
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
#

: "Define function: __print_output__."
__print_output__()
{
    #set -x #>
    : #>
    : "pound: $#" #>
    : "ampersand:" "$@" #>
    : "\$1: $1" #>
    : "\$2: $2" #>
    : "\$global_return_code: $global_return_code" #>
    : "\$posparm_canpth_exists: $posparm_canpth_exists" #>
    : "\$setting_verbose_on: $setting_verbose_on" #>
    : "\$posparm_tty_output: $posparm_tty_output" #>
    #exit "${LINENO}" #>
    : #>
    : #>

  : "\\case\\ on \\setting_verbose_on\\."
  case "${setting_verbose_on}" in
    no )
      : "Case branch: \\no\\."

      if [ "$2" = "${string_nsfod}" ]
      then
        : "t:0:${LINENO}"
      printf '%s\n' "$2"
      else
        : "f:$?:${LINENO}"
      fi


    ;;
    yes )
      : "Case branch: \\yes\\."
      printf '%s: %b%s%b -> %s\n' "${script_nm}" "\x27" "$1" "\x27" "$2"
    ;;
    * ) echo "Unreachable code."; exit "${LINENO}";; #>
  esac

    exit "${LINENO}" #>
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
  posparm_canpth_exists=unknown
  posparm_original_string=${dD}
  :
  :
  : "The given path must exist in the filesystem."
  if [ -e "${dD}" ]
  then
    : "t:0:${LINENO}" #>
    : "Path exists."
  else
    : "f:$?:${LINENO}" #>
    :
    : "Path does not exist on this system."
    global_return_code=1
    posparm_canpth_exists=no
    posparm_tty_output=stderr
    :
    __print_output__
    continue 1
  fi

    #exit "${LINENO}" #>
    set -x #>


  :
  : "Minor loop A: Use \\file\\ to resolve any symlinks."
  while true
  do
    # Note, these data manipulations must be within minor loop A.

    :
    # Case if input is \/\, single forward slash, FS root.
    #
    # Case if input is \.\, single period, CWD.
    #
    # Case if input begins with \./\, anchoring file in CWD.
    #
    # Case if input is \..\, double period, aka, \dirname\.
    #
    # Case if input begins with \../, anchoring file in \dirname\.


    : "Remove trailing forward slashes if doing so won\\t empty the var."
    if [ "${#dD}" -gt 1 ]
    then
      : "t:0:${LINENO}" #>

      # Note, if the directory is \/\, FS root, then PE\s an error.
      dD=${dD%/}
    else
      : "f:$?:${LINENO}" #>
    fi

      exit "${LINENO}" #>
      set -x #>

    :
    #: "Remove leading double dots."
    #dD=${dD#..}

    # Remove leading double dots if doing so won\t empty the variable.
    if [ "${#dD}" -gt 3 ]
    then
      : "t:0:${LINENO}" #>
      dD=${dD#..}
    else
      : "f:$?:${LINENO}" #>
    fi

      exit "${LINENO}" #>
      set -x #>

    :
    : "Add in a missing leading forward slash, if output\\s a dir."
    if [ -d "${dD}" ]
    then
      : "t:0:${LINENO}" #>
      : "\\dD\\ is a directory."
    else
      : "f:$?:${LINENO}" #>
      : "\\dD\\ is not a directory."

      if [ -d "/${dD}" ]
      then
        : "t:0:${LINENO}" #>
        : "Adding a leading forward slash makes \\dD\\ a directory."
        dD=/${dD}
      else
        : "f:$?:${LINENO}" #>
        : "Adding a leading fwd. slash doesn\\t make \\dD\\ a directory."
      fi
    fi

    :
    : "Get output of \\file\\."
    output_0_file=$( file "${dD}" )

      exit "${LINENO}" #>
      set -x #>

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
    if [ -d "${eE}" ]
    then
      : "t:0:${LINENO}" #>

      :
      : "Then get the \\dirname\\ of \\eE\\."
      eE=$( dirname "${eE}" )

      :
      : "If the \\dirname\\ of \\eE\\ is also a directory..."
      if [ -d "${eE}" ]
      then
        : "t:0:${LINENO}" #>

        :
        : "Then, if the new \\eE\\ is the filesystem root, \\/\\..."
        if [ "${eE}" = "/" ]
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
  :"Print warnings if the directory is not readable\/writable\/searchable."

:
  :"Verify it\\s a directory by using \\find\\."
output_2_find=$( find "${canpth}" -prune -type d )

    exit "${LINENO}" #>
    set -x #>

if [ -n "${output_2_find}" ]
then
  : "t:0:${LINENO}" #>

  :
  : "See whether \\canpth\\ and \\output_2_find\\ are equivalent strings."
  if [ "${canpth}" = "${output_2_find}" ]
  then
    : "t:0:${LINENO}" #>

    :
    : "See whether \\canpth\\ is a symlink."
    if [ ! -L "${canpth}" ]
    then
      : "t:0:${LINENO}" #>
      :
      : "\\canpth\\ is not a symlink"

      # Tests in serial:

        exit "${LINENO}" #>
        set -x #>

      :
      : "See whether \\canpth\\ is searchable."
      if [ -x "${canpth}" ]
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
      if [ -r "${canpth}" ]
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
      if [ -w "${canpth}" ]
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

