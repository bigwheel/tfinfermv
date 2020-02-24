#!/usr/bin/env bash
#
# Power Assert for Bash
#

# print the expanded sentense
function powerassert_expand() {
  echo ""
  echo "expanded:"
  echo ""
  echo "[[[ $@ ]]]"
}

# print diff
function powerassert_diff() {
  left_name="$1"
  right_name="$2"
  left_val="$3"
  right_val="$4"
  echo ""
  # change ---, +++ line
  echo "--- ${left_name}"
  echo "+++ ${right_name}"
  diff -u <(echo "${left_val}") <(echo "${right_val}") |
    sed -e '/^---/d' |
    sed -e '/^+++/d'
}

# print as
#
# $left:  AAA
# $right: BBB
#
function powerassert_table() {
  left_name="$1"
  right_name="$2"
  left_val="$3"
  right_val="$4"
  echo ""
  {
    echo -e "${left_name}:\t${left_val}"
    echo -e "${right_name}:\t${right_val}"
  } | column -t -s $'\t'
}

# print as
#
# [[[ $a == aa ]]]
#     |
#     a
#
function powerassert_single_point() {
  sentence="$1"
  val="$2"

  # print "|"
  echo "${sentence}"     |
    sed -e 's/[^\$]/ /g' |
    sed -e 's/\$.*$/|/'

  # indent
  echo -n "${sentence}"  |
    sed -e 's/[^\$]/ /g' |
    sed -e 's/\$.*$//'

  echo "${val}"
}

# print as
#
# [[[ $a == $b ]]]
#     |     |
#     |     BB
#     AA
#
function powerassert_double_point() {
  sentence="$1"
  right_val="$2"
  left_val="$3"

  # print "| |"
  echo "${sentence}"     |
    sed -e 's/[^\$]/ /g' |
    sed -e 's/\$/|/g '   |
    sed -e 's/ .$//'

  # print "|" and indent
  echo -n "${sentence}"  |
    sed -e 's/[^\$]/ /g' |
    sed -e 's/\$/|/g '   |
    sed -e 's/| *$//'

  echo "${left_val}"

  # indent
  echo -n "${sentence}"  |
    sed -e 's/[^\$]/ /g' |
    sed -e 's/\$.*$//'

  echo "${right_val}"
}

# print stack trace
function powerassert_print_stacktrace() {
  echo ""
  index=0
  while frame=($(caller "${index}")); do
    ((index++))
    # do not print stacks in power assert
    if [ "${frame[2]}" == "power-assert.bash" ]; then
      continue
    fi
    # at function <function name> (<file name>:<line no>)
    echo "at function ${frame[1]} (${frame[2]}:${frame[0]})"
  done
}

# Return error point: "<file name> <line no>"
function powerassert_error_point() {
  index=0
  while frame=($(caller "${index}")); do
    ((index++))
    if [ "${frame[2]}" == "power-assert.bash" ]; then
      continue
    fi
    # the first stack out of power assert
    echo "${frame[2]}" "${frame[0]}"
    return
  done
}

# remove spaces and brackets from command sentence
function powerassert_get_equation() {
  sentence="$1"
  echo "${sentence}"                 |
    sed -e 's/^\[\[\[[[:space:]]*//' |
    sed -e 's/[[:space:]]*\]\]\]$//'
}

# TODO: make regex matching with variables to be more pricise

