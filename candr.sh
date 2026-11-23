#!/bin/env sh
# candr.xtrace / canonicalize-dir.sh
# shellcheck disable=SC2028,SC2268,SC2310,SC2329
#
#set | sha256sum #>
#set | wc #>
set > output_tof_set.txt  #>
script_version=26.11.22 # Script is incomplete & unfinished.
#\set -x #>
#
#
#   Manual canonicalization of directories. Output can be in brief or
# verbose formats; brief is the default; script accepts multiple
# operands.
#
#   Goals: that this script...
#     - Is written for any Posix 2008 compliant shell.
#     - May be either executed or sourced.
#     - Avoids any local side-effects.
#
#   (c) Wiley Young 2026, MIT License
#
#
# Tested on these distros and shells:
#   - Fedora 44: bash-5.3.9
#   - Fedora 45: bash-5.3.15, dash-0.5.13.2, ksh-1.0.10,
#       mksh-59c-16, oksh-7.9-2, yash-2.61, zsh-5.9.2.



#_  Notes:
#_  - In Busybox 1.37, \unset\ without \-f\ doesn\t unset functions.
#_      :-(
#_  - In POSIX \08, for printing functions use \type\. The \set\
#_  built-in does\t print them yet, as it does in version 5.3 of Bash.
#_  - Not all \unset\s have \-f\, ie, Solaris 11.2 \sh\. However, the
#_  Solaris 11.2 man page for unset\1\ reads, \\For each name,
#_  \unset\ removes the corresponding variable or function value.\\
#_  Still, historical versions of \unset\ may not have included the
#_  unsetting of functions.
#_  - In Posix \08, for Special Built-in \unset\, option \-f\ is
#_  specified.
#_  - In Posix \08 \sh\, the ENV parameter is not expanded in a non-
#_  interactive shell. So any value of ENV won\t have any effect.
#_  - In Bash 5.3, the BASH_ENV parameter is sourced by non-
#_  interactive shells. When bash is invoked as \sh\, it enters posix
#_  mode after reading the startup files. So a value of BASH_ENV
#_  could have an effect, but only before the script is executed, so
#_  unsetting BASH_ENV would not have any effect.
#_  - In Posix \08 \awk\, \split()\ is indeed specified.
#_  - BusyBox \grep\ does have \-q\ as of v.1.37.0.
#_  - Variable \cmd_str_*\ is defined as a particular invocation so
#_  that (a) command execution and (b) the various related messages
#_  can all use or reference the precise same command string.
#_  - Re variables \function_variable__1\ and similar: these are
#_  global variables.
#_  - Re why filenames beginning with a hyphen are by default
#_  disallowed in this script, see Posix \08, General Concepts 4.7.
#_  - On Fedora 45, the default values according to \getconf\:
#_  NAME_MAX = 255; PATH_MAX = 4096
#_  - As of 12 Nov 2026, all non-built-ins are located in /usr/bin on
#_  Fedora 45.
#_  - Variables of the form \ec1\ are used for transmitting the
#_  value of the exit code from the if list to \:\ into
#_  \return_code_for_script\.
#_  - \codeblocks\ is not Posix at all, 2008-2024, and not installed.
#_  - Commands which are not Posix at all: \enable\ and \which\.
#_  - In Bash on Fedoras 44 & 45, \PATH=${PATH}\ removes the hash
#_  table as expected even if PATH is set as RO.
#_  - Redirections are applied before any expansions occur.
#_  - \#!/bin/env -i sh\ fails.
#_  - LINENO does exist in Posix \08.
#_  - Reportedly, Solaris 10 uses a Bourne sh which is not Posix
#_  compliant.
#_      https://unix.stackexchange.com/questions/322035/\
#_        are-there-still-systems-around-with-a-bin-sh-binary
#_  - Reportedly, in Busybox \awk\ is optional.
#_  - When called from a restricted interactive shell, the script
#_  does not inherit the restricted setting.
#_  - Both \realpath\ and \readlink\ weren\t specified in Posix until
#_  \24.
#_  - The \-P\ option to \type\ is not portable.
#_  - The \pathchk\ utility offers three separate sets of tests;
#_  there is no overlap between said sets in the specification, but
#_  in GNU utilities there is.
#_  - The \-q\ option to \grep\ does exist in Posix \08.
#_  - In Posix \08, the handling of \//\ is intentionally
#_  implementation defined, so catch it, flag it as an error, and
#_  write a warning to Stderr. See spec. on \dirname\.
#_  - Defining directories with a trailing forward slash will
#_  effect whether \[[\, \test\, \[\ and \stat\ dereference
#_  symlinks. However, \realpath -e\ will still resolve such
#_  strings correctly.
#_  - The \-r\ option to \hash\ does exist in Posix \08.
#_  - If PATH is set RO in the interactive calling shell, in the
#_  script PATH can still be altered.
#_  - For \readonly\ without arguments, the results are unspecified.
#_  - Option \-v\ of utility \unset\ is in fact specified in \08.
#_  - The \!\ keyword doesn\t print in xtrace.
#_  - Reminder: don\t change the name of /etc/passwd. Bad things
#_  happen.
#_  - In Zsh...
#_    - \set +x\ within a function appears to be in local scope.
#_    - \command\ cannot find built-ins, apparently.
#_  - In Oksh, evidently, \hash\ is not available.
#_  - In Posix, \set -o posix\ DNE, in 2008 or 2024. Also, it appears
#_  that POSIXLY_CORRECT also DNE exist in Posix \08 or \24.
#_  - In Dash, \eval\ cannot accept the string \--\ to signify end
#_  of options.
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
#_  \08, so the least confusing workaround has been applied.
#_

  #> Debug.
  #reset; clear; grep -v -F -e '#>' -e '#_' ./candr.xtrace 2>&1 | less -RNS
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
# Posix \24 suggestion for \\Start off a \secure shell script\ in
# which the script avoids being spoofed by its parent,\\ as found in
# its spec. for \command\.
#
# Value of IFS should include one tabstop.
old_ifs=${IFS}
IFS=' 	
'
\unalias -a

# In Solaris \sh\, \unset\ does\t have \-f\.
#+ Workaround for errexit.
if unset -f command : #2>/dev/null
then
  : "t:$?:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>
  : "Command \\unset -f\\ returned non-zero"
fi
if unset command : #2>/dev/null
then
  : "t:$?:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>
  : "Command \\unset\\ returned non-zero"
fi

# PATH could be set as RO.
#_  - Some shells exit at an attempted assignment to a RO variable:
#_    - In Bash 5.3, attempting in a script to assign a value to a RO
#_    variable is a fatal error, but that doesn\t appear to have been
#_    specified by Posix in \08.
old_path=${PATH}
if PATH="$( command -p getconf PATH ):${PATH}"
then
  : "t:$?:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>
  command -p printf '%s: Notice: Assignment to variable failed: %s\n' \
    "$0" "PATH" 1>&2
  command -p printf '%s: Value of variable %s: <%s>\n' \
    "$0" "PATH" "${PATH}" 1>&2
fi
  #>
  #exit "${LINENO}" #>
  #set -x #>


:;: "Settings"

  # Bug, how to restore previous settings?

old_hyphen=$-
command -p set -a
command -p set -e
command -p set -f # Disable pathname expansion
command -p set -u
#command -p set -x
command -p set -C


