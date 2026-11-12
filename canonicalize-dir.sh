#!/bin/env sh
# candr.sh / canonicalize-dir.sh
# shellcheck disable=SC2028,SC2268,SC2310
#
#   Script is unfinished - 11 Nov 2026 WY
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
#   compliant.
#       https://unix.stackexchange.com/questions/322035/\
#         are-there-still-systems-around-with-a-bin-sh-binary
#   - Reportedly, in Busybox \a\wk\ is optional.
#     - \awk\s been removed from this script.
#   - When called from a restricted interactive shell, the script
#   does not inherit the restricted setting.
#   - Both \realpath\ and \readlink\ weren\t specified in Posix until
#   2024.
#   - The \-P\ option to \type\ is not portable.
#   - The \pathchk\ utility offers three separate sets of tests;
#   there is no overlap between said sets in the specification, but
#   in GNU utilities there is.
#   - The \-q\ option to \g\rep\ does exist in Posix 2008.
#   - In Posix-2008, the handling of \//\ is intentionally
#   implementation defined, so catch it, flag it as an error, and
#   write a warning to Stderr. See spec. on \dirname\.
#   - Defining directories with a trailing f\orward slash will
#   effect whether \[[\, \test\, \[\ and \stat\ dereference
#   symlinks. However, \realpath -e\ will still resolve such
#   strings correctly.
#   - The \-r\ option to \hash\ does exist in Posix 2008.
#   - If PATH is s\et RO in the interactive calling shell, in the
#   script PATH can still be altered.
#   - For \readonly\ without arguments, the results are unspecified. In
#   Bash, attempting in a script to assign a value to a RO variable is
#   a fatal error, but that doesn\t appear to have been specified by
#   Posix in 2008.
#   - Names of special built-ins cannot be used as names of functions
#   (ie, \unset\).
#   -



  #> Debug.
  \set -x #>
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
  #\exit "${LINENO}" #>


\:;\: "Security."
#
# Posix-2024 suggestion for \Start off a \\secure shell script\\ in
# which the script avoids being spoofed by its parent,\ as found in
# its spec. for \command\.
#
# Value of IFS should include one tabstop.
IFS=' 	
'
\unalias -a
unset -f command \
  grep hash set

# PATH could be set as RO.
if PATH="$( command -p getconf PATH ):${PATH}"
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"
  printf '%s: Notice: Assignment to variable failed: %s\n' \
    "$0" "PATH"
  printf '%s: Notice: Value of variable %s: <%s>\n' \
    "$0" "PATH" "${PATH}"
fi

  #exit "${LINENO}" #>
  #set -x #>


:;: "Settings."
set -a
set -u
set -C


:;: "Bootstrap Variables."
LC_ALL=C
global_return_code=0
special_var_zero=${0#./}
special_var_zero=${0##*/}
usage_msg="${special_var_zero}:

    Usage: The first argument may be an option flag.
        candr.sh [-b|-v] [FILE] ...
"
unset ec0 ec1 ec2 ec3 ec4 ec5


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
      __reset_xtrace__ ()
      {
        printf '# __reset_xtrace__\n'
        set -x
        : "Leaving __reset_xtrace__";:
      }
      set +x
      ;;
    *)
      __reset_xtrace__ ()
      {
        :
        : "Leaving __reset_xtrace__";:
      }
      ;;
  esac
  : "Leaving __xtrace_off__";:
}

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
    __print_error__ "Input required"
    __print_notice__ "Exiting."
    printf '%s\n' "${usage_msg:?}" 1>&2
    exit 1
  fi
  : "Leaving __input_required__";:
}

: "Define function:  __check_for_variable_assignment__"
#
# Usage:
#     __check_for_variable_assignment__ [Variable]
#     __check_for_variable_assignment__ HOME
#
# Note, this particular function is used in \if...fi\ tests, so the
# fact that it ends with a pipeline which could return false is
# intended. However, as a standalone function, errexit, if the
# variable at \$1\ has no assigned value, causes the script to
# halt. To have halted would have been an error. Yet, it\s Posix
# 2008, so the least confusing workaround has been applied.
#
__check_for_variable_assignment__ ()
{
  if set | grep -q -E -e "^${1}=.+"
  then
    : "t:0:${LINENO}"
  else
    : "f:$?:${LINENO}"
    return 1
  fi
  : "Leaving __check_for_variable_assignment__";:
}

  # Script Testing:
  #__check_for_variable_assignment__ PATH
  #__check_for_variable_assignment__ TTY
  #exit "${LINENO}"

