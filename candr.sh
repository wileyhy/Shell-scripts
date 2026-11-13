#!/bin/env sh
# candr.xtrace / canonicalize-dir.sh
# shellcheck disable=SC2028,SC2268,SC2310
#
#   Script is unfinished - 13 Nov 2026 WY
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
#_ Notes:
#_  - Redirections are applied before any expansions occur.
#_  - \#!/bin/env -i sh\ fails.
#_  - LINENO does exist in Posix 2008.
#_  - Reportedly, Solaris 10 uses a Bourne sh which is not Posix
#_  compliant.
#_      https://unix.stackexchange.com/questions/322035/\
#_        are-there-still-systems-around-with-a-bin-sh-binary
#_  - Reportedly, in Busybox \awk\ is optional.
#_    - \awk\s been removed from this script.
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

  #> Debug.
  #reset; clear; grep -vFe '#>' -e '#_' ./candr.xtrace 2>&1 | less -RNS
  #\set -x #>
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
if ! unset -f command grep hash set 2>/dev/null
then
  : "f:$?:${LINENO}" #>
  : "Command \\unset\\ returned non-zero"
else : "t:0:${LINENO}" #>
fi

# PATH could be set as RO.
if ! PATH="$( command -p getconf PATH ):${PATH}"
then
  : "f:$?:${LINENO}" #>
  printf '%s: Notice: Assignment to variable failed: %s\n' \
    "$0" "PATH"
  printf '%s: Notice: Value of variable %s: <%s>\n' \
    "$0" "PATH" "${PATH}"
else : "t:0:${LINENO}" #>
fi
  #>
  #exit "${LINENO}" #>
  #set -x #>


:;: "Settings"
set -a
set -u
set -C


:;: "Bootstrap Variables"
LC_ALL=C
global_return_code=0
#_ Note, the Special Variable zero is of global scope.
special_var_zero=${0#./}
special_var_zero=${0##*/}
usage_msg="${special_var_zero}:

    Usage: The first argument may be an option flag.
        candr.xtrace [-b|-h|-v] [FILE] ...
          --brief     -b
          --help      -h
          --verbose   -v
"
unset ec0 ec1 ec2 ec3 ec4 ec5 ec6


:;: "Functions"
#_
#_ Unset xtrace and prepare to restore state at the end of this
#_ section.
#_
#_ Usage:
#_     __xtrace_off__ [No arguments]
#_     __reset_xtrace__  [No arguments]
#_
: "Define functions: __xtrace_off__ & __reset_xtrace__" #>
__xtrace_off__ ()
{
  case $- in
    *x*) set +x; __reset_xtrace__ () { printf '# __reset_xtrace__\n'; set -x; }; ;;
    *) __reset_xtrace__ () { :; } ;;
  esac
  : "Leaving __xtrace_off__";: #>
}

__reset_xtrace__ ()
{
  :
}

: "Define function:  __input_required__" #>
#_
#_ Usage:    __input_required__ "$@"
#_
__input_required__ ()
{
  if ! test 0 -lt "$#"
  then
    : "f:$?:${LINENO}" #>
    __print_error__ "Input required"
    printf '%s\n' "${usage_msg:?}" 1>&2
    exit 1
  else : "t:0:${LINENO}" #>
  fi
  : "Leaving __input_required__";: #>
}

: "Define function:  __check_for_variable_assignment__" #>
#_
#_ Usage:
#_     __check_for_variable_assignment__ [Unexpanded variable name]
#_     __check_for_variable_assignment__ HOME
#_
#_ Note, this particular function is used in \if...fi\ tests, so the
#_ fact that it ends with a pipeline which could return false is
#_ intended. However, as a standalone function, errexit, if the
#_ variable at \$1\ has no assigned value, causes the script to
#_ halt. To have halted would have been an error. Yet, it\s Posix
#_ 2008, so the least confusing workaround has been applied.
#_
__check_for_variable_assignment__ ()
{
  if ! set | grep -q -E -e "^${1}=.+" 2>/dev/null
  then
    : "f:$?:${LINENO}" #>
    : "Leaving __check_for_variable_assignment__" #>
    return 1
  else : "t:0:${LINENO}" #>
  fi
  : "Leaving __check_for_variable_assignment__";: #>
}
  #>
  #> Script Testing:
  #__check_for_variable_assignment__ PATH #>
  #__check_for_variable_assignment__ TTY #>
  #exit "${LINENO}" #>