:;: "Bootstrap Variables"
old_posixly_correct=${POSIXLY_CORRECT}
POSIXLY_CORRECT=Y
old_lc_all=${LC_ALL:-}
LC_ALL=C
old_ld_preload=${LD_PRELOAD:-}
command -p unset LD_PRELOAD
global__yn__output_verbose_on=N
return_code_for_script=0
special_variable_zero=${0#./}
special_variable_zero=${0##*/}
usage_msg="
  Usage: The first argument may be an option flag. If both \\-b\\
  and \\-v\\ are present, the last one shall apply.

  ${special_variable_zero} [-b|-h|-v|-V] [FILES] ...
    --brief     -b    Default format: '%s\n' [output]
    --help      -h    Print this message and exit.
    --verbose   -v    Format: '%s: \"%s\" -> %s\n' \$0 [input] [output]
    --version   -V    Print version information and exit.
    --                End of options; allow inputs which begin with 
                      hyphens.
"
yn__allow_input_strings_to_begin_with_hyphens=N
yn__print_only__value_of_path=N
# These variables are in use locally.
command -p unset \
  aA bB cC dD eE fF \
  ec0 ec1 ec2 ec3 ec4 ec5 ec6
  #>
  #set -x #>


:;: "Define functions: Group 0, Level 0" #>

:   "Define function:    __check_for_presence_of_commands__" #>
#
# Usage:
#     __check_for_presence_of_commands__ \
#         [Options for command] [Message, argument for Notice] \
#             [Whether to unset user functions]
#     __check_for_presence_of_commands__ [-pv|-v] "Blah" [Y|N]
#     __check_for_presence_of_commands__ \
#         -pv "Command is not in PATH" -- [command names]
#     __check_for_presence_of_commands__ \
#         -v "Built-in is not available" -- [command names]
#
__check_for_presence_of_commands__ ()
{
  :;: "A minimum of four inputs are required"
  if command -p test $# -gt 3
  then
    : "t:$?:${LINENO}" #>
    local__option_for_command=$1
    local__text_for_print_notice=$2
    if command -p test "--" = "$3"
    then
      : "t:$?:${LINENO}" #>
    else
      : "f:$?:${LINENO}" #>
      command -p printf 'Error, positional parameters\n'
      command -p exit "${LINENO}"
    fi
    command -p shift 3
  else
    : "f:$?:${LINENO}" #>
    command -p printf 'Error, positional parameters\n'
    command -p exit "${LINENO}"
  fi
  :;: "Loop on the remainder of positional parameters"
  for iI
  do
      :;: "iI: \\${iI}\\";: #>
    if command "${local__option_for_command}" -- "${iI}" >/dev/null
    then
      : "t:$?:${LINENO}" #>
    else
      : "f:${ec1:=$?}:${LINENO}" #>
      return_code_for_script=${ec1:=$?}
      yn__print_only__value_of_path=Y
      command -p printf '%s: %s: %s\n' \
        "$0" "${local__text_for_print_notice}" "${iI}" 1>&2
    fi
    __unset_user_functions__ "${iI}"
  done
  command -p unset \
    local__option_for_command \
    local__text_for_print_notice
  : "Leaving __check_for_presence_of_commands__";: #>
}

:   "Define function:    __reset_xtrace__" #>
# Usage:
#     __reset_xtrace__  [No arguments]
#
__reset_xtrace__ ()
{
  :
}

:   "Define function:    __unset_user_functions__" #>
#
# Usage:
#   __unset_user_functions__  [string]
#   __unset_user_functions__  "${aA}"
#
__unset_user_functions__ ()
{
  :;: "Is the function \\${local__name_of_function:="$1"}\\ defined?"
  if command -p type "${local__name_of_function}" \
    | command -p grep "function" >/dev/null
  then
    : "t:$?:${LINENO}" #>
    : "Yes: attempt \\unset\\ of function"
    if command -p unset -- "${local__name_of_function}" #2>/dev/null
    then
      : "t:$?:${LINENO}" #>
    else
      : "f:$?:${LINENO}" #>
    fi
    : "Was the function actually unset?"
    if command -p type -- "${local__name_of_function}" \
      | command -p grep "function" >/dev/null
    then
      : "t:$?:${LINENO}" "No, function was not unset" #>
      :;: "Try again. Attempt \\unset -f\\ of function"
      if command -p unset -f -- "${local__name_of_function}" #2>/dev/null
      then
        : "t:$?:${LINENO}" #>
      else
        : "f:$?:${LINENO}" #>
      fi
      : "Again, was the function actually unset?"
      if command -p type -- "${local__name_of_function}" \
        | command -p grep "function" >/dev/null
      then
        : "t:$?:${LINENO}" "No, function was not unset" #>
        command -p printf '%s: Error: \\unset\\ and \\unset ' \
          "$0" 1>&2
        command -p printf '-f\\ of function failed: %s\n' \
          "${local__name_of_function}" 1>&2
        command -p unset local__name_of_function
        command -p exit 1
      else : "f:$?:${LINENO}" "Yes, function was unset" #>
      fi
    else : "f:$?:${LINENO}" "Yes, function was unset" #>
    fi
  else : "f:$?:${LINENO}" "No, function was not defined" #>
  fi
  command -p unset local__name_of_function
  : "Leaving __unset_user_functions__";: #>
}
  #>
  #> Debug
  #:;: #>
  #__unset_user_functions__ "__reset_xtrace__" #>
  #type __reset_xtrace__ #>
  #exit "${LINENO}" #>
  # __print_only__notice_stderr__ "Exiting"
  # __print_only__error_stderr__ "Input contains one or more non-printable strings"
  # __print_only__warning_stderr__ "Command failed" "hash -r"
  # __print_only__notice_stderr__ "Value of PATH" "${PATH}"
  #exit "${LINENO}" #>
  #>
  #> Script Testing:
  # __check_for_variable_assignment__ PATH #>
  # __check_for_variable_assignment__ TTY #>
  #exit "${LINENO}" #>

:   "Define function:    __xtrace_off__" #>
# Unset xtrace and prepare to restore state.
#
#   Usage:  __xtrace_off__ [No arguments]
#
__xtrace_off__ ()
{
  case $- in
    *x* ) set +x
      __reset_xtrace__ ()
      {
        printf '# __reset_xtrace__\n' 1>&2
        set -x
      }
      ;;
    * ) __reset_xtrace__ ()
      { :;}
      ;;
  esac
  : "Leaving __xtrace_off__";: #>
}


:;: "Commands"
#
# Remove the hash table, so that PATH lookups are forced and
# therefore current. Posix \08 recommends \PATH=${PATH}\ in spec.
# on \hash\.
  #>
  #> Script Testing:
  #readonly PATH #>
  #set +e #>
  #enable -n hash #>

# shellcheck disable=SC2269
if command -v hash >/dev/null 2>&1
then
  : "t:$?:${LINENO}" #>
  stdout_08_hash=$( command -p hash )
  if command -p test -n "${stdout_08_hash}"
  then
    : "t:$?:${LINENO}" #>
    #+ Workaround for errexit; informative in xtrace.
    if command -p hash -r
    then
      : "t:$?:${LINENO}" #>
    else
      : "f:$?:${LINENO}" #>
    fi
    stdout_09_hash=$( command -p hash )
    if ! command -p test -n "${stdout_09_hash}"
    then
      : "f:$?:${LINENO}" #>
      command -p printf '%s: %s: %s\n' \
        "$0" "Command failed." "\\hash -r\\" 1>&2
      PATH=${PATH}
    else : "t:$?:${LINENO}" #>
    fi
  else : "f:$?:${LINENO}" #>
  fi
else
  : "f:$?:${LINENO}" #>
  PATH=${PATH}
fi

# If xtrace is on, turn it off.
__xtrace_off__ "${LINENO}"
  #>
  #> Script Testing:
  #enable -n break #>
  #aA=codeblocks #>
  #cd(){ echo foo;} #>


# Utilities
__check_for_presence_of_commands__ "-pv" "Command is not in PATH" -- \
  "awk" \
  "cd" \
  "command" \
  "dirname" \
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
  "type" \
  "unalias"

# Built-ins: Special and Regular
#_  - Special Built-ins per Posix \08 -- break : continue . eval exec
#_  exit export readonly return set shift times trap unset
#_  - Names of Special Built-ins cannot be used as names of functions
#_  (ie, \unset\), per testing with Bash in \--posix\ mode.
__check_for_presence_of_commands__ "-v" "Built-in not available" -- \
  "break" \
  ":" \
  "continue" \
  "." \
  "eval" \
  "exec" \
  "exit" \
  "export" \
  "readonly" \
  "return" \
  "set" \
  "shift" \
  "times" \
  "trap" \
  "unset"

# If xtrace was on, restore it.
__reset_xtrace__

:;: "Print the value of PATH if necessary."
if test "Y" = "${yn__print_only__value_of_path}"
then
  : "t:$?:${LINENO}" #>
  command -p printf '%s: Notice: Value of PATH: <%s>\n' \
    "$0" "${PATH}" 1>&2
else : "f:$?${LINENO}" #>
fi

# If any of the commands were missing, then exit.
#__exit_per_return_code_for_script__
  #>
  #set -x #>
  #exit "${LINENO}" #>
  #set +x #>



