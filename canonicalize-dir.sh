#!/bin/env sh
# candr.sh / canonicalize-dir.sh
# shellcheck disable=SC2028,SC2268
#
#   Script is unfinished - 08 Nov 2026 WY
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
#   - Fedora 44: bash-5.3.9
#   - Fedora 45: bash-5.3.15
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
#   - When called from a restricted interactive shell, the script
#     does not inherit the restricted setting.
#   - Both \realpath\ and \readlink\ weren\t specified in Posix until
#     2024.
#   - The \-P\ option to \type\ is not portable.
#   - The \pathchk\ utility offers three separate sets of tests; there
#     is no overlap between said sets.
#   - The \-q\ option to \g\rep\ does exist in Posix 2008.
#   - In Posix-2008, the handling of \//\ is intentionally
#     implementation defined, so catch it, flag it as an error, and
#     write a warning to Stderr. See spec. on \dirname\.
#   - Defining directories with a trailing f\orward slash will
#     effect whether \[[\, \test\, \[\ and \stat\ dereference
#     symlinks. However, \realpath -e\ will still resolve such
#     strings correctly.
#   - The \-r\ option to \hash\ does exist in Posix 2008.
#   - If PATH is s\et RO in the interactive calling shell, in the
#     script PATH can still be altered.
#   - For \readonly\ without arguments, the results are unspecified. In
#     Bash, attempting in a script to assign a value to a RO variable is
#     a fatal error, but that doesn\t appear to have been specified by
#     Posix in 2008.
#   - Names of special built-ins cannot be used as names of functions
#     (ie, \unset\).
#   - 



  #> Debug.
  #\set -x #>

    #> Testing backslash quoting of commands
    #shopt -s expand_aliases; alias set='echo foo'; set -e #>

  #> Debug
  \set -e #>

    #> Testing errexit
    #false #>

  \set -f #> Disable pathame expansion.

    #> Testing disabling of pathname expansion
    #ls -alhFid ~/.bash* #>

  \: #> Debug
  \: "Dash: $-"
  \: "Pound: $#" #>
  \: "Ampersand:" "${@:-}" #>
  \: "\$0: <$0>, <${0#./}> "
  \: "\$1: ${1:-}" #>
  \: "\$2: ${2:-}" #>
  \: "\$LINENO: ${LINENO:-}" #>
  \: "\$SHELL: ${SHELL:-}" #>
  #\exit "${LINENO}" #>


\:;\: "Settings."
\set -u

  #> Testing nounset
  #echo "${unbound_variable}" #>

\set -C

  #> Testing noclobber
  #file=~/tmp/random-file.${RANDOM}.log #>
  #touch "${file}" #>
  #echo foo > "${file}" #>

  #> Testing variable assignment (IFS), pt 1
  #IFS=:
  #readonly IFS

\:;\: "Security."
#
# Posix-2024 suggestion for \Start off a \\secure shell script\\ in
# which the script avoids being spoofed by its parent,\ as found in
# its spec. for \command\.
#
# Value of IFS should include one tabstop.
IFS=' 	
'

  #> Testing variable assignment (IFS), pt 2
  #declare -p IFS #>

  #> Testing \unalias\, pt 1
  #shopt -s expand_aliases; alias unalias='echo foo' #>
  #alias #>

\unalias -a

  #> Testing \unalias\, pt 2
  #alias #>
  #exit "${LINENO}" #>

  #> Testing \unset\ as a function name
  #unset () { echo Foo;}

  #> Testing \command\ as a function name, pt 1
  #command () { echo Bar;}

unset -f command

  #> Testing \command\ as a function name, pt 2
  #command -p echo Baz #>
  #exit "${LINENO}" #>

  #> Testing variable assignment (PATH)
  #set -r #>
  #readonly PATH #>
  #readonly -p; exit "${LINENO}" #>

# PATH could be set as RO.
if PATH="$( command -p getconf PATH ):${PATH}"
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"
  printf '%s: Notice: Assignment to variable failed: %s\n' "$0" "PATH"
  printf '%s: Notice: Value of variable %s: <%s>\n' "$0" "PATH" "${PATH}"
