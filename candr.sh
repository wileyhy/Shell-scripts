#!/bin/env sh
# candr.xtrace / canonicalize-dir.sh
# shellcheck disable=SC2028,SC2268,SC2310,SC2329
#
#   Script is unfinished - 16 Nov 2026 WY
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
#   - Fedora 45: bash-5.3.15, dash-0.5.13.2, ksh-1.0.10,
#       mksh-59c-16, oksh-7.9-2, yash-2.61, zsh-5.9.2.




#_
#_  Notes:
#_  - BusyBox \grep\ does have \-q\ as of v.1.37.0. 
#_  - Variable \cmd_str\ is defined as a particular invocation so
#_  that (a) command execution and (b) the various related messages
#_  can all use or reference the precise same command string.
#_  - Re variables \local_posparm_one\ and similar: the variables
#_  are named \\local_\\, but the variables themselves are of global
#_  scope. Bug?
#_  - Re how filenames beginning with a hyphen are disallowed, see
#_  Posix 2008, General Concepts 4.7.
#_  - On Fedora 45, the default values according to \getconf\:
#_  NAME_MAX = 255; PATH_MAX = 4096
#_  - At 11/12, all non-builtins are located in /usr/bin on
#_  Fedora 45.
#_  - Variables of the form \ec1\ are used for transmitting the
#_  value of the exit code from the if list to \:\ into
#_  \global_return_code\.
#_  - Special Builtins per Posix 2008: break : continue . eval exec
#_  exit export readonly return set shift times trap unset
#_  - \codeblocks\ is not Posix at all, 2008-2024, and not installed.
#_  - Commands which are not Posix at all: \enable\ and \which\.
#_  - In Bash on Fedoras 44 & 45, \PATH=${PATH}\ removes the hash
#_  table as expected even if PATH is set as RO.
#_  - Redirections are applied before any expansions occur.
#_  - \#!/bin/env -i sh\ fails.
#_  - LINENO does exist in Posix 2008.
#_  - Reportedly, Solaris 10 uses a Bourne sh which is not Posix
#_  compliant.
#_      https://unix.stackexchange.com/questions/322035/\
#_        are-there-still-systems-around-with-a-bin-sh-binary
#_  - Reportedly, in Busybox \awk\ is optional.
#_  - When called from a restricted interactive shell, the script
#_  does not inherit the restricted setting.
#_  - Both \realpath\ and \readlink\ weren\t specified in Posix until
#_  2024.
#_  - The \-P\ option to \type\ is not portable.
#_  - The \pathchk\ utility offers three separate sets of tests;
#_  there is no overlap between said sets in the specification, but
#_  in GNU utilities there is.
#_  - The \-q\ option to \grep\ does exist in Posix 2008.
#_  - In Posix-2008, the handling of \//\ is intentionally
#_  implementation defined, so catch it, flag it as an error, and
#_  write a warning to Stderr. See spec. on \dirname\.
#_  - Defining directories with a trailing forward slash will
#_  effect whether \[[\, \test\, \[\ and \stat\ dereference
#_  symlinks. However, \realpath -e\ will still resolve such
#_  strings correctly.
#_  - The \-r\ option to \hash\ does exist in Posix 2008.
#_  - If PATH is set RO in the interactive calling shell, in the
#_  script PATH can still be altered.
#_  - For \readonly\ without arguments, the results are unspecified. In
#_  Bash, attempting in a script to assign a value to a RO variable is
#_  a fatal error, but that doesn\t appear to have been specified by
#_  Posix in 2008.
#_  - Names of special built-ins cannot be used as names of functions
#_  (ie, \unset\).
#_  - Option \-v\ of utility \unset\ is in fact specified in 2008.
#_  - The \!\ keyword doesn\t print in xtrace.
#_  - Reminder: don\t change the name of /etc/passwd. Bad things
#_  happen.
#_  - In Zsh...
#_    - \set +x\ within a function appears to be in local scope.
#_    - \command\ cannot find built-ins, apparently.
#_  - In Oksh, evidently, \hash\ is not available.
#_  - In Posix, \set -o posix\ DNE, in 2008 or 2024. Also, it appears
#_  that POSIXLY_CORRECT also DNE exist in Posix 2008 or 2024.
#_  - In Dash, \eval\ cannot accept the string \--\ to signify end
#_  of options.
#_  - Some shells exit an an attempted assignment to a RO variable:
#_    - Bash, ...
#_  - The POSIXLY_CORRECT environment variable is from Bash; it is
#_   not specified by Posix.
#_  - Per testing, the Special Variable zero is of global scope.
#_  - Re __check_for_variable_assignment__
#_  This particular function is used in \if...fi\ tests, so the
#_  fact that it ends with a pipeline which could return false is
#_  intended. However, as a standalone function, if the variable at
#_  \$1\ has no assigned value, or if the variable in question is not
#_  included in the output of \set\, then errexit causes the script to
#_  halt. To have halted would have been an error. Yet, it\s Posix
#_  2008, so the least confusing workaround has been applied.
#_

  #> Debug.
  #reset; clear; grep -v -F -e '#>' -e '#_' ./candr.xtrace 2>&1 | less -RNS
  \set -x #>
  \set -e #>
  \set -f #> Disable pathame expansion.
  #\: #>
  #\: "Dash: $-" #>
  #\: "Pound: $#" #>
  #\: "Ampersand:" "${@:-}" #>
  #\: "\$0: <$0>, <${0#./}> " #>
  #\: "\$1: ${1:-}" #>
  #\: "\$2: ${2:-}" #>
  #\: "\$LINENO: ${LINENO:-}" #>
  #\: "\$SHELL: ${SHELL:-}" #>
  #\exit "${LINENO}" #>
  #>

\:;\: "Security"
#
# Posix-2024 suggestion for \\Start off a \secure shell script\ in
# which the script avoids being spoofed by its parent,\\ as found in
# its spec. for \command\.
#
# Value of IFS should include one tabstop.
IFS=' 	
'
\unalias -a
#+ Workaround for errexit.
if unset -f command \
  grep hash set 2>/dev/null
then
  : "t:$?:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>
  : "Command \\unset\\ returned non-zero"
fi

# PATH could be set as RO.
if PATH="$( command -p getconf PATH ):${PATH}"
then
  : "t:$?:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>
  printf '%s: Notice: Assignment to variable failed: %s\n' \
    "$0" "PATH"
  printf '%s: Notice: Value of variable %s: <%s>\n' \
    "$0" "PATH" "${PATH}"
fi
  #>
  #exit "${LINENO}" #>
  #set -x #>


:;: "Settings"
POSIXLY_CORRECT=yes
set -a
set -u
set -C