:;: "Define functions: Group 1, Level 0" #>

:   "Define function:    __check_for_variable_assignment__" #>
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
    : "Leaving __check_for_variable_assignment__";: #>
    return 1
  fi
  : "Leaving __check_for_variable_assignment__";: #>
}

# Bug? The message formatting is standardized, but it\s slower.
#
# Bug, the Usage description has x3 operands, while actual usage has x4

:   "Define function:    __print_only__message_stderr__" #>
# Usage (bug):
#         __print_only__message_stderr__ [Message type] [Description] [Data]
#         __print_only__message_stderr__ "Warning"      "$1"          "${2:-}"
#         __print_only__message_stderr__ "Exiting" (Later inputs can be omitted)
# Actual:
#         __print_only__message_stderr__ "${special_variable_zero}" "Error"   "$1" "${2:-}"
# Possible:
#         __print_only__message_stderr__ "${special_variable_zero}" "PATH"  "" "${2:-}"
#
__print_only__message_stderr__ ()
{
  # Formatting
  #   Just execute as many if..fi\s as there are assigned positional
  # parameters.
  while true
  do
    # Start with \$4 so that the others can be empty.
    if test -n "${4:-}"
    then
      : "t:$?:${LINENO}" #>
      function_variable__4=$( printf ': %b%s%b' '\x27' "$4" '\x27' )
    else : "f:$?:${LINENO}" #>
      #> Do not break the loop yet.
    fi

    if test -n "${1:-}"
    then
      : "t:$?:${LINENO}" #>
      function_variable__1=${1}
    else
      : "f:$?:${LINENO}" #>
      break
    fi

    if test -n "${2:-}"
    then
      : "t:$?:${LINENO}" #>
      function_variable__2=": $2"
    else
      : "f:$?:${LINENO}" #>
      break
    fi

    if test -n "${3:-}"
    then
      : "t:$?:${LINENO}" #>
      function_variable__3=": $3"
    else
      : "f:$?:${LINENO}" #>
      break
    fi

    break
  done

  # Print
  printf '%s%s%s%s\n' 1>&2 \
    "${function_variable__1:-}" \
    "${function_variable__2:-}" \
    "${function_variable__3:-}" \
    "${function_variable__4:-}"

  unset \
    function_variable__1 \
    function_variable__2 \
    function_variable__3 \
    function_variable__4
  : "Leaving __print_only__message_stderr__";: #>
}

:;: "Define functions: Group 1, Level 1" #>

:   "Define function:    __print_only__error_stderr__" #>
# Usage:
#        __print_only__error_stderr__   [Description]         [Data]
#        __print_only__error_stderr__   "Zero length input" \
#                                    (Latter inputs can be omitted)
#
__print_only__error_stderr__   ()
{
  __xtrace_off__ "${LINENO}"
  __print_only__message_stderr__ \
    "${special_variable_zero}" "Error"   "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_only__error_stderr__";: #>
}

:   "Define function:    __print_only__notice_stderr__" #>
# Usage:
#        __print_only__notice_stderr__  [Description]   [Data]
#        __print_only__notice_stderr__  "Value of PATH" "${PATH}"
#
__print_only__notice_stderr__  ()
{
  __xtrace_off__ "${LINENO}"
  __print_only__message_stderr__ \
    "${special_variable_zero}" "Notice"  "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_only__notice_stderr__";: #>
}

:   "Define function:    __print_only__warning_stderr__" #>
# Usage:
#         __print_only__warning_stderr__  [Description]     [Data]
#         __print_only__warning_stderr__  "Command failed"  "hash -r"
#
__print_only__warning_stderr__ ()
{
  __xtrace_off__ "${LINENO}"
  __print_only__message_stderr__ \
    "${special_variable_zero}" "Warning" "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_only__warning_stderr__";: #>
}


:;: "Define functions: Group 1, Level 2" #>

:   "Define function:    __error_invalid_option__" #>
#
# Usage:    __error_invalid_option__ \
#                     [option in question] [optional line number]
#           __error_invalid_option__ \
#                     "${foo}"              "${LINENO}"
#
__error_invalid_option__ ()
{
  __print_only__error_stderr__ "Invalid option" "$1"
  __print_only__message_stderr__ "$(
  printf 'Try %b%s%b for more information.\n' \
    '\x27' "${special_variable_zero} --help" '\x27'
  )"
}

:   "Define function:    __exit_per_return_code_for_script__" #>
# If the value of variable \return_code_for_script\ is non-zero, then
# exit.
#   Usage:
#       __exit_per_return_code_for_script__ [no arguments]
#
__exit_per_return_code_for_script__ ()
{
    #set -x #>
  : "Test \\return_code_for_script\\"
  if test 0 -eq "${return_code_for_script}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_only__notice_stderr__ "Exiting"
    exit "${return_code_for_script}"
  fi
  : "Leaving __exit_per_return_code_for_script__";: #>
}

:   "Define function:    __input_required__" #>
# Usage:    __input_required__ "$@"
#
__input_required__ ()
{
  if test 0 -lt "$#"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_only__message_stderr__ "$0" "Input required"
    printf '%s\n' "${usage_msg:?}"
    exit 1
  fi
  : "Leaving __input_required__";: #>
}

:   "Define function:    __make_sure_variable_is_defined_properly__" #>
# Test possible values of HOME.
#
# Usage:
#  __make_sure_variable_is_defined_properly__ \
#          [Unexpanded variable name] [affirmative|negative|Y]
#
#>  If any of the tests fail, then \global__assign_variable\ should have
#>  a value of \Y__*\. If all of the tests succeed then
#>  \global__assign_variable\ should have a value of either
#>  \affirmative__*\ or \negative__*\.
#>
#>  \Y\ and \affirmative\ indicate that the value of the
#>  unexpanded variable name at $1 should be changed; \negative\
#>  indicates that the value of the value of $1 should not be
#>  changed.
#>
#>  Valid values for $2 and their meanings are:
#>
#>    values            # tests       change variable?
#>    ####################################################
#>    Y               # failed      do change
#>    affirmative       # passed      do change
#>    negative          # passed      do not change
#>
__make_sure_variable_is_defined_properly__ ()
{
  if __check_for_variable_assignment__ "$1"
  then
    : "t:$?:${LINENO}" #>
    if test -n "$1" # Confirmation test
    then
      : "t:$?:${LINENO}" #>
      if eval test -e '$'"$1"
      then
        : "t:$?:${LINENO}" #>
        if eval test -d '$'"$1"
        then
          : "t:$?:${LINENO}" #>
          if eval test -x '$'"$1"
          then
            : "t:$?:${LINENO}" #>
            global__assign_variable="$2__$1"
          else
            : "f:0:${LINENO}" "Directory is not searchable" #>
            global__assign_variable="Y__$1"
          fi
        else
          : "f:0:${LINENO}" "Filesystem object is not a directory" #>
          global__assign_variable="Y__$1"
        fi
      else
        : "f:0:${LINENO}" "Filesystem object DNE" #>
        global__assign_variable="Y__$1"
      fi
    else
      : "f:0:${LINENO}" #>
      global__assign_variable="Y__$1"
      __print_only__error_stderr__ "Conflicting data" "Line:${LINENO}"
      exit 2
    fi
  else
    : "f:0:${LINENO}" "Parameter $1 is undefined" #>
    global__assign_variable="Y__$1"
  fi
  : "Leaving __make_sure_variable_is_defined_properly__'";: #>
}

