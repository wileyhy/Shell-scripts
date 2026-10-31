#!/bin/env sh
# candr.sh / canonicalize-dir.sh
#  hellcheck disable=SC2319,SC2292
#
#   Script is unfinished - 31 Oct 2026 WY
#
#
#   Manual canonicalization of directories. Output can be in brief or
# verbose formats; brief is the default; script accepts multiple
# operands.
#
#   Both \realpath\ and \readlink\ weren\t specified in POSIX until
# 2024, so it\s likely that there are numerous systems which do not
# offer any utilities which canonicalize file paths.
#
#   Goals: that this script...
#     - is written for any POSIX-2008 compliant shell.
#     - can be executed successfully in resticted mode.
#
#   (c) Wiley Young 2026
#
# Tested on these distros and shells:
#
# Notes:
#   - redirection operators cannot be placed within parameter
#       expansions and still function as redirection operators.
#   - #!/bin/env -i sh fails.
#   - LINENO does exist in POSIX-2008.



  #> Debug
  \set -x #>
  \set -e #>
  \set -f #> Disable pathame expansion.
  \set -u #>
  \: #>
  \: "pound: $#" #>
  \: "ampersand:" "${@:-}" #>
  \: "\$0: <$0>, <${0#./}> "
  \: "\$1: ${1:-}" #>
  \: "\$2: ${2:-}" #>
  \:
  \:


: "Security"
#
# POSIX-2024 suggestion for \Start off a \\secure shell script\\ in
# which the script avoids being spoofed by its parent,\ as found in
# its spec. for \command\.
IFS=' 	
'
# Value of IFS should include one tabstop.
\unalias -a
unset -f command
#PATH="$(command -p getconf PATH):$PATH" # See next section on
# Restricted Mode.


: "Restricted Mode"
#
#   Note, restricted mode is not specified by POSIX 2024; reasoning
# described in spec. on utility \sh\.
# 
# Bash 5.3.9
#   - Restricted mode is inherited by subshells from interactive 
#     shells.
#   - Restricted mode is not inherited by scripts which are executed
#     from interactive shells when...
#       - their dirname is located in PATH and without a leading
#         \./\.
#   - Description in \man bash\:
#       o     Changing directories with cd.
#       o     Setting or unsetting the values of SHELL, PATH,
#               HISTFILE, ENV, or BASH_ENV.
#       o     Specifying command names containing /.
#       o     Specifying a filename containing a / as an argument
#               to the .  builtin command.
#       o     Using the -p option to the .  builtin command to
#               specify a search path.
#       o     Specifying a filename containing a slash as an
#               argument to the history builtin command.
#       o     Specifying a filename containing a slash as an
#               argument to the -p option to the hash builtin
#               command.
#       o     Importing function definitions from the shell
#               environment at startup.
#       o     Parsing the values of BASHOPTS and SHELLOPTS from the
#               shell environment at startup.
#       o     Redirecting output using the >, >|, <>, >&, &>, and >>
#               redirection operators.
#       o     Using the exec builtin command to replace the shell
#               with another command.
#       o     Adding or deleting builtin commands with the -f and -d
#               options to the enable builtin command.
#       o     Using the enable builtin command to enable disabled
#               shell builtins.
#       o     Specifying the -p option to the command builtin
#               command.
#       o     Turning off restricted mode with set +r or shopt -u
#               restricted_shell.
if PATH="$(command -p getconf PATH):$PATH"
then
  : "t:0" "PATH variable can be altered."
  if ( cd / )
  then
    : "t:0" "\\cd\\ succeeds."
    is_restricted=no
  else
    : "f:$?" "\\cd\\ fails."
    printf '%s: warning: mixed test results from \%s\; exiting\n' \
      "$0" "cd"
    exit 1
  fi
else
  : "f:$?" "PATH variable cannot be altered."
  # Variable could be set as read-only.
  case $- in
    *r*)
      : "\\\$-\\ shows restricted mode is on."
      is_restricted=yes
      ;;
    *)
      : "\\\$-\\ shows restricted mode is off."
      # Notes, 
      #   - \set +o\ doesn\t list restricted mode, possibly because it
      #     isn\t specified by POSIX.
      #   - \shopt\ is only available in Bash?
      is_restricted=no
      ;;
  esac
fi


: "Commands"
#
# Utilities & Special Builtins
#   Test string: \codeblocks\
case $- in
  *x*)  reset="set -x"; set +x;;
  *)    reset="";;
esac
for uU in \
  "awk" "cd" "command" "dirname" "echo" \
  "env" "file" "find" "getconf" "grep" \
  "id" "pathchk" "printf" "pwd" "sed" \
  "sh" "test" "true" "unalias" ":" \
  "break" "continue" "exit" "set" "shift" \
  "unset" \
    "hash" "readonly" # count is 28
  #"codeblocks" #> Codeblocks is not specified by POSIX-2008; the
  # rest in this list are.
