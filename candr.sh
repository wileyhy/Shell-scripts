#!/bin/env sh
# candr.xtrace / canonicalize-dir.sh
# shellcheck disable=SC2028,SC2268,SC2310
#
#   Script is unfinished - 12 Nov 2026 WY
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
#_ Notes:
#_  - Redirections are applied before any expansions occur.
#_  - \#!/bin/env -i sh\ fails.
#_  - LINENO does exist in Posix 2008.
#_  - Reportedly, Solaris 10 uses a Bourne s\h w\hich is not Posix
#_  compliant.
#_      https://unix.stackexchange.com/questions/322035/\
#_        are-there-still-systems-around-with-a-bin-sh-binary
#_  - Reportedly, in Busybox \a\wk\ is optional.
#_    - \awk\s been removed from this script.
#_  - When called from a restricted interactive s\hell, the script
#_  does not inherit the restricted s\etting.
#_  - Both \realpath\ and \readlink\ weren\t specified in Posix until
#_  2024.
#_  - The \-P\ option to \type\ is not portable.
#_  - The \p\athchk\ utility offers three separate s\ets of tests;
#_  there is no overlap between sai\d s\ets in the specification, but
#_  in GNU utilities there is.
#_  - The \-q\ option to \g\rep\ does exist in Posix 2008.
#_  - In Posix-2008, the handling of \//\ is intentionally
#_  implementation defined, so catch it, flag it as an error, and
#_  write a warning to Stderr. See spec. on \d\irname\.
#_  - Defining directories with a trailing f\orward slas\h will
#_  effect whether \[[\, \test\, \[\ and \stat\ dereference
#_  symlinks. However, \realpath -e\ will still resolve such
#_  strings correctly.
#_  - The \-r\ option to \h\as\h\ does exist in Posix 2008.
#_  - If PATH is s\et RO in the interactive calling s\hell, in the
#_  script PATH can still be altered.
#_  - For \r\eadonly\ without arguments, the results are unspecified. In
#_  Bas\h, attempting in a script to assign a value to a RO variable is
#_  a fatal error, but that doesn\t appear to have been specified by
#_  Posix in 2008.
#_  - Names of special built-ins cannot be us\ed as names of functions
#_  (ie, \uns\et\).
#_  - Option \-v\ of utility \uns\et\ is in fact specified in 2008.
#_  - The \!\ keyword doesn\t print in xtrace.
#_  - Reminder: don\t change the name of /etc/passwd. Bad things
#_  happen.

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
# Posix-2024 suggestion for \Start off a \\secure shell script\\ in
# which the script avoids being spoofed by its parent,\ as found in
# its spec. for \command\.
#
# Value of IFS should include one tabstop.
IFS=' 	
'
\unalias -a
unset -f command grep hash set

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
unset ec0 ec1 ec2 ec3 ec4 ec5


:;: "Functions"
#_
#_ Uns\et xtrace and prepare to restore state at the end of this
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
    __print_notice__ "Exiting"
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
#_ Note, this particular function is us\ed in \if...fi\ tests, so the
#_ fact that it ends with a pipeline w\hich could r\eturn false is
#_ intended. However, as a standalone function, erre\xit, if the
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
#_ e\xit.
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
  #set -- a b c; shift 4 #> Error: "s\hift count out of range"
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
    __print_notice__ "Exiting"
    exit 1
    ;;
  * )
    : "\\case\\ branch: no options: use default: \\--brief\\" #>
    output_verbose_on=no
    #_ Note, No \s\hift\ c\ommand.
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

#_ Utilities & Special Builtins
#_   Script Test string: \codeblocks\ #>
#_
# Remove the hash table, so that PATH lookups are forced and
# therefore current. Posix recommends \PATH=${PATH}\ in spec. on
# \hash\.
#_
#_ Note, In Bash on Fedoras 44 & 45, this recommendation works as
#_ expected even if PATH is s\et as RO.
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
  if command -v hash
  then
    : "t:0:${LINENO}" #>
    if ! hash -r
    then
      : "f:$?:${LINENO}" #>
      __print_warning__ "Command failed" "hash -r"
    else : "t:0:${LINENO}" #>
    fi
  else : "f:$?:${LINENO}" #>
    #_ Note, If \h\ash\ is NA on the system, then this condition will
    #_ be caught in the next section.
  fi