: "Define function:  __print_message__."
#
# Usage:
#         __print_message__ [Message type] [Description] [Data]
#         __print_message__ "Warning" "$1" "${2:-}"
#
__print_message__ ()
{
  printf '%s: %s: %s: <%s>\n' \
    "${special_var_zero}" "$2" "$3" "${4:-}" 2>&1
  : "Leaving __print_message__";:
}

: "Define functions: __print_*__."
#
# Usage:
#         __print_error__   [Description] [Data]
#         __print_warning__ "Command failed" "hash -r"
#
__print_error__   ()
{
  __print_message__ "Error"    "$1" "${2:-}"
  : "Leaving __print_error__";:
}
__print_notice__  ()
{
  __print_message__ "Notice"   "$1" "${2:-}"
  : "Leaving __print_notice__";:
}
__print_warning__ ()
{
  __print_message__ "Warning"  "$1" "${2:-}"
  : "Leaving __print_warning__";:
}



  # Script Testing
  #set --
  #set -- a b c
  #set -- a b c; shift 4 # Error: "shift count out of range"
  #set -- a b c; shift 3
  #__input_required__ "$@"
  #exit "${LINENO}"


:;: "Parse input."
#
  # Script Testing:
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

  #exit "${LINENO}" #>

__input_required__ "$@"

  #: "output_verbose_on: ${output_verbose_on}" #>
  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


:;: "Commands."
#
# Utilities & Special Builtins
#   Script Test string: \codeblocks\
#
# Remove the hash table, so that PATH lookups are forced and
# therefore current. Posix recommends \PATH=${PATH}\ in spec. on
# \hash\. In Bash on Fedoras 44 & 45, this recommendation works as
# expected even if PATH is set as RO.

  # Script Testing:
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
    if hash -r
    then
      : "t:0:${LINENO}"
    else
      : "f:$?:${LINENO}"
      __print_warning__ "Command failed" "hash -r"
    fi
  else
    : "f:$?:${LINENO}"
    __print_notice__ "Command is not in PATH" "hash"
  fi
fi

# If xtrace is on, turn it off.
__xtrace_off__

  # Script Testing:
  #enable -n break

# Tests for each command
for aA in \
  "cd" "command" "dirname" "env" \
  "file" "find" "getconf" "grep" "id" \
  "ls" "pathchk" "printf" "ps" "pwd" \
  "sed" "sh" "strings" "test" "true" \
    "type" "unalias" "which" \
  ":" "break" "continue" "exit" "hash" \
    "readonly" "set" "shift" "unset" \
  "eval" "echo" "logname"
    # count is -3-2-
  #"codeblocks" #>
  # Note, \codeblocks\ is not specified by Posix-2008; the
  # rest of the commands in this list are, except for \which\.
do
    #> Just to see in which directory each utility is located.
    #which "${aA}"; continue #>
    #> Note
    #>   - At 32 commands, all non-special-builtins are located in
    #>     /usr/bin on Fedora 44.

  # Determine whether command \aA\ is in PATH.
  if command -pv -- "${aA}" >/dev/null
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec0:=$?}"
    __print_notice__ "Command is not in PATH" "${aA}"
    global_return_code=${ec0}
  fi
  # Unset user functions
  unset -f "${aA}"
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
    __print_notice__ "Value of PATH" "${PATH}"
    __print_notice__ "Exiting."
    exit "${global_return_code}"
fi

  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