:;: "Bootstrap Variables"
LC_ALL=C
global_return_code=0
special_variable_zero=${0#./}
special_variable_zero=${0##*/}
usage_msg="${special_variable_zero}:

  Usage: The first argument may be an option flag. If both -b and
  -v are present, the last one shall apply.
    
  "${special_variable_zero}" [-b|-h|-v|-V] [FILES] ...
    --brief     -b    Default format: '%s\n' [output]
    --help      -h    Print this message and exit. 
    --verbose   -v    Format: '%s: \"%s\" -> %s\n' \$0 [input] [output]
    --version   -V    Print version information and exit.
    --                End of options; let hyphens begin strings.
"
# These variables are in use locally.
unset -v \
  aA bB cC dD eE fF \
  ec0 ec1 ec2 ec3 ec4 ec5 ec6



:;: "Functions"

: "Define function:    __check_for_variable_assignment__" #>
# Usage:
#     __check_for_variable_assignment__ [Unexpanded variable name]
#     __check_for_variable_assignment__ HOME
#
__check_for_variable_assignment__ ()
{
  #+ This particular if..fi handles errexit.
  if set | grep -q -E -e "^${1}=.+" 2>/dev/null
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    : "Leaving __check_for_variable_assignment__" #>
    return 1
  fi
  : "Leaving __check_for_variable_assignment__";: #>
}

: "Define function:    __exit_per_global_return_code__" #>
# If the value of variable \global_return_code\ is non-zero, then
# exit.
#   Usage:
#       __exit_per_global_return_code__ [no arguments]
#
__exit_per_global_return_code__ ()
{
  if test 0 -eq "${global_return_code}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_stderr_notice__ "Exiting"
    exit "${global_return_code}"
  fi
  : "Leaving __exit_per_global_return_code__";: #>
}

: "Define function:    __input_required__" #>
# Usage:    __input_required__ "$@"
#
__input_required__ ()
{
  if test 0 -lt "$#"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_stderr_error__ "Input required"
    printf '%s\n' "${usage_msg:?}" 1>&2
    exit 1
  fi
  : "Leaving __input_required__";: #>
}

: "Define functions:   __print_stderr_error__" #>
# Usage:
#        __print_stderr_error__   [Description]         [Data]
#        __print_stderr_error__   "Zero length input" \
#                                    (Latter inputs can be omitted)
#
__print_stderr_error__   ()
{
  __xtrace_off__
  __print_stderr_message__ "Error"   "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_stderr_error__";: #>
}

: "Define function:    __print_stderr_message__" #>
# Usage:
#         __print_stderr_message__ [Message type] [Description] [Data]
#         __print_stderr_message__ "Warning"      "$1"          "${2:-}"
#         __print_stderr_message__ "Exiting" (Latter inputs can be omitted)
#
__print_stderr_message__ ()
{
  local_posparm_one=${1:-}
  local_posparm_two=${2:-}
  local_posparm_three=${3:-}

  if test -n "${local_posparm_one}"
  then
    : "t:$?:${LINENO}" #>
    local_posparm_one=": ${local_posparm_one}"
  else : "f:$?:${LINENO}" #>
  fi

  if test -n "${local_posparm_two}"
  then
    : "t:$?:${LINENO}" #>
    local_posparm_two=": ${local_posparm_two}"
  else : "f:$?:${LINENO}" #>
  fi

  if test -n "${local_posparm_three}"
  then
    : "t:$?:${LINENO}" #>
    local_posparm_three=": <${local_posparm_three}>"
  else : "f:$?:${LINENO}" #>
  fi

  printf '%s%s%s%s\n' 1>&2 \
    "${special_variable_zero}" \
    "${local_posparm_one}" \
    "${local_posparm_two}" \
    "${local_posparm_three}"

  # If the script is sourced, or \dot\ted in, then it might be
  # more useful if the script avoided having any side-effects on
  # the local execution environment.
  unset -v \
    local_posparm_one \
    local_posparm_two \
    local_posparm_three
  : "Leaving __print_stderr_message__";: #>
}

: "Define functions:   __print_stderr_notice__" #>
# Usage:
#        __print_stderr_notice__  [Description]   [Data]
#        __print_stderr_notice__  "Value of PATH" "${PATH}"
#
__print_stderr_notice__  ()
{
  __xtrace_off__
  __print_stderr_message__ "Notice"  "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_stderr_notice__";: #>
}

: "Define functions:   __print_stderr_warning__" #>
# Usage:
#         __print_stderr_warning__  [Description]     [Data]
#         __print_stderr_warning__  "Command failed"  "hash -r"
#
__print_stderr_warning__ ()
{
  __xtrace_off__
  __print_stderr_message__ "Warning" "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_stderr_warning__";: #>
}

: "Define function:    __print_results__" #>
# Usage:    __print_results__ [Script input] [canpth|nsfod] [redirection]
# Usage:    __print_results__ "${fF}" "${canpth}"
#                                         # ^normal output to STDOUT
# Usage:    __print_results__ "${fF}" "${nsfod}" >&2
#                                         # ^redirect output to STDERR
# shellcheck disable=SC2329
__print_results__ ()
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

  :;: "If error, then switch verbose on"
  if test 0 -eq "${global_return_code}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    output_verbose_on=yes
  fi

  :;: "\\case\\ on \\output_verbose_on\\"
  case "${output_verbose_on}" in
    yes | y )
      : "\\case\\ branch: \\yes\\" #>
      printf '%s: %b%s%b -> %s\n' \
        "${special_variable_zero}" "\x27" "$1" "\x27" "$2"
      ;;
    no | n )
      : "\\case\\ branch: \\no\\" #>
      printf '%s\n' "$2"
      ;;
    * )
      __print_stderr_error__ "Unreachable code" "Line:${LINENO}"
      exit 2
      ;;
  esac
    #>
    #exit "${LINENO}" #>
}

: "Define functions:   __reset_xtrace__" #>
# Usage:
#     __reset_xtrace__  [No arguments]
#
__reset_xtrace__ ()
{
  :
}

: "Define functions:   __xtrace_off__" #>
# Unset xtrace and prepare to restore state.
#   Usage:
#     __xtrace_off__ [No arguments]
#
__xtrace_off__ ()
{
  case $- in
    *x*) set +x; __reset_xtrace__ () { printf '# __reset_xtrace__\n'; set -x; }; ;;
    *) __reset_xtrace__ () { :; } ;;
  esac
  : "Leaving __xtrace_off__";: #>
}
  #> Debug
  # __print_stderr_notice__ "Exiting"
  # __print_stderr_error__ "Input contains one or more non-printable strings"
  # __print_stderr_warning__ "Command failed" "hash -r"
  # __print_stderr_notice__ "Value of PATH" "${PATH}"
  #exit "${LINENO}" #>
  #>
  #> Script Testing:
  # __check_for_variable_assignment__ PATH #>
  # __check_for_variable_assignment__ TTY #>
  #exit "${LINENO}" #>
  #>
  #> Script Testing
  #set -- #>
  #set -- a b c #>
  #set -- a b c; shift 4 #> Error: "shift count out of range"
  #set -- a b c; shift 3 #>
  # __input_required__ "$@" #>
  #exit "${LINENO}" #>