:   "Define function:    __print_only__results__" #>
# Usage:  __print_only__results__ [Script input] \
#                                   [${canpth}|${nsfod}] \
#                                              [optional redirection]
# Usage:  __print_only__results__ "${fF}" "${nsfod}" >&2
#                                      ^redirect output to STDERR
# Usage:  __print_only__results__ "${fF}" "${canpth}"
#                                      ^normal output to STDOUT
# shellcheck disable=SC2329
__print_only__results__ ()
{
    #set -x #>
    : #>
    : "local variables:"
    : "pound: <$#>" #>
    : "ampersand:" "$@" #>
    : "\$1: $1"
    : "\$2: $2"
    : "\$return_code_for_script: ${return_code_for_script:-}" #>
    : "\$global__yn__output_verbose_on: ${global__yn__output_verbose_on:-}" #>
    #exit "${LINENO}" #>

  :;: "If there was an error, then switch verbose to \\on\\"
  if test 0 -eq "${return_code_for_script}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    global__yn__output_verbose_on=Y
  fi

  :;: "\\case\\ on \\global__yn__output_verbose_on\\"
  case "${global__yn__output_verbose_on}" in
    Y )
      : "\\case\\ branch: \\Y\\" #>
      printf '%s: %b%s%b -> %s\n' \
        "${special_variable_zero}" "\x27" "$1" "\x27" "$2"
      ;;
    N )
      : "\\case\\ branch: \\N\\" #>
      printf '%s\n' "$2"
      ;;
    * )
      __print_only__error_stderr__ "Unreachable code" "Line:${LINENO}"
      exit 2
      ;;
  esac
    #>
    #exit "${LINENO}" #>
}
  #>
  #__reset_xtrace__ () { :; } #>
  #type __reset_xtrace__ #>
  #:;: #>
  #>
  #> Script Testing
  # __input_required__ "$@" #>
  #exit "${LINENO}" #>



:;: "Input validation: \\tr\\, \\strings\\ and \\pathchk\\"
#
    #> Script Testing:
    #reset;clear #>
    #./candr.xtrace "$(dd if=/dev/urandom bs=32b count=1 2>/dev/null)" #>
    #reset; clear; ./candr.xtrace -v "" #>
    #reset; clear; ./candr.xtrace -v -foo #>
    #reset; clear; ./candr.xtrace -v foooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo #>
    #reset; clear; ./candr.xtrace -v /-foo #>
    #>
for cC
do
    :;: "Top of loop";: #>
    #>
  __xtrace_off__ "${LINENO}"

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
    return_code_for_script=${ec2:=$?}

    __print_only__error_stderr__ \
        "Input contains one or more non-printable strings"
    break
  fi

  __reset_xtrace__

  # Tests on filename length.
  #
  # Zero length input is disallowed.
  if test -n "${cC}"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:${ec3:=$?}:${LINENO}" #>
    return_code_for_script=${ec3:=$?}
    
    __print_only__error_stderr__ "Zero length input"
    break
  fi
    #>
    #set -x #>

  # Input exceeding PATH_MAX and NAME_MAX is disallowed.
  #
  # \pathchk [no arguments]\ checks \\each component of each pathname
  # of the underlying file system\\ using PATH_MAX and NAME_MAX, for any
  # non-searchable directory, and for any character that is invalid in
  # its containing directory, under Posix \08.
  #
  if pathchk -- "${cC}" 1>&2
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:${ec4:=$?}:${LINENO}" #>
    return_code_for_script=${ec4:=$?}
    
    __print_only__error_stderr__ \
      "Error received from \\pathchk [no args]\\" "${cC}"

    # Print the values of the relevant variables.
    __print_only__notice_stderr__ "Values of relevant system parameters"
    getconf -a | grep -E -e ^"PATH_MAX" -e ^"NAME_MAX"
    break 1
  fi
done
:;: "End of loop";: #>

# If any input validation problems occurred, then exit.
__exit_per_return_code_for_script__
  #>
  #set -x #>
  #: exit "${LINENO}" #>


:;: "Parse input"
  #>
  #> Script Testing:
  #set -x #>
  #set -- #>
  #set -- a b c #>
  #set -- a b c; shift 4 #> Error: "shift count out of range"
  #set -- a b c; shift 3 #>
  #set -- -ve #>
  #set -- -br #>
  #set -- --verbos #>
  #set -- --brie #>

__input_required__ "$@"

: "\\case\\ on positional paramters of the script"
for yY
do
  :;: "Test \\return_code_for_script\\" #>
  if test 0 -ne "${return_code_for_script}"
  then
    : "t:$?:${LINENO}" #>
    break
  else
    : "f:$?:${LINENO}" #>
    case "$1" in
      --* | -[bhVv\?]* )
        : "\\case\\ branch: double hyphen and option strings" #>
        :;: "Test \\yn__allow_input_strings_to_begin_with_hyphens\\" #>
        if test "Y" = "${yn__allow_input_strings_to_begin_with_hyphens}"
        then
          : "t:$?:${LINENO}" #>
          : "Filenames beginning with hyphens are allowed" #>
          break
        else
          : "f:$?:${LINENO}" #>
          : "Filenames beginning with hyphens are not allowed" #>
          if test -e "$1"
          then
            : "t:$?:${LINENO}" "Filename exists" #>
            __error_invalid_option__ "$1" "${LINENO}"
            return_code_for_script=1
          else
            : "f:$?:${LINENO}" "Filename DNE" #>
            case "$1" in
              --brief | --b* | -b )
                : "\\case\\ branch: --brief" #>
                global__yn__output_verbose_on=N
                shift
                continue
                ;;
              --help | --h* | -h | -\? )
                : "\\case\\ branch: --help" #>
                printf '%s\n' "${usage_msg:?}" 1>&2
                return_code_for_script=1
                ;;
              --verbose | --verb* | -v )
                : "\\case\\ branch: --verbose" #>
                global__yn__output_verbose_on=Y
                shift
                continue
                ;;
              --version | --vers* | -V )
                : "\\case\\ branch: --version" #>
                __print_only__message_stderr__ \
                  "${special_variable_zero}" "Version" "${script_version}"
                return_code_for_script=1
                ;;
              -- )
                : "\\case\\ branch: end-of-options string" #>
                yn__allow_input_strings_to_begin_with_hyphens=Y
                shift
                break
                ;;
              * )
                echo "Unreachable code"
                exit 2
                ;;
            esac
          fi
        fi
        ;;
      -* )
        : "\\case\\ branch: single hyphen" #>
        :;: "Test \\yn__allow_input_strings_to_begin_with_hyphens\\" #>
        if test "Y" = "${yn__allow_input_strings_to_begin_with_hyphens}"
        then
          : "t:$?:${LINENO}" #>
          break
        else
          : "f:$?:${LINENO}" #>

          # Filenames beginning with a hyphen are disallowed, part 1\2.
          stdout_02_cut=$( printf '%s' "${cC}" | cut -c 1 )
          if test "-" != "${stdout_02_cut}"
          then
            : "t:$?:${LINENO}" #>
          else
            : "f:${ec5:=$?}:${LINENO}" #>
            return_code_for_script=${ec5:=$?}
            __error_invalid_option__ "$1" "${LINENO}"
            return_code_for_script=1
          fi

          # Filenames beginning with a hyphen are disallowed, part 2\2.
          if pathchk -P -- "${cC}" 1>&2
          then
            : "t:$?:${LINENO}" #>
          else
            : "f:${ec6:=$?}:${LINENO}" #>
            return_code_for_script=${ec6:=$?}
            __print_only__error_stderr__ \
              "Error received from \\pathchk -P\\" "${cC}"
            __error_invalid_option__ "$1" "${LINENO}"
            return_code_for_script=1
          fi

          __error_invalid_option__ "$1" "${LINENO}"
          return_code_for_script=1
        fi
        ;;
      * )
        : "\\case\\ branch: asterisk: \\\$1\\: $1" #>
        true
        ;;
    esac
  fi
done
:;: "End of loop" #>
  #>
  #exit "${LINENO}" #>

__exit_per_return_code_for_script__
__input_required__ "$@"
  #>
  #: "global__yn__output_verbose_on: ${global__yn__output_verbose_on}" #>
  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


  # Bug, this list of environment variables is incomplete.