# get left term from equation string
function powerassert_get_left_term() {
  equation="$1"
  # match to $a ${a} "$a" "${a}"
  if [[ ${equation} =~ ^\$[A-Za-z0-9_?]+     ||
        ${equation} =~ ^\$\{[A-Za-z0-9_?]+\} ||
        ${equation} =~ ^\"\$[A-Za-z0-9_?]+\" ||
        ${equation} =~ ^\"\$\{[A-Za-z0-9_?]+\}\" ]]; then
    echo "${BASH_REMATCH[0]}"
  else
    echo ""
  fi
}

# get right term from equation string
function powerassert_get_right_term() {
  equation="$1"
  # match to $a ${a} "$a" "${a}"
  if [[ ${equation} =~ \$[A-Za-z0-9_?]+$     ||
        ${equation} =~ \$\{[A-Za-z0-9_?]+\}$ ||
        ${equation} =~ \"\$[A-Za-z0-9_?]+\"$ ||
        ${equation} =~ \"\$\{[A-Za-z0-9_?]+\}\"$ ]]; then
    echo "${BASH_REMATCH[0]}"
  else
    echo ""
  fi
}

# describe in the case where
#   [[[ <operator> <term> ]]]
# or
#   [[[ ! <operator> <term> ]]]
function powerassert_describe_2word() {
  sentence="$1"
  shift
  argv=("$@")
  if [ "$#" -gt 2 ]; then
    not="true"
    operatior="$2"
    val="$3"
  else
    not=""
    operatior="$1"
    val="$2"
  fi
  equation="$(powerassert_get_equation "${sentence}")"
  name="$(powerassert_get_right_term "${equation}")"
  case "${operatior}" in
    -z | -n )
      if [ -z "${name}" ]; then
        return
      fi
      powerassert_single_point "${sentence}" "\"${val}\""
      return
      ;;

    -d | -f | -s | -r | -w | -x )
      if [ -n "${name}" ]; then
        powerassert_single_point "${sentence}" "${val}"
      fi
      echo ""
      echo "ls -l ${val}"
      echo -n "->  "
      ls -l "${val}"
      return
      ;;

    * )
      return
      ;;
  esac
}

# describe in the case where
#   [[[ <left term> <operator> <right term> ]]]
# or
#   [[[ ! <left term> <operator> <right term> ]]]
function powerassert_describe_3word() {
  sentence="$1"
  shift
  argv=("$@")
  if [ "$#" -gt 3 ]; then
    not="true"
    left_val="$2"
    operatior="$3"
    right_val="$4"
  else
    not=""
    left_val="$1"
    operatior="$2"
    right_val="$3"
  fi

  equation="$(powerassert_get_equation "${sentence}")"

  left_name="$(powerassert_get_left_term "${equation}")"
  right_name="$(powerassert_get_right_term "${equation}")"

  num_var=0
  if [ "${left_name}" != "" ]; then
    ((num_var++))
  fi
  if [ "${right_name}" != "" ]; then
    ((num_var++))
  fi

  if [ "${num_var}" -eq 0 ]; then
    return
  fi

  case "${operatior}" in
    == | != )
      # == or ! !=
      if [[ ${operatior} == "==" && -z $not ]] ||
         [[ ${operatior} == "!=" && -n $not ]]; then

        # if either of left or right value has two or more line, print diff
        if [ $(echo "${left_val}" | wc -l) -gt 1 ] ||
           [ $(echo "${right_val}" | wc -l) -gt 1 ]
        then
          powerassert_diff                 \
            "${left_name}" "${right_name}" \
            "${left_val}" "${right_val}"
          return
        fi

        if [ "${num_var}" -eq 2 ]; then
          powerassert_table                     \
            "${left_name}" "${right_name}"      \
            "\"${left_val}\"" "\"${right_val}\""
          return
        fi

        # ${num_var} -eq 1
        if [ "${left_name}" != "" ]; then
          val="${left_val}"
        else
          val="${right_val}"
        fi
        powerassert_single_point "${sentence}" "\"${val}\""
        return

      # != or ! ==
      else
        powerassert_single_point "${sentence}" "\"${left_val}\""
        return
      fi
      ;;

    -eq | -ne | -lt | -gt | -le | -ge )
      if [ "${num_var}" -eq 2 ]; then
        powerassert_double_point \
          "${sentence}" "${left_val}" "${right_val}"
        return
      fi

      # ${num_val} -eq 1
      if [ "${left_name}" != "" ]; then
        val="${left_val}"
      else
        val="${right_val}"
      fi
      powerassert_single_point "${sentence}" "${val}"
      return
      ;;

    *)
      if [ "${num_var}" -ne 0 ]; then
        powerassert_expand "${argv[@]}"
      fi
      return
      ;;
  esac
}

# get command sentence from script file
function powerassert_get_sentence() {
  err_point=($(powerassert_error_point))

  sentence=$(head "${err_point[0]}" -n "${err_point[1]}" |
             tail -n 1)

  # trim commant and spaces
  sentence=$(echo "${sentence}" |
    sed -e 's/#.*$//'           |
    sed -e 's/^[[:space:]]*//'  |
    sed -e 's/[[:space:]]*$//')

  # expect sentence is one line
  if [[ ! ${sentence} =~ ^\[\[\[.*\]\]\]$ ]]; then
    echo ""
  else
    echo "${sentence}"
  fi
}

# print descriptive messages
function powerassert_describe() {

  echo "assertion error:"

  sentence="$(powerassert_get_sentence)"
  if [ -z "${sentence}" ]; then
    return
  fi

  echo ""
  echo "${sentence}  ->  false"

  if [ "$1" == "!" ]; then
    not=1
  else
    not=0
  fi

  case "$(($# - ${not}))" in
    2)
      powerassert_describe_2word "${sentence}" "$@"
      return
      ;;
    3)
      powerassert_describe_3word "${sentence}" "$@"
      return
      ;;
    *)
      powerassert_expand "$@"
      return
      ;;
  esac
}

# power assert original [ command
# print error description if it fails
function [[[() {

  # run in a sub shell for
  # 1. applying +xve option only in this function
  # 2. avoiding use local command
  # 3. printing all to stderr
  (
    set +xve

    argv=("$@")
    if [ "${argv[$# - 1]}" != "]]]" ]; then
      echo "[[[: missing ']]]'"
      exit 2
    fi
    argv=("${argv[@]:0:$(($#-1))}")

    test "${argv[@]}"
    code="$?"

    case "${code}" in
      0 )
        # true
        exit 0
        ;;
      1 )
        # false
        powerassert_describe "${argv[@]}"
        powerassert_print_stacktrace
        exit 1
        ;;
      * )
        # other error
        echo "arguments: ${argv[@]}"
        powerassert_print_stacktrace
        exit "${code}"
        ;;
    esac
  ) >&2
}