else : "t:0:${LINENO}" #>
fi

#_ If xtrace is on, turn it off.
__xtrace_off__
  #>
  #> Script Testing:
  #enable -n break #>

#_ Tests for each c\ommand
#_ Note, Commands w\hich are not Posix at all: \e\nable\ and \w\hich\.
print_value_of_path=no

for aA in \
  "awk" \
  "cd" \
  "command" \
  "dirname" \
  "echo" \
  "enable" \
  "env" \
  "file" \
  "find" \
  "getconf" \
  "grep" \
  "hash" \
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
  "which" \
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
  #>
  #> count is 34
  #>
  #"codeblocks" #> Not Posix at all, 2008-2024, and not installed.
  #>
  #> Special Builtins per Posix 2008:
  #>    b\reak : c\ontinue . e\val e\xec e\xit e\xport r\eadonly
  #>    r\eturn s\et s\hift t\imes t\rap u\ns\et
  #>
do
    #> Just to see in w\hich directory each utility is located.
    #which "${aA}" 2>/dev/null || command -v "${aA}" #>
    #continue #>
    #>
    #> Note
    #>   - At 11/12, all non-special-builtins are located in
    #>     /usr/bin on Fedora 45.
    #>
  #_ Determine whether c\ommand \aA\ is in PATH.
  if ! command -pv -- "${aA}" >/dev/null
  then
    : "f:${ec0:=$?}" #>
    global_return_code=${ec0:=$?}
    __print_notice__ "Command is not in PATH" "${aA}"
    print_value_of_path=yes
  else : "t:0:${LINENO}" #>
  fi

  #_ Uns\et user functions
  unset -f "${aA}"
done
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

