#!/bin/env sh
# candr.sh / canonicalize-dir.sh
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
#N Notes:
#N   - Redirections are applied before any expansions occur.
#N   - \#!/bin/env -i sh\ fails.
#N   - LINENO does exist in Posix 2008.
#N   - Reportedly, Solaris 10 uses a Bourne s\h w\hich is not Posix
#N   compliant.
#N       https://unix.stackexchange.com/questions/322035/\
#N         are-there-still-systems-around-with-a-bin-sh-binary
#N   - Reportedly, in Busybox \a\wk\ is optional.
#N     - \awk\s been removed from this script.
#N   - When called from a restricted interactive s\hell, the script
#N   does not inherit the restricted s\etting.
#N   - Both \realpath\ and \readlink\ weren\t specified in Posix until
#N   2024.
#N   - The \-P\ option to \type\ is not portable.
#N   - The \p\athchk\ utility offers three separate s\ets of tests;
#N   there is no overlap between sai\d s\ets in the specification, but
#N   in GNU utilities there is.
#N   - The \-q\ option to \g\rep\ does exist in Posix 2008.
#N   - In Posix-2008, the handling of \//\ is intentionally
#N   implementation defined, so catch it, flag it as an error, and
#N   write a warning to Stderr. See spec. on \d\irname\.
#N   - Defining directories with a trailing f\orward slas\h will
#N   effect whether \[[\, \test\, \[\ and \stat\ dereference
#N   symlinks. However, \realpath -e\ will still resolve such
#N   strings correctly.
#N   - The \-r\ option to \h\as\h\ does exist in Posix 2008.
#N   - If PATH is s\et RO in the interactive calling s\hell, in the
#N   script PATH can still be altered.
#N   - For \r\eadonly\ without arguments, the results are unspecified. In
#N   Bas\h, attempting in a script to assign a value to a RO variable is
#N   a fatal error, but that doesn\t appear to have been specified by
#N   Posix in 2008.
#N   - Names of special built-ins cannot be us\ed as names of functions
#N   (ie, \uns\et\).
#N   - Option \-v\ of utility \uns\et\ is in fact specified in 2008.
#N   - The \!\ keyword doesn\t print in xtrace.

  #> Debug.
  #reset; clear; grep -vFe '#>' -e '#N' ./candr.sh 2>&1 | less -RNS
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


:;: "Settings."
set -a
set -u
set -C


:;: "Bootstrap Variables."
LC_ALL=C
global_return_code=0
#N Note, the Special Variable zero is of global scope.
special_var_zero=${0#./}
special_var_zero=${0##*/}
usage_msg="${special_var_zero}:

    Usage: The first argument may be an option flag.
        candr.sh [-b|-h|-v] [FILE] ...
          --brief     -b
          --help      -h
          --verbose   -v
"
unset ec0 ec1 ec2 ec3 ec4 ec5


:;: "Functions."
#N
#N Uns\et xtrace and prepare to restore state at the end of this
#N section.
#N
#N Usage:
#N     __xtrace_off__ [No arguments]
#N     __reset_xtrace__  [No arguments]
#N
: "Define functions: __xtrace_off__ & __reset_xtrace__." #>
__xtrace_off__ ()
{
  case $- in
    *x*) set +x; __reset_xtrace__ () { printf '# __reset_xtrace__\n'; set -x; }; ;;
    *) __reset_xtrace__ () { :; } ;;
  esac
  : "Leaving __xtrace_off__";: #>
}

: "Define function:  __input_required__." #>
#N
#N Usage:    __input_required__ "$@"
#N
__input_required__ ()
{
  if ! test 0 -lt "$#"
  then
    : "f:$?:${LINENO}" #>
    __print_error__ "Input required"
    __print_notice__ "Exiting."
    printf '%s\n' "${usage_msg:?}" 1>&2
    exit 1
  else : "t:0:${LINENO}" #>
  fi
  : "Leaving __input_required__";: #>
}