:;: "Section on \\getconf\\" #>
#
# DEBUG BLOCK -- To be run only if xtrace is enabled.
#
#
# Lists of environment variables.
#
# [ ] for GNU Coreutils, v.9.11 (c.2026)
#             BLOCK_SIZE
#             BLOCKSIZE
#             POSIXLY_CORRECT
# [ ] for Posix \08, Pathname Resolution
#             _POSIX_NO_TRUNC
#             NAME_MAX
# [ ] for Posix \08 -- Common env. vars.
#             LC_ALL
# [ ] for Posix \08 Utility \awk\
# [ ] for Posix \08 Utility \cd\
#             CDPATH
#             HOME
#             PATH_MAX
#             OLDPWD
#             PWD
# [ ] for Posix \08 Utility \command\
# [ ] for Posix \08 Utility \dirname\
# [ ] for Posix \08 Utility \echo\
# [ ] for Posix \08 Utility \env\
# [ ] for Posix \08 Utility \file\
# [ ] for Posix \08 Utility \find\
# [ ] for Posix \08 Utility \getconf\
# [ ] for Posix \08 Utility \grep\
# [ ] for Posix \08 Utility \id\
# [ ] for Posix \08 Utility \logname\
# [ ] for Posix \08 Utility \pathchk [no args]\
#             NAME_MAX
#             PATH_MAX
# [ ] for Posix \08 Utility \printf\
# [ ] for Posix \08 Utility \pwd\
#             PATH_MAX
#             PWD
# [ ] for Posix \08 Utility \sed\
# [ ] for Posix \08 Utility \sh\
#             PATH
# [ ] for Posix \08 Utility \strings\
# [ ] for Posix \08 Utility \test\
# [ ] for Posix \08 Utility \true\
# [ ] for Posix \08 Utility \type\
# [ ] for Posix \08 Utility \unalias
# [ ] for Posix \08 Special Parameter \break\
# [ ] for Posix \08 Special Parameter \:\
# [ ] for Posix \08 Special Parameter \continue\
# [ ] for Posix \08 Special Parameter \eval\
# [ ] for Posix \08 Special Parameter \exit\
# [ ] for Posix \08 Special Parameter \readonly\
# [ ] for Posix \08 Special Parameter \return\
# [ ] for Posix \08 Special Parameter \set\
# [ ] for Posix \08 Special Parameter \shift\
# [ ] for Posix \08 Special Parameter \unset\
# [ ] for paranoia ;-P
#             LD_PRELOAD
# [ ] for ?
#             LOGNAME
# [ ] for Posix \08 C function \chdir()\
#             SYMLOOP_MAX
#
if printf '%s' "$-" | grep -q -e "x"
then
  : "t:$?:${LINENO}" "Parameter values per \\getconf\\"
  __xtrace_off__ "${LINENO}"
  stdout_03_getconf_a=$( getconf -a )
 
  for dD in \
    _POSIX_NO_TRUNC \
    CDPATH \
    HOME \
    LC_ALL \
    LD_PRELOAD \
    NAME_MAX \
    PATH_MAX \
    OLDPWD \
    PATH \
    PWD \
    SYMLOOP_MAX
  do
      #echo "dD: ${dD}"
    #+ Note, this particular \if..fi\ is a workaround for errexit
    #+ and xtrace visibility.
    if printf '%s\n' "${stdout_03_getconf_a}" | grep -E -e "^${dD} "
    then : "t:$?:${LINENO}"
    else : "f:$?:${LINENO}"
    fi
  done
  __reset_xtrace__
#else : #> xtrace is off, so this line doesn\t print.
fi
 
  #set -x
  #: exit "${LINENO}"
 

:;: "Unset Environment Variables"
  #>
  #> Script Testing:
  #POSIXLY_CORRECT=Y #>
  #LD_PRELOAD=foo #>
  #eE=LD_PRELOAD #>
  #set | grep -E "^${eE}=.+"; echo $? #>
  #unset LD_PRELOAD; echo $? #>
  #set | grep -E "^${eE}=.+"; echo $? #>
  #LD_PRELOAD=x #>
  #>

old_oldpwd=${OLDPWD:-}
old_cdpath=${CDPATH:-}

for eE in \
  CDPATH \
  OLDPWD
do
    #: "eE: ${eE}" #>
    #>
  # It would seem obvious to use \test -n\ and a loop, but doing
  # so would be problematic under Posix \08 due to there being
  # multiple layers of expansion. Using a function allows the
  # regular expression to be defined in just one place.
  if __check_for_variable_assignment__ "${eE}"
  then
    : "t:$?:${LINENO}" "${eE} is defined" #>
    # shellcheck disable=SC2016
    cmd_str_03='unset -- "${eE}"'

    if eval "${cmd_str_03}"
    then
      : "t:$?:${LINENO}" "\\${cmd_str_03}\\ returned zero" #>
      if __check_for_variable_assignment__ "${eE}"
      then
        : "t:$?:${LINENO}" #>
        __print_only__error_stderr__ "${eE} is defined"
        exit 1
      else : "f:$?:${LINENO}" "${eE} is undefined / zero length";: #>
      fi
    else
      : "f:$?:${LINENO}" #>
      __print_only__notice_stderr__ \
        "Command \\unset\\ failed" "\\${cmd_str_03}\\"
    fi
  else : "f:$?:${LINENO}" "${eE} is undefined or of zero length";: #>
  fi