#_ If any of the c\ommands were missing, then e\xit.
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
  stdout_10_tr_d=$(
    printf '%s' "${bB}"
      | tr -d '\0'
    )
  stdout_11_strings_n1=$(
    printf '%s' "${stdout_10_tr_d}" \
      | strings -n 1
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

  # Tests on f\ilename length.
  #_
  #_ \p\athchk [no arguments]\ checks \each component of each pathname
  #_ of the underlying f\ile system\ using PATH_MAX and NAME_MAX, for any
  #_ non-searchable directory, and for any character that is invali\d in
  #_ its containing directory.
  #_
  #_ On Fedora 45, the default values according to \g\etconf\:
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
      "Error received from \\p\athchk [no args]\\" "${bB}"

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
      "Error received from \\p\athchk -P\\" "${bB}"
    break 1
  else : "t:0:${LINENO}" #>
  fi
done
:;: "End of loop" #>

#_ If any input vali\dation problems occurred, then e\xit.
__exit_per_global_return_code__
  #>
  #set -x #>
  #: exit "${LINENO}" #>

#> DEBUG BLOCK
#>
:;: "IF XTRACE IS ON -- Section on \\g\etconf\\" #>
#>  BASH_ENV          # for \bas\h\
#>  CDPATH            # for \c\d\
#>  ENV               # for \s\h\
#>  HOME              # for \c\d\
#>  LC_ALL            # Common
#>  LD_PRELOAD        # for paranoia ;-P
#>  LOGNAME           # for ?
#>  NAME_MAX          # for \p\athchk [no args]\
#>  PATH_MAX          # for \c\d\, \p\athchk [no args]\ and \p\wd\
#>  OLDPWD            # for \c\d\
#>  PATH              # for \s\h\
#>  PWD               # for \c\d\ and \p\wd\
#>  SYMLOOP_MAX       # for \chdir()\
if printf '%s' "$-" | grep -q -e "x" #>
then #>
  : "t:0:${LINENO}" "Parameter values per \\g\etconf\\" #>
  __xtrace_off__ #>
  stdout_01_getconf_a=$( getconf -a ) #>
  for eE in BASH_ENV CDPATH ENV HOME LC_ALL LD_PRELOAD NAME_MAX PATH_MAX OLDPWD PATH PWD SYMLOOP_MAX #>
  do #>
      #echo "eE: ${eE}" #>
    #> Note, this particular \if..fi\ is a workaround for erre\xit
    #> and xtrace visibility.
    if printf '%s\n' "${stdout_01_getconf_a}" | grep -E -e "^${eE} " #>
    then : "t:0:${LINENO}" #>
    else : "f:$?:${LINENO}" #>
    fi #>
  done #>
  __reset_xtrace__ #>
else : "f:$?:${LINENO}" "Section on \\g\etconf\\: xtrace is off" #>
fi #>
  #>
  #set -x #>
  #: exit "${LINENO}" #>
  #>

:;: "Unset Environment Variables"
#_ Uns\et certain e\nv. vars. if possible and if they\re defined. See
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
    #_ the c\ommand can be executed and so that (b) the various related
    #_ messages can cite the precise c\ommand string w\hich was
    #_ executed.
    cmd_str='unset -v -- "${fF}"'

    if eval command -p -- "${cmd_str}"
    then
      : "t:0:${LINENO}" "\\${cmd_str}\\ returned zero" #>
      if __check_for_variable_assignment__ "${fF}"
      then
        : "t:0:${LINENO}" #>
        __print_error__ "${fF} is defined"
        __print_notice__ "Exiting"
        exit 1
      else : "f:$?:${LINENO}" "${fF} is undefined or of zero length";: #>
      fi
    else
      __print_notice__ "Command failed" "\\${cmd_str}\\"
    fi
  else : "f:$?:${LINENO}" "${fF} is undefined or of zero length";: #>
  fi
done
  #>
  set -x #>
  : exit "${LINENO}" #>
  #unset HOME #>
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
  #HOME=~ #>
  #HOME=~root #>
  #readonly HOME #>

# Make sure HOME is defined, for \cd\.
#_
#_ Notes,
#_   - Assigning PWD depends on HOME having a vali\d value.
#_   - From Posix 2008:
#_     - Shell Command Language 2.6.1: \\If HOME is uns\et, the results
#_     are unspecified.\\
#_   - The \i\d\ utility has no knowledge of \sudo\ or means of
#_   differentiating regular vs. elevated permissions.
#_   - If the name of /etc/passwd is changed, \id\ throws an error.
stdout_02_id_un=$( id -un )
assign_variable=no

: "Define function:  __make_sure_home_is_defined__"
#>
#> If any of the tests fail, then \assign_variable\ should be \yes\.
#>
#> If all of the tests succeed, and the variable is a searchable
#> directory, then operand number two contains the value which should
#> be assigned to the variable \assign_variable\. See \eval test -x\.
#>
#> Usage: 
#>  __make_sure_home_is_defined__ [Unexpanded variable name] [yes|no]
#>  __make_sure_home_is_defined__ "HOME" "no"
#>
__make_sure_home_is_defined__ ()
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
            assign_variable=$2
          else
            : "f:0:${LINENO}" "Directory is not searchable" #>
            assign_variable=yes
          fi
        else
          : "f:0:${LINENO}" "Filesystem object is not a directory" #>
          assign_variable=yes
        fi
      else
        : "f:0:${LINENO}" "Filesystem object DNE" #>
        assign_variable=yes
      fi
    else
      : "f:0:${LINENO}" #>
      assign_variable=yes
      __print_error__ "Conflicting test results" "Line:${LINENO}"
      __print_notice__ "Exiting"
      exit 2
    fi
  else
    : "f:0:${LINENO}" "Parameter $1 is undefined" #>
    assign_variable=yes
  fi
  : "Leaving __make_sure_home_is_defined__'";:
}
__make_sure_home_is_defined__ "HOME" "no"
  #>
  #set -x #>
  : exit "${LINENO}" #>

#_ Note,
#_   - Spec. on \l\ogname\: \\The l\ogname utility explicitly ignores
#_   the LOGNAME e\nvironment variable because e\nvironment changes
#_   could produce erroneous results.\\
#_   - Therefore, use \l\ogname\.
#_
#_ Question, These commands produce different results. Why?
#_       sudo sh -c 'eval echo ~"$( logname )"' sh
#_       sudo sh -c 'eval echo ~"${LOGNAME}"' sh

:;: "Assign HOME in two different ways, if possible"
#
# Get the HOME directory via Tilde Expansion.
#_ Note, Workaround for errexit and xtrace visibility, as throughout.
if stdout_06_tilde_exp=$(
  eval echo ~"$( logname )"
)
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
  if grep -q "${stdout_02_id_un}" /etc/passwd
  then
    : "t:0:${LINENO}" #>
    #> Workaround for errexit and xtrace visibility.
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
      "Username is not present in /etc/passwd! " "${stdout_02_id_un}"
    __print_notice__ "Exiting"
    exit 1
  fi