: "Define function:  __check_for_variable_assignment__" #>
#N
#N Usage:
#N     __check_for_variable_assignment__ [Variable]
#N     __check_for_variable_assignment__ HOME
#N
#N Note, this particular function is us\ed in \if...fi\ tests, so the
#N fact that it ends with a pipeline w\hich could r\eturn false is
#N intended. However, as a standalone function, erre\xit, if the
#N variable at \$1\ has no assigned value, causes the script to
#N halt. To have halted would have been an error. Yet, it\s Posix
#N 2008, so the least confusing workaround has been applied.
#N
__check_for_variable_assignment__ ()
{
  if ! set | grep -q -E -e "^${1}=.+"
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

: "Define function:  __print_message__." #>
#N
#N Usage:
#N         __print_message__ [Message type] [Description] [Data]
#N         __print_message__ "Warning" "$1" "${2:-}"
#N         __print_message__ "Exiting."
#N
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

: "Define functions: __print_{error,notice,warning}__." #> #>
#N
#N Usage:
#N         __print_error__   [Description] [Data]
#N         __print_warning__ "Command failed" "hash -r"
#N
__print_error__   ()
{
  __xtrace_off__
  __print_message__ "Error"    "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_error__";: #>
}

__print_notice__  ()
{
  __xtrace_off__
  __print_message__ "Notice"   "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_notice__";: #>
}

__print_warning__ ()
{
  __xtrace_off__
  __print_message__ "Warning"  "$1" "${2:-}"
  __reset_xtrace__
  : "Leaving __print_warning__";: #>
}

: "Define function:  __exit_per_global_return_code__." #> #>
#N
#N If the value of variable \global_return_code\ is non-zero, then
#N e\xit.
#N
#N Usage:
#N       __exit_per_global_return_code__ [no arguments]
#N
__exit_per_global_return_code__ ()
{
  if ! test 0 -eq "${global_return_code}"
  then
    : "f:$?:${LINENO}" #>
    __print_notice__ "Exiting."
    exit "${global_return_code}"
  else : "t:0:${LINENO}" #>
  fi
  : "Leaving __exit_per_global_return_code__";: #>
}
  #> Debug
  #__print_notice__ "Exiting."
  #__print_error__ "Input contains one or more non-printable strings."
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


:;: "Parse input."
  #>
  #> Script Testing:
  #set -- -ve #>
  #set -- -br #>
  #set -- --verbos #>
  #set -- --brie #>

__input_required__ "$@"

: "\\case\\ on posparm 1."
case "$1" in
  --verbose | -v* | --v* )
    : "\\case\\ branch: \\--verbose\\." #>
    output_verbose_on=yes
    shift
    ;;
  --brief   | -b* | --b* )
    : "\\case\\ branch: \\--brief\\." #>
    output_verbose_on=no
    shift
    ;;
  --help    | -h* | --h* | -? )
    : "\\case\\ branch: \\--help\\." #>
    printf '%s\n' "${usage_msg:?}" 1>&2
    __print_notice__ "Exiting."
    exit 1
    ;;
  * )
    : "\\case\\ branch: no options: use default: \\--brief\\." #>
    output_verbose_on=no
    #N Note, No \s\hift\ c\ommand.
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


:;: "Commands."

#N Utilities & Special Builtins
#N   Script Test string: \codeblocks\ #>
#N
# Remove the h\ash table, so that PATH lookups are forced and
# therefore current. Posix recommends \PATH=${PATH}\ in spec. on
# \h\ash\.
#N
#N Note, In Bash on Fedoras 44 & 45, this recommendation works as
#N expected even if PATH is s\et as RO.
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
    #N Note, If \h\ash\ is NA on the system, then this condition will
    #N be caught in the next section.
  fi
else : "t:0:${LINENO}" #>
fi

#N If xtrace is on, turn it off.
__xtrace_off__
  #>
  #> Script Testing:
  #enable -n break #>

#N Tests for each c\ommand
#N Note, Commands w\hich are not Posix at all: \e\nable\ and \w\hich\.
print_value_of_path=no