: "Define function:  __print_message__" #>
#_
#_ Usage:
#_         __print_message__ [Message type] [Description] [Data]
#_         __print_message__ "Warning" "$1" "${2:-}"
#_         __print_message__ "Exiting"
#_
__print_message__ ()
{
  local_posparm_one=${1:-}
  local_posparm_two=${2:-}
  local_posparm_three=${3:-}

  if test -n "${local_posparm_one}"
  then
    : "t:0:${LINENO}" #>
    local_posparm_one=": ${local_posparm_one}"
  else : "f:$?:${LINENO}" #>
  fi

  if test -n "${local_posparm_two}"
  then
    : "t:0:${LINENO}" #>
    local_posparm_two=": ${local_posparm_two}"
  else : "f:$?:${LINENO}" #>
  fi

  if test -n "${local_posparm_three}"
  then
    : "t:0:${LINENO}" #>
    local_posparm_three=": <${local_posparm_three}>"
  else : "f:$?:${LINENO}" #>
  fi

  printf '%s%s%s%s\n' 1>&2 \
    "${special_var_zero}" \
    "${local_posparm_one}" \
    "${local_posparm_two}" \
    "${local_posparm_three}"
  : "Leaving __print_message__";: #>
}

: "Define functions: __print_{error,notice,warning}__" #> #>
#_
#_ Usage:
#_         __print_error__   [Description] [Data]
#_         __print_warning__ "Command failed" "hash -r"
#_
__print_error__   ()
{
  __xtrace_off__
  __print_message__ "Error"   "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_error__";: #>
}

__print_notice__  ()
{
  __xtrace_off__
  __print_message__ "Notice"  "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_notice__";: #>
}

__print_warning__ ()
{
  __xtrace_off__
  __print_message__ "Warning" "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_warning__";: #>
}

: "Define function:  __exit_per_global_return_code__" #> #>
#_
#_ If the value of variable \global_return_code\ is non-zero, then
#_ exit.
#_
#_ Usage:
#_       __exit_per_global_return_code__ [no arguments]
#_
__exit_per_global_return_code__ ()
{
  if ! test 0 -eq "${global_return_code}"
  then
    : "f:$?:${LINENO}" #>
    __print_notice__ "Exiting"
    exit "${global_return_code}"
  else : "t:0:${LINENO}" #>
  fi
  : "Leaving __exit_per_global_return_code__";: #>
}
  #> Debug
  #__print_notice__ "Exiting"
  #__print_error__ "Input contains one or more non-printable strings"
  #__print_warning__ "Command failed" "hash -r"
  #__print_notice__ "Value of PATH" "${PATH}"
  #exit "${LINENO}" #>
  #>
  #> Script Testing
  #set -- #>
  #set -- a b c #>
  #set -- a b c; shift 4 #> Error: "shift count out of range"
  #set -- a b c; shift 3 #>
  #__input_required__ "$@" #>
  #exit "${LINENO}" #>


:;: "Parse input"
  #>
  #> Script Testing:
  #set -- -ve #>
  #set -- -br #>
  #set -- --verbos #>
  #set -- --brie #>

__input_required__ "$@"

: "\\case\\ on posparm 1"
case "$1" in
  --verbose | -v* | --v* )
    : "\\case\\ branch: \\--verbose\\" #>
    output_verbose_on=yes
    shift
    ;;
  --brief   | -b* | --b* )
    : "\\case\\ branch: \\--brief\\" #>
    output_verbose_on=no
    shift
    ;;
  --help    | -h* | --h* | -? )
    : "\\case\\ branch: \\--help\\" #>
    printf '%s\n' "${usage_msg:?}" 1>&2
    #__print_notice__ "Exiting"
    exit 1
    ;;
  * )
    : "\\case\\ branch: no options: use default: \\--brief\\" #>
    output_verbose_on=no
    #_ Note, No \shift\ command.
    ;;
esac
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

#_ Utilities
#_
#_   Script Test string: \codeblocks\ #>
#_
# Remove the hash table, so that PATH lookups are forced and
# therefore current. Posix recommends \PATH=${PATH}\ in spec. on
# \hash\.
#_
#_ Note, In Bash on Fedoras 44 & 45, this recommendation works as
#_ expected even if PATH is set as RO.
  #>
  #> Script Testing:
  #readonly PATH #>
  #set +e #>
  #enable -n hash #>
  #if ! PATH=${PATH} #>

