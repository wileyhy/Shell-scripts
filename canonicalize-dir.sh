#!/bin/bash
# candr.sh / canonicalize-dir.sh
# shellcheck disable=SC2319,SC2292
#
# Manual canonicalization of directories.
#
# Written for any POSIX-2008 compliant shell. This script can be
# executed successfully in resticted mode. With a few adjustments,
# a list of directories can be canonicalized in the same execution.
#
# (c) Wiley Young 2026
#
# Tested:
#   2026-06-11; Fedora 44; sh(bash), bash 5.3.9, dash 0.5.13, ksh 1.0.10,
#       mksh 59c, oksh 7.8.2, yash 2.61, zsh 5.9, and busybox(ash) 1.37.0

#<> Debug
reset #<>
clear #<>
set -e #<>
set -u #<>
#set -x #<>


# Some input required
if [ "$#" -eq 0 ]
then
  : "t:0:${LINENO}" #<>

  printf 'Input required; exiting.\n' 1>&2
  exit "${LINENO}"
else : "f:$?:${LINENO}" #<>
fi

#
_print_findings_()
{
  case "$1" in
    -v|--verbose )
      printf 'Input:\t\t\t%s\n' "$2"
      printf '  Canonicalized path:'
      if [ "$2" = "$3" ]
      then
        : "t:0:${LINENO}" #<>
        true
      else
        : "f:$?:${LINENO}" #<>
        printf '*'
      fi
      printf '\t%s\n' "$3"

      # Note, to check just one directory, uncomment this \exit\ command;
      #   to check all directories, comment it.
      exit "${LINENO}"
    ;;
    -b|--brief )
      printf '%s\n' "$3"
    ;;
    *)
      printf 'Error; exiting: %s.\n' "${2}" 1>&2
      exit "${LINENO}"
    ;;
  esac
}


:;: "Major loop"
# Note, a list of some of the common temporary directories in use in Linux.

for dd in "$@" /dev/shm /var/tmp /usr/tmp /usr/local/tmp \
  "${XDG_RUNTIME_DIR:=}/tmp" /tmp ~/tmp  ~