for aA in \
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
  #> count is 33
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

  #N Determine whether c\ommand \aA\ is in PATH.
  if ! command -pv -- "${aA}" >/dev/null
  then
    : "f:${ec0:=$?}" #>
    global_return_code=${ec0:=$?}
    __print_notice__ "Command is not in PATH" "${aA}"
    print_value_of_path=yes
  else : "t:0:${LINENO}" #>
  fi

  #N Uns\et user functions
  unset -f "${aA}"
done
  #>
  #exit "${LINENO}" #>

#N If xtrace was on, restore it.
__reset_xtrace__

#N Print the value of PATH if necessary.
if test "yes" = "${print_value_of_path}"
then
  : "t:0:${LINENO}" #>
  __print_notice__ "Value of PATH" "${PATH}"
else : "f:$?${LINENO}" #>
fi

#N If any of the c\ommands were missing, then e\xit.
__exit_per_global_return_code__
  #>
  #set -x #>
  #: exit "${LINENO}" #>
  #set +x #>


:;: "Input vali\dation: \\tr\\, \\strings\\ and \\p\athchk\\."
#
for bB in "$@"
do
    :;: "Top of loop.";: #>
    #>
  # Non-printable input is disallowed.
    #>
    #> Script Testing:
    #reset;clear #>
    #./candr.s\h "$(dd if=/dev/urandom bs=32b count=1 2>/dev/null)" #>
    #>
  __xtrace_off__

  # Remove NULs
  cC=$( printf '%s' "${bB}" | tr -d '\0'   )
  
  # Remove nonprintable
  dD=$( printf '%s' "${cC}" | strings -n 1 )

  if ! test "X${bB}" = "X${dD}"
  then
    : "f:${ec1:=$?}:${LINENO}" #>
    global_return_code=${ec1:=$?}
    __print_error__ \
      "Input contains one or more non-printable strings."
    break 1
  else : "t:0:${LINENO}" #>
  fi
  __reset_xtrace__

  # Zero length input is disallowed.
    #>
    #> Script Testing:
    #reset; clear; ./candr.s\h -v "" #>
    #>
  if ! test -n "${bB}"
  then
    : "f:${ec2:=$?}:${LINENO}" #>
    global_return_code=${ec2:=$?}
    __print_error__ "Zero length input." ""
    break 1
  else : "t:0:${LINENO}" #>
  fi

    #set -x #>

  # Filenames beginning with a hyphen are disallowed.
  #N
  #N Note, see Posix 2008, General Concepts 4.7.
    #>
    # Script Testing: #>
    #reset; clear; ./candr.s\h -v -foo #>
    #>
  stdout_00_cut=$( printf '%s' "${bB}" | cut -c 1 )

  if ! test "-" != "${stdout_00_cut}"
  then
    : "f:${ec3:=$?}:${LINENO}" #>
    global_return_code=${ec3:=$?}
    __print_error__ \
      "Filenames beginning with a hyphen are disallowed." "${bB}"
    break 1
  else : "t:0:${LINENO}" #>
  fi

  # Tests on f\ilename length.
  #N
  #N \p\athchk [no arguments]\ checks \each component of each pathname
  #N of the underlying f\ile system\ using PATH_MAX and NAME_MAX, for any
  #N non-searchable directory, and for any character that is invali\d in
  #N its containing directory.
  #N
  #N On Fedora 45, the default values according to \g\etconf\:
  #N   NAME_MAX                            255
  #N   PATH_MAX                            4096
    #>
    #> Script Testing:
    #reset; clear; ./candr.s\h -v foooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo #>
    #>
  if ! pathchk -- "${bB}"
  then
    : "f:${ec4:=$?}:${LINENO}" #>
    global_return_code=${ec4:=$?}
    __print_error__ \
      "Error received from \\p\athchk [no args]\\." "${bB}"

    #N Print out the values of the relevant variables.
    __print_notice__ "Values of relevant system parameters"
    getconf -a | grep -E -e ^"PATH_MAX" -e ^"NAME_MAX"
    break 1
  else : "t:0:${LINENO}" #>
  fi

  # Filenames beginning with a hyphen are disallowed.
  #N
  ##NNote, see Posix 2008, General Concepts 4.7.
    #>
    # Script Testing: #>
    #reset; clear; ./candr.s\h -v /-foo #>
    #>
  if ! pathchk -P -- "${bB}"
  then
    : "f:${ec5:=$?}:${LINENO}" #>
    global_return_code=${ec5:=$?}
    __print_error__ \
      "Error received from \\p\athchk -P\\." "${bB}"
    break 1
  else : "t:0:${LINENO}" #>
  fi
