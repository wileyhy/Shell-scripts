#!/bin/bash
# fake-prng.sh - Version 1.0
# shellcheck disable=SC2319,SC2312


##<> Debug
#reset #<>
#clear #<>
#set -x #<>
set -eu #<>
set -C #<>
shopt -s nullglob inherit_errexit


### Setup

## Traps
trap - EXIT INT
# shellcheck disable=SC2329
_trap_function_(){
  trap - EXIT INT;
  /bin/kill -s INT "$$";
}
trap _trap_function_ EXIT INT;


## Remove any data files from previous executions of this script.
filename_template=/dev/shm/value
_remove_data_files_()
{
  for FF in "${filename_template}"_*;
  do
    if [[ -f "${FF}" ]] \
      && [[ ! -L "${FF}" ]]
    then
      : t #<>
      if rm -- "${FF}";
      then
        : t #<>
        :
      else
        : f:$? #<>
        printf '\n\tCommand \rm\ failed; exiting.'
        exit "${LINENO}"
      fi
    else : "f:$?" #<>
    fi
  done
}
_remove_data_files_

  #set -x #<>


## Variables
output_max_length=8

# Capture the time in \seconds since the epoch\ format.
start_time=$( date +%s )

# Define a filepath and name for the data file.
file=${filename_template}_${start_time}
output=0
ii=0
current_file=${file}_${ii}