:;: "Parse input"
  #>
  #> Script Testing:
  #set -- -ve #>
  #set -- -br #>
  #set -- --verbos #>
  #set -- --brie #>

__input_required__ "$@"

: "\\case\\ on positional paramters of the script"
if test 0 -lt $#
then
  : "t:$?:${LINENO}"
  while true
  do
    case "$1" in
      --brief   | -b* | --b* )
        : "\\case\\ branch: \\--brief\\" #>
        output_verbose_on=no
        if shift 2>/dev/null
        then
          : "t:$?:${LINENO}"
          continue
        else
          : "f:$?:${LINENO}"
          break
        fi
        ;;
      --help    | -h* | --h* | -? )
        : "\\case\\ branch: \\--help\\" #>
        printf '%s\n' "${usage_msg:?}" 1>&2
        exit 1
        ;;
      --verbose | -v* | --verb* )
        : "\\case\\ branch: \\--verbose\\" #>
        output_verbose_on=yes
        if shift 2>/dev/null
        then
          : "t:$?:${LINENO}"
          continue
        else
          : "f:$?:${LINENO}"
          break
        fi
        ;;
      --version | -V* | --vers* )
        : "\\case\\ branch: \\--version\\" #>
        printf '%s\n' "${usage_msg:?}" 1>&2
        exit 1
        ;;
      -- )
        : "\\case\\ branch: \\--\\: let strings begin with hypens" #>
        output_verbose_on=no
        shift
        break
        ;;
      * )
        : "\\case\\ branch: no options: use default: \\--brief\\" #>
        output_verbose_on=no
        break
        ;;
    esac
  done
else
  : "f:$?:${LINENO}"
fi
  #>
  #exit "${LINENO}" #>

__input_required__ "$@"
  #>
  #: "output_verbose_on: ${output_verbose_on}" #>
  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


:;: "Commands"
print_value_of_path=no

# Remove the hash table, so that PATH lookups are forced and
# therefore current. Posix 2008 recommends \PATH=${PATH}\ in spec.
# on \hash\.
  #>
  #> Script Testing:
  #readonly PATH #>
  #set +e #>
  #enable -n hash #>
  #if ! PATH=${PATH} #>

# shellcheck disable=SC2269
if PATH=${PATH}
then
  : "t:$?:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>
  if command -v hash >/dev/null 2>&1
  then
    : "t:$?:${LINENO}" #>
    cmd_str="hash -r"

    if eval "${cmd_str}" 2>/dev/null
    then
      : "f:$?:${LINENO}" #>
      __print_stderr_warning__ "Command failed" "${cmd_str}"
    else : "t:$?:${LINENO}" #>
    fi
    unset cmd_str
  else
    : "f:$?:${LINENO}" #>
    print_value_of_path=yes
    __print_stderr_notice__ "Command is not in PATH" "hash"
  fi
fi

# If xtrace is on, turn it off.
__xtrace_off__
  #>
  #> Script Testing:
  #enable -n break #>
  #aA=codeblocks #>


  # Bug, these two loops are nearly the same: convert to a function.


# Utilities
#
for aA in \
  "awk" \
  "cd" \
  "command" \
  "dirname" \
  "echo" \
  "env" \
  "file" \
  "find" \
  "getconf" \
  "grep" \
  "id" \
  "logname" \
  "pathchk" \
  "printf" \
  "pwd" \
  "sed" \
  "sh" \
  "strings" \
  "test" \
  "true" \
  "unalias" \
  #>
  #> count is ?
  #>
do
    #> Just to see in which directory each utility is located.
    #which "${aA}" 2>/dev/null || command -v "${aA}" #>
    #continue #>
  if command -pv -- "${aA}" >/dev/null
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:${ec0:=$?}" #>
      #>
      #command -v -- "${aA}" ||: #>
      #>
    global_return_code=${ec0:=$?}
    print_value_of_path=yes
    __print_stderr_notice__ "Command is not in PATH" "${aA}"
  fi

  # Unset user functions
  #+ Workaround for errexit.
  cmd_str="unset -f"
  if eval "${cmd_str}" -- "${aA}" 2>/dev/null
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    : "Command \\${cmd_str}\\ returned non-zero"
  fi
  unset cmd_str
done
unset aA #>
  #>
  #exit "${LINENO}" #>

# If xtrace was on, restore it.
__reset_xtrace__

# Print the value of PATH if necessary.
if test "yes" = "${print_value_of_path}"
then
  : "t:$?:${LINENO}" #>
  __print_stderr_notice__ "Value of PATH" "${PATH}"
else : "f:$?${LINENO}" #>
fi

# Built-ins: Special and Regular
#
for bB in \
  "break" \
  ":" \
  "continue" \
  "eval" \
  "exit" \
  "readonly" \
  "return" \
  "set" \
  "shift" \
  "unset"
do
  if command -v -- "${bB}" >/dev/null
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:${ec1:=$?}" #>
    global_return_code=${ec1:=$?}
    __print_stderr_notice__ "Built-in is not available" "${bB}"
  fi

  # Unset user functions
  #+ Workaround for errexit.
  cmd_str="unset -f"
  if eval "${cmd_str}" -- "${bB}" 2>/dev/null
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    : "Command \\${cmd_str}\\ returned non-zero"
  fi
  unset cmd_str
done
unset bB #>
  #>
  #exit "${LINENO}" #>


# If any of the commands were missing, then exit.
__exit_per_global_return_code__
  #>
  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


:;: "Input validation: \\tr\\, \\strings\\ and \\pathchk\\"
#
    #>
    #> Script Testing:
    #reset;clear #>
    #./candr.xtrace "$(dd if=/dev/urandom bs=32b count=1 2>/dev/null)" #>
    #>
    #>
    #> Script Testing:
    #reset; clear; ./candr.xtrace -v "" #>
    #>
    #>
    # Script Testing: #>
    #reset; clear; ./candr.xtrace -v -foo #>
    #>
    #>
    #> Script Testing:
    #reset; clear; ./candr.xtrace -v foooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo #>
    #>
    #>
    # Script Testing: #>
    #reset; clear; ./candr.xtrace -v /-foo #>
    #>
