BASEDIR=$(dirname "$0")
RS_TMP_PATH=/tmp/rainsphere

source_script() {
  local script=$1
  local fallback=$2

  [ -f $script ] && source $script || {
    [ -f $fallback ] && source $fallback || {
      printf "failed to source script: $script\n"
      exit 1
    }
  }
}

source_script $BASEDIR/format.sh $RS_TMP_PATH/format.sh
source_script $BASEDIR/utils.sh $RS_TMP_PATH/utils.sh