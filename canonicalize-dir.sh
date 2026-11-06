#!/bin/env sh
# candr.sh / canonicalize-dir.sh
# shellcheck disable=SC2028,SC2268
#
#   Script is unfinished - 05 Nov 2026 WY
#
#
#   Manual canonicalization of directories. Output can be in brief or
# verbose formats; brief is the default; script accepts multiple
# operands.
#
#   Goals: that this script...
#     - Is written for any Posix-2008 compliant shell.
#
#   (c) Wiley Young 2026
#
# Tested on these distros and shells:
#   - Fedora 44: bash-5.3.9-3
#
# Notes:
#   - Redirections are applied before any expansions occur.
#   - \#!/bin/env -i sh\ fails.
#   - LINENO does exist in Posix 2008.
#   - Reportedly, Solaris 10 uses a Bourne sh which is not Posix
#     compliant.
#       https://unix.stackexchange.com/questions/322035/\
#         are-there-still-systems-around-with-a-bin-sh-binary
#   - Reportedly, in BusyBox \a\wk\ is optional.
#   - If PATH is s\et RO in the interactive calling shell, in the
#     script PATH can still be altered.
#   - When called from a restricted interactive shell, the script
#     does not inherit the restricted setting.
#   - Both \realpath\ and \readlink\ weren\t specified in Posix until
#     2024.
#   - The \-P\ option to \type\ is not portable.
#   - The \pathchk\ utility offers three separate sets of tests.
#   - The \-q\ option to \g\rep\ does exist in Posix 2008.
#   - In Posix-2008, the handling of \//\ is intentionally
#     implementation defined, so catch it, flag it as an error, and
#     write a warning to Stderr. See spec. on \dirname\.
#   - Defining directories with a trailing f\orward slash will
#     effect whether \[[\, \test\, \[\ and \stat\ dereference
#     symlinks. However, \realpath -e\ will still resolve such
#     strings correctly.



  #> Debug
  #\set -x #>
  \set -e #>
  \set -f #> Disable pathame expansion.
  \: #>
  \: "Dash: $-"
  \: "Pound: $#" #>
  \: "Ampersand:" "${@:-}" #>
  \: "\$0: <$0>, <${0#./}> "
  \: "\$1: ${1:-}" #>
  \: "\$2: ${2:-}" #>
  \: "\$LINENO: ${LINENO:-}" #>
  \: "\$SHELL: ${SHELL:-}" #>


\:;\: "Settings"
\set -u
\set -C


\:;\: "Security"
#
# Posix-2024 suggestion for \Start off a \\secure shell script\\ in
# which the script avoids being spoofed by its parent,\ as found in
# its spec. for \command\.
#
IFS=' 	
'
# Value of IFS should include one tabstop.
\unalias -a
unset -f command
PATH="$( command -p getconf PATH ):${PATH}"

  #exit "${LINENO}" #>
  #set -x #>


:;: "Bootstrap Functions"
#
# Unset xtrace and prepare to restore state at the end of this
# section.
: "Define function, __offset__"
__offset__ ()
{
  : "Define function, __reset__"
  case $- in
    *x*) __reset__ () { set -x;}; set +x ;;
    *) __reset__ () { :;}; ;;
  esac
}


:;: "Bootstrap Variables."
usage_msg="${0#./}:

    Usage: the first argument may be an option flag.
        candr.sh [-b|-v] [FILE] ...
"


:;: "Printing format."
#
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
export output_verbose_on

  # Bug, var names, \output_\ meaning, from a utility, vs. \output\
  # meaning, of the script.

  #declare -p output_verbose_on
  #exit "${LINENO}"


:;: "Input required."
#
#   Testing command: s\et --
if test 0 -lt "$#"
then
  : "t:0:${LINENO}" #>
else
  printf '%s\n' "f:$?:${LINENO}" #>
  printf 'Input required.\n\n' #>
  printf '%s\n' "${usage_msg:?}" 1>&2
  exit 1
fi


:;: "Commands"
#
# Utilities & Special Builtins
#   Test string: \codeblocks\
#
# Remove the hash table, so that PATH lookups are forced and
# therefore current. Posix recommends \PATH=${PATH}\ in spec. on 
# \hash\.
# shellcheck disable=SC2269
PATH=${PATH}