fi

  #exit "${LINENO}" #>
  #set -x #>


:;: "Bootstrap Variables."
global_return_code=0
special_var_zero=${0#./}
special_var_zero=${0##*/}
usage_msg="${special_var_zero}:

    Usage: The first argument may be an option flag.
        candr.sh [-b|-v] [FILE] ...
"
unset ec0 ec1 ec2 ec3 ec4 ec5 ec6 ec7


:;: "Bootstrap Functions."
#
# Unset xtrace and prepare to restore state at the end of this
# section.
#
# Usage:
#     __xtrace_off__ [No arguments]
#     __reset_xtrace__  [No arguments]
#
: "Define functions: __xtrace_off__ & __reset_xtrace__."
__xtrace_off__ ()
{
  : "__xtrace_off__: Define function:  __reset_xtrace__."
  case $- in
    *x*)
      __reset_xtrace__ () { echo "# __reset_xtrace__"; set -x; }
      set +x
      ;;
    *)
      __reset_xtrace__ () { :; }
      ;;
  esac
}

: "Define function:  __check_for_variable_assignment__"
#
# Usage:
#     __check_for_variable_assignment__ [Variable]
#     __check_for_variable_assignment__ HOME
#
__check_for_variable_assignment__ ()
{
    #: "FUNCNAME:" "${FUNCNAME[@]}" #>

  if test -n "$1"
  then
    : "t:0:${LINENO}"
  else
    : "f:$?:${LINENO}"
    printf '%s: Input required; exiting.' "${FUNCNAME[0]}"
  fi

  # Bug, consolodate the various \unset -f\ commands.

  unset -f set grep 

  # Note, this particular function is used in \if...fi\ tests, so the
  # fact that it ends with a pipeline which could return false is
  # intended. However, as a standalone function, errexit, if the
  # variable at \$1\ has no assigned value, causes the script to
  # halt. To have halted would have been an error. Yet, it\s Posix
  # 2008, so the least confusing workaround has been applied.
  if set | grep -E "^${1}=.+"
  then
    : "t:0:${LINENO}"
  else
    : "f:$?:${LINENO}"
  fi
}

  # Testing:
  #__check_for_variable_assignment__ PATH
  #__check_for_variable_assignment__ TTY
  #exit "${LINENO}"

: "Define function:  __input_required__."
#
# Usage:    __input_required__ "$@"
#
__input_required__ ()
{
  if test 0 -lt "$#"
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    printf '%s: Input required.\n' "${special_var_zero}"
    printf '%s\n' "${usage_msg:?}" 1>&2
    exit 1
  fi
}

  # Testing
  #set --
  #set -- a b c
  #set -- a b c; shift 4 # Error: "shift count out of range"
  #set -- a b c; shift 3
  #__input_required__ "$@"
  #exit "${LINENO}"


:;: "Parse input."
#
  # Testing:
  #set -- -ve
  #set -- -br
  #set -- --verbos
  #set -- --brie
  #set -- -B
  #set -- -V

__input_required__ "$@"

: "\\case\\ on posparm 1."
case "$1" in
  --verbose | -[Vv]* | --[Vv]*)
    : "\\case\\ branch: \\--verbose\\."
    output_verbose_on=yes
    shift
    ;;
  --brief | -[Bb]* | --[Bb]* )
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

  #exit "${LINENO}" #>

__input_required__ "$@"

  #: "output_verbose_on: ${output_verbose_on}" #>
  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


:;: "Commands."
#
# Utilities & Special Builtins
#   Test string: \codeblocks\
#
# Remove the hash table, so that PATH lookups are forced and
# therefore current. Posix recommends \PATH=${PATH}\ in spec. on
# \hash\. In Bash on Fedoras 44 & 45, this recommendation works as
# expected even if PATH is set as RO.

  # Testing:
  #readonly PATH
  #set +e
  #enable -n hash
  #if ! PATH=${PATH}