done
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
home_original=${HOME}
#_
#_  Notes,
#_    - Assigning PWD depends on HOME having a valid value.
#_      ^^^ Is this statement accurate??
#_      - \PWD\: \\An absolute pathname of the current working
#_      directory. If an application sets or unsets the value of PWD,
#_      the behavior of \pwd\ is unspecified.\\ - spec. on \pwd\.
#_    - From Posix \08:
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
  global__assign_variable=N

  # Bug, is \global__assign_variable\ extraneous?

  __make_sure_variable_is_defined_properly__ \
      "HOME" "negative"
  alter_value__home_original="${global__assign_variable}"
  #_ Note,
  #_   Possible values for \alter_value__home_original\ are:
  #_   - negative__HOME, or
  #_   - Y__HOME
  #_
  unset global__assign_variable
    #>
    #set -x #>
    : exit "${LINENO}" #>

  #_ Note,
  #_   - Spec. on \logname\: \\The logname utility explicitly ignores
  #_   the LOGNAME environment variable because environment changes
  #_   could produce erroneous results.\\
  #_   - Therefore, use \logname\.
  #_
  #_ Question, These commands produce different results. Why? `sudo sh -c 'eval echo ~"$( logname )"' sh` `sudo sh -c 'eval echo ~"${LOGNAME}"' sh`

  :;: "Confirm the value of HOME in two different ways, if possible"
  #
  # Get the HOME directory via Tilde Expansion.
  #
  #+  Note, Workaround for errexit and xtrace visibility, as
  #+  throughout.
  if stdout_05_tilde_exp=$( eval printf '%s\n' ~"$( logname )" )
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
      __print_only__error_stderr__ \
        "Username is not present in /etc/passwd " "${stdout_06_id_un}"
      exit 1
    fi
  else
    : "f:$?:${LINENO}" #>
    __print_only__error_stderr__ "...there are systems without \"/etc/passwd\"???"
    __print_only__notice_stderr__ "Exiting"
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
    home_confirmed=${stdout_05_tilde_exp}
    home_found=NA
  else
    : "f:$?:${LINENO}" #>
    #__print_only__notice_stderr__ "Conflicting data" "Line:${LINENO}"
    home_confirmed="::Conflicting_data::"
    home_found=""
    #_
    #_  Note,
    #_    If the data is incongruent, then which variable does the
    #_  script use? Whichever one exists?
    #_    Tilde Expansion is specified.
    #_    The GNU Coreutils 9.11 version of \id\ requires
    #_  /etc/passwd, but that doesn\t necessarily mean that other
    #_  implementations do also. The Posix \08 spec. of \id\ doesn\t
    #_  mention /etc/passwd at all.
    #_    So prefer data from Tilde Expansion.
    #_
    if test -n "${stdout_05_tilde_exp}"
    then
      : "t:$?:${LINENO}" #>
      home_found=${stdout_05_tilde_exp}
    else
      : "f:$?:${LINENO}" #>
      if test -n "${stdout_07_awk_etc_passwd}"
      then
        : "t:$?:${LINENO}" #>
        home_found=${stdout_07_awk_etc_passwd}
      else
        : "f:$?:${LINENO}" #>
        home_found="::No_valid_values_were_found::"
        __print_only__warning_stderr__ "Value not found" "HOME"
        exit 2
      fi
    fi
  fi

  # Check the new data for validity.
  if test -n "${home_confirmed}"
  then
    : "t:$?:${LINENO}" #>
    __make_sure_variable_is_defined_properly__ \
        "home_confirmed" "affirmative"
    alter_value__home_confirmed="${global__assign_variable}"
    alter_value__home_found="N"
    #_
    #_ Note, possible values for \alter_value__home_confirmed\ are:
    #_   - affirmative__home_confirmed, or
    #_   - Y__home_confirmed
    #_
    unset global__assign_variable
  else
    : "f:$?:${LINENO}" #>
    alter_value__home_confirmed="Y"
    alter_value__home_found=""
    if test -n "${home_found}"
    then
      : "t:$?:${LINENO}" #>
      __make_sure_variable_is_defined_properly__ \
          "home_found" "affirmative"
      alter_value__home_found="${global__assign_variable}"
      #_ Note,
      #_   Possible values for \alter_value__home_found\, are:
      #_   - affirmative__home_found, or
      #_   - Y__home_found
      #_
      unset global__assign_variable
    else
      : "f:$?:${LINENO}" #>
      __print_only__notice_stderr__ \
          "Data from both sources are of zero length" "Line:${LINENO}"
    fi
  fi
    :;: #>
    : "HOME: ${HOME:-}" #>
    : "alter_value__home_original: ${alter_value__home_original:-}" #>
    : "home_confirmed: ${home_confirmed:-}" #>
    : "alter_value__home_confirmed: ${alter_value__home_confirmed:-}" #>
    : "home_found: ${home_found:-}" #>
    : "alter_value__home_found: ${alter_value__home_found:-}" #>
    #exit "${LINENO}" #>

    #_ Note,
    #_   Var  HOME             could have values of  Y   or  negative
    #_   Var  home_confirmed   could have values of  Y   or  affirmative
    #_   Var  home_found       could have values of  Y   or  affirmative

  # Assign HOME accordingly.
  #_ Do HOME and \home_confirmed\ have the same value?
  if test "${HOME:=}" = "${home_confirmed}"
  then
    : "t:$?:${LINENO}" #>
    #_ Yes, HOME and \home_confirmed\ have the same value.
    #_
    #_ Did HOME pass all of the tests?
    if test "negative__HOME" = "${alter_value__home_original}"
    then
      : "t:$?:${LINENO}" #>
      #_ Yes, HOME passed all of the tests.
      #if HOME=${HOME}; then : "t:$?:${LINENO}"; else : "f:$?:${LINENO}"; fi #>
      #_ Done
    else
      : "f:$?:${LINENO}" #>
      #_ No, HOME failed some of the tests.
      #_
      #_ But HOME is equivalent to \home_confirmed\, so you cannot use
      #_ that value either.
      #_
      #_ Did the third variable, \home_found\, pass all of the tests?
      if test "affirmative__home_found" = "${alter_value__home_found}"
      then
        : "t:$?:${LINENO}" #>
        #_ Yes, \home_found\ passed all of the tests.
        if HOME=${home_found}
        then : "t:$?:${LINENO}"
        else : "f:$?:${LINENO}"
        fi
        #_ Done
      else
        : "f:$?:${LINENO}" #>
        #_ No, \home_found\ failed some of the tests.
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
    #_ No, HOME and \home_confirmed\ do NOT have the same value.
    #_
    #_ Did HOME pass all of the tests?
    if test "negative__HOME" = "${alter_value__home_original}"
    then
      : "t:$?:${LINENO}" #>
      #_ Yes, HOME passed all of the tests.
      #_
      #_ But, HOME and \home_confirmed\ do not have the same value.
      #_
      #_ So, did \home_confirmed\ pass all of the tests?
      if test "affirmative__home_confirmed" = "${alter_value__home_confirmed}"
      then
        : "t:$?:${LINENO}" #>
        #_ Yes, \home_confirmed\ passed all of the tests.
        #_
        #_ So both values passed all of the tests.
        #_
        # __print_only__warning_stderr__ "Conflicting data" "Line:${LINENO}"
        #_ If \home_found\ also passed all of the tests, then use that
        #_ one because \home_found\ is based on /etc/passwd.
        #_
        #_ Did \home_found\ pass all of the tests?
        if test "affirmative__home_found" = "${alter_value__home_found}"
        then
          : "t:$?:${LINENO}" #>
          #_ Yes, \home_found\ passed all of the tests.
          if HOME=${home_found}
          then : "t:$?:${LINENO}"
          else : "f:$?:${LINENO}"
          fi
          #_ Done
        else
          : "f:$?:${LINENO}" #>
          #_ No, \home_found\ failed some of the tests.
          #_
          #_ Between both verified values HOME and \home_confirmed\,
          #_ which should be used: the one set by the user or the one
          #_ identified by Tilde Expansion?
          #_
          #_ The one set by the user could be malicious, so use the
          #_ one identified by Tilde Expansion: \home_confirmed\.
          if HOME=${home_confirmed}
          then : "t:$?:${LINENO}"
          else : "f:$?:${LINENO}"
          fi
          #_ Done
        fi
      else : "f:$?:${LINENO}" #>
        #_ No, \home_confirmed\ failed some of the tests.
        #_
        #_ Since HOME passed all of the tests, and since HOME and
        #_ \home_confirmed\ do not have the same value, keep the
        #_ current value of HOME.
        #if HOME=${HOME}; then : "t:$?:${LINENO}"; else : "f:$?:${LINENO}"; fi #>
        #_ Done
      fi
    else
      : "f:$?:${LINENO}" #>
      #_ No, HOME failed some of the tests.
      #_
      #_ Since HOME and \home_confirmed\ do not have the same value,
      #_
      #_ Did \home_confirmed\ pass all of the tests?
      if test "affirmative__home_confirmed" = "${alter_value__home_confirmed}"
      then
        : "t:$?:${LINENO}" #>
        #_ Yes, \home_confirmed\ passed all of the tests.
        if HOME=${home_confirmed}
        then : "t:$?:${LINENO}"
        else : "f:$?:${LINENO}"
        fi
        #_ Done.
      else
        : "f:$?:${LINENO}" #>
        #_ No, \home_confirmed\ failed some of the tests.
        #_
        #_ So both HOME and \home_confirmed\ failed some of the tests.
        #_
        #_ Did \home_found\ pass all of the tests?
        if test "affirmative__home_found" = "${alter_value__home_found}"
        then
          : "t:$?:${LINENO}" #>
          #_ Yes, \home_found\ passed all of the tests.
          if HOME=${home_found}
          then : "t:$?:${LINENO}"
          else : "f:$?:${LINENO}"
          fi
          #_ Done.
        else
          : "f:$?:${LINENO}" #>
          #_ No, \home_found\ failed some of the tests.
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
  #>
  #exit "${LINENO}" #>


:;: "PWD aught to be defined, for \\cd\\ and \\pwd\\"
#_ Notes,
#_   - In Posix \08 effects of assignments to PWD are unspecified.
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
  #_ Notes, from Posix \08:
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
  #_        -- disallow empty strings as operands.
  #_
  #_  - Posix \08 \pwd\:
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
    __print_only__error_stderr__ "Command \\cd\\ failed" "cd; cd -P ."
    exit 1
  fi

  if __check_for_variable_assignment__ "PWD"
  then
    : "t:$?:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>

    # Bug, try also \pwd -P\

    __print_only__warning_stderr__ "Parameter is undefined" "PWD"
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
    return_code_for_script=1
    __print_only__results__ "${fF}" "${nsfod}" >&2
    continue 1
  fi
done



echo not yet implemented



  # Buggy - rewrite script from this point on.
  #
  # See Posix \08, Base Definitions, General Concepts,
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
  #    - start with a \symlink_detected\ canary variable, set to \N\
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
  #          to \Y\
  #            - get the value of the symlink from \file\
  #            - test for whether the of value from \file\ has a
  #            leading forward slash
  #              - if Y, then use the symlink\s value as the total
  #              pathname thus far and continue
  #              - if N, then append the symlink\s value to the
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
  #      - if \symlink_detected\ is \Y\, then remain in the true
  #      loop; otherwise \break 2\
  #  - end true loop
  #  - how do you detect data loops? tmp file of pathnames at top of
  #  each true loop - duplicates mean data loop and error?
  #
  #
  #: "global__yn__output_verbose_on: ${global__yn__output_verbose_on}" #>
  #exit "${LINENO}" #>


  # Bug, this section should probably go into a trap.

:;: "Clean up"
# In case the script is sourced.
#
# Reset variables.

  # Bug, what if the env vars didn\t exist before, ie, CDPATH & OLDPATH?