else
  : "f:$?:${LINENO}"
  __print_error__ "Are there systems without /etc/passwd?"
  __print_notice__ "Exiting"
  exit 2
fi
  #>
  #set -x #>
  : exit "${LINENO}" #>

# Check for conflicting results.
if ! test "X${stdout_06_tilde_exp}" = "X${stdout_07_awk_etc_passwd}"
then
  : "f:$?:${LINENO}"
  __print_error__ "Conflicting test results" "Line:${LINENO}"
  __print_notice__ "Exiting"
  exit 2
else : "t:0:${LINENO}" "Result confirmed" #>
fi

  # Bug, there\s a few logic bugs in this section, depending on what
  # the outputs from Tilde Expansion and /etc/passwd could be.

# To assign or not to assign the variable.
if test "yes" = "${assign_variable}"
then
  : "t:0:${LINENO}" #> #>
  if ! HOME="${stdout_06_tilde_exp}"
  then
    : "f:$?:${LINENO}" #>
    __print_error__ "Assignment to variable failed" "HOME"
    __print_notice__ "Exiting"
    exit 1
  else : "t:0:${LINENO}" "Assignment to HOME succeeded" #>
  fi
else
  : "f:$?:${LINENO}" #>
  if test -n "${stdout_07_awk_etc_passwd}"
  then
    : "t:0:${LINENO}" #>
    if ! test "${HOME}" = "${stdout_07_awk_etc_passwd}"
    then
      : "f:$?:${LINENO}" #>
      __print_notice__ \
        "Value of HOME disagrees with /etc/passwd" "${HOME}"
      
      __make_sure_home_is_defined__ \
          "stdout_07_awk_etc_passwd" "yes"
      
      if test "yes" = "${assign_variable}"
      then
        : "t:0:${LINENO}" #> #>
        __print_notice__ "Resetting" "${stdout_07_awk_etc_passwd}"
        if ! HOME=${stdout_07_awk_etc_passwd}
        then
          : "f:$?:${LINENO}" #>
          : "Assignment to HOME failed: HOME could be set RO" #>
          readonly -p | grep -E -e "^readonly HOME="
        else : "t:0:${LINENO}" "Assignment to HOME succeeded" #>
        fi
      else : "f:$?:${LINENO}" "Unreachable code" #>
      fi
    else : "t:0:${LINENO}" "Variables match" #>
    fi
  else
    : "f:$?:${LINENO}" "Var \\stdout_07_awk_etc_passwd\\: empty" #>
    if test -n "${stdout_06_tilde_exp}"
    then
      : "t:0:${LINENO}" #>
      if ! test "${HOME}" = "${stdout_06_tilde_exp}"
      then
        : "f:$?:${LINENO}" #>
        __print_notice__ \
          "Value of HOME disagrees with Tilde Expansion" "${HOME}"
      
        __make_sure_home_is_defined__ \
            "stdout_06_tilde_exp" "yes"
      
        if test "yes" = "${assign_variable}"
        then
          : "t:0:${LINENO}" #> #>
          __print_notice__ "Resetting" "${stdout_06_tilde_exp}"
          if ! HOME=${stdout_06_tilde_exp}
          then
            : "f:$?:${LINENO}" #>
            : "Assignment to HOME failed: HOME could be set RO" #>
            readonly -p | grep -E -e "^readonly HOME="
          else : "t:0:${LINENO}" "Assignment to HOME succeeded" #>
          fi
        else : "f:$?:${LINENO}" "Unreachable code" #>
        fi
      else : "t:0:${LINENO}" "Variables match" #>
      fi
    else
      : "t:0:${LINENO}" #>
      __print_error__ "Both variables have length zero"
      __print_notice__ "Exiting"
      exit 2
    fi
  fi
fi

  echo "HOME: ${HOME}"
  #set -x #>
  exit "${LINENO}" #>