# Tests for each command
__offset__
for uU in \
  "awk" "cd" "command" "dirname" "env" \
  "file" "find" "getconf" "grep" "id" \
  "ls" "pathchk" "printf" "ps" "pwd" \
  "sed" "sh" "strings" "test" "true" \
  "type" "unalias" \
    ":" "break" "continue" "exit" "readonly" "set" "shift" \
  "unset" # count is 31
  #
  #"codeblocks" #> Codeblocks is not specified by Posix-2008; the
  # rest of the commands in this list are.
do
    #> Just to see in which directory each utility is located.
    #which "${uU}"; continue #>
    #> Note
    #>   - At 31 commands, all non-special-builtins are located in 
    #>     /usr/bin on Fedora 44.
  # Determine whether command \uU\ is in PATH.
  if command -pv "${uU}" >/dev/null
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec0:=$?}"
    printf '%s: Command <%s> is not installed or available.\n' \
      "$0" "${uU}"

    # Bug, s\et a flag to signal exit after loop.
    
    exit "${ec0}"
  fi
  # Unset user functions
  unset -f "${uU}"
done
__reset__

  #exit "${LINENO}" #>
  #set -x #>


:;: "\\tr\\", "\\strings\\ and \\pathchk\\"
#
#   Test input: "$( dd if=/dev/urandom bs=32b count=1
#     2>/dev/null )"
for aA in "$@" '.' '..'
do
  bB=$( printf '%s' "${aA}" | tr -d '\0'   ) # Remove NULs
  cC=$( printf '%s' "${bB}" | strings -n 1 ) # Remove nonprintable
  if test "X${aA}" = "X${cC}"
  then
    : "t:0:${LINENO}"
  else
    printf '%s\n' "f:$?:${LINENO}"
    printf '%s: error: %\n' \
      "$0" "input contains one or more non-printable strings."
    exit 1
  fi

  # \pathchk\ x3
  #
  # Checks \each component of each pathname of the underlying file system.\
  # using PATH_MAX and NAME_MAX, for any non-searchable directory, and for
  # any character that is invalid in its containing directory.
  if pathchk "${aA}"
  then
    : "t:0:${LINENO}"
  else
    printf '%s\n' "f:$?:${LINENO}"
    printf '%s: warning: %\n' \
      "$0" "input fails \pathchk\ tests."
  fi

  # Checks \each component of each pathname of the underlying file system.\
  # using _POSIX_PATH_MAX and _POSIX_NAME_MAX, and for any character not in
  # the portable character set.
  if pathchk -p "${aA}"
  then
    : "t:0:${LINENO}"
  else
    printf '%s\n' "f:$?:${LINENO}"
    printf '%s: warning: %\n' \
      "$0" "input fails \pathchk -p\ tests."
  fi

  # Checks for any component which begins with a hyphen, and any component
  # which is empty.
  if pathchk -P "${aA}"
  then
    : "t:0:${LINENO}"
  else
    printf '%s\n' "f:$?:${LINENO}"
    printf '%s: warning: %\n' \
      "$0" "input fails \pathchk -P\ tests."
  fi
done


:;: "\\getconf\\" # -- if xtrace is on.
#   _POSIX_NAME_MAX   # for \pathchk\
#   _POSIX_PATH_MAX   # for \pathchk\
#   BASH_ENV          # for \bash\
#   CDPATH            # for \cd\
#   ENV               # for \sh\
#   HOME              # for \cd\
#   LC_ALL            # Common
#   LD_PRELOAD        # for paranoia ;-P
#   NAME_MAX          # for \pathchk\
#   PATH_MAX          # for \cd\, \pathchk\ and \pwd\
#   OLDPWD            # for \cd\
#   PWD               # for \cd\ and \pwd\
if printf '%s' "$-" | grep -q "x"
then
  : "t:0:${LINENO}"
  __offset__
  output_getconf_00_a=$( getconf -a )
  for eV in \
    _POSIX_NAME_MAX \
    _POSIX_PATH_MAX \
    CDPATH \
    HOME \
    LC_ALL \
    NAME_MAX \
    PATH_MAX \
    OLDPWD \
    PWD
  do
    printf '%s\n' "${output_getconf_00_a}" | grep -E "^${eV}" ||:
  done
  __reset__