done
:;: "End of loop." #>

#N If any input vali\dation problems occurred, then e\xit.
__exit_per_global_return_code__
  #>
  #set -x #>
  #: exit "${LINENO}" #>

#> DEBUG BLOCK
#>
:;: "IF XTRACE IS ON -- Section on \\g\etconf\\." #>
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
    #> Note, this particular \if..fi\ is a workaround for erre\xit.
    if printf '%s\n' "${stdout_01_getconf_a}" | grep -E -e "^${eE} " #>
    then : "t:0:${LINENO}" #>
    else : "f:$?:${LINENO}" #>
    fi #>
  done #>
  __reset_xtrace__ #>
else : "f:$?:${LINENO}: Section on \\g\etconf\\: xtrace is off." #>
fi #>
  #>
  set -x #>
  : exit "${LINENO}" #>
  #>

:;: "Unset Environment Variables."
#N Uns\et certain e\nv. vars. if possible and if they\re defined. See
#N specification pages under Posix 2008.
  #>
  #> Script Testing:
  #POSIXLY_CORRECT=yes #>
  #LD_PRELOAD=foo #>
  #fF=LD_PRELOAD #>
  #set | grep -E "^${fF}=.+"; echo $? #>
  #unset LD_PRELOAD; echo $? #>
  #set | grep -E "^${fF}=.+"; echo $? #>

for fF in \
  BASH_ENV \
  CDPATH \
  ENV \
  LD_PRELOAD \
  OLDPWD
do
    #: "fF: ${fF}" #>
    #>
  if __check_for_variable_assignment__ "${fF}"
  then
    : "t:0:${LINENO}: ${fF} is defined." #>

    #N Note, define \cmd_str\ as a particular invocation so that (a)
    #N the c\ommand can be executed and so that (b) the various related
    #N messages can cite the precise c\ommand string w\hich was
    #N executed.
    cmd_str='unset -v -- "${fF}"'

    #N Note, Word Splitting is intended in this particular c\ommand.
    # shellcheck disable=SC2086
    if ! eval command -p -- "${cmd_str}"
    then
      __print_notice__ "Command failed." "\\${cmd_str}\\"
    else : "t:0:${LINENO}: \\${cmd_str}\\ returned zero" #>
    fi
  else : "f:$?:${LINENO}: Parameter ${fF} is undefined.";: #>
  fi
done
  #>
  exit "${LINENO}" #>

# Make sure HOME is defined, for \cd\.
#N
#N Notes,
#N   - Assigning PWD depends on HOME having a vali\d value.
#N   - From Posix 2008:
#N     - Shell Command Language 2.6.1: \\If HOME is uns\et, the results
#N     are unspecified.\\
#N   - The \i\d\ utility has no knowledge of \sudo\ or means of
#N   differentiating regular vs. elevated permissions.
stdout_02_id_un=$( id -un )
assign_home=no

  # Bug, the logic of this codeblock is a little fuzzy.
  #   - Why use the \p\rintf | g\rep\?
  #   - The \e\val\ seems like the most dependable solution, but the
  #   stdout of \l\ogname\ vs. the value of LOGNAME happens why?
  #

if __check_for_variable_assignment__ "HOME"
then
  : "t:0:${LINENO}" "Parameter HOME is defined." #>
  if printf '%s\n' "${HOME}" | grep -q -e "${stdout_02_id_un}"
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    assign_home=yes
  fi
else
  : "f:$?:${LINENO}: Parameter HOME is undefined." #>
  assign_home=yes