for cC in "$@"
do
    :;: "Top of loop";: #>
    #>
  __xtrace_off__

  # Remove NULs and nonprintable bytes.
  stdout_00_tr_d=$( printf '%s' "${cC}" | tr -d '\0' )
  stdout_01_strings_n1=$(
    printf '%s' "${stdout_00_tr_d}" | strings -n 1
  )

  if test "X${cC}" = "X${stdout_01_strings_n1}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:${ec2:=$?}:${LINENO}" #>
    global_return_code=${ec2:=$?}
    __print_stderr_error__ \
        "Input contains one or more non-printable strings"
    break 1
  fi

  __reset_xtrace__

  # Zero length input is disallowed.
  if test -n "${cC}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:${ec3:=$?}:${LINENO}" #>
    global_return_code=${ec3:=$?}
    __print_stderr_error__ "Zero length input"
    break 1
  fi
    #>
    #set -x #>

  # Tests on filename length.
  #
  # \pathchk [no arguments]\ checks \\each component of each pathname
  # of the underlying file system\\ using PATH_MAX and NAME_MAX, for any
  # non-searchable directory, and for any character that is invalid in
  # its containing directory, under Posix 2008.
  #
  if pathchk -- "${cC}"
  then
    : "t:$?:${LINENO}" #>
  else 
    : "f:${ec4:=$?}:${LINENO}" #>
    global_return_code=${ec4:=$?}
    __print_stderr_error__ \
      "Error received from \\pathchk [no args]\\" "${cC}"

    # Print the values of the relevant variables.
    __print_stderr_notice__ "Values of relevant system parameters"
    getconf -a | grep -E -e ^"PATH_MAX" -e ^"NAME_MAX"
    break 1
  fi

  # Filenames beginning with a hyphen are disallowed, part 1\2.
  stdout_02_cut=$( printf '%s' "${cC}" | cut -c 1 )

  if test "-" != "${stdout_02_cut}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:${ec5:=$?}:${LINENO}" #>
    global_return_code=${ec5:=$?}
    __print_stderr_error__ \
      "Filenames beginning with a hyphen are disallowed" "${cC}"
    break 1
  fi

  # Filenames beginning with a hyphen are disallowed, part 2\2.
  if pathchk -P -- "${cC}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:${ec6:=$?}:${LINENO}" #>
    global_return_code=${ec6:=$?}
    __print_stderr_error__ \
      "Error received from \\pathchk -P\\" "${cC}"
    __print_stderr_error__ \
      "Filenames beginning with a hyphen are disallowed" "${cC}"
    break 1
  fi
done
unset -v \
  cC \
  stdout_00_tr_d \
  stdout_01_strings_n1 \
  stdout_02_cut
:;: "End of loop" #>

# If any input validation problems occurred, then exit.
__exit_per_global_return_code__
  #>
  #set -x #>
  #: exit "${LINENO}" #>


  # Bug, this list of environment variables is incomplete.


#> DEBUG BLOCK -- To be run only if xtrace is enabled.
#>
:;: "Section on \\getconf\\" #>
#>  _POSIX_NO_TRUNC   # for Pathname Resolution
#>  BASH_ENV          # for \bash\
#>  BLOCK_SIZE        # for GNU Coreutils
#>  BLOCKSIZE         # for GNU Coreutils
#>  CDPATH            # for \cd\
#>  ENV               # for \sh\
#>  HOME              # for \cd\
#>  LC_ALL            # Common
#>  LD_PRELOAD        # for paranoia ;-P
#>  LOGNAME           # for ?
#>  NAME_MAX          # for \pathchk [no args]\ and Pathname Resolution
#>  PATH_MAX          # for \cd\, \pathchk [no args]\ and \pwd\
#>  OLDPWD            # for \cd\
#>  PATH              # for \sh\
#>  POSIXLY_CORRECT   # for GNU Coreutils
#>  PWD               # for \cd\ and \pwd\
#>  SYMLOOP_MAX       # for \chdir()\
#>
if printf '%s' "$-" | grep -q -e "x" #>
then #>
  : "t:$?:${LINENO}" "Parameter values per \\getconf\\" #>
  __xtrace_off__; set +x #>
  stdout_03_getconf_a=$( getconf -a ) #>
  #>
  for dD in _POSIX_NO_TRUNC BASH_ENV CDPATH ENV HOME LC_ALL LD_PRELOAD NAME_MAX PATH_MAX OLDPWD PATH PWD SYMLOOP_MAX #>
  do #>
      #echo "dD: ${dD}" #>
    #+ Note, this particular \if..fi\ is a workaround for errexit
    #+ and xtrace visibility.
    if printf '%s\n' "${stdout_03_getconf_a}" | grep -E -e "^${dD} " #>
    then : "t:$?:${LINENO}" #>
    else : "f:$?:${LINENO}" #>
    fi #>
  done #>
  unset dD #>
  __reset_xtrace__ #>
else
  echo "f:$?:${LINENO}" "Section on \\getconf\\: xtrace is off" #>
fi #>
unset -v stdout_03_getconf_a #>
  #>
  #set -x #>
  #: exit "${LINENO}" #>
  #>

:;: "Unset Environment Variables"
  #>
  #> Script Testing:
  #POSIXLY_CORRECT=yes #>
  #LD_PRELOAD=foo #>
  #eE=LD_PRELOAD #>
  #set | grep -E "^${eE}=.+"; echo $? #>
  #unset LD_PRELOAD; echo $? #>
  #set | grep -E "^${eE}=.+"; echo $? #>
  #LD_PRELOAD=x #>
  #>
for eE in \
  BASH_ENV \
  CDPATH \
  ENV \
  LD_PRELOAD \
  OLDPWD
do
    #: "eE: ${eE}" #>
    #>
  # It would seem obvious to use \test -n\ and a loop, but doing
  # so would be problematic under Posix 2008 due to there being
  # multiple layers of expansion. Using a function allows the
  # regular expression to be defined in just one place.
  if __check_for_variable_assignment__ "${eE}"
  then
    : "t:$?:${LINENO}" "${eE} is defined" #>
    # shellcheck disable=SC2016
    cmd_str='unset -v -- "${eE}"'

    if eval "${cmd_str}"
    then
      : "t:$?:${LINENO}" "\\${cmd_str}\\ returned zero" #>
      if __check_for_variable_assignment__ "${eE}"
      then
        : "t:$?:${LINENO}" #>
        __print_stderr_error__ "${eE} is defined"
        exit 1
      else : "f:$?:${LINENO}" "${eE} is undefined / zero length";: #>
      fi
    else
      : "f:$?:${LINENO}" #>
      __print_stderr_notice__ \
        "Command \\unset\\ failed" "\\${cmd_str}\\"
    fi
    unset cmd_str
  else : "f:$?:${LINENO}" "${eE} is undefined or of zero length";: #>
  fi
done
unset eE
  #>
  #set -x #>
  : exit "${LINENO}" #>
  #>
  #> Script Testing
  #unset PWD #>
  #unset HOME #>
  #unset USER #>
  #>
  #HOME=/ #>
  #HOME=~/nonexistent.d #>
  #HOME=~/nonexistent.sym #>
  #HOME=~/existent.d #>
  #HOME=~/existent.sym #>
  #HOME="" #>
  #HOME=$'\0' #>
  #HOME='.+' #>
  #HOME=. #>
  #HOME=.. #>
  #unset HOME
  #HOME=~ #>
  #HOME=~root #>
  #readonly HOME #>