else
  printf '%s\n' "f:$?:${LINENO}: \\getconf\\"
fi



:;: "Environment Variables"
# See man pages under Posix 2008
# Common
LC_ALL=C
# \cmd\
CDPATH=
OLDPWD=

# Unset certain env. vars. if possible and if they\re defined.
#
#   Testing:
#     POSIXLY_CORRECT=yes
#     LD_PRELOAD=foo
#     cC=LD_PRELOAD
#     set | grep -E "^${cC}=.+"; echo $?
#     unset LD_PRELOAD; echo $?
#     set | grep -E "^${cC}=.+"; echo $?
#
for cC in  BASH_ENV  ENV  LD_PRELOAD
do
  : "t:0:${LINENO}"
  if set | grep -E "^${cC}=.+"
  then
    : "t:0:${LINENO}"
    unset "${cC}" \
      && printf '%s: notice: %s\n' "$0" "\\unset ${cC}\\ succeeded" #>
  else
    printf '%s\n' "f:$?:${LINENO}: ${cC}"
  fi
done

# Make sure HOME is defined, for \cd\.
cC=HOME
if set | grep -E "^${cC}=.+"
then
  : "t:0:${LINENO}"
else
  printf '%s\n' "f:$?:${LINENO}"
  username=$( id -un )

  # Bug, use if-fi

  HOME=$(
    awk -F: -v "vV=${username}" '$1 == vV { print $6 }' /etc/passwd
  ) \
    && printf '%s\n' "HOME was assigned."
fi

# PWD aught to be defined, for \cd\ and \pwd\
# Notes,
#   - In Posix-2008 effects of assignments to PWD are unspecified.
#   - If restricted mode is enabled and PWD is undefined, a call to
#     \cd\ will not assign a value to PWD, in Bash 5.3.9.
cC=PWD
if set | grep -E "^${cC}=.+"
then
  : "t:0:${LINENO}"
else
  printf '%s\n' "f:$?:${LINENO}"
  cd . ||:

  if set | grep -E "^${cC}=.+"
  then
    : "t:0:${LINENO}"
  else
    printf '%s\n' "f:$?:${LINENO}"
    printf '%s: warning: %s.\n' "$0" "PWD is undefined"
  fi
fi


: "Script Variables"
canpth=
global_return_code=0
nsfod="(No such file or directory)"
:
  #set -x #>
  #printf '%s\n' stdout #>
  #printf '%s\n' stderr 1>&2 #>
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
#             echo GL-scriptnm: GL-majloop-input: \
#                                 [GL-minloop-canpth GL-minloop-STDo/e]
#
#           brief
#             echo                                \
#                                 [GL-minloop-canpth GL-minloop-STDo/e]
#
#
#     dne     .'. GL-minloop-STDo/e = STDERR
#             .'. GL-rtncode = 1
#
#       _print_output_
#
#           verbose
#             echo GL-scriptnm: GL-majloop-input: \
#                                 [GL-minloop-NSFOD GL-minloop-STDo/e]
#
#           brief
#             echo                                \
#                                 [GL-minloop-NSFOD GL-minloop-STDo/e]
#
#
# exit GL-rtncode