# shellcheck disable=SC2269
if ! PATH=${PATH}
then
  : "f:$?:${LINENO}" #>
  if command -v hash >/dev/null 2>&1
  then
    : "t:0:${LINENO}" #>
    cmd_str="hash -r"
    if eval "${cmd_str}" 2>/dev/null
    then
      : "f:$?:${LINENO}" #>
      __print_warning__ "Command failed" "${cmd_str}"
    else : "t:0:${LINENO}" #>
    fi
    unset cmd_str
  else
    : "f:$?:${LINENO}" #>
    #_ Note, If \hash\ is NA on the system, then this condition will
    #_ be caught in the next section.
    __print_notice__ "Command is not in PATH" "hash"
    print_value_of_path=yes
  fi
else : "t:0:${LINENO}" #>
fi

#_ If xtrace is on, turn it off.
#__xtrace_off__
  #>
  #> Script Testing:
  #enable -n break #>


  # Bug, these two loops are nearly the same: convert to a function.


#_ Tests for each command
#_ Note, Commands which are not Posix at all: \enable\ and \which\.
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
  #"codeblocks" #> Not Posix at all, 2008-2024, and not installed.
  #>
  #> Special Builtins per Posix 2008:
  #>    break : continue . eval exec exit export readonly
  #>    return set shift times trap unset
  #>
do
    #> Just to see in which directory each utility is located.
    #which "${aA}" 2>/dev/null || command -v "${aA}" #>
    #continue #>
    #>
    #> Note
    #>   - At 11/12, all non-builtins are located in
    #>     /usr/bin on Fedora 45.
    #>
  #_ Determine whether command \aA\ is in PATH.
  if ! command -pv -- "${aA}" >/dev/null
  then
    : "f:${ec0:=$?}" #>
      #>
      #command -v -- "${aA}" ||: #>
    global_return_code=${ec0:=$?}
    print_value_of_path=yes
    __print_notice__ "Command is not in PATH" "${aA}"
  else : "t:0:${LINENO}" #>
  fi

  # Unset user functions
  #+ Workaround for errexit.
  cmd_str="unset -f"
  if ! eval "${cmd_str}" -- "${aA}" 2>/dev/null
  then
    : "f:$?:${LINENO}" #>
    : "Command \\${cmd_str}\\ returned non-zero"
  else : "t:0:${LINENO}" #>
  fi
  unset cmd_str
done
unset aA #>
  #>
  #exit "${LINENO}" #>

#_ If xtrace was on, restore it.
__reset_xtrace__

#_ Print the value of PATH if necessary.
if test "yes" = "${print_value_of_path}"
then
  : "t:0:${LINENO}" #>
  __print_notice__ "Value of PATH" "${PATH}"
else : "f:$?${LINENO}" #>
fi

#_ Built-ins: Special and Regular
for cC in \
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
  #_ Determine whether Built-in \cC\ is in PATH.
  if ! command -v -- "${cC}" >/dev/null
  then
    #_ Note, \ec6\ is used for transmitting the exit code from
    #_ \:\ into \global_return_code\.
    : "f:${ec6:=$?}" #>
    global_return_code=${ec6:=$?}
    __print_notice__ "Built-in is not available" "${cC}"
  else : "t:0:${LINENO}" #>
  fi

  # Unset user functions
  #+ Workaround for errexit.
  cmd_str="unset -f"
  if ! eval "${cmd_str}" -- "${cC}" 2>/dev/null
  then
    : "f:$?:${LINENO}" #>
    : "Command \\${cmd_str}\\ returned non-zero"
  else : "t:0:${LINENO}" #>
  fi
  unset cmd_str
done
unset cC #>
  #>
  #exit "${LINENO}" #>


#_ If any of the commands were missing, then exit.
__exit_per_global_return_code__
  #>
  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