:;: "Make sure HOME is defined, for \\cd\\"
#_
#_  Notes,
#_    - Assigning PWD depends on HOME having a valid value. 
#_      ^^^ Is this statement accurate??
#_      - \PWD\: \\An absolute pathname of the current working
#_      directory. If an application sets or unsets the value of PWD,
#_      the behavior of \pwd\ is unspecified.\\ - spec. on \pwd\.
#_    - From Posix 2008:
#_      - Shell Command Language 2.6.1: \\If HOME is unset, the results
#_      are unspecified.\\
#_    - The \id\ utility has no knowledge of \sudo\ or means of
#_    differentiating regular vs. elevated permissions.
#_    - If the name of /etc/passwd is changed, \id\ throws an error.
  #>
  #set -x #>

# Is the existing variable HOME set as RO?
stdout_04_readonly_awk=$(
  readonly -p \
    | awk \
      '{
        split($0, arr)
        for (a in arr) {
          if(arr[a] ~ /^HOME=/) {
            printf("%s\n", arr[a])
          }
        }
      }'
    )
if test -n "${stdout_04_readonly_awk:-}"
then
  : "t:$?:${LINENO}" #>
else
  : "f:0:${LINENO}" #>
  assign_variable=no

  : "Define function:  __make_sure_variable_is_defined_properly__"
  #>
  #> If any of the tests fail, then \assign_variable\ should be \yes\.
  #>
  #> If all of the tests succeed, and the variable is a searchable
  #> directory, then operand number two contains the value which should
  #> be assigned to the variable \assign_variable\. See
  #> \eval test -x\.
  #>
  #> Usage:
  #>  __make_sure_variable_is_defined_properly__ \
  #>          [Unexpanded variable name] [affirmative|negative|yes]
  #>
  #>  Valid values for $2 are:
  #>                            tests       change var
  #>                          ##########################
  #>              affirmative # passed      do change
  #>              negative    # passed      do not change
  #>              yes         # failed      do change
  #>
  #>
  #> Existing commandlines:
  #>
  #>   __make_sure_variable_is_defined_properly__ \
  #>       "HOME" "negative"
  #>
  #>           Var HOME could have values of yes or negative
  #>
  #>   __make_sure_variable_is_defined_properly__ \
  #>       "confirmed_home" "affirmative"
  #>
  #>           Var confirmed_home could have values of yes or affirmative
  #>
  #>   __make_sure_variable_is_defined_properly__ \
  #>       "found_home" "affirmative"
  #>
  #>           Var found_home could have values of yes or affirmative
  #>
  __make_sure_variable_is_defined_properly__ ()
  {
    if __check_for_variable_assignment__ "$1"
    then
      : "t:$?:${LINENO}" "Parameter $1 is defined" #>
      if test -n "$1" # Confirmation test
      then
        : "t:$?:${LINENO}" "Result confirmed" #>
        if eval test -e '$'"$1"
        then
          : "t:$?:${LINENO}" "Filesystem object exists" #>
          if eval test -d '$'"$1"
          then
            : "t:$?:${LINENO}" "Filesystem object is a directory" #>
            if eval test -x '$'"$1"
            then
              : "t:$?:${LINENO}" "Directory is searchable" #>
              assign_variable="$2__$1"
            else
              : "f:0:${LINENO}" "Directory is not searchable" #>
              assign_variable="yes__$1"
            fi
          else
            : "f:0:${LINENO}" "Filesystem object is not a directory" #>
            assign_variable="yes__$1"
          fi
        else
          : "f:0:${LINENO}" "Filesystem object DNE" #>
          assign_variable="yes__$1"
        fi
      else
        : "f:0:${LINENO}" #>
        assign_variable="yes__$1"
        __print_stderr_error__ "Conflicting data" "Line:${LINENO}"
        # __print_stderr_notice__ "Exiting"
        exit 2
      fi
    else
      : "f:0:${LINENO}" "Parameter $1 is undefined" #>
      assign_variable="yes__$1"
    fi
    : "Leaving __make_sure_variable_is_defined_properly__'";: #>
  }

  __make_sure_variable_is_defined_properly__ \
      "HOME" "negative"
  #_ Note,
  #_   Possible values for \alter_original_home_value\ are:
  #_   - negative__HOME, or
  #_   - yes__HOME
  #_
  alter_original_home_value="${assign_variable}"
  unset assign_variable
    #>
    #set -x #>
    : exit "${LINENO}" #>

  #_ Note,
  #_   - Spec. on \logname\: \\The logname utility explicitly ignores
  #_   the LOGNAME environment variable because environment changes
  #_   could produce erroneous results.\\
  #_   - Therefore, use \logname\.
  #_
  #_ Question, These commands produce different results. Why?
  #_       sudo sh -c 'eval echo ~"$( logname )"' sh
  #_       sudo sh -c 'eval echo ~"${LOGNAME}"' sh

  :;: "Confirm the value of HOME in two different ways, if possible"
  #
  # Get the HOME directory via Tilde Expansion.
  #
  #+  Note, Workaround for errexit and xtrace visibility, as
  #+  throughout.
  if stdout_05_tilde_exp=$( eval echo ~"$( logname )" )
  then
    : "t:$?:${LINENO}" #>
    : "Tilde expansion succeeded"
  else
    : "f:$?:${LINENO}" #>
    : "Tilde expansion failed"
  fi

  # Get the HOME directory from /etc/passwd.
  if test -f /etc/passwd
  then
    : "t:$?:${LINENO}" #>
    stdout_06_id_un=$( id -un )

    if grep -q "${stdout_06_id_un}" /etc/passwd
    then
      : "t:$?:${LINENO}" #>
      #+ Workaround for errexit and xtrace visibility.
      if stdout_07_awk_etc_passwd=$(
           awk -F: -v usrnm="${stdout_06_id_un}" \
             '$1 == usrnm { print $6 }' /etc/passwd
           )
      then
        : "t:$?:${LINENO}" #>
        : "\\awk\\ succeeded"
      else
        : "f:$?:${LINENO}" #>
        : "\\awk\\ failed"
      fi
    else
      : "f:$?:${LINENO}" #>
      __print_stderr_error__ \
        "Username is not present in /etc/passwd " "${stdout_06_id_un}"
      # __print_stderr_notice__ "Exiting"
      exit 1
    fi
  else
    : "f:$?:${LINENO}" #>
    __print_stderr_error__ "...there are systems without \"/etc/passwd\"???"
    __print_stderr_notice__ "Exiting"
    exit 2
  fi
    #>
    #set -x #>
    : exit "${LINENO}" #>

  # Check for conflicting results.
  #_ Note, in theory, both variables could be of zero length.
  if test "X${stdout_05_tilde_exp}" = "X${stdout_07_awk_etc_passwd}"
  then
    : "t:$?:${LINENO}" "Result confirmed" #>
    confirmed_home=${stdout_05_tilde_exp}
    found_home=NA
  else
    : "f:$?:${LINENO}" #>
    __print_stderr_notice__ "Conflicting data" "Line:${LINENO}"
    confirmed_home="::Conflicting_data::"
    found_home=""
    #_
    #_  Note,
    #_    If the data is incongruent, then which variable does the
    #_  script use? Whichever one exists?
    #_    Tilde Expansion is specified.
    #_    The GNU Coreutils 9.11 version of \id\ requires
    #_  /etc/passwd, but that doesn\t necessarily mean that other
    #_  implementations do also. The Posix 2008 spec. of \id\ doesn\t
    #_  mention /etc/passwd at all.
    #_    So prefer data from Tilde Expansion.
    #_
    if test -n "${stdout_05_tilde_exp}"
    then
      : "t:$?:${LINENO}" #>
      found_home=${stdout_05_tilde_exp}
    else
      : "f:$?:${LINENO}" #>
      if test -n "${stdout_07_awk_etc_passwd}"
      then
        : "t:$?:${LINENO}" #>
        found_home=${stdout_07_awk_etc_passwd}
      else
        : "f:$?:${LINENO}" #>
        found_home="::No_valid_values_were_found::"
        __print_stderr_warning__ "Value not found" "HOME"
        exit 2
      fi
    fi
  fi

  # Check the new data for validity.
  if test -n "${confirmed_home}"
  then
    : "t:$?:${LINENO}" #>
    __make_sure_variable_is_defined_properly__ \
        "confirmed_home" "affirmative"
    #_
    #_ Note, possible values for \alter_confirmed_home_value\ are:
    #_   - affirmative__confirmed_home, or
    #_   - yes__confirmed_home
    #_
    alter_confirmed_home_value="${assign_variable}"
    alter_found_home_value="no"
    unset assign_variable
  else
    : "f:$?:${LINENO}" #>
    alter_confirmed_home_value="yes"
    alter_found_home_value=""
    if test -n "${found_home}"
    then
      : "t:$?:${LINENO}" #>
      __make_sure_variable_is_defined_properly__ \
          "found_home" "affirmative"
      #_ Note,
      #_   Possible values for \alter_found_home_value\, are:
      #_   - affirmative__found_home, or
      #_   - yes__found_home
      #_
      alter_found_home_value="${assign_variable}"
      unset assign_variable
    else
      : "f:$?:${LINENO}" #>
      __print_stderr_notice__ \
          "Data from both sources are of zero length" "Line:${LINENO}"
    fi
  fi
    :;: #>
    : "HOME: ${HOME:-}" #>
    : "alter_original_home_value: ${alter_original_home_value:-}" #>
    : "confirmed_home: ${confirmed_home:-}" #>
    : "alter_confirmed_home_value: ${alter_confirmed_home_value:-}" #>
    : "found_home: ${found_home:-}" #>
    : "alter_found_home_value: ${alter_found_home_value:-}" #>
    #exit "${LINENO}" #>

    #_ Note,
    #_   Var  HOME             could have values of  yes   or  negative
    #_   Var  confirmed_home   could have values of  yes   or  affirmative
    #_   Var  found_home       could have values of  yes   or  affirmative

  # Assign HOME accordingly.
  #_ Do HOME and \confirmed_home\ have the same value?
  if test "${HOME:=}" = "${confirmed_home}"
  then
    : "t:$?:${LINENO}" #>
    #_ Yes, HOME and \confirmed_home\ have the same value.
    #_
    #_ Did HOME pass all of the tests?
    if test "negative__HOME" = "${alter_original_home_value}"
    then
      : "t:$?:${LINENO}" #>
      #_ Yes, HOME passed all of the tests.
      #if HOME=${HOME}; then : "t:$?:${LINENO}"; else : "f:$?:${LINENO}"; fi #>
      #_ Done
    else
      : "f:$?:${LINENO}" #>
      #_ No, HOME failed some of the tests.
      #_
      #_ But HOME is equivalent to \confirmed_home\, so you cannot use
      #_ that value either.
      #_
      #_ Did the third variable, \found_home\, pass all of the tests?
      if test "affirmative__found_home" = "${alter_found_home_value}"
      then
        : "t:$?:${LINENO}" #>
        #_ Yes, \found_home\ passed all of the tests.
        if HOME=${found_home}
        then : "t:$?:${LINENO}"
        else : "f:$?:${LINENO}"
        fi
        #_ Done
      else
        : "f:$?:${LINENO}" #>
        #_ No, \found_home\ failed some of the tests.
        #_
        #_ So none of the possible values for HOME passed all of the
        #_ tests.
        #_
        #_ So use the filesystem root directory. Rationale below.
        if HOME="/"
        then : "t:$?:${LINENO}"
        else : "f:$?:${LINENO}"
        fi
        #_ Done
      fi
    fi
  else
    : "f:$?:${LINENO}" #>
    #_ No, HOME and \confirmed_home\ do NOT have the same value.
    #_
    #_ Did HOME pass all of the tests?
    if test "negative__HOME" = "${alter_original_home_value}"
    then
      : "t:$?:${LINENO}" #>
      #_ Yes, HOME passed all of the tests.
      #_
      #_ But, HOME and \confirmed_home\ do not have the same value.
      #_
      #_ So, did \confirmed_home\ pass all of the tests?
      if test "affirmative__confirmed_home" = "${alter_confirmed_home_value}"
      then
        : "t:$?:${LINENO}" #>
        #_ Yes, \confirmed_home\ passed all of the tests.
        #_
        #_ So both values passed all of the tests.
        #_
        # __print_stderr_warning__ "Conflicting data" "Line:${LINENO}"
        #_ If \found_home\ also passed all of the tests, then use that
        #_ one because \found_home\ is based on /etc/passwd.
        #_
        #_ Did \found_home\ pass all of the tests?
        if test "affirmative__found_home" = "${alter_found_home_value}"
        then
          : "t:$?:${LINENO}" #>
          #_ Yes, \found_home\ passed all of the tests.
          if HOME=${found_home}
          then : "t:$?:${LINENO}"
          else : "f:$?:${LINENO}"
          fi
          #_ Done
        else
          : "f:$?:${LINENO}" #>
          #_ No, \found_home\ failed some of the tests.
          #_
          #_ Between both verified values HOME and \confirmed_home\,
          #_ which should be used: the one set by the user or the one
          #_ identified by Tilde Expansion?
          #_
          #_ The one set by the user could be malicious, so use the
          #_ one identified by Tilde Expansion: \confirmed_home\.
          if HOME=${confirmed_home}
          then : "t:$?:${LINENO}"
          else : "f:$?:${LINENO}"
          fi
          #_ Done
        fi
      else : "f:$?:${LINENO}" #>
        #_ No, \confirmed_home\ failed some of the tests.
        #_
        #_ Since HOME passed all of the tests, and since HOME and
        #_ \confirmed_home\ do not have the same value, keep the
        #_ current value of HOME.
        #if HOME=${HOME}; then : "t:$?:${LINENO}"; else : "f:$?:${LINENO}"; fi #>
        #_ Done
      fi
    else
      : "f:$?:${LINENO}" #>
      #_ No, HOME failed some of the tests.
      #_
      #_ Since HOME and \confirmed_home\ do not have the same value,
      #_
      #_ Did \confirmed_home\ pass all of the tests?
      if test "affirmative__confirmed_home" = "${alter_confirmed_home_value}"
      then
        : "t:$?:${LINENO}" #>
        #_ Yes, \confirmed_home\ passed all of the tests.
        if HOME=${confirmed_home}
        then : "t:$?:${LINENO}"
        else : "f:$?:${LINENO}"
        fi
        #_ Done.
      else
        : "f:$?:${LINENO}" #>
        #_ No, \confirmed_home\ failed some of the tests.
        #_
        #_ So both HOME and \confirmed_home\ failed some of the tests.
        #_
        #_ Did \found_home\ pass all of the tests?
        if test "affirmative__found_home" = "${alter_found_home_value}"
        then
          : "t:$?:${LINENO}" #>
          #_ Yes, \found_home\ passed all of the tests.
          if HOME=${found_home}
          then : "t:$?:${LINENO}"
          else : "f:$?:${LINENO}"
          fi
          #_ Done.
        else
          : "f:$?:${LINENO}" #>
          #_ No, \found_home\ failed some of the tests.
          #_
          #_ So all three values failed some of the tests.
          #_
          #_ So then which value should be used?
          #_   - The invalid value from the user,
          #_   - The invalid value from Tilde Expansion, or
          #_   - The invalid value from /etc/passwd?
          #_
          #_ It depends on how each value failed the tests.
          #_
          #_ If any value failed with reason \.*__nosrch\, then use
          #_ that value.
          #_
          #_ But, why on earth would a HOME directory not be
          #_ searchable by USER??
          #_
          #_ ...yeah, there really isn\t a good reason why a value of
          #_ HOME would be non-searchable directory. Yeah, no.
          #_
          #_ So use the NUL string? Use the filesystem root?
          #_
          #_ Honestly, the filesystem root might be the best choice.
          #_ At least it\s guaranteed to always exist, as far as I
          #_ know.
          if HOME="/"
          then : "t:$?:${LINENO}"
          else : "f:$?:${LINENO}"
          fi
        fi
      fi
    fi
  fi
    #>
    #set -x #>
    : "HOME: ${HOME}" #>
    #exit 101 #"${LINENO}" #>
    #>