: "Define function: __print_output__."
#
# Usage:    __print_output__ [Script input] [canpth|nsfod] [redirection]
# Usage:    __print_output__ "${dD}" "${canpth}"
#                                         # ^normal output to STDOUT
# Usage:    __print_output__ "${dD}" "${nsfod}" >&2
#                                         # ^redirect output to STDERR
#
# shellcheck disable=SC2329
__print_output__ ()
{
    #set -x #>
    : #>
    : "local variables:"
    : "pound: $#" #>
    : "ampersand:" "$@" #>
    : "\$1: $1"
    : "\$2: $2"
    : "\$global_return_code: ${global_return_code}" #>
    : "\$output_verbose_on: ${output_verbose_on}" #>
    #exit "${LINENO}" #>

  :;: "If error, then switch verbose on."
  if test 0 -ne "${global_return_code}"
  then
    : "t:0:${LINENO}"
    output_verbose_on=yes
  else
    printf '%s\n' "f:$?:${LINENO}" #>
  fi

  :;: "\\case\\ on \\output_verbose_on\\."
  case "${output_verbose_on}" in
    yes | y )
      : "Case branch: \\yes\\."
      printf '%s: %b%s%b -> %s\n' "$0" "\x27" "$1" "\x27" "$2"
      ;;
    no | n )
      : "Case branch: \\no\\."
      printf '%s\n' "$2"
      ;;
    * ) printf '%s\n' "Unreachable code."; exit "${LINENO}";; #>
  esac

    #exit "${LINENO}" #>
}
:
  #set -x #>
  #exit "${LINENO}" #>
  set -x #>
  :
  :

  # Buggy - rewrite script from this point on.
  #  - put the entire thing in a true loop
  #    - check for leading forward slash
  #      - if missing, then prepend output of \pwd\
  #    - handle a double forward slash at the far left of the string
  #    - using \a\wk -F/\, separate the pathname out into separate elements
  #    - load the elements into the positional array
  #    - start with a \symlink_detected\ canary variable, s\et to \no\
  #      - loop through the array; the idea is to use concatenation to
  #      build up a new pathname; loop on \$# and \$1; use \shift\
  #        - for each element, ad\d one leading forward slash to the
  #        current element
  #        - if there was an existing \canpath\ string from a previous
  #        loop, then prepend that on
  #        - use both \file\ and \test\ to determine the filetype of the
  #        basename of the \canpath\ string
  #        - if both utilities agree, then
  #          - if element is a symlink, then switch \symlink_detected\ to
  #          \yes\
  #            - get the value of the symlink from \file\
  #            - test for whether the of value from \file\ has a leading
  #            forward slash
  #              - if yes, then use the symlink\s value as the total
  #              pathname thus far and continue
  #              - if no, then append the symlink\s value to the existing
  #              value of \canpath\
  #                ...and continue?
  #          - if element is a directory, then continue
  #          - if element is neither a symlink nor a directory, then 
  #            - if there are no more elements in the loop, then \break 1\
  #            - if there are elements remaining, then error
  #              ...and figure out what that means. is it a dangling
  #              symlink?
  #        - if the two utilities disagree, then error
  #      end element loop
  #      - if \symlink_detected\ is \yes\, then remain in the true loop;
  #      otherwise \break 2\
  #  - end true loop
  #  - how do you detect data loops? tmp file of pathnames at top of each
  #  true loop - duplicates mean data loop and error?

  #declare -p output_verbose_on
  #exit "${LINENO}"


:;: "The given path must exist in the filesystem."
# Test input: /dev/qwertyuiop
for dD
do
  if test -e "${dD}"
  then
    : "t:0:${LINENO}" #>
    : "Path exists."
  else
    printf '%s\n' "f:$?:${LINENO}" #>
    global_return_code=1
    __print_output__ "${dD}" "${nsfod}" >&2
    continue 1
  fi
done


exit 00


##### INCORRECT #####################################################

  : "Minor loop A: Use \\file\\ to resolve any symlinks."

: "Major loop"
#   Testing strings: a list of common temporary directories in Linux.
for dD
  #/dev/shm /var/tmp /usr/tmp /usr/local/tmp "${XDG_RUNTIME_DIR:=}/tmp" \
  #/tmp ~/tmp ~ #>