:;: "Input validation: \\tr\\, \\strings\\ and \\pathchk\\."
#
for bB in "$@"
do
  :;: "Top of loop.";:

  # Input validation: Error and exit.
  #
  # Script Testing:
  #reset; clear; ./candr.sh -v \
  #"$( dd if=/dev/urandom bs=32b count=1 2>/dev/null )"
  #
  __xtrace_off__
  cC=$( printf '%s' "${bB}" | tr -d '\0'   ) # Remove NULs
  dD=$( printf '%s' "${cC}" | strings -n 1 ) # Remove nonprintable

  if test "X${bB}" = "X${dD}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec1:=$?}:${LINENO}"
    global_return_code=${ec1}
    __print_error__ \
      "Input contains one or more non-printable strings."
    break 1
  fi
  __reset_xtrace__

  # Zero length input is disallowed: Error and exit.
  #
  # Script Testing:
  #reset; clear; ./candr.sh -v ""
  #
  if test -n "${bB}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec2:=$?}:${LINENO}"
    global_return_code=${ec2}
    __print_error__ "Zero length input." ""
    break 1
  fi

    #set -x #>

  # Filenames beginning with a hyphen are disallowed: Error and exit.
  #
  # Note, see Posix 2008, General Concepts 4.7.
  #
  # Script Testing:
  #reset; clear; ./candr.sh -v -foo
  #
  stdout_00_cut=$( printf '%s' "${bB}" | cut -c 1 )
  if test "-" != "${stdout_00_cut}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec3:=$?}:${LINENO}"
    global_return_code=${ec3}
    __print_error__ \
      "Filenames beginning with a hyphen are disallowed." "${bB}"
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
  # Script Testing:
  #reset; clear; ./candr.sh -v foooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
  #
  if pathchk -- "${bB}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec4:=$?}:${LINENO}"
    global_return_code=${ec4}
    __print_error__ \
      "Error received from \\pathchk [no args]\\." "${bB}"

    # Print out the values of the relevant variables.
    __print_notice__ "Values of relevant system parameters"
    getconf -a | grep -E -e ^"PATH_MAX" -e ^"NAME_MAX"
    break 1
  fi

  # Filenames beginning with a hyphen are disallowed: Error and exit.
  #
  # Note, see Posix 2008, General Concepts 4.7.
  #
  # Script Testing:
  #reset; clear; ./candr.sh -v /-foo
  #
  if pathchk -P -- "${bB}"
  then
    : "t:0:${LINENO}"
  else
    : "f:${ec5:=$?}:${LINENO}"
    global_return_code=${ec5}
    __print_error__ \
      "Error received from \\pathchk -P\\." "${bB}"
    break 1
  fi
done

if test 0 -eq "${global_return_code}"
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"
  __print_notice__ "Exiting"
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
#   SYMLOOP_MAX       # for \chdir()\
if printf '%s' "$-" | grep -q -e "x"
then
  : "t:0:${LINENO}"

    : "Parameter values per \\getconf\\" #>

  __xtrace_off__
  stdout_01_getconf_a=$( getconf -a )
  for eE in \
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
      #echo "eE: ${eE}" #>

    # Note, this particular \if..fi\ is a workaround for errexit.
    if printf '%s\n' "${stdout_01_getconf_a}" | grep -E -e "^${eE} "
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
# See man pages under Posix 2008.
#
# Unset certain env. vars. if possible and if they\re defined.

    # Script Testing:
    #POSIXLY_CORRECT=yes
    #LD_PRELOAD=foo
    #fF=LD_PRELOAD
    #set | grep -E "^${fF}=.+"; echo $?
    #unset LD_PRELOAD; echo $?
    #set | grep -E "^${fF}=.+"; echo $?

for fF in \
  BASH_ENV \
  CDPATH \
  ENV \
  LD_PRELOAD \
  OLDPWD
do
    #: "fF: ${fF}" #>

  if __check_for_variable_assignment__ "${fF}"
  then
    : "t:0:${LINENO}: ${fF} is defined."

    # Bug, \-v\ of \unset\ is specified, right?

    # Note, define \cmd_str\ as a particular invocation so that (a)
    # the command can be executed and so that (b) the various related
    # messages can cite the precise command string which was
    # executed.
    cmd_str="unset -v -- ${fF}"

    # Note, Word Splitting is intended in this particular command.
    # shellcheck disable=SC2086
    if command -p -- ${cmd_str}
    then
      : "t:0:${LINENO}: \\${cmd_str}\\ returned zero"
    else
      __print_notice__ "Command failed." "\\${cmd_str}\\"
    fi
  else
    : "f:$?:${LINENO}: Parameter ${fF} is undefined.";:
  fi
done

# Make sure HOME is defined, for \cd\.
#
# Notes,
#   - Assigning PWD depends on HOME having a valid value.
#   - From Posix 2008:
#     - Shell Command Language 2.6.1: \\If HOME is unset, the results
#     are unspecified.\\
#   - The \id\ utility has no knowledge of \sudo\ or means of
#   differentiating regular vs. elevated permissions.
stdout_02_id_un=$( id -un )
assign_home=no

  # Bug, the logic of this codeblock is a little fuzzy.
  #   - Why use the \printf | grep\?
  #   - The \eval\ seems like the most dependable solution, but the
  #   stdout of \logname\ vs. the value of LOGNAME happens why?
  #

