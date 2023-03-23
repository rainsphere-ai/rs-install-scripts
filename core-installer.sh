#!/bin/zsh
#
# Core installer to set up dev environment

BASEDIR=$(dirname "$0")
RS_TMP_PATH=/tmp/rainsphere

setup_scripts() {
  source $BASEDIR/scripts.sh || source $RS_TMP_PATH/scripts.sh
}

setup_paths() {
  # rainsphere dev paths
  RS_DEV_PATH="${RS_DEV_PATH:-$(prompt_user "Enter the absolute path to your rainsphere dev directory" "$PWD")}"
  RS_DEV_ONBOARDING_PATH="${RS_DEV_ONBOARDING_PATH:-$RS_DEV_PATH/rs-onboarding-scripts}"
  RS_DEV_SCRIPTS_PATH="${RS_DEV_SCRIPTS_PATH:-$RS_DEV_ONBOARDING_PATH/scripts}"
}

setup_nostromo() {
  # Prevent the cloned repository from having insecure permissions. Failing to do
  # so causes compinit() calls to fail with "command not found: compdef" errors
  # for users with insecure umasks (e.g., "002", allowing group writability). Note
  # that this will be ignored under Cygwin by default, as Windows ACLs take
  # precedence over umasks except for filesystems mounted with option "noacl".
  umask g-w,o-w

  touch ~/.zshrc

  fmt_info "Installing Homebrew..."
  command_exists brew || {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      fmt_error "homebrew installation failed"
      exit 1
    }

    eval "$(/opt/homebrew/bin/brew shellenv)"
  }

  fmt_info "Installing nostromo..."
  command_exists nostromo || brew install pokanop/pokanop/nostromo || {
    fmt_error "nostromo installation failed"
    exit 1
  }

  fmt_info "Initializing nostromo..."
  nostromo init || {
    fmt_error "nostromo initialization failed"
    exit 1
  }

  ostype=$(uname)
  if [ -z "${ostype%CYGWIN*}" ] && git --version | grep -Eq 'msysgit|windows'; then
    fmt_error "Windows/MSYS Git is not supported on Cygwin"
    fmt_error "Make sure the Cygwin git package is installed and is first on the \$PATH"
    exit 1
  fi
}

setup_dev() {
  fmt_info "Cloning development scripts..."
  if dir_exists $RS_DEV_PATH/rs-onboarding-scripts; then
    # Update the repo if it already exists
    $(cd $RS_DEV_PATH/rs-onboarding-scripts && git checkout main && git pull) > /dev/null 2>&1
  else
    pushd $RS_DEV_PATH
    git clone git@github.com:rainsphere-ai/rs-onboarding-scripts.git || {
      fmt_error "rs-onboarding-scripts clone failed"
      exit 1
    }
    popd
  fi

  [ -z $RS_RAINSPHERE_SCRIPT_LOADED ] && {
    source $RS_DEV_ONBOARDING_PATH/rainsphere.sh || {
      fmt_error "rainsphere.sh sourcing failed"
      exit 1
    }
  }
 
  fmt_info "Docking nostromo manifests..."
  nostromo dock git@github.com:rainsphere-ai/rs-onboarding-scripts.git || {
    fmt_error "nostromo docking failed"
    exit 1
  }

  source ~/.zshrc

  fmt_info "Setting up dev tools..."
  dev setup tools || {
    fmt_error "dev tools installation failed"
    exit 1
  }

  fmt_info "Setting up dev env..."
  dev setup env || {
    fmt_error "dev env installation failed"
    exit 1
  }
}

# shellcheck disable=SC2183  # printf string has more %s than arguments ($FMT_RAINBOW expands to multiple arguments)
print_success() {
  printf '\n'
  fmt_info "Hooray! Your rainsphere development environment is ready to go 🎉"
  printf '\n'
  printf '\n'
  printf '%s\n' "• Join our $(fmt_link "Slack channel" https://rainsphere.slack.com/archives/C02G25XC00M)"
  printf '%s\n' $FMT_RESET
}

main() {
  setup_scripts
  setup_colors
  
  setup_paths
  setup_nostromo
  setup_dev

  print_success
}

main "$@"