# shellcheck disable=SC2269
if PATH=${PATH}
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"
  if command -v hash
  then
    : "t:0:${LINENO}"
    unset -f hash
    if hash -r
    then
      : "t:0:${LINENO}"
    else
      : "f:$?:${LINENO}"
      printf '%s: warning: command failed: <%s>\n' "hash -r"
    fi
  else
    : "f:$?:${LINENO}"
  fi
fi

# If xtrace is on, turn it off.
__xtrace_off__

  # Testing:
  #enable -n break

# Tests for each command
for uU in \
  "awk" "cd" "command" "dirname" "env" \
  "file" "find" "getconf" "grep" "id" \
  "ls" "pathchk" "printf" "ps" "pwd" \
  "sed" "sh" "strings" "test" "true" \
    "type" "unalias" "which" \
  ":" "break" "continue" "exit" "hash" \
    "readonly" "set" "shift" "unset" # count is 32
  #"codeblocks" #>
  # Note, \codeblocks\ is not specified by Posix-2008; the
  # rest of the commands in this list are, except for \which\.
do
    #> Just to see in which directory each utility is located.
    #which "${uU}"; continue #>
    #> Note
    #>   - At 32 commands, all non-special-builtins are located in
    #>     /usr/bin on Fedora 44.

  # Determine whether command \uU\ is in PATH.
  if command -pv "${uU}" >/dev/null
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec0:=$?}"
    printf '%s: Command is not in PATH:  <%s>\n' \
      "${special_var_zero}" "${uU}"
    global_return_code=${ec0}
  fi
  # Unset user functions
  unset -f "${uU}"
done

# If xtrace was on, restore it.
__reset_xtrace__

  # Bug, this block could be a function, doubling up with a similar
  # block farther down.

# If any of the commands were missing, then exit.
:;: "Test for value of \\global_return_code\\."
if test 0 -eq "${global_return_code}"
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"
    printf '%s: Value of PATH:  <%s>\n' \
      "${special_var_zero}" "${PATH}"
    printf '%s: Exiting.\n' "${special_var_zero}"
    exit "${global_return_code}"
fi

  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


:;: "Input validation: \\tr\\, \\strings\\ and \\pathchk\\."
#
for aA in "$@" '.' '..'
do
  :;: "Top of loop.";:

  # Input validation: Error and exit.
  #
  # Testing:
  #reset; clear; ./candr.sh -v \
  #"$( dd if=/dev/urandom bs=32b count=1 2>/dev/null )"
  #
  __xtrace_off__
  bB=$( printf '%s' "${aA}" | tr -d '\0'   ) # Remove NULs
  cC=$( printf '%s' "${bB}" | strings -n 1 ) # Remove nonprintable

  if test "X${aA}" = "X${cC}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec1:=$?}:${LINENO}"
    global_return_code=${ec1}
    printf '%s: Error: %s\n' "${special_var_zero}" \
      "Input contains one or more non-printable strings."
    break 1
  fi
  __reset_xtrace__

  # Zero length input is disallowed: Error and exit.
  #
  # Testing:
  #reset; clear; ./candr.sh -v ""
  #
  if test -n "${aA}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec1:=$?}:${LINENO}"
    global_return_code=${ec1}
    printf '%s: Error: %s\n' "${special_var_zero}" \
      "Zero length input."
    break 1
  fi

    #set -x #>

  # Filenames beginning with a hyphen are disallowed: Error and exit.
  #
  # Testing:
  #reset; clear; ./candr.sh -v -foo
  #
  stdout_04_cut=$( printf '%s' "${aA}" | cut -c 1 )
  if test "-" != "${stdout_04_cut}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec1:=$?}:${LINENO}"
    global_return_code=${ec1}
    printf '%s: %s\n' "${special_var_zero}" \
      "Filenames beginning with a hyphen are disallowed."
    break 1
  fi

  # Tests on filename length: Error and exit.
  #
  # \pathchk [no arguments]\ checks \each component of each pathname
  # of the underlying file system\ using PATH_MAX and NAME_MAX, for any
  # non-searchable directory, and for any character that is invalid in
  # its containing directory.
  #
  # On Fedora 45, the default values according to \getconf\:
  #   NAME_MAX                            255
  #   PATH_MAX                            4096
  #
  # Testing:
  #reset; clear; ./candr.sh -v foooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
  #
  if pathchk "${aA}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec1:=$?}:${LINENO}"
    global_return_code=${ec1}
    printf '%s: %s\n' \
      "${special_var_zero}" 'Error received from \pathchk\ (no options).'
    
    # Print out the values of the relevant variables.
    printf '%s: %s\n' \
      "${special_var_zero}" 'Values of relevant system parameters:'
    getconf -a | grep -Ee ^"PATH_MAX" -e ^"NAME_MAX"
    break 1
  fi

  # Filenames beginning with a hyphen are disallowed: Error and exit.
  #
  # Testing:
  #reset; clear; ./candr.sh -v /-foo
  #
  if pathchk -P "${aA}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec1:=$?}:${LINENO}"
    global_return_code=${ec1}
    printf '%s: %s\n' \
      "${special_var_zero}" 'Error received from \pathchk -P\.'
    break 1
  fi