fi

#N Note,
#N   - Spec. on \l\ogname\: \\The l\ogname utility explicitly ignores
#N   the LOGNAME e\nvironment variable because e\nvironment changes
#N   could produce erroneous results.\\

  # Bug, These c\ommands produce different results:
  #       sudo sh -c 'eval echo ~"$( logname )"' sh
  #       sudo sh -c 'eval echo ~"${LOGNAME}"' sh

if test "yes" = "${assign_home}"
then
  : "t:0:${LINENO}" #>
  :;: "Assign HOME."
  if HOME=$(
    eval echo ~"$(logname)"
  )
  then
    : "t:0:${LINENO}: Assignment to HOME succeeded." #>
  else
    : "f:$?:${LINENO}" #>
    __print_error__ "Assignment to variable failed" "HOME"
    __print_notice__ "Exiting"
    exit 1
  fi
else
  : "f:$?:${LINENO}" #>
fi

# PWD aught to be defined, for \c\d\ and \p\wd\.
#N
#N Notes,
#N   - In Posix-2008 effects of assignments to PWD are unspecified.
#N   - In Bas\h 5.3.9+,
#N     - If restricted mode is e\nabled and PWD is undefined, a call to
#N     \c\d\ will not assign a value to PWD.
#N     - Values of HOME and PWD are inherited from the calling
#N     interactive s\hell.
#N
if __check_for_variable_assignment__ "PWD"
then
  : "t:0:${LINENO}" #>
else
  : "f:$?:${LINENO}" #>

  #N A call to \c\d\ is suppos\ed to assign a value to PWD.
  #N
  #N Notes, from Posix 2008:
  #N   - Shell Command Language 2.6.1: \\If HOME is uns\et, the results
  #N   are unspecified.\\
  #N   - Spec. of \c\d\, description of algorithm:
  #N     - (Step 1) \\If no directory operand is given and the HOME
  #N     e\nvironment variable is empty or undefined, the default
  #N     behavior is implementation-defined and no further steps
  #N     s\hall be taken.\\
  #N       -- HOME aught to be defined.
  #N       -- A directory operand aught to be us\ed.
  #N     - (Step 2) \\If no directory operand is given and the HOME
  #N     e\nvironment variable is s\et to a non-empty value, the c\d
  #N     utility s\hall behave as if the directory named in the HOME
  #N     e\nvironment variable was specified as the directory
  #N     operand.\\
  #N     - (Step 3) \\If the directory operand begins with a <slas\h>
  #N     character, s\et curpath to the operand and proceed to step 7.\\
  #N     - (Step 4) \\If the first component of the directory operand
  #N     is dot or dot-dot, proceed to step 6.\\
  #N     - (Step 6) \\If the -P option is in effect, s\et curpath to
  #N     the directory operand. Otherwise....\\
  #N       -- Use the -P option.
  #N     - (Step 7) \\If the -P option is in effect, proceed to step
  #N     10.\\
  #N     - (Step 10) \\The c\d utility s\hall then perform actions
  #N     equivalent to the chdir() function called with curpath as
  #N     the path argument. If these actions fail for any reason, the
  #N     c\d utility s\hall display an appropriate error message and the
  #N     remainder of this step s\hall not be executed. ... If the -P
  #N     option is in effect, the PWD e\nvironment variable s\hall be
  #N     s\et to the string that would be output by p\wd -P. If there is
  #N     insufficient permission on the new directory, or on any
  #N     parent of that directory, to determine the current working
  #N     directory, the value of the PWD e\nvironment variable is
  #N     unspecified.\\
  #N       -- Any error message aught to be assigned to a variable.
  #N       -- The output of \p\wd -P\ is relevant.
  #N     - \-P\: \\Handle the operand dot-dot physically; symbolic
  #N     link components s\hall be resolved before dot-dot components
  #N     are process\ed.\\
  #N     - SYNOPSIS:
  #N       - \\c\d [-L|-P] [directory]\\
  #N         - \directory\: \\An absolute or relative pathname of the
  #N         directory that s\hall become the new working directory.
  #N         The interpretation of a relative pathname by c\d depends
  #N         on the -L option and the CDPATH and PWD e\nvironment
  #N         variables. If directory is an empty string, the results
  #N         are unspecified.\\
  #N
  #N   - Posix 2008 \p\wd\:
  #N     - \\The p\wd utility s\hall write to standard output an
  #N     absolute pathname of the current working directory, w\hich
  #N     does not contain the f\ilenames dot or dot-dot.\\
  #N     - \-P\: \\The pathname written to standard output s\hall not
  #N     contain any components that refer to f\iles of type symbolic
  #N     link.\\
  #N     - \PWD\: \\An absolute pathname of the current working
  #N     directory. If an application s\ets or uns\ets the value of PWD,
  #N     the behavior of p\wd is unspecified.\\
  #N   - This \if..fi\ structure is a workaround for erre\xit.
  #N
  if stderr_cd_P=$(
    cd -- "${HOME}"
    cd -P -- . 2>&1 >/dev/null
  ) #N Subs\hell
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_error__ "Subs\hell failed" "cd; cd -P ."
    __print_notice__ "Exiting"
    exit 1
  fi

  if __check_for_variable_assignment__ "PWD"
  then
    : "t:0:${LINENO}" #>
  else
    : "f:$?:${LINENO}" #>
    __print_warning__ "Parameter is undefined." "PWD"
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