# PWD aught to be defined, for \c\d\ and \p\wd\.
#_
#_ Notes,
#_   - In Posix-2008 effects of assignments to PWD are unspecified.
#_   - In Bas\h 5.3.9+,
#_     - If restricted mode is e\nabled and PWD is undefined, a call to
#_     \c\d\ will not assign a value to PWD.
#_     - Values of HOME and PWD are inherited from the calling
#_     interactive s\hell.
#_
if __check_for_variable_assignment__ "PWD"
then
  : "t:0:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>

  #_ A call to \c\d\ is suppos\ed to assign a value to PWD.
  #_
  #_ Notes, from Posix 2008:
  #_  - Shell Command Language 2.6.1: \\If HOME is uns\et, the results
  #_  are unspecified.\\
  #_  - Spec. of \c\d\, description of algorithm:
  #_    - (Step 1) \\If no directory operand is given and the HOME
  #_    e\nvironment variable is empty or undefined, the default
  #_    behavior is implementation-defined and no further steps
  #_    s\hall be taken.\\
  #_      -- HOME aught to be defined.
  #_      -- A directory operand aught to be us\ed.
  #_    - (Step 2) \\If no directory operand is given and the HOME
  #_    e\nvironment variable is s\et to a non-empty value, the c\d
  #_    utility s\hall behave as if the directory named in the HOME
  #_    e\nvironment variable was specified as the directory
  #_    operand.\\
  #_    - (Step 3) \\If the directory operand begins with a <slas\h>
  #_    character, s\et curpath to the operand and proceed to step 7.\\
  #_    - (Step 4) \\If the first component of the directory operand
  #_    is dot or dot-dot, proceed to step 6.\\
  #_    - (Step 6) \\If the -P option is in effect, s\et curpath to
  #_    the directory operand. Otherwise....\\
  #_      -- Use the -P option.
  #_    - (Step 7) \\If the -P option is in effect, proceed to step
  #_    10.\\
  #_    - (Step 10) \\The c\d utility s\hall then perform actions
  #_    equivalent to the chdir() function called with curpath as
  #_    the path argument. If these actions fail for any reason, the
  #_    c\d utility s\hall display an appropriate error message and the
  #_    remainder of this step s\hall not be executed. ... If the -P
  #_    option is in effect, the PWD e\nvironment variable s\hall be
  #_    s\et to the string that would be output by p\wd -P. If there is
  #_    insufficient permission on the new directory, or on any
  #_    parent of that directory, to determine the current working
  #_    directory, the value of the PWD e\nvironment variable is
  #_    unspecified.\\
  #_      -- Any error message aught to be assigned to a variable.
  #_      -- The output of \p\wd -P\ is relevant.
  #_    - \-P\: \\Handle the operand dot-dot physically; symbolic
  #_    link components s\hall be resolved before dot-dot components
  #_    are process\ed.\\
  #_    - SYNOPSIS:
  #_      - \\c\d [-L|-P] [directory]\\
  #_        - \directory\: \\An absolute or relative pathname of the
  #_        directory that s\hall become the new working directory.
  #_        The interpretation of a relative pathname by c\d depends
  #_        on the -L option and the CDPATH and PWD e\nvironment
  #_        variables. If directory is an empty string, the results
  #_        are unspecified.\\
  #_
  #_  - Posix 2008 \p\wd\:
  #_    - \\The p\wd utility s\hall write to standard output an
  #_    absolute pathname of the current working directory, w\hich
  #_    does not contain the f\ilenames dot or dot-dot.\\
  #_    - \-P\: \\The pathname written to standard output s\hall not
  #_    contain any components that refer to f\iles of type symbolic
  #_    link.\\
  #_    - \PWD\: \\An absolute pathname of the current working
  #_    directory. If an application s\ets or uns\ets the value of PWD,
  #_    the behavior of p\wd is unspecified.\\
  #_  - This \if..fi\ structure is a workaround for erre\xit and
  #_  xtrace visibility
  #_
  if stderr_cd_P=$(
    cd -- "${HOME}"
    cd -P -- . 2>&1 >/dev/null
  ) #_ Subs\hell
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_error__ "Subshell failed" "cd; cd -P ."
    __print_notice__ "Exiting"
    exit 1
  fi

  if __check_for_variable_assignment__ "PWD"
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_warning__ "Parameter is undefined" "PWD"
  fi
fi