do
  :

  # Bug, rename var \majloop_orig_str\

  : "Per major loop variables."
  posparm_original_string=${dD}
  :
    exit "${LINENO}" #>
    #set -x #>

  while true
  do
    # In case the string is \^//$\.
    

    # String matching; the possibilities are endless, ie, not good.

    # Case if input is \/\, single forward slash, FS root.
    if test "X${dD}" = 'X/' \
      || test "X${dD}" = 'X//' \
      || test "X${dD}" = 'X///'
    then
      : "t:0:${LINENO}" #>
      canpth=/
      __print_output__ "$1" "${canpth}"
      : exit "\${global_return_code}"
      exit "${global_return_code}"
    else
      printf '%s\n' "f:$?:${LINENO}" #>
    fi

    #   Case if input is \.\, single period, CWD.
    #   Case if input begins with \./\, anchoring file in CWD.
    if test "X${dD}" = 'X.' \
      || test "X${dD}" = 'X./' \
      || test "X${dD}" = 'X.//'
    then
      : "t:0:${LINENO}" #>
      canpth=$( pwd )
      __print_output__ "$1" "${canpth}"
      : exit "\${global_return_code}"
      exit "${global_return_code}"
    else
      printf '%s\n' "f:$?:${LINENO}" #>
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



    :
    : "See whether \\file\\ says \\symbolic link\\."
    if printf '%s' "${output_0_file}" \
      | grep -q -E ': symbolic link to [/\.a-z]'
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
      printf '%s\n' "f:$?:${LINENO}" "...otherwise, test if \\directory\\ is" \
        "present in the string."
      if printf '%s' "${output_0_file}" \
        | sed 's,.*: ,,' \
        | grep -q "directory"
      then
        : "t:0:${LINENO}" "If it is, then \\break\\ this loop."
        break 1
      else
        printf '%s\n' "f:$?:${LINENO}" "If it\\s neither a symlink nor a" \
          "directory, that\\s an error." 1>&2
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
        if test "X${eE}" = "X/"
        then
          : "t:0:${LINENO}" #>

          :
          : "Then double-check it using \\grep\\."
          if printf '%s\n' "${eE}" \
            | grep -q -E '^/$'
          then
            : "t:0:${LINENO}" #>
            :
            : "\\grep\\ succeeded, so \\break\\ this loop."
            __print_output__
            break 1
          else
            printf '%s\n' "f:$?:${LINENO}" "\\test\\ passed but \\grep\\ failed." \
              "Error. Exiting."
            exit "${LINENO}"
          fi
        else
          printf '%s\n' "f:$?:${LINENO}" "The new \\eE\\ is not the FS root" \
            "directory; next iteration."
          continue 1
        fi
      else
        printf '%s\n' "f:$?:${LINENO}" "The \\dirname\\ of \\eE\\ is not a" \
          "directory."
        exit "${LINENO}"
      fi
    else
      printf '%s\n' "f:$?:${LINENO}" "Error: \\eE\\ is not a directory. Exiting."
      exit "${LINENO}"
    fi
  done
done

  exit "${LINENO}" #>
  #set -x #>


:
  : "Print warnings if the directory is not" \
      "readable \/ writable \/ searchable."

:
  : "Verify it\\s a directory by using \\find\\."
output_2_find=$( find "${canpth}" -prune -type d )

    exit "${LINENO}" #>
    #set -x #>

if test -n "${output_2_find}"
then
  : "t:0:${LINENO}" #>

  :
  : "See whether \\canpth\\ and \\output_2_find\\ are equivalent strings."
  if test "X${canpth}" = "X${output_2_find}"
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
        #set -x #>

      :
      : "See whether \\canpth\\ is searchable."
      if test -x "${canpth}"
      then
        : "t:0:${LINENO}" #>
        :
        : "\\canpth\\ is searchable."

      else
        printf '%s\n' "f:$?:${LINENO}" "\\canpth\\ is not searchable."

        printf 'Warning: directory is not searchable.\n' 1>&2
      fi

        exit "${LINENO}" #>
        #set -x #>

      :
      : "See whether \\canpth\\ is readable."
      if test -r "${canpth}"
      then
        : "t:0:${LINENO}" #>
        :
        : "\\canpth\\ is readable."

      else
        printf '%s\n' "f:$?:${LINENO}" "\\canpth\\ is not readable."

        printf 'Warning: directory is not readable.\n' 1>&2
      fi

        exit "${LINENO}" #>
        #set -x #>

      :
      : "See whether \\canpth\\ is writable."
      if test -w "${canpth}"
      then
        : "t:0:${LINENO}" #>
        :
        : "\\canpth\\ is writable."
      else
        printf '%s\n' "f:$?:${LINENO}" "\\canpth\\ is not writable."

        printf 'Warning: directory is not writable.\n' 1>&2
      fi
        exit "${LINENO}" #>
        #set -x #>

    else
      printf '%s\n' "f:$?:${LINENO}" "\\canpth\\ is a symlink." 1>&2
      exit "${LINENO}"
    fi
  else
    printf '%s\n' "f:$?:${LINENO}" "\\canpth\\ and \\output_2_find\\ are not" \
      "equivalent strings." 1>&2
    exit "${LINENO}"
  fi
else
  printf '%s\n' "f:$?:${LINENO}" "\\find -type d\\ did not locate the directory." 1>&2
  exit "${LINENO}"
fi