done

if test 0 -eq "${global_return_code}"
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"
  printf '%s: Exiting.\n' "${special_var_zero}"
  exit "${global_return_code}"
fi
:;: "End of loop."

  #set -x #>
  #: exit "${LINENO}" #>


:;: "IF XTRACE IS ON -- Section on \\getconf\\."
#   BASH_ENV          # for \bash\
#   CDPATH            # for \cd\
#   ENV               # for \sh\
#   HOME              # for \cd\
#   LC_ALL            # Common
#   LD_PRELOAD        # for paranoia ;-P
#   NAME_MAX          # for \pathchk [no args]\
#   PATH_MAX          # for \cd\, \pathchk [no args]\ and \pwd\
#   OLDPWD            # for \cd\
#   PATH              # for \sh\
#   PWD               # for \cd\ and \pwd\
if printf '%s' "$-" | grep -q "x"
then
  : "t:0:${LINENO}"
 
    : "Parameter values per \\getconf\\" #>

  __xtrace_off__
  stdout_00_getconf_a=$( getconf -a )
  for eV in \
    BASH_ENV \
    CDPATH \
    HOME \
    LC_ALL \
    LD_PRELOAD \
    NAME_MAX \
    PATH_MAX \
    OLDPWD \
    PATH \
    PWD
  do
      #echo "eV: ${eV}" #>

    # Note, this particular \if..fi\ is a workaround for errexit.
    if printf '%s\n' "${stdout_00_getconf_a}" | grep -E "^${eV} "
    then
      : "t:0:${LINENO}"
    else
      : "f:$?:${LINENO}"
    fi
  done
  __reset_xtrace__
else : "f:$?:${LINENO}: Section on \\getconf\\: xtrace is off." #>
fi

  set -x #>
  : exit "${LINENO}" #>


:;: "Environment Variables."
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
for cC in BASH_ENV  ENV  LD_PRELOAD
do
  : "t:0:${LINENO}"

    #: "cC: ${cC}" #>

  if __check_for_variable_assignment__ "${cC}"
  then
    : "t:0:${LINENO}: ${cC} is defined."

    # Bug, \-v\ of \unset\ is specified, right?

    # Note, define \cmd_str\ as a particular invocation so that (a)
    # the command can be executed and so that (b) the various related
    # messages can cite the precise command string which was
    # executed.
    cmd_str="unset -v ${cC}"

    # Note, Word Splitting is intended in this particular command.
    if command -p ${cmd_str}
    then
      : "t:0:${LINENO}: \\${cmd_str}\\ returned zero"
    else
      printf '%s: Notice: %s\n' "${special_var_zero}" \
        "Command \\${cmd_str}\\ failed." #>
    fi
  else
    : "f:$?:${LINENO}: Parameter ${cC} is undefined."
  fi
done

# Make sure HOME is defined, for \cd\.
if __check_for_variable_assignment__ "HOME"
then
  : "t:0:${LINENO}" "Parameter HOME is defined."