fi
unset -v \
  stdout_04_readonly_awk \
  stdout_05_tilde_exp \
  stdout_06_id_un \
  stdout_07_awk_etc_passwd
  #>
  #exit "${LINENO}" #>


:;: "PWD aught to be defined, for \\cd\\ and \\pwd\\"
#_ Notes,
#_   - In Posix-2008 effects of assignments to PWD are unspecified.
#_   - In Bash 5.3.9+,
#_     - If restricted mode is enabled and PWD is undefined, a call to
#_     \cd\ will not assign a value to PWD.
#_     - Values of HOME and PWD are inherited from the calling
#_     interactive shell.
if __check_for_variable_assignment__ "PWD"
then
  : "t:$?:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>

  #_ A call to \cd\ is supposed to assign a value to PWD.
  #_
  #_ Notes, from Posix 2008:
  #_  - Shell Command Language 2.6.1: \\If HOME is unset, the results
  #_  are unspecified.\\
  #_  - Spec. of \cd\, description of algorithm:
  #_    - (Step 1) \\If no directory operand is given and the HOME
  #_    environment variable is empty or undefined, the default
  #_    behavior is implementation-defined and no further steps
  #_    Shall be taken.\\
  #_      -- HOME aught to be defined.
  #_      -- A directory operand aught to be used.
  #_    - (Step 2) \\If no directory operand is given and the HOME
  #_    environment variable is set to a non-empty value, the cd
  #_    utility Shall behave as if the directory named in the HOME
  #_    environment variable was specified as the directory
  #_    operand.\\
  #_    - (Step 3) \\If the directory operand begins with a <slash>
  #_    character, set curpath to the operand and proceed to step 7.\\
  #_    - (Step 4) \\If the first component of the directory operand
  #_    is dot or dot-dot, proceed to step 6.\\
  #_    - (Step 6) \\If the -P option is in effect, set curpath to
  #_    the directory operand. Otherwise....\\
  #_      -- Use the -P option.
  #_    - (Step 7) \\If the -P option is in effect, proceed to step
  #_    10.\\
  #_    - (Step 10) \\The cd utility Shall then perform actions
  #_    equivalent to the chdir() function called with curpath as
  #_    the path argument. If these actions fail for any reason, the
  #_    cd utility Shall display an appropriate error message and the
  #_    remainder of this step Shall not be executed. ... If the -P
  #_    option is in effect, the PWD environment variable Shall be
  #_    set to the string that would be output by pwd -P. If there is
  #_    insufficient permission on the new directory, or on any
  #_    parent of that directory, to determine the current working
  #_    directory, the value of the PWD environment variable is
  #_    unspecified.\\
  #_      -- Any error message aught to be assigned to a variable.
  #_      -- The output of \pwd -P\ is relevant.
  #_    - \-P\: \\Handle the operand dot-dot physically; symbolic
  #_    link components Shall be resolved before dot-dot components
  #_    are processed.\\
  #_    - SYNOPSIS:
  #_      - \\cd [-L|-P] [directory]\\
  #_        - \directory\: \\An absolute or relative pathname of the
  #_        directory that Shall become the new working directory.
  #_        The interpretation of a relative pathname by cd depends
  #_        on the -L option and the CDPATH and PWD environment
  #_        variables. If directory is an empty string, the results
  #_        are unspecified.\\
  #_
  #_  - Posix 2008 \pwd\:
  #_    - \\The pwd utility Shall write to standard output an
  #_    absolute pathname of the current working directory, which
  #_    does not contain the filenames dot or dot-dot.\\
  #_    - \-P\: \\The pathname written to standard output Shall not
  #_    contain any components that refer to files of type symbolic
  #_    link.\\
  #_    - \PWD\: \\An absolute pathname of the current working
  #_    directory. If an application sets or unsets the value of PWD,
  #_    the behavior of pwd is unspecified.\\
  #+  - This \if..fi\ structure is a workaround for errexit and
  #+  xtrace visibility
  if stderr_cd_P=$( cd -- "${HOME}"; cd -P -- . 2>&1 >/dev/null )
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_stderr_error__ "Command \\cd\\ failed" "cd; cd -P ."
    # __print_stderr_notice__ "Exiting"
    exit 1
  fi

  if __check_for_variable_assignment__ "PWD"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>

    # Bug, try also \pwd -P\

    __print_stderr_warning__ "Parameter is undefined" "PWD"
  fi