:;: "Script Variables"
canpth=
nsfod="(No such f\ile or directory)"

  set -x #>
  #printf '%s\n' stdout #>
  #printf '%s\n' stderr 1>&2 #>
  :;: set #>
  set | grep -E -e '^HOME=' -e '^PWD=' #>
  exit "${LINENO}" #>


#_ Pseudocode re function __print_output__
#_
#_ GL-scriptnm = defined
#_ GL-p\rintformat=[-b|-v]          (per execution)
#_ GL-rtnc\de=0                     (per execution)
#_
#_ GL-majloop-input-1 = defined    (per line)
#_
#_   GL-minloop-canpth = [exists/dne]
#_
#_     exists  .'. GL-minloop-STDo/e = STDOUT
#_             .'. GL-rtncode = no change
#_
#_       _print_output_
#_
#_           verbose
#_             e\cho GL-scriptnm: GL-majloop-input: \
#_                                 [GL-minloop-canpth GL-minloop-STDo/e]
#_
#_           brief
#_             e\cho                                \
#_                                 [GL-minloop-canpth GL-minloop-STDo/e]
#_
#_
#_     dne     .'. GL-minloop-STDo/e = STDERR
#_             .'. GL-rtncode = 1
#_
#_       _print_output_
#_
#_           verbose
#_             e\cho GL-scriptnm: GL-majloop-input: \
#_                                 [GL-minloop-NSFOD GL-minloop-STDo/e]
#_
#_           brief
#_             e\cho                                \
#_                                 [GL-minloop-NSFOD GL-minloop-STDo/e]
#_
#_
#_ e\xit GL-rtncode


: "Define function: __print_output__" #> #>
#_
#_ Usage:    __print_output__ [Script input] [canpth|nsfod] [redirection]
#_ Usage:    __print_output__ "${gG}" "${canpth}"
#_                                         # ^normal output to STDOUT
#_ Usage:    __print_output__ "${gG}" "${nsfod}" >&2
#_                                         # ^redirect output to STDERR
#_
#_ shellcheck disable=SC2329
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
  else
    : "f:$?:${LINENO}" #>
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
    * ) printf '%s\n' "Unreachable code"; exit "${LINENO}";; #>
  esac
    #>
    #exit "${LINENO}" #>
}
  #>
  #set -x #>
  #exit "${LINENO}" #>
  set -x #>


:;: "The given path must exist in the f\ilesystem"
# Script Test input: /dev/qwertyuiop
for gG
do
  if test -e "${gG}"
  then
    : "t:0:${LINENO}" #>
    : "Path exists"
  else
    : "f:$?:${LINENO}" #>
    global_return_code=1
    __print_output__ "${gG}" "${nsfod}" >&2
    continue 1
  fi
done


  # Buggy - rewrite script from this point on.
  #  - put the entire thing in a true loop
  #    - check for leading forward slas\h
  #      - if missing, then prepend output of \p\wd\
  #    - handle a double forward slas\h at the far left of the string
  #    - using \a\wk -F/\, separate the pathname out into separate
  #    elements
  #    - load the elements into the positional array
  #    - start with a \symlink_detected\ canary variable, s\et to \no\
  #      - loop through the array; the i\dea is to use concatenation to
  #      build up a new pathname; loop on \$# and \$1; use \s\hift\
  #        - for each element, ad\d one leading forward slas\h to the
  #        current element
  #        - if there was an existing \canpath\ string from a previous
  #        loop, then prepend that on
  #        - use both \f\ile\ and \test\ to determine the f\iletype of
  #        the basename of the \canpath\ string
  #        - if both utilities agree, then
  #          - if element is a symlink, then switch \symlink_detected\
  #          to \yes\
  #            - get the value of the symlink from \f\ile\
  #            - test for whether the of value from \f\ile\ has a
  #            leading forward slas\h
  #              - if yes, then use the symlink\s value as the total
  #              pathname thus far and c\ontinue
  #              - if no, then append the symlink\s value to the
  #              existing value of \canpath\ ...and c\ontinue?
  #          - if element is a directory, then c\ontinue
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
  #  - how do you detect data loops? tmp f\ile of pathnames at top of
  #  each true loop - duplicates mean data loop and error?

  #: "output_verbose_on: ${output_verbose_on}"
  #exit "${LINENO}"


exit 00