:;: "Input validation: \\tr\\, \\strings\\ and \\pathchk\\"
#
for bB in "$@"
do
    :;: "Top of loop";: #>
    #>
  __xtrace_off__

  # Remove NULs and nonprintable bytes.
    #>
    #> Script Testing:
    #reset;clear #>
    #./candr.xtrace "$(dd if=/dev/urandom bs=32b count=1 2>/dev/null)" #>
    #>
  stdout_10_tr_d=$( printf '%s' "${bB}" | tr -d '\0' )
  stdout_11_strings_n1=$(
    printf '%s' "${stdout_10_tr_d}" | strings -n 1
  )

  if ! test "X${bB}" = "X${stdout_11_strings_n1}"
  then
    : "f:${ec1:=$?}:${LINENO}" #>
    global_return_code=${ec1:=$?}
    __print_error__ \
        "Input contains one or more non-printable strings"
    break 1
  else : "t:0:${LINENO}" #>
  fi

  __reset_xtrace__

  # Zero length input is disallowed.
    #>
    #> Script Testing:
    #reset; clear; ./candr.xtrace -v "" #>
    #>
  if ! test -n "${bB}"
  then
    : "f:${ec2:=$?}:${LINENO}" #>
    global_return_code=${ec2:=$?}
    __print_error__ "Zero length input"
    break 1
  else : "t:0:${LINENO}" #>
  fi

    #set -x #>

  # Filenames beginning with a hyphen are disallowed, part 1\2.
  #_
  #_ Note, see Posix 2008, General Concepts 4.7.
    #>
    # Script Testing: #>
    #reset; clear; ./candr.xtrace -v -foo #>
    #>
  stdout_00_cut=$( printf '%s' "${bB}" | cut -c 1 )

  if ! test "-" != "${stdout_00_cut}"
  then
    : "f:${ec3:=$?}:${LINENO}" #>
    global_return_code=${ec3:=$?}
    __print_error__ \
      "Filenames beginning with a hyphen are disallowed" "${bB}"
    break 1
  else : "t:0:${LINENO}" #>
  fi

  # Tests on filename length.
  #_
  #_ \pathchk [no arguments]\ checks \\each component of each pathname
  #_ of the underlying file system\\ using PATH_MAX and NAME_MAX, for any
  #_ non-searchable directory, and for any character that is invalid in
  #_ its containing directory.
  #_
  #_ On Fedora 45, the default values according to \getconf\:
  #_   NAME_MAX                            255
  #_   PATH_MAX                            4096
    #>
    #> Script Testing:
    #reset; clear; ./candr.xtrace -v foooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo #>
    #>
  if ! pathchk -- "${bB}"
  then
    : "f:${ec4:=$?}:${LINENO}" #>
    global_return_code=${ec4:=$?}
    __print_error__ \
      "Error received from \\pathchk [no args]\\" "${bB}"

    #_ Print out the values of the relevant variables.
    __print_notice__ "Values of relevant system parameters"
    getconf -a | grep -E -e ^"PATH_MAX" -e ^"NAME_MAX"
    break 1
  else : "t:0:${LINENO}" #>
  fi

  # Filenames beginning with a hyphen are disallowed, part 2\2.
  #_
  #_ Note, see Posix 2008, General Concepts 4.7.
    #>
    # Script Testing: #>
    #reset; clear; ./candr.xtrace -v /-foo #>
    #>
  if ! pathchk -P -- "${bB}"
  then
    : "f:${ec5:=$?}:${LINENO}" #>
    global_return_code=${ec5:=$?}
    __print_error__ \
      "Error received from \\pathchk -P\\" "${bB}"
    break 1
  else : "t:0:${LINENO}" #>
  fi
done
:;: "End of loop" #>

#_ If any input validation problems occurred, then exit.
__exit_per_global_return_code__
  #>
  #set -x #>
  #: exit "${LINENO}" #>

#> DEBUG BLOCK
#>
:;: "IF XTRACE IS ON -- Section on \\getconf\\" #>
#>  BASH_ENV          # for \bash\
#>  CDPATH            # for \cd\
#>  ENV               # for \sh\
#>  HOME              # for \cd\
#>  LC_ALL            # Common
#>  LD_PRELOAD        # for paranoia ;-P
#>  LOGNAME           # for ?
#>  NAME_MAX          # for \pathchk [no args]\
#>  PATH_MAX          # for \cd\, \pathchk [no args]\ and \pwd\
#>  OLDPWD            # for \cd\
#>  PATH              # for \sh\
#>  PWD               # for \cd\ and \pwd\
#>  SYMLOOP_MAX       # for \chdir()\
if printf '%s' "$-" | grep -q -e "x" #>
then #>
  : "t:0:${LINENO}" "Parameter values per \\getconf\\" #>
  __xtrace_off__; set +x #>
  stdout_01_getconf_a=$( getconf -a ) #>
  for eE in BASH_ENV CDPATH ENV HOME LC_ALL LD_PRELOAD NAME_MAX PATH_MAX OLDPWD PATH PWD SYMLOOP_MAX #>
  do #>
      #echo "eE: ${eE}" #>
    #+ Note, this particular \if..fi\ is a workaround for errexit
    #+ and xtrace visibility.
    if printf '%s\n' "${stdout_01_getconf_a}" | grep -E -e "^${eE} " #>
    then : "t:0:${LINENO}" #>
    else : "f:$?:${LINENO}" #>
    fi #>
  done #>
  __reset_xtrace__ #>