else
  : "f:$?:${LINENO}: Parameter HOME is undefined."

  :;: "Assign HOME."
  username=$( id -un )
  if HOME=$(
        awk -F: -v "vV=${username}" '$1 == vV { print $6 }' \
          /etc/passwd
      )
  then
    : "t:0:${LINENO}: Assignment to HOME succeeded."
  else
    : "f:$?:${LINENO}"
    printf '%s: %s\n' "${special_var_zero}" \
      "Assignment to HOME failed; exiting."
    exit 1
  fi
fi

# PWD aught to be defined, for \cd\ and \pwd\
# Notes,
#   - In Posix-2008 effects of assignments to PWD are unspecified.
#   - If restricted mode is enabled and PWD is undefined, a call to
#     \cd\ will not assign a value to PWD, in Bash 5.3.9.
if __check_for_variable_assignment__ "PWD"
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"

    # Bug, citation?

  # A call to \cd\ is supposed to assign a value to PWD.
  # Note, \if..fi\ structure is a workaround for errexit.
  if cd .
  then
    : "t:0:${LINENO}"
  else
    : "f:$?:${LINENO}"
  fi

  if __check_for_variable_assignment__ "PWD"
  then
    : "t:0:${LINENO}"
  else
    : "f:$?:${LINENO}"
    printf '%s: Warning: %s.\n' \
      "${special_var_zero}" "Parameter PWD is undefined."
  fi
fi


: "Script Variables"
canpth=
nsfod="(No such file or directory)"
:
  set -x #>
  #printf '%s\n' stdout #>
  #printf '%s\n' stderr 1>&2 #>
  exit "${LINENO}" #>


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
    : "pound: <$#>" #>
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
      printf '%s: %b%s%b -> %s\n' \
        "${special_var_zero}" "\x27" "$1" "\x27" "$2"
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

  : "Per major loop variables."
  majloop_orig_str=${dD}
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
    stdout_01_file=$( file "${dD}" )

      exit "${LINENO}" #>
      #set -x #>


    : "Remove trailing forward slashes if doing so won\\t empty the var."



    :
    : "See whether \\file\\ says \\symbolic link\\."
    if printf '%s' "${stdout_01_file}" \
      | grep -q -E ': symbolic link to [/\.a-z]'
    then
      : "t:0:${LINENO}" #>

      :
      : "If so, then use \\sed\\ to get the resolved path."
      stdout_02_sed=$(
        printf '%s' "${stdout_01_file}" \
          | sed 's,.*: symbolic link to ,,'
        )

      :
      : "...and redefine \\dD\\ for the next iteration."
      dD=${stdout_02_sed}
    else
      printf '%s\n' "f:$?:${LINENO}" \
        "...otherwise, test if \\directory\\ is present in the string."
      if printf '%s' "${stdout_01_file}" \
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
            printf '%s\n' "f:$?:${LINENO}" \
              "\\test\\ passed but \\grep\\ failed. Error. Exiting."
            exit "${LINENO}"
          fi
        else
          printf '%s\n' "f:$?:${LINENO}" \
            "The new \\eE\\ is not the FS root directory; next iteration."
          continue 1
        fi
      else
        printf '%s\n' "f:$?:${LINENO}" \
          "The \\dirname\\ of \\eE\\ is not a directory."
        exit "${LINENO}"
      fi
    else
      printf '%s\n' "f:$?:${LINENO}" \
        "Error: \\eE\\ is not a directory. Exiting."
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
stdout_03_find=$( find "${canpth}" -prune -type d )

    exit "${LINENO}" #>
    #set -x #>

if test -n "${stdout_03_find}"
then
  : "t:0:${LINENO}" #>

  :
  : "See whether \\canpth\\ and \\stdout_03_find\\ are equivalent strings."
  if test "X${canpth}" = "X${stdout_03_find}"
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
    printf '%s\n' "f:$?:${LINENO}" \
      "\\canpth\\ and \\stdout_03_find\\ are not equivalent strings." 1>&2
    exit "${LINENO}"
  fi
else
  printf '%s\n' "f:$?:${LINENO}" \
    "\\find -type d\\ did not locate the directory." 1>&2
  exit "${LINENO}"
fi