CDPATH=${old_cdpath:-}
IFS=${old_ifs:-}
LC_ALL=${old_lc_all:-}
OLDPATH=${old_oldpath:-}
PATH=${old_path:-}

  # Bug, this \unset\ list is out of date

# Unset variables and functions
set -- \
  POSIXLY_CORRECT \
  aA \
    bB cC dD eE fF iI yY \
  alter_value__home_confirmed \
    alter_value__home_found \
    alter_value__home_original \
  ec0 \
    ec1 ec2 ec3 ec4 ec5 ec6 \
  canpth \
  cmd_str_00 \
    cmd_str_01 \
    cmd_str_02 \
    cmd_str_03 \
  function_variable__1 \
    function_variable__2 \
    function_variable__3 \
    function_variable__4 \
    function_variable__cmd_str \
  global__assign_variable \
  global__yn__output_verbose_on \
  home_confirmed \
    home_found \
    home_original \
  nsfod \
  old_cdpath \
    old_hyphen \
    old_ifs \
    old_lc_all \
    old_ld_preload \
    old_oldpath \
    old_oldpwd \
    old_path \
    old_posixly_correct \
  return_code_for_script \
  stdout_00_tr_d \
    stdout_01_strings_n1 \
    stdout_02_cut \
    stdout_03_getconf_a \
    stdout_04_readonly_awk \
    stdout_05_tilde_exp \
    stdout_06_id_un \
    stdout_07_awk_etc_passwd \
    stdout_08_hash \
  script_version \
  special_variable_zero \
  usage_msg \
  yn__allow_input_strings_to_begin_with_hyphens \
  yn__print_only__value_of_path \
  __check_for_presence_of_commands__ \
  __check_for_variable_assignment__ \
  __error_invalid_option__ \
  __exit_per_return_code_for_script__ \
  __input_required__ \
  __make_sure_variable_is_defined_properly__ \
  __print_only__error_stderr__ \
  __print_only__message_stderr__ \
  __print_only__notice_stderr__ \
  __print_only__results__ \
  __print_only__warning_stderr__ \
  __unset_user_functions__ \
  __reset_xtrace__ \
  __xtrace_off__
  #>
  set -x #>

if unset -f "$@" 2>/dev/null
then
  : "t:$?:${LINENO}"
else
  : "f:$?:${LINENO}"
fi
if unset "$@" 2>/dev/null
then
  : "t:$?:${LINENO}"
else
  : "f:$?:${LINENO}"
fi
  #>
  #set | sha256sum #>
  #set | wc #>
  set > output_eof_set.txt  #>

:;: "Done"
exit 000