do
  :;: "Get the original string."
  cc=${dd}

  :;: "The path must exist in the filesystem."
  if [ -e "${dd}" ]
  then
    : "t:0:${LINENO}" #<>
    true
  else
    : "f:$?:${LINENO}" #<>

    :;: "The path does not exist on this system. Next pathname."
    _print_findings_ -v "${cc}" \
      "NA: Input pathname does not exist on this filesystem."
    continue 1
  fi

  :;: "Minor loop A: Use \\file\\ to resolve any symlinks."
  while true
  do
    # Note, these data manipulations must be within minor loop A.

    :;: "Remove trailing forward slashes if doing so won\\t empty the var."
    if [ "${#dd}" -gt 1 ]
    then
      : "t:0:${LINENO}" #<>
      # Note, if the directory is \/\, FS root, then PE\s an error.
      dd=${dd%/}
    else
      : "f:$?:${LINENO}" #<>
    fi

    :;: "Remove leading double dots."
    dd=${dd#..}

      # Remove leading double dots if doing so won\t empty the variable.
      #if [ "${#dd}" -gt 3 ]
      #then
        #: "t:0:${LINENO}" #<>
        #dd=${dd#..}
      #else
        #: "f:$?:${LINENO}" #<>
      #fi

    :;: "Add in a missing leading forward slash, if output\\s a dir."
    if [ -d "${dd}" ]
    then
      : "t:0:${LINENO}" #<>
      : "\\dd\\ is a directory."
    else
      : "f:$?:${LINENO}" #<>
      : "\\dd\\ is not a directory."

      if [ -d "/${dd}" ]
      then
        : "t:0:${LINENO}" #<>
        : "Adding a leading forward slash makes \\dd\\ a directory."
        dd=/${dd}
      else
        : "f:$?:${LINENO}" #<>
        : "Adding a leading fwd. slash doesn\\t make \\dd\\ a directory."
      fi
    fi

    :;: "Get output of \\file\\."
    file_out_0=$( file "${dd}" )

    :;: "See whether \\file\\ says \\symbolic link\\."
    if printf '%s' "${file_out_0}" \
      | grep -qEe ': symbolic link to [/\.a-z]'
    then
      : "t:0:${LINENO}" #<>

      :;: "If so, then use \\sed\\ to get the resolved path."
      sed_out_0=$(
        printf '%s' "${file_out_0}" \
          | sed 's,.*: symbolic link to ,,'
        )

      :;: "...and redefine \\dd\\ for the next iteration."
      dd=${sed_out_0}
    else
      : "f:$?:${LINENO}" #<>

      :;: "...otherwise, test if \\directory\\ is present in the string."
      if printf '%s' "${file_out_0}" \
        | sed 's,.*: ,,' \
        | grep -q "directory"
      then
        : "t:0:${LINENO}" #<>

        :;: "If it is, then \\break\\ this loop."
        break 1
      else
        : "f:$?:${LINENO}" #<>

        :;: "If it\\s neither a symlink nor a directory, that\\s an error."
        echo Error 1>&2
        exit "${LINENO}"
      fi
    fi
  done

  :;: "Record what aught to be the correct, canonicalized absolute path."
  canpth=${dd}

  # Note, it\s something of an assumption at this time that \file\ will
  #   remove any symlinks from the interior of the absolute pathname --
  #   hence minor loop B.

  :;: "Define a variable \\ee\\ that can be re-defined within a loop."
  ee=${canpth}

  :;: "Minor loop B: Make sure every dir. in the abs. path is not a sym."
  while true
  do
    :;: "If \\ee\\ is a directory..."
    if [ -d "${ee}" ]
    then
      : "t:0:${LINENO}" #<>

      :;: "Then get the \\dirname\\ of \\ee\\."
      ee=$( dirname "${ee}" )

      :;: "If the \\dirname\\ of \\ee\\ is also a directory..."
      if [ -d "${ee}" ]
      then
        : "t:0:${LINENO}" #<>

        :;: "Then, if the new \\ee\\ is the filesystem root, \\/\\..."
        if [ "${ee}" = "/" ]
        then
          : "t:0:${LINENO}" #<>

          :;: "Then double-check it using \\grep\\."
          if printf '%s\n' "${ee}" \
            | grep -qEe '^/$'
          then
            : "t:0:${LINENO}" #<>

            # Note, to check all directories, uncomment this block and
            #   comment the other.

            #:;: "\\grep\\ succeeded, so \\break\\ this loop."
            #_print_findings_ -b "${cc}" "${canpth}"
            #break 1

            # Note, to check just one directory, uncomment this block and
            #   comment the other.

            :;: " \\grep\\ succeeded, so \\break\\ all loops."
            _print_findings_ -b "${cc}" "${canpth}"
            break 2
          else
            : "f:$?:${LINENO}" #<>

            :;: "\\test\\ passed but \\grep\\ failed. Error. Exiting."
            exit "${LINENO}"
          fi
        else
          : "f:$?:${LINENO}" #<>

          :;: "The new \\ee\\ is not the FS root directory; next iteration."
          continue 1
        fi
      else
        : "f:$?:${LINENO}" #<>

        :;: "The \\dirname\\ of \\ee\\ is not a directory."
        exit "${LINENO}"
      fi
    else
      : "f:$?:${LINENO}" #<>

      :;: "Error: \\ee\\ is not a directory. Exiting."
      exit "${LINENO}"
    fi
  done
done


:;: "Print warnings if the directory is not readable\/writable\/searchable."

:;: "Verify it\\s a directory by using \\find\\."
find_out=$( find "${canpth}" -prune -type d )
if [ -n "${find_out}" ]
then
  : "t:0:${LINENO}" #<>

  :;: "See whether \\canpth\\ and \\find_out\\ are equivalent strings."
  if [ "${canpth}" = "${find_out}" ]
  then
    : "t:0:${LINENO}" #<>

    :;: "See whether \\canpth\\ is a symlink."
    if [ ! -L "${canpth}" ]
    then
      : "t:0:${LINENO}" #<>
      :;: "\\canpth\\ is not a symlink"

      # Tests in serial:

      :;: "See whether \\canpth\\ is searchable."
      if [ -x "${canpth}" ]
      then
        : "t:0:${LINENO}" #<>
        :;: "\\canpth\\ is searchable."

      else
        : "f:$?:${LINENO}" #<>
        :;: "\\canpth\\ is not searchable."

        printf 'Warning: directory is not searchable.\n' 1>&2
      fi

      :;: "See whether \\canpth\\ is readable."
      if [ -r "${canpth}" ]
      then
        : "t:0:${LINENO}" #<>
        :;: "\\canpth\\ is readable."

      else
        : "f:$?:${LINENO}" #<>
        :;: "\\canpth\\ is not readable."

        printf 'Warning: directory is not readable.\n' 1>&2
      fi

      :;: "See whether \\canpth\\ is writable."
      if [ -w "${canpth}" ]
      then
        : "t:0:${LINENO}" #<>
        :;: "\\canpth\\ is writable."
      else
        : "f:$?:${LINENO}" #<>
        :;: "\\canpth\\ is not writable."

        printf 'Warning: directory is not writable.\n' 1>&2
      fi
    else
      : "f:$?:${LINENO}" #<>
      :;: "\\canpth\\ is a symlink."
      echo Error 1>&2
      exit "${LINENO}"
    fi
  else
    : "f:$?:${LINENO}" #<>
    :;: "\\canpth\\ and \\find_out\\ are not equivalent strings."
    echo Error 1>&2
    exit "${LINENO}"
  fi
else
  : "f:$?:${LINENO}" #<>
  :;: "\\find -type d\\ did not locate the directory."
  echo Error 1>&2
  exit "${LINENO}"
fi

exit 00