else : "f:$?:${LINENO}" "Section on \\getconf\\: xtrace is off" #>
fi #>
  #>
  #set -x #>
  #: exit "${LINENO}" #>
  #>

:;: "Unset Environment Variables"
#_ Unset certain env. vars. if possible and if they\re defined. See
#_ specification pages under Posix 2008.
  #>
  #> Script Testing:
  #POSIXLY_CORRECT=yes #>
  #LD_PRELOAD=foo #>
  #fF=LD_PRELOAD #>
  #set | grep -E "^${fF}=.+"; echo $? #>
  #unset LD_PRELOAD; echo $? #>
  #set | grep -E "^${fF}=.+"; echo $? #>
  #LD_PRELOAD=x #>

for fF in \
  BASH_ENV \
  CDPATH \
  ENV \
  LD_PRELOAD \
  OLDPWD
do
    #: "fF: ${fF}" #>
    #>
  #_ Note, using \test -n\ and a loop at the same time is problematic
  #_ due to multiple layers of expansion. \set | grep\ is an okay
  #_ solution.
  if __check_for_variable_assignment__ "${fF}"
  then
    : "t:0:${LINENO}" "${fF} is defined" #>
    #_ Note, define \cmd_str\ as a particular invocation so that (a)
    #_ the command can be executed and so that (b) the various related
    #_ messages can cite the precise command string which was
    #_ executed.
    # shellcheck disable=SC2016
    cmd_str='unset -v -- "${fF}"'

    if eval "${cmd_str}"
    then
      : "t:0:${LINENO}" "\\${cmd_str}\\ returned zero" #>
      if __check_for_variable_assignment__ "${fF}"
      then
        : "t:0:${LINENO}" #>
        __print_error__ "${fF} is defined"
        #__print_notice__ "Exiting"
        exit 1
      else : "f:$?:${LINENO}" "${fF} is undefined or of zero length";: #>
      fi
    else
      : "f:$?:${LINENO}" #>
      __print_notice__ "Command failed" "\\${cmd_str}\\"
    fi
    unset cmd_str
  else : "f:$?:${LINENO}" "${fF} is undefined or of zero length";: #>
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
#_
#_ Notes,
#_   - Assigning PWD depends on HOME having a valid value.
#_   - From Posix 2008:
#_     - Shell Command Language 2.6.1: \\If HOME is unset, the results
#_     are unspecified.\\
#_   - The \id\ utility has no knowledge of \sudo\ or means of
#_   differentiating regular vs. elevated permissions.
#_   - If the name of /etc/passwd is changed, \id\ throws an error.
  #>
  #set -x #>