if __check_for_variable_assignment__ "HOME"
then
  : "t:0:${LINENO}" "Parameter HOME is defined."
  if printf '%s\n' "${HOME}" | grep -q -e "${stdout_02_id_un}"
  then
    : "t:0:${LINENO}"
  else
    : "f:$?:${LINENO}"
    assign_home=yes
  fi
else
  : "f:$?:${LINENO}: Parameter HOME is undefined."
  assign_home=yes
fi

# Note,
#   - Spec. on \logname\: \\The logname utility explicitly ignores
#   the LOGNAME environment variable because environment changes
#   could produce erroneous results.\\

  # Bug, These commands produce different results:
  #       sudo sh -c 'eval echo ~"$( logname )"' sh
  #       sudo sh -c 'eval echo ~"${LOGNAME}"' sh

if test "yes" = "${assign_home}"
then
  : "t:0:${LINENO}"
  :;: "Assign HOME."
  if HOME=$(
    eval echo ~"$(logname)"
  )
  then
    : "t:0:${LINENO}: Assignment to HOME succeeded."
  else
    : "f:$?:${LINENO}"
    __print_error__ "Assignment to variable failed" "HOME"
    __print_notice__ "Exiting"
    exit 1
  fi
else
  : "f:$?:${LINENO}"
fi

# PWD aught to be defined, for \cd\ and \pwd\.
#
# Notes,
#   - In Posix-2008 effects of assignments to PWD are unspecified.
#   - In Bash 5.3.9+,
#     - If restricted mode is enabled and PWD is undefined, a call to
#     \cd\ will not assign a value to PWD.
#     - Values of HOME and PWD are inherited from the calling
#     interactive shell.
#
if __check_for_variable_assignment__ "PWD"
then
  : "t:0:${LINENO}"
else
  : "f:$?:${LINENO}"

  # A call to \cd\ is supposed to assign a value to PWD.
  #
  # Notes, from Posix 2008:
  #   - Shell Command Language 2.6.1: \\If HOME is unset, the results
  #   are unspecified.\\
  #   - Spec. of \cd\, description of algorithm:
  #     - (Step 1) \\If no directory operand is given and the HOME
  #     environment variable is empty or undefined, the default
  #     behavior is implementation-defined and no further steps
  #     shall be taken.\\
  #       -- HOME aught to be defined.
  #       -- A directory operand aught to be used.
  #     - (Step 2) \\If no directory operand is given and the HOME
  #     environment variable is set to a non-empty value, the cd
  #     utility shall behave as if the directory named in the HOME
  #     environment variable was specified as the directory
  #     operand.\\
  #     - (Step 3) \\If the directory operand begins with a <slash>
  #     character, set curpath to the operand and proceed to step 7.\\
  #     - (Step 4) \\If the first component of the directory operand
  #     is dot or dot-dot, proceed to step 6.\\
  #     - (Step 6) \\If the -P option is in effect, set curpath to
  #     the directory operand. Otherwise....\\
  #       -- Use the -P option.
  #     - (Step 7) \\If the -P option is in effect, proceed to step
  #     10.\\
  #     - (Step 10) \\The cd utility shall then perform actions
  #     equivalent to the chdir() function called with curpath as
  #     the path argument. If these actions fail for any reason, the
  #     cd utility shall display an appropriate error message and the
  #     remainder of this step shall not be executed. ... If the -P
  #     option is in effect, the PWD environment variable shall be
  #     set to the string that would be output by pwd -P. If there is
  #     insufficient permission on the new directory, or on any
  #     parent of that directory, to determine the current working
  #     directory, the value of the PWD environment variable is
  #     unspecified.\\
  #       -- Any error message aught to be assigned to a variable.
  #       -- The output of \pwd -P\ is relevant.
  #     - \-P\: \\Handle the operand dot-dot physically; symbolic
  #     link components shall be resolved before dot-dot components
  #     are processed.\\
  #     - SYNOPSIS:
  #       - \\cd [-L|-P] [directory]\\
  #         - \directory\: \\An absolute or relative pathname of the
  #         directory that shall become the new working directory.
  #         The interpretation of a relative pathname by cd depends
  #         on the -L option and the CDPATH and PWD environment
  #         variables. If directory is an empty string, the results
  #         are unspecified.\\
  #
  #   - Posix 2008 \pwd\:
  #     - \\The pwd utility shall write to standard output an
  #     absolute pathname of the current working directory, which
  #     does not contain the filenames dot or dot-dot.\\
  #     - \-P\: \\The pathname written to standard output shall not
  #     contain any components that refer to files of type symbolic
  #     link.\\
  #     - \PWD\: \\An absolute pathname of the current working
  #     directory. If an application sets or unsets the value of PWD,
  #     the behavior of pwd is unspecified.\\
  #   - This \if..fi\ structure is a workaround for errexit.
  #
  if stderr_cd_P=$(
    cd -- "${HOME}"
    cd -P -- . 2>&1 >/dev/null
  ) # Subshell
  then
    : "t:0:${LINENO}"
  else
    : "f:$?:${LINENO}"
    __print_error__ "Subshell failed" "cd; cd -P ."
    __print_notice__ "Exiting"
    exit 1
  fi

  if __check_for_variable_assignment__ "PWD"
  then
    : "t:0:${LINENO}"
  else
    : "f:$?:${LINENO}"
    __print_warning__ "Parameter is undefined." "PWD"
  fi