do
    #> Just to see in which directory each utility is located.
    #which "${uU}" #>
    # Note
    #   - At 26 commands, all non-special-builtins are located in 
    #     /usr/bin
  # Determine whether command \uU\ is in PATH.
  if command -v "${uU}" >/dev/null
  then
    : "t:0"
  else
    : "f:${ec0:=$?}"
    printf '%s: Command <%s> is not installed or available.\n' \
      "$0" "${uU}"
    exit "${ec0}"
  fi
  # Unset user functions
  unset -f "${uU}"
done
$reset # Word-Splitting intended.


: "Input required."
#
# Testing command:
#set --
if test "$#" -eq 0
then
  : "t:0" #>
  printf '%s\n' "${usage_msg:?}" 1>&2
  exit 1
else : "f:$?" #>
fi


: "\\strings\\ and \\pathchk\\"
#
#   Test input: "$( dd if=/dev/urandom of=/dev/stdout bs=32b count=1
#     2>/dev/null )"
for aA
do
  bB=$( printf '%s' "${aA}" | strings -n 1 )
  if test "${aA}" = "${bB}"
  then
    : "t:0"
  else
    : "f:$?"
    printf '%s: error: input contains non-printable strings.\n' \
      "$0"
    exit 1
  fi
  if pathchk -Pp "${aA}" >/dev/null
  then
    : "t:0"
  else
    : "f:$?"
    printf '%s: warning: %\n' \
      "input contains one or more non-printable strings."
  fi

done


: "Environment Variables"
# See man pages under POSIX 2008
# Common
LC_ALL=C
# \cd\
CDPATH=
OLDPWD=
  

# Use \getconf\.
getconf PATH_MAX # for \pwd\
getconf NAME_MAX


# 
# Unset certain env. vars. if possible and if they\re defined.
if test "${is_restricted}" = "no"
then
  for cC in BASH_ENV ENV LD_PRELOAD
  do
    : "t:0"
    if set | grep "${cC}" >/dev/null
    then
      : "t:0"
      unset "${cC}"
      printf '%s: notice: %s\n' "$0" "BASH_ENV was unset" #>
    else
      : "f:$?"
    fi
  done
else
  : "f:$?"
fi


# Make sure HOME is defined, for \cd\.
if set | grep HOME >/dev/null
then
  : "t:0"
else
  : "f:$?"
  username=$( id -un )
  HOME=$(
    awk -F: -v "vV=${username}" '$1 == vV { print $6 }' /etc/passwd
  )
  echo HOME was assigned.
fi

# PWD aught to be defined, for \cd\ and \pwd\
# Notes,
#   - In POSIX-2008 effects of assignments to PWD are unspecified.
#   - If restricted mode is enabled and PWD is undefined, a call to
#     \cd\ will not assign a value to PWD, in Bash 5.3.9.
if set | grep PWD >/dev/null
then
  : "t:0"
else
  : "f:$?"
  printf '%s: warning: %s.\n' "$0" "PWD is undefined"
fi


: "Script Variables"
canpth=
global_return_code=0
output_verbose_on=
nsfod="(No such file or directory)"
usage_msg="${0#./}:

    Usage: the first argument may be an option flag.
        candr.sh [-b|-v] [FILE] ...