# Digest binaries
digest_binaries=()
for BB in "b2sum" "sha512sum" "sha384sum" "sha256sum" "sha224sum" "sha1sum";
do
  :;: "Command must exist in PATH."
  if command -v "${BB}" >/dev/null
  then
    : t #<>
    if (( ${#digest_binaries[@]} < 3 ))
    then
      : t #<>
      digest_binaries+=( "${BB}" )
    else
      : f:$? #<>
      break
    fi
  else
    : f:$? #<>
    continue
  fi
done

:;: "Only add the \\broken\\ digests if the more secure ones are NA."
for AA in md5sum cksum sum;
do
  if (( ${#digest_binaries[@]} < 3 ))
  then
    : t #<>
    if command -v "${BB}" >/dev/null
    then
      : t #<>
      printf '\n\tWarning: using insecure digest function: %s\n.' "${AA}"
      digest_binaries+=( "${AA}" )
    else : f:$? #<>
    fi
  else
    : f:$? #<>
    break
  fi
done


### Start with some number

:;: "Write a non-random number to file."
# shellcheck disable=SC3028
printf '%s\n' $(( "${PPID:- "$$"}" * "${RANDOM:="${start_time}"}" )) \
  | tee "${current_file}" >/dev/null
next_file=${file}_$(( ++ii ))


### Process the number, once per each digest command
xx=0
for CC in "${digest_binaries[@]}";
do
  :;: "Index counter. \\break\\ after three rounds."
  xx=$(( ++xx ))

  :;: "Take the digest of file."
  command -p "${CC}" "${current_file}" \
    | tee "${next_file}" >/dev/null
  current_file=${next_file}
  next_file=${file}_$(( ++ii ))

    #set -x #<>


  :;: "Assign values to variables using data from file."
  # Note, \read\ requires a trailing newline.
  read -r dividend divisor _ < "${current_file}";

    #dividend=$( sha256sum <<< "${dividend}" ) #<>
    #declare -p dividend divisor ii current_file next_file #<>


  :;: "Remove any filenames from the divisor, or dashes."
  if [[ ${divisor} =~ ^(-|/[[:alnum:]]*/.*)$ ]]
  then
    : t #<>
    divisor=;
  else : f:$? #<>
  fi

  :;: "Remove any non-integer characters or leading zeros, "
  #   Note, \cut\ command is not necc with \sum\ or \cksum\; other
  #   bins not yet tested.
  _remove_non_integers_and_leading_zeros_()
  {
    local var
    var=${1:-};

    if (( ${#var} > 0 ))
    then
      : t #<>
      if [[ ${var} =~ [^[:digit:]] ]]
      then
        : t #<>
        var=$( printf '%s' "${var}" \
          | sed 's/[^[:digit:]]//g')
      else : f:$? #<>
      fi

      :;: "Also remove leading zeros."
      var=$( printf 'scale=0; %s * 1\n' "${var}" \
          | bc \
          | tr -d '\\\n')

      :;: "Print the output to populate the variable assignment"
      printf '%s' "${var}"
    else
      : f:$? #<>
      return
    fi
  }

  dividend=$( _remove_non_integers_and_leading_zeros_ "${dividend}" )
  divisor=$(  _remove_non_integers_and_leading_zeros_ "${divisor}"  )

    #declare -p dividend divisor #<>
    #exit "${LINENO}" #<>


  # The last digit of the dividend could be used as a divisor, so remove
  # any trailing zeros from the dividend, if the divisor is zero, is not
  # an integer, or DNE.

  :;: "Dividend should not be all zeros."
  if (( dividend != 0 ))
  then
    : t #<>
  else
    : f:$? #<>
    echo error
    exit "${LINENO}"
  fi

  :;: "Dividend must have at least 2 characters length."
  if (( ${#dividend} >= 2 ))
  then
    : t #<>
  else
    : f:$? #<>
    echo error
    exit "${LINENO}"
  fi

    #divisor=0 #<>
    #divisor= #<>
    #divisor=- #<>


  :;: "If divisor\\s problematic, use trailing non-zero integer from dividend."
  if [[ -z ${divisor} ]]
  then
    : t #<>
    while true
    do
      # Get the last digit of the string.
      last=$( printf '%s' "${dividend}" \
          | sed 's,'"${dividend%?}"',,')
      # If the last digit is a 0 or 1, then remove the digit and
      #   begin this function\s loop again.
      if [[ ${last} == [2-9] ]]
      then
        : t #<>
        dividend=${dividend%?}
        divisor=${last}
        break
      else
        : f:$? #<>
        dividend=${dividend%?}
      fi
    done
  else
    : f:$? #<>
  fi

    #declare -p dividend divisor #<>
    #exit "${LINENO}" #<>
    #set -x #<>


  :;: "Verify the divisor is an integer."
  if printf '%s' "${divisor}" \
    | grep -E '^[0-9]+$' >/dev/null
  then
    : t #<>
    : # If it is, then move to the next step.
  else
    : f$? #<>
    echo error
    exit "${LINENO}"
  fi


  :;: "Perform integer division using the \\bc\\ command."
  output=$( printf 'scale=0; %s / %d\n' "${dividend}" "${divisor}" \
      | bc \
      | tr -d '\\\n')
  while true
  do
    if (( ${#output} > output_max_length * 2 ))
    then
      : t #<>
      divisor=$(( divisor + 2 ))
      output=$( printf 'scale=0; %s / %d\n' "${output}" "${divisor}" \
          | bc \
          | tr -d '\\\n')
    else
      : f:$? #<>
      break
    fi
  done

    #declare -p dividend divisor output xx #<>
    #exit "${LINENO}" #<>

  :;: "Write the output of this round to file, and redefine file names"
  printf '%s\n' "${output}" \
    | tee "${next_file}" >/dev/null
  current_file=${next_file}
  next_file=${file}_$(( ++ii ))

  :;: "\\break\\ after three rounds."
  if (( xx == 3 ))
  then
    : t #<>
    break
  else : f:$? #<>
  fi
done


output_max_length=$(( --output_max_length )) # For zero-based math.

if (( ${#output} <= output_max_length ))
then
  : t #<>
  printf '%d\n' "${output}"
else
  : f:$? #<>
  extra=$(( ${#output} - output_max_length ))
  start=$(( extra / 2 ))

  while true
  do
    if (( ${output:${start}:1} == 0 ))
    then
      : t #<>
      start=$(( ++start ))
    else
      : f:$? #<>
      break
    fi
  done

    #declare -p extra start #<>

  printf '%d\n' "${output:${start}:${output_max_length}}"
fi

_remove_data_files_
exit 00