fi

:;: "Script Variables"
canpth=
nsfod="(No such file or directory)"

  set -x #>
  #printf '%s\n' stdout #>
  #printf '%s\n' stderr 1>&2 #>
  :;: set #>
  set | grep -E -e '^HOME=' -e '^PWD=' #>
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
# Usage:    __print_output__ "${gG}" "${canpth}"
#                                         # ^normal output to STDOUT
# Usage:    __print_output__ "${gG}" "${nsfod}" >&2
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
    : "f:$?:${LINENO}" #>
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
  #    - using \a\wk -F/\, separate the pathname out into separate
  #    elements
  #    - load the elements into the positional array
  #    - start with a \symlink_detected\ canary variable, s\et to \no\
  #      - loop through the array; the idea is to use concatenation to
  #      build up a new pathname; loop on \$# and \$1; use \shift\
  #        - for each element, ad\d one leading forward slash to the
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

  #: "output_verbose_on: ${output_verbose_on}"
  #exit "${LINENO}"


:;: "The given path must exist in the filesystem."
# Script Test input: /dev/qwertyuiop
for gG
do
  if test -e "${gG}"
  then
    : "t:0:${LINENO}" #>
    : "Path exists."
  else
    : "f:$?:${LINENO}" #>
    global_return_code=1
    __print_output__ "${gG}" "${nsfod}" >&2
    continue 1
  fi
done


exit 00


##### INCORRECT #####################################################

  : "Minor loop A: Use \\file\\ to resolve any symlinks."