"
:
  #set -x #>
  #echo stdout #>
  #echo stderr 1>&2 #>
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
      printf '%s: %b%s%b -> %s\n' "$0" "\x27" "$1" "\x27" "$2"
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
  #set -x #>
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
  # Test input: /dev/qwertyuiop
  if test -e "${dD}"
  then
    : "t:0" #>
    : "Path exists."
  else
    : "f:$?" #>
    global_return_code=1
    __print_output__ "${dD}" "${nsfod}" >&2
    continue 1
  fi

    #exit "${LINENO}" #>
    #set -x #>


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
      : "t:0" #>
      canpth=/
      __print_output__ "$1" "${canpth}"
      : exit "\${global_return_code}"
      exit "${global_return_code}"
    else : "f:$?" #>
    fi

    #   Case if input is \.\, single period, CWD.
    #   Case if input begins with \./\, anchoring file in CWD.
    if test "${dD}" = '.' \
      || test "${dD}" = './' \
      || test "${dD}" = './/'
    then
      : "t:0" #>
      canpth=$( pwd )
      __print_output__ "$1" "${canpth}"
      : exit "\${global_return_code}"
      exit "${global_return_code}"
    else : "f:$?" #>
    fi

    for zZ in '/' '//' '.' './' '..' '../'
    do
      __test_for_string__ "${zZ}"
    done

      exit "${LINENO}" #>
      #set -x #>

    #   Case if input is \..\, double period, aka, \dirname\.
    #   Case if input begins with \../, anchoring file in \dirname\.
    #   Case if ....

    :
    : "Get output of \\file\\."
    output_0_file=$( file "${dD}" )

      exit "${LINENO}" #>
      #set -x #>


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
      : "t:0" #>

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
      : "f:$?" #>

      :
      : "...otherwise, test if \\directory\\ is present in the string."
      if printf '%s' "${output_0_file}" \
        | sed 's,.*: ,,' \
        | grep -q "directory"
      then
        : "t:0" #>

        :
        : "If it is, then \\break\\ this loop."
        break 1
      else
        : "f:$?" #>

        :
        : "If it\\s neither a symlink nor a directory, that\\s an error."
        echo Error 1>&2
        exit "${LINENO}"
      fi
    fi
  done

    exit "${LINENO}" #>
    #set -x #>

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
    #set -x #>

  :
  : "Minor loop B: Make sure every dir. in the abs. path is not a sym."
  while true
  do
    :
    : "If \\eE\\ is a directory..."
    if test -d "${eE}"
    then
      : "t:0" #>

      :
      : "Then get the \\dirname\\ of \\eE\\."
      eE=$( dirname "${eE}" )

      :
      : "If the \\dirname\\ of \\eE\\ is also a directory..."
      if test -d "${eE}"
      then
        : "t:0" #>

        :
        : "Then, if the new \\eE\\ is the filesystem root, \\/\\..."
        if test "${eE}" = "/"
        then
          : "t:0" #>

          :
          : "Then double-check it using \\grep\\."
          if printf '%s\n' "${eE}" \
            | grep -qEe '^/$'
          then
            : "t:0" #>
            :
            : "\\grep\\ succeeded, so \\break\\ this loop."
            __print_output__
            break 1
          else
            : "f:$?" #>

            :
            : "\\test\\ passed but \\grep\\ failed. Error. Exiting."
            exit "${LINENO}"
          fi
        else
          : "f:$?" #>

          :
          : "The new \\eE\\ is not the FS root directory; next iteration."
          continue 1
        fi
      else
        : "f:$?" #>

        :
        : "The \\dirname\\ of \\eE\\ is not a directory."
        exit "${LINENO}"
      fi
    else
      : "f:$?" #>

      :
      : "Error: \\eE\\ is not a directory. Exiting."
      exit "${LINENO}"
    fi
  done
done

  exit "${LINENO}" #>
  #set -x #>


:
  : "Print warnings if the directory is not readable\/writable\/searchable."

:
  : "Verify it\\s a directory by using \\find\\."
output_2_find=$( find "${canpth}" -prune -type d )

    exit "${LINENO}" #>
    #set -x #>

if test -n "${output_2_find}"
then
  : "t:0" #>

  :
  : "See whether \\canpth\\ and \\output_2_find\\ are equivalent strings."
  if test "${canpth}" = "${output_2_find}"
  then
    : "t:0" #>

    :
    : "See whether \\canpth\\ is a symlink."
    if test ! -L "${canpth}"
    then
      : "t:0" #>
      :
      : "\\canpth\\ is not a symlink"

      # Tests in serial:

        exit "${LINENO}" #>
        #set -x #>

      :
      : "See whether \\canpth\\ is searchable."
      if test -x "${canpth}"
      then
        : "t:0" #>
        :
        : "\\canpth\\ is searchable."

      else
        : "f:$?" #>
        :
        : "\\canpth\\ is not searchable."

        printf 'Warning: directory is not searchable.\n' 1>&2
      fi

        exit "${LINENO}" #>
        #set -x #>

      :
      : "See whether \\canpth\\ is readable."
      if test -r "${canpth}"
      then
        : "t:0" #>
        :
        : "\\canpth\\ is readable."

      else
        : "f:$?" #>
        :
        : "\\canpth\\ is not readable."

        printf 'Warning: directory is not readable.\n' 1>&2
      fi

        exit "${LINENO}" #>
        #set -x #>

      :
      : "See whether \\canpth\\ is writable."
      if test -w "${canpth}"
      then
        : "t:0" #>
        :
        : "\\canpth\\ is writable."
      else
        : "f:$?" #>
        :
        : "\\canpth\\ is not writable."

        printf 'Warning: directory is not writable.\n' 1>&2
      fi
        exit "${LINENO}" #>
        #set -x #>

    else
      : "f:$?" #>
      :
      : "\\canpth\\ is a symlink."
      echo Error 1>&2
      exit "${LINENO}"
    fi
  else
    : "f:$?" #>
    :
    : "\\canpth\\ and \\output_2_find\\ are not equivalent strings."
    echo Error 1>&2
    exit "${LINENO}"
  fi
else
  : "f:$?" #>
  :
  : "\\find -type d\\ did not locate the directory."
  echo Error 1>&2
  exit "${LINENO}"
fi

    exit "${LINENO}" #>
    #set -x #>

exit 00