#######  URL\s  #######
#
# POSIX
#
#   # Main Index
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/
#
#   # Base Definitions
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/idx/xbd.html
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/idx/xbd.html
#
#   # Base Definitions: General Concepts
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/basedefs/V1_chap04.html
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap04.html
#
#   # Base Definitions: Environment Variables
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/basedefs/V1_chap08.html
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap08.html
#
#   # Base Definitions: Regular Expressions
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/basedefs/V1_chap09.html
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap09.html
#
#   # Shell & Utilities
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/idx/xcu.html
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/idx/xcu.html
#
#   # Shell & Utilities: Introduction
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap01.html
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap01.html#tag_18
#
#   # Shell & Utilities: Shell Command Language
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/idx/shell.html
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/idx/shell.html
#
#   # Shell & Utilities: Utilities
#     # 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/idx/utilities.html
#
#     # 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/idx/utilities.html
#
#
#
# Special considerations
#   https://www.gnu.org/software/coreutils/manual/coreutils.html#Trailing-slashes-1
#   https://www.pixelbeat.org/docs/coreutils-gotchas.html
#
#
#
# Utilities: multiple man pages for each.
#     # POSIX 2008
#     # POSIX 2024
#     # GNU
#     # IBM (AIX)
#     # Oracle (Solaris)
#     # Mac
#     # FreeBSD
#     # NetBSD
#     # OpenBSD
#     # BusyBox
#
#
#   # awk
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/awk.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/awk.html
#
#     # GNU
#     https://www.gnu.org/software/gawk/manual/gawk.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/awk-1.html#scrolltoc -- AWK
#     https://docs.oracle.com/cd/E36784_01/html/E36870/nawk-1.html#scrolltoc -- nAWK
#
#     # Mac
#     https://ss64.com/mac/awk.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=awk&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/awk.1
#
#     # OpenBSD
#     https://man.openbsd.org/awk.1
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#awk
#
#
#
#   # basename
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/basename.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/basename.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/basename-invocation.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/basename-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/basename.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=basename&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/basename.1
#
#     # OpenBSD
#     https://man.openbsd.org/basename.1
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#basename
#
#
#
#   # cd
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/cd.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/cd.html
#
#     # GNU -- NA in rpm coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-cd
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/cd-1.html#scrolltoc -- binary!
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/cd.html -- bash built-in
#     https://ss64.com/mac/cd-zsh.html -- zsh built-in
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=cd&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/cd.1 -- binary?
#     https://man.netbsd.org/sh.1 -- built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: \cd\ is a shell built-in in both busybox sh and ash
#
#
#
#   # command
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/command.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/command.html
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-command
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/command-1.html#scrolltoc -- binary!
#     # No shell built-in
#
#     # Mac
#     https://ss64.com/mac/command.html -- bash and zsh built-ins; just one man page, though
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=command&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox - Not directly available - try BusyBox sh or ash
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # dirname
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/dirname.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/dirname.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/dirname-invocation.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/dirname-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/dirname.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=dirname&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/dirname.1
#
#     # OpenBSD
#     https://man.openbsd.org/dirname
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#dirname
#
#
#
#   # echo
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/echo.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/echo.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/echo-invocation.html
#
#       # Also, Bash:
#       https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-echo
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/echo-1.html#scrolltoc -- binary!
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/echo.html -- bash built-in
#     # Apparently there\s a zsh built-in echo, but the man page link points to \alias\
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=echo&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/echo.1 -- binary
#     # No shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/echo -- echo
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#echo
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: also shell built-in in both busybox sh and ash
#
#
#
#   # env
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/env.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/env.html
#
#     # GNU -- NA in Bash
#     https://www.gnu.org/software/coreutils/manual/html_node/env-invocation.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/env-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/env.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=env&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/env.1
#
#     # OpenBSD
#     https://man.openbsd.org/env
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#env
#
#
#
#   # file
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/file.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/file.html
#
#     # GNU -- rpm: file
#         NA
#
#         # Developers -- No current documentation
#         https://www.darwinsys.com/file/
#
#         # Die.net
#         https://linux.die.net/man/1/file
#
#         # Man7.org
#         https://www.man7.org/linux/man-pages/man1/file.1.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/file-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/file.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=file&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/file.1
#
#     # OpenBSD
#     https://man.openbsd.org/file
#
#     # BusyBox
#       NA
#
#
#
#   # find
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/find.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/find.html
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/findutils/manual/find.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/find-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/find.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=find&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/find.1
#
#     # OpenBSD
#     https://man.openbsd.org/find
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#find
#
#
#
#   # getconf
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/getconf.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/getconf.html
#
#     # GNU -- binary is from rpm glibc-common, however, documentation is NA on gnu.org
#       NA
#
#       # Die.net
#       https://linux.die.net/man/1/getconf
#
#       # Man7.org
#       https://www.man7.org/linux/man-pages/man1/getconf.1p.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/getconf-1.html#scrolltoc
#
#     # Mac
#       NA
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=getconf&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/getconf.1
#
#     # OpenBSD
#     https://man.openbsd.org/getconf
#
#     # BusyBox
#       NA
#
#
#
#   # grep
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/grep.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/grep.html
#
#     # GNU
#     https://www.gnu.org/software/grep/manual/grep.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/grep-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/grep.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=grep&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/grep.1
#
#     # OpenBSD
#     https://man.openbsd.org/grep
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#grep
#
#
#
#   # hash
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/hash.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/hash.html
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-hash
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/hash-1.html#scrolltoc -- binary!
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/hash.html -- bash built-in
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=hash&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox - Not directly available - try BusyBox sh or ash
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # id
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/id.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/id.html
#
#     # GNU -- NA in Bash
#     https://www.gnu.org/software/coreutils/manual/html_node/id-invocation.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/id-1g.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/id.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=id&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/id.1
#
#     # OpenBSD
#     https://man.openbsd.org/id
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#id
#
#
#
#   # ln
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/ln.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/ln.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/ln-invocation.html
#
#     # IBM (AIX)
#     https://www.ibm.com/docs/en/aix/7.3.0?topic=l-ln-command
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/ln-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/ln.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=ln&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/ln.1
#
#     # OpenBSD
#     https://man.openbsd.org/ln.1
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#ln
#
#
#
#   # logname
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/logname.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/logname.html
#
#     # GNU -- NA in Bash
#     https://www.gnu.org/software/coreutils/manual/html_node/logname-invocation.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/logname-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/logname.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=logname&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/logname.1
#
#     # OpenBSD
#     https://man.openbsd.org/logname
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#logname
#
#
#
#   # pathchk
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/pathchk.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/pathchk.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/pathchk-invocation.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/pathchk-1.html#scrolltoc
#
#     # Mac
#       NA
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=pathchk&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/pathchk.1
#
#     # OpenBSD
#       NA
#
#     # BusyBox
#       NA
#
#
#
#   # printf
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/printf.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/printf.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/printf-invocation.html
#
#       # Also, Bash:
#       https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-printf
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/printf-1.html#scrolltoc
#     # No shell built-in
#
#     # Mac
#     https://ss64.com/mac/printf.html -- bash built-in
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=printf&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/printf.1 -- binary
#     # No shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/printf -- binary
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#printf
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: also shell built-in in both busybox sh and ash
#
#
#
#   # pwd
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/pwd.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/pwd.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/pwd-invocation.html -- binary
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-pwd -- shell built-in
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/pwd-1.html#scrolltoc -- binary!
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/pwd.html -- binary? man page is silent re built-ins
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=pwd&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/pwd.1 -- binary?
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/pwd
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#pwd
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: also a shell built-in in both busybox sh and ash
#
#
#
#   # readlink
#     # POSIX 2008
#     NA
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/readlink.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/readlink-invocation.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/readlink-1.html
#
#     # Mac
#     https://ss64.com/mac/stat.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=readlink&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/readlink.1
#
#     # OpenBSD
#     https://man.openbsd.org/readlink.1
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#readlink
#
#
#
#   # realpath
#     # POSIX 2008
#     NA
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/realpath.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/realpath-invocation.html
#     https://www.gnu.org/savannah-checkouts/gnu/coreutils/manual/html_node/Realpath-usage-examples.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/realpath-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/realpath.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=realpath&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/realpath.1
#
#     # OpenBSD
#     https://man.openbsd.org/realpath.1
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#realpath
#
#
#
#   # sed
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/sed.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/sed.html
#
#     # GNU
#     https://www.gnu.org/software/sed/manual/sed.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sed-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/sed.html
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=sed&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sed.1
#
#     # OpenBSD
#     https://man.openbsd.org/sed
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#sed
#
#
#
#   # sh
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/sh.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/sh.html
#
#     # GNU
#     https://www.gnu.org/software/bash/manual/bash.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc
#       #_ Note, Oracle has separate man pages for each of the shells:
#       #     bash, beansh, csh, git-sh, jsh, ksh, ksh88, ksh93, sh, tcsh, zsh.
#       https://docs.oracle.com/cd/E36784_01/html/E36870/shell-built-ins-1.html#scrolltoc
#
#     # Mac
#     https://ss64.com/mac/bash.html -- has --posix mode
#     https://ss64.com/mac/zsh.html -- Zsh built-ins on MacOS
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=sed&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1
#
#     # OpenBSD
#     https://man.openbsd.org/sh
#
#     # BusyBox -- exists in BusyBox, but the full documentations is where??
#     http://www.busybox.net/downloads/BusyBox.html#sh
#     https://man.archlinux.org/man/busybox.1.en#sh
#
#       # See also, BusyBox ash
#       http://www.busybox.net/downloads/BusyBox.html#ash
#       https://man.archlinux.org/man/busybox.1.en#ash
#
#
#
#   # strings
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/strings.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/strings.html
#
#     # GNU -- rpm: binutils
#     https://sourceware.org/binutils/docs/binutils/strings.html
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/strings-1.html#scrolltoc
#
#     # Mac
#       NA
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=strings&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/strings.1
#
#     # OpenBSD
#     https://man.openbsd.org/strings
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#strings
#
#
#
#   # test
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/test.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/test.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/test-invocation.html
#
#       # Also, Bash:
#       https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-test
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/test-1.html#scrolltoc -- binary!
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/test.html -- bash utility and zsh built-in; one man page
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=test&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/test.1 -- binary
#     # No shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/test -- binary
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#test
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: also a shell built-in in both busybox sh and ash
#
#
#
#   # true
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/true.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/true.html
#
#     # GNU
#     https://www.gnu.org/software/coreutils/manual/html_node/true-invocation.html
#
#       # Also, Bash:
#       https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-true
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/true-1.html#scrolltoc
#     # No shell built-in
#
#     # Mac
#     https://ss64.com/mac/true.html -- binary?
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=true&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/true.1 -- binary
#     # No shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/true -- binary
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     http://www.busybox.net/downloads/BusyBox.html#true
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: also a shell built-in in both busybox sh and ash
#
#
#
#   # unalias
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/unalias.html
#
#     # POSIX 2024
#     https://pubs.opengroup.org/onlinepubs/9799919799/utilities/unalias.html
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-unalias
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/unalias-1.html#scrolltoc
#     # No shell built-in
#
#     # Mac
#     https://ss64.com/mac/alias.html -- bash built-in
#     https://ss64.com/mac/alias-zsh.html -- zsh built-in
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=unalias&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # break -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#break
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-break
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/break-1.html#scrolltoc -- binary
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/break.html -- bash and zsh built-ins; one man page
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=break&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell keyword
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # colon -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#colon
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-_003a
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#       NA?
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=continue&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # continue -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#continue
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-continue
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/continue-1.html#scrolltoc -- binary?
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/continue.html -- bash and zsh built-ins; one man page
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=continue&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell keyword
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # eval -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#eval
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-eval
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/eval-1.html#scrolltoc -- binary?
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/eval.html -- bash and zsh built-in; one man page
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=eval&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # exit -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#exit
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-exit
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/exit-1.html#scrolltoc -- binary?
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/exit.html -- bash and zsh built-in; one man page
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=exit&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # readonly -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#readonly
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-readonly
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/readonly-1.html#scrolltoc -- binary?
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/readonly.html -- bash utility
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=readonly&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # return -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#return
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-return
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/return-1.html#scrolltoc -- binary?
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/return.html -- bash built-in
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=return&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # set -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#set
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#index-set
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/set-1.html#scrolltoc -- binary?
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/set.html -- bash built-in
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=set&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # shift -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#shift
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-shift
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/shift-1.html#scrolltoc -- binary?
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/shift.html -- bash built-in
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=shift&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash
#
#
#
#   # unset -- POSIX 2024 Special Built-in
#     # POSIX 2008
#     https://pubs.opengroup.org/onlinepubs/9699919799.2008edition/utilities/V3_chap02.html#unset
#
#     # POSIX 2024
#
#     # GNU -- NA in coreutils
#     https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-unset
#
#     # IBM (AIX)
#
#     # Oracle (Solaris)
#     https://docs.oracle.com/cd/E36784_01/html/E36870/unset-1.html#scrolltoc -- binary?
#     https://docs.oracle.com/cd/E36784_01/html/E36870/sh-1.html#scrolltoc -- shell built-in
#
#     # Mac
#     https://ss64.com/mac/unset.html -- bash built-in
#
#     # FreeBSD
#     https://man.freebsd.org/cgi/man.cgi?query=unset&apropos=0&sektion=0&manpath=FreeBSD+15.1-RELEASE+and+Ports.quarterly&format=html
#
#     # NetBSD
#     https://man.netbsd.org/sh.1 -- shell built-in
#
#     # OpenBSD
#     https://man.openbsd.org/sh -- shell built-in
#
#     # BusyBox
#     https://man.archlinux.org/man/busybox.1.en#sh
#     https://man.archlinux.org/man/busybox.1.en#ash
#     # Per commandline: shell built-in in both busybox sh and ash