: "Major loop"
#   Script Testing strings: a list of common temporary directories
# in Linux.
#
#/dev/shm /var/tmp /usr/tmp /usr/local/tmp "${XDG_RUNTIME_DIR:=}/tmp" \
#/tmp ~/tmp ~ #>
#
for gG
do
  :

  : "Per major loop variables."
  majloop_orig_str=${gG}
  :
    exit "${LINENO}" #>
    #set -x #>

  while true
  do
    # In case the string is \^//$\.


    # String matching; the possibilities are endless, ie, not good.

    # Case if input is \/\, single forward slash, FS root.
    if test "X${gG}" = 'X/' \
      || test "X${gG}" = 'X//' \
      || test "X${gG}" = 'X///'
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
    if test "X${gG}" = 'X.' \
      || test "X${gG}" = 'X./' \
      || test "X${gG}" = 'X.//'
    then
      : "t:0:${LINENO}" #>
      canpth=$( pwd -P )
      __print_output__ "$1" "${canpth}"
      : exit "\${global_return_code}"
      exit "${global_return_code}"
    else
      : "f:$?:${LINENO}" #>
    fi

    for hH in '/' '//' '.' './' '..' '../'
    do
      __test_for_string__ "${hH}"
    done

      exit "${LINENO}" #>
      #set -x #>

    #   Case if input is \..\, double period, aka, \dirname\.
    #   Case if input begins with \../, anchoring file in \dirname\.
    #   Case if ....

    :
    : "Get output of \\file\\."
    stdout_03_file=$( file -- "${gG}" )

      exit "${LINENO}" #>
      #set -x #>

    # wrong
    #: "Remove trailing forward slashes if doing so won\\t empty the
    #var."



    :
    : "See whether \\file\\ says \\symbolic link\\."
    if printf '%s' "${stdout_03_file}" \
      | grep -q -E -e ': symbolic link to [/\.a-z]'
    then
      : "t:0:${LINENO}" #>

      :
      : "If so, then use \\sed\\ to get the resolved path."
      stdout_04_sed=$(
        printf '%s' "${stdout_03_file}" \
          | sed -e 's,.*: symbolic link to ,,'
        )

      :
      : "...and redefine \\gG\\ for the next iteration."
      gG=${stdout_04_sed}
    else
      : "f:$?:${LINENO}" \
        "...otherwise, test if \\directory\\ is present in string."
      if printf '%s' "${stdout_03_file}" \
        | sed -e 's,.*: ,,' \
        | grep -q -e "directory"
      then
        : "t:0:${LINENO}" "If it is, then \\break\\ this loop."
        break 1
      else
        : "f:$?:${LINENO}" "If it\\s neither a symlink nor a" \
          "directory, that\\s an error." 1>&2
        exit "${LINENO}"
      fi
    fi
  done

    exit "${LINENO}" #>
    #set -x #>

  :
  : "Record what aught to be the correct, canonicalized absolute" \
      "path."
  canpth=${gG}

  # Note, it\s something of an assumption at this time that \file\
  # will remove any symlinks from the interior of the absolute
  # pathname -- hence minor loop B.

  :
  : "Define a variable \\iI\\ that can be re-defined within a loop."
  iI=${canpth}

    exit "${LINENO}" #>
    #set -x #>

  :
  : "Minor loop B: Make sure every dir. in the abs. path is not a" \
    "symlink."
  while true
  do
    :
    : "If \\iI\\ is a directory..."
    if test -d "${iI}"
    then
      : "t:0:${LINENO}" #>

      :
      : "Then get the \\dirname\\ of \\iI\\."
      iI=$( dirname -- "${iI}" )

      :
      : "If the \\dirname\\ of \\iI\\ is also a directory..."
      if test -d "${iI}"
      then
        : "t:0:${LINENO}" #>

        :
        : "Then, if the new \\iI\\ is the filesystem root, \\/\\..."
        if test "X${iI}" = "X/"
        then
          : "t:0:${LINENO}" #>

          :
          : "Then double-check it using \\grep\\."
          if printf '%s\n' "${iI}" \
            | grep -q -E -e '^/$'
          then
            : "t:0:${LINENO}" #>
            :
            : "\\grep\\ succeeded, so \\break\\ this loop."
            __print_output__
            break 1
          else
            __print_error__ "\\test\\ passed but \\grep\\ failed."
            __print_notice__ "Exiting"
            exit "${LINENO}"
          fi
        else
          : "f:$?:${LINENO}" \
            "The new \\iI\\ is not the FS root directory; next" \
            "iteration."
          continue 1
        fi
      else
        : "f:$?:${LINENO}" \
          "The \\dirname\\ of \\iI\\ is not a directory."
        exit "${LINENO}"
      fi
    else
      __print_error__ "Value is not a directory" "${iI}"
      __print_notice__ "Exiting"
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
stdout_05_find=$( find -- "${canpth}" -prune -type d )

    exit "${LINENO}" #>
    #set -x #>

if test -n "${stdout_05_find}"
then
  : "t:0:${LINENO}" #>

  :
  : "See whether \\canpth\\ and \\stdout_05_find\\ are equivalent" \
      "strings."
  if test "X${canpth}" = "X${stdout_05_find}"
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
        : "f:$?:${LINENO}" "\\canpth\\ is not searchable."
        __print_warning__ "Directory is not searchable" "${canpth}"
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
        : "f:$?:${LINENO}" "\\canpth\\ is not readable."
        __print_warning__ "Directory is not readable." "${canpth}"
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
        : "f:$?:${LINENO}"
        __print_warning__ "Directory is not writable." "${canpth}"
      fi
        exit "${LINENO}" #>
        #set -x #>

    else
      : "f:$?:${LINENO}" "\\canpth\\ is a symlink."
      exit "${LINENO}"
    fi
  else
    : "f:$?:${LINENO}" \
        "\\canpth\\ and \\stdout_05_find\\ are not equivalent" \
        "strings." 1>&2
    exit "${LINENO}"
  fi
else
  : "f:$?:${LINENO}" \
    "\\find -type d\\ did not locate the directory." 1>&2
  exit "${LINENO}"
fi