fi


:;: "Script Variables"
canpth=""
nsfod="(No such file or directory)"
  #>
  #set -x #>
  #printf '%s\n' stdout #>
  #printf '%s\n' stderr 1>&2 #>
  #:;: set #>
  #set | grep -E -e '^HOME=' -e '^PWD=' #>
  #exit "${LINENO}" #>


  #>
  #set -x #>
  #exit "${LINENO}" #>
  #set -x #>


:;: "The given path must exist in the filesystem"
#> Script Test input: /dev/qwertyuiop
for fF
do
  if test -e "${fF}"
  then
    : "t:$?:${LINENO}" "Path exists" #>
  else
    : "f:$?:${LINENO}" #>
    global_return_code=1
    __print_results__ "${fF}" "${nsfod}" >&2
    continue 1
  fi
done
unset fF


  # Buggy - rewrite script from this point on.
  #
  # See Posix 2008, Base Definitions, General Concepts,
  #   4.13 Pathname Resolution
  #
  # Requirements:
  # - \\existing directory entry\\
  # - ID predecessor directory.
  #   - If ID is inconclusive, 
  #     - then the process fails and errors out.
  #   - if pathname begins with a (forward-)slash \/\, 
  #     - then the predecessor of 1st filename in the pathname is
  #     taken to be FS root: \/\.
  #   - if pathname does not begin with a slash \/\,
  #     - then the predecessor of 1st filename in the pathname is
  #     taken to be either:
  #       - \A\, the current working directory, or
  #       - \B\, for \\certain processes\\ ...??... the directory
  #       identified by a file descriptor. ???
  #   - if any pathname component, ie filename, is longer than 
  #   NAME_MAX, 
  #     - then the process fails and errors out.
  #   - if pathname contains at least one non-slash character, and
  #   ends with one or more trailing slash characters, then the last
  #   pathname component before the trailing slash character(s) must
  #   be an existing directory.
  #     - or the process fails and errors out.
  #   - If a symbolic link is encountered during pathname resolution, 
  #     - then behavior Shall depend on: 
  #       - \A\, whether the pathname component is at the end of the
  #       component, and
  #       - \B\, on the function being performed. 
  #     - If all three of these are true, then pathname resolution
  #     succeeds:
  #       - \1\, The symbolic link is the last pathname component of
  #       the pathname, 
  #       - \2\, The pathname does not have any trailing slashes, and
  #       - \3\, The function is required to or allowed to return as
  #       output the symbolic link itself. (ie, an \-L\, or \logical\
  #       resolution). ??
  #     - All other cases:
  #       - If the symlink is empty, 
  #         - Then either
  #           - The process fails and errors out with a message, or
  #           - The pathname of the directory containing the symbolic
  #           link Shall be used in place of the contents of the 
  #           symbolic link.
  #       - If the symlink is non-empty:
  #         - If the symlink consists solely of slash characters,
  #           - Then all leading slash characters of the remaining
  #           pathname Shall be omitted from the resulting combined
  #           pathname, leaving only the leading slash characters
  #           from the symbolic link contents.
  #         - If the symlink does not consist solely of slash
  #         characters, 
  #           - Then prefix remaining pathname, if any, with the
  #           contents of the symbolic link.
  #       - If prefixing occurrs, 
  #         - If the combined length exceeds PATH_MAX, and
  #           - If the implementation considers this, exceeding
  #           PATH_MAX, to be an error,
  #             - Then the process Shall fail, and error out with a
  #             message.
  #           - \\Otherwise, the resolved pathname Shall be the
  #           resolution of the pathname just created.\\ I'm reading
  #           this ambiguous sentence as, \if the implementation does
  #           not consider this, exceeding PATH_MAX, to be an error,
  #           then the resolved pathname Shall be the resolution of
  #           the pathname just created.\
  #       - If the pathname does not begin with a slash \/\,
  #         - then the predecessor of 1st filename in the pathname
  #         is \\taken to be the directory containing the symbolic
  #         link.\\
  #       - If the system detects a loop,
  #         - The process Shall fail, and error out with a message.
  #       - If the resolution process follows more than SYMLOOP_MAX
  #       symbolic links, 
  #         - Then the process May fail, and error out with a
  #         message.
  #       - The special filename dot, \.\, \\Shall refer to the
  #       directory specified by its predecessor.\\
  #       - The special filename dot-dot, \..\, \\Shall refer to the
  #       parent directory of its predecessor directory.
  #         - If \.\ is \/root\, then \..\ May also be \/root\.
  #         Note, this is c.2008 -- look for changes since then!
  #         - ...
  #
  #       
  #
  # Implementation:
  #  - put the entire thing in a true loop
  #    - handle a double forward slash at the far left of the string
  #      - how?
  #    - check for leading forward slash
  #      - if missing, then prepend output of \pwd -P\
  #    - using \awk -F/\, separate the pathname out into separate
  #    elements
  #    - load the elements into the positional array
  #    - start with a \symlink_detected\ canary variable, set to \no\
  #      - loop through the array; the idea is to use concatenation to
  #      build up a new pathname; loop on \$# and \$1; use \shift\
  #        - for each element, add one leading forward slash to the
  #        current element
  #        - if there was an existing \canpath\ string from a previous
  #        loop, then prepend that on
  #        - use both \file\ and \test\ to determine the filetype of
  #        the basename of the \canpath\ string
  #        - if both utilities agree, then
  #          - if element is a symlink, then switch \symlink_detected\
  #          to \yes\
  #            - get the value of the symlink from \file\
  #            - test for whether the of value from \file\ has a
  #            leading forward slash
  #              - if yes, then use the symlink\s value as the total
  #              pathname thus far and continue
  #              - if no, then append the symlink\s value to the
  #              existing value of \canpath\ ...and continue?
  #          - if element is a directory, then continue
  #          - if element is neither a symlink nor a directory, then
  #            - if there are no more elements in the loop, then
  #            \break 1\
  #            - if there are elements remaining, then error
  #              ...and figure out what that means. is it a dangling
  #              symlink?
  #        - if the two utilities disagree, then error
  #      end element loop
  #      - if \symlink_detected\ is \yes\, then remain in the true
  #      loop; otherwise \break 2\
  #  - end true loop
  #  - how do you detect data loops? tmp file of pathnames at top of
  #  each true loop - duplicates mean data loop and error?
  #
  #
  #: "output_verbose_on: ${output_verbose_on}" #>
  #exit "${LINENO}" #>


exit 00