# Is the existing variable HOME set as RO?
stdout_12_readonly_awk=$(
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
if ! test -n "${stdout_12_readonly_awk:-}"
then
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
      : "t:0:${LINENO}" "Parameter $1 is defined" #>
      if test -n "$1" # Confirmation test
      then
        : "t:0:${LINENO}" "Result confirmed" #>
        if eval test -e '$'"$1"
        then
          : "t:0:${LINENO}" "Filesystem object exists" #>
          if eval test -d '$'"$1"
          then
            : "t:0:${LINENO}" "Filesystem object is a directory" #>
            if eval test -x '$'"$1"
            then
              : "t:0:${LINENO}" "Directory is searchable" #>
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
        __print_error__ "Conflicting data" "Line:${LINENO}"
        #__print_notice__ "Exiting"
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
  if stdout_06_tilde_exp=$( eval echo ~"$( logname )" )
  then
    : "t:0:${LINENO}" #>
    : "Tilde expansion succeeded"
  else
    : "f:$?:${LINENO}" #>
    : "Tilde expansion failed"
  fi

  # Get the HOME directory from /etc/passwd.
  if test -f /etc/passwd
  then
    : "t:0:${LINENO}" #>
    stdout_02_id_un=$( id -un )

    if grep -q "${stdout_02_id_un}" /etc/passwd
    then
      : "t:0:${LINENO}" #>
      #+ Workaround for errexit and xtrace visibility.
      if stdout_07_awk_etc_passwd=$(
           awk -F: -v usrnm="${stdout_02_id_un}" \
             '$1 == usrnm { print $6 }' /etc/passwd
           )
      then
        : "t:0:${LINENO}" #>
        : "\\awk\\ succeeded"
      else
        : "f:$?:${LINENO}" #>
        : "\\awk\\ failed"
      fi
    else
      : "f:$?:${LINENO}" #>
      __print_error__ \
        "Username is not present in /etc/passwd " "${stdout_02_id_un}"
      #__print_notice__ "Exiting"
      exit 1
    fi
  else
    : "f:$?:${LINENO}" #>
    __print_error__ "...there are systems without \"/etc/passwd\"???"
    __print_notice__ "Exiting"
    exit 2
  fi
    #>
    #set -x #>
    : exit "${LINENO}" #>

  # Check for conflicting results.
  #_ Note, in theory, both variables could be of zero length.
  if test "X${stdout_06_tilde_exp}" = "X${stdout_07_awk_etc_passwd}"
  then
    : "t:0:${LINENO}" "Result confirmed" #>
    confirmed_home=${stdout_06_tilde_exp}
    found_home=NA
  else
    : "f:$?:${LINENO}" #>
    __print_notice__ "Conflicting data" "Line:${LINENO}"
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
    if test -n "${stdout_06_tilde_exp}"
    then
      : "t:0:${LINENO}" #>
      found_home=${stdout_06_tilde_exp}
    else
      : "f:$?:${LINENO}" #>
      if test -n "${stdout_07_awk_etc_passwd}"
      then
        : "t:0:${LINENO}" #>
        found_home=${stdout_07_awk_etc_passwd}
      else
        : "f:$?:${LINENO}" #>
        found_home="::No_valid_values_were_found::"
        __print_warning__ "Value not found" "HOME"
        exit 2
      fi
    fi
  fi

  # Check the new data for validity.
  if test -n "${confirmed_home}"
  then
    : "t:0:${LINENO}" #>
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
      : "t:0:${LINENO}" #>
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
      __print_notice__ \
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
    : "t:0:${LINENO}" #>
    #_ Yes, HOME and \confirmed_home\ have the same value.
    #_
    #_ Did HOME pass all of the tests?
    if ! test "negative__HOME" = "${alter_original_home_value}"
    then
      : "f:$?:${LINENO}" #>
      #_ No, HOME failed some of the tests.
      #_
      #_ But HOME is equivalent to \confirmed_home\, so you cannot use
      #_ that value either.
      #_
      #_ Did the third variable, \found_home\, pass all of the tests?
      if test "affirmative__found_home" = "${alter_found_home_value}"
      then
        : "t:0:${LINENO}" #>
        #_ Yes, \found_home\ passed all of the tests.
        if HOME=${found_home}
        then : "t:0:${LINENO}"
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
        then : "t:0:${LINENO}"
        else : "f:$?:${LINENO}"
        fi
        #_ Done
      fi
    else : "t:0:${LINENO}" #>
      #_ Yes, HOME passed all of the tests.
      #if HOME=${HOME}; then : "t:0:${LINENO}"; else : "f:$?:${LINENO}"; fi #>
      #_ Done
    fi
  else
    : "f:$?:${LINENO}" #>
    #_ No, HOME and \confirmed_home\ do NOT have the same value.
    #_
    #_ Did HOME pass all of the tests?
    if test "negative__HOME" = "${alter_original_home_value}"
    then
      : "t:0:${LINENO}" #>
      #_ Yes, HOME passed all of the tests.
      #_
      #_ But, HOME and \confirmed_home\ do not have the same value.
      #_
      #_ So, did \confirmed_home\ pass all of the tests?
      if test "affirmative__confirmed_home" = "${alter_confirmed_home_value}"
      then
        : "t:0:${LINENO}" #>
        #_ Yes, \confirmed_home\ passed all of the tests.
        #_
        #_ So both values passed all of the tests.
        #_
        __print_warning__ "Conflicting data" "Line:${LINENO}"
        #_ If \found_home\ also passed all of the tests, then use that
        #_ one because \found_home\ is based on /etc/passwd.
        #_
        #_ Did \found_home\ pass all of the tests?
        if test "affirmative__found_home" = "${alter_found_home_value}"
        then
          : "t:0:${LINENO}" #>
          #_ Yes, \found_home\ passed all of the tests.
          if HOME=${found_home}
          then : "t:0:${LINENO}"
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
          then : "t:0:${LINENO}"
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
        #if HOME=${HOME}; then : "t:0:${LINENO}"; else : "f:$?:${LINENO}"; fi #>
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
        : "t:0:${LINENO}" #>
        #_ Yes, \confirmed_home\ passed all of the tests.
        if HOME=${confirmed_home}
        then : "t:0:${LINENO}"
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
          : "t:0:${LINENO}" #>
          #_ Yes, \found_home\ passed all of the tests.
          if HOME=${found_home}
          then : "t:0:${LINENO}"
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
          then : "t:0:${LINENO}"
          else : "f:$?:${LINENO}"
          fi
        fi
      fi
    fi
  fi
    #>
    #set -x #>
    : "HOME: ${HOME}" #>
    exit 101 #"${LINENO}" #>
    #>
else : "t:0:${LINENO}" #>
fi
unset stdout_12_readonly_awk
  #>
  exit "${LINENO}" #>


:;: "PWD aught to be defined, for \\cd\\ and \\pwd\\"
#_
#_ Notes,
#_   - In Posix-2008 effects of assignments to PWD are unspecified.
#_   - In Bash 5.3.9+,
#_     - If restricted mode is enabled and PWD is undefined, a call to
#_     \cd\ will not assign a value to PWD.
#_     - Values of HOME and PWD are inherited from the calling
#_     interactive shell.
#_
if ! __check_for_variable_assignment__ "PWD"
then
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
  #_    shall be taken.\\
  #_      -- HOME aught to be defined.
  #_      -- A directory operand aught to be used.
  #_    - (Step 2) \\If no directory operand is given and the HOME
  #_    environment variable is set to a non-empty value, the cd
  #_    utility shall behave as if the directory named in the HOME
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
  #_    - (Step 10) \\The cd utility shall then perform actions
  #_    equivalent to the chdir() function called with curpath as
  #_    the path argument. If these actions fail for any reason, the
  #_    cd utility shall display an appropriate error message and the
  #_    remainder of this step shall not be executed. ... If the -P
  #_    option is in effect, the PWD environment variable shall be
  #_    set to the string that would be output by pwd -P. If there is
  #_    insufficient permission on the new directory, or on any
  #_    parent of that directory, to determine the current working
  #_    directory, the value of the PWD environment variable is
  #_    unspecified.\\
  #_      -- Any error message aught to be assigned to a variable.
  #_      -- The output of \pwd -P\ is relevant.
  #_    - \-P\: \\Handle the operand dot-dot physically; symbolic
  #_    link components shall be resolved before dot-dot components
  #_    are processed.\\
  #_    - SYNOPSIS:
  #_      - \\cd [-L|-P] [directory]\\
  #_        - \directory\: \\An absolute or relative pathname of the
  #_        directory that shall become the new working directory.
  #_        The interpretation of a relative pathname by cd depends
  #_        on the -L option and the CDPATH and PWD environment
  #_        variables. If directory is an empty string, the results
  #_        are unspecified.\\
  #_
  #_  - Posix 2008 \pwd\:
  #_    - \\The pwd utility shall write to standard output an
  #_    absolute pathname of the current working directory, which
  #_    does not contain the filenames dot or dot-dot.\\
  #_    - \-P\: \\The pathname written to standard output shall not
  #_    contain any components that refer to files of type symbolic
  #_    link.\\
  #_    - \PWD\: \\An absolute pathname of the current working
  #_    directory. If an application sets or unsets the value of PWD,
  #_    the behavior of pwd is unspecified.\\
  #+  - This \if..fi\ structure is a workaround for errexit and
  #+  xtrace visibility
  #_
  if ! stderr_cd_P=$(
    cd -- "${HOME}"
    cd -P -- . 2>&1 >/dev/null
  ) # Subshell
  then
    : "f:$?:${LINENO}" #>
    __print_error__ "Subshell failed" "cd; cd -P ."
    #__print_notice__ "Exiting"
    exit 1
  else : "t:0:${LINENO}" #>
  fi

  if ! __check_for_variable_assignment__ "PWD"
  then
    : "f:$?:${LINENO}" #>

    # Bug, try also \pwd -P\

    __print_warning__ "Parameter is undefined" "PWD"
  else : "t:0:${LINENO}" #>
  fi
else : "t:0:${LINENO}" #>
fi


:;: "Script Variables"
canpth=""
nsfod="(No such file or directory)"
  #>
  #set -x #>
  #printf '%s\n' stdout #>
  #printf '%s\n' stderr 1>&2 #>
  :;: set #>
  set | grep -E -e '^HOME=' -e '^PWD=' #>
  exit "${LINENO}" #>


: "Define function: __print_output__" #> #>
#_
#_ Usage:    __print_output__ [Script input] [canpth|nsfod] [redirection]
#_ Usage:    __print_output__ "${gG}" "${canpth}"
#_                                         # ^normal output to STDOUT
#_ Usage:    __print_output__ "${gG}" "${nsfod}" >&2
#_                                         # ^redirect output to STDERR
#_
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

  :;: "If error, then switch verbose on"
  if test 0 -ne "${global_return_code}"
  then
    : "t:0:${LINENO}" #>
    output_verbose_on=yes
  else : "f:$?:${LINENO}" #>
  fi

  :;: "\\case\\ on \\output_verbose_on\\"
  case "${output_verbose_on}" in
    yes | y )
      : "\\case\\ branch: \\yes\\" #>
      printf '%s: %b%s%b -> %s\n' \
        "${special_var_zero}" "\x27" "$1" "\x27" "$2"
      ;;
    no | n )
      : "\\case\\ branch: \\no\\" #>
      printf '%s\n' "$2"
      ;;
    * )
      printf '%s\n' "Unreachable code"
      exit "${LINENO}"
      ;;
  esac
    #>
    #exit "${LINENO}" #>
}
  #>
  #set -x #>
  #exit "${LINENO}" #>
  #set -x #>