#N Pseudocode re function __print_output__
#N
#N GL-scriptnm = defined
#N GL-p\rintformat=[-b|-v]          (per execution)
#N GL-rtnc\de=0                     (per execution)
#N
#N GL-majloop-input-1 = defined    (per line)
#N
#N   GL-minloop-canpth = [exists/dne]
#N
#N     exists  .'. GL-minloop-STDo/e = STDOUT
#N             .'. GL-rtncode = no change
#N
#N       _print_output_
#N
#N           verbose
#N             e\cho GL-scriptnm: GL-majloop-input: \
#N                                 [GL-minloop-canpth GL-minloop-STDo/e]
#N
#N           brief
#N             e\cho                                \
#N                                 [GL-minloop-canpth GL-minloop-STDo/e]
#N
#N
#N     dne     .'. GL-minloop-STDo/e = STDERR
#N             .'. GL-rtncode = 1
#N
#N       _print_output_
#N
#N           verbose
#N             e\cho GL-scriptnm: GL-majloop-input: \
#N                                 [GL-minloop-NSFOD GL-minloop-STDo/e]
#N
#N           brief
#N             e\cho                                \
#N                                 [GL-minloop-NSFOD GL-minloop-STDo/e]
#N
#N
#N e\xit GL-rtncode


: "Define function: __print_output__." #> #>
#N
#N Usage:    __print_output__ [Script input] [canpth|nsfod] [redirection]
#N Usage:    __print_output__ "${gG}" "${canpth}"
#N                                         # ^normal output to STDOUT
#N Usage:    __print_output__ "${gG}" "${nsfod}" >&2
#N                                         # ^redirect output to STDERR
#N
#N shellcheck disable=SC2329
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
    : "t:0:${LINENO}" #>
    output_verbose_on=yes
  else
    : "f:$?:${LINENO}" #>
  fi

  :;: "\\case\\ on \\output_verbose_on\\."
  case "${output_verbose_on}" in
    yes | y )
      : "\\case\\ branch: \\yes\\." #>
      printf '%s: %b%s%b -> %s\n' \
        "${special_var_zero}" "\x27" "$1" "\x27" "$2"
      ;;
    no | n )
      : "\\case\\ branch: \\no\\." #>
      printf '%s\n' "$2"
      ;;
    * ) printf '%s\n' "Unreachable code."; exit "${LINENO}";; #>
  esac
    #>
    #exit "${LINENO}" #>
}
  #>
  #set -x #>
  #exit "${LINENO}" #>
  set -x #>


:;: "The given path must exist in the f\ilesystem."
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