:;: "The given path must exist in the filesystem"
#> Script Test input: /dev/qwertyuiop
for gG
do
  if ! test -e "${gG}"
  then
    : "f:$?:${LINENO}" #>
    global_return_code=1
    __print_output__ "${gG}" "${nsfod}" >&2
    continue 1
  else : "t:0:${LINENO}" "Path exists" #>
  fi
done


  #> Buggy - rewrite script from this point on.
  #>  - put the entire thing in a true loop
  #>    - check for leading forward slash
  #>      - if missing, then prepend output of \pwd\
  #>    - handle a double forward slash at the far left of the string
  #>    - using \awk -F/\, separate the pathname out into separate
  #>    elements
  #>    - load the elements into the positional array
  #>    - start with a \symlink_detected\ canary variable, set to \no\
  #>      - loop through the array; the idea is to use concatenation to
  #>      build up a new pathname; loop on \$# and \$1; use \shift\
  #>        - for each element, add one leading forward slash to the
  #>        current element
  #>        - if there was an existing \canpath\ string from a previous
  #>        loop, then prepend that on
  #>        - use both \file\ and \test\ to determine the filetype of
  #>        the basename of the \canpath\ string
  #>        - if both utilities agree, then
  #>          - if element is a symlink, then switch \symlink_detected\
  #>          to \yes\
  #>            - get the value of the symlink from \file\
  #>            - test for whether the of value from \file\ has a
  #>            leading forward slash
  #>              - if yes, then use the symlink\s value as the total
  #>              pathname thus far and continue
  #>              - if no, then append the symlink\s value to the
  #>              existing value of \canpath\ ...and continue?
  #>          - if element is a directory, then continue
  #>          - if element is neither a symlink nor a directory, then
  #>            - if there are no more elements in the loop, then
  #>            \break 1\
  #>            - if there are elements remaining, then error
  #>              ...and figure out what that means. is it a dangling
  #>              symlink?
  #>        - if the two utilities disagree, then error
  #>      end element loop
  #>      - if \symlink_detected\ is \yes\, then remain in the true
  #>      loop; otherwise \break 2\
  #>  - end true loop
  #>  - how do you detect data loops? tmp file of pathnames at top of
  #>  each true loop - duplicates mean data loop and error?
  #>
  #: "output_verbose_on: ${output_verbose_on}" #>
  #exit "${LINENO}" #>


exit 00

