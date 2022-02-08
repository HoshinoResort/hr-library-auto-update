#!/bin/bash

## Color
RED='\033[0;31m'
BG_RED='\033[0;41m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
## Clear the color after that
CLEAR='\033[0m'

## Git
USER_EMAIL="hr-library-auto-update@users.noreply.github.com"
USER_NAME="github-action"

## CLI
MVNW="./mvnw"
SETTINGS_XML=
RULES_XML=

declare -a DEFAULT_USE_LATEST_RELEASES_PARAMETERS=(
    "generateBackupPoms=false"
    "allowMajorUpdates=false"
)

## functions
function is_executable() {
    local path="$1"
    test -x "$path"
    if [[ $? -ne 0 ]]; then
        error "${path} is not found or executable"
        return 1
    fi
}

function run() {
    local path="$(which $1)"
    local arguments="${@:2}"
    is_executable "$path"
    if [[ $? -eq 0 ]]; then
        echo "$ ${path} ${arguments}"
        eval "${path} ${arguments}"
    fi
}

function print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${CLEAR}"
}

function success() {
    local message="SUCCESS: $1"
    print_color $GREEN "$message"
}

function info() {
    local message="INFO: $1"
    print_color $BLUE "$message"
}

function error() {
    local message="ERROR: $1"
    print_color $BG_RED "$message"
}

function get_params() {
    local name="$1"
    local params=""
    for param in $(eval echo '${'$name'[@]}')
    do
        params="${params} -D${param}"
    done
    echo $params
}

function set_settings_xml() {
    local path="$1"
    test -f "$path"
    SETTINGS_XML="$path"
    info "use maven settings: $SETTINGS_XML"
}

function set_rules_xml() {
    local path="$1"
    test -f "$path"
    RULES_XML="$path"
    info "use comparison rules: $RULES_XML"
}

function run_mvnw() {
    local arguments="$@"
    local params="--no-transfer-progress"
    if [[ -n "$SETTINGS_XML" ]]; then
        params="${params} --settings \"$SETTINGS_XML\""
    fi
    run $MVNW $params $arguments
}

function mvnw_version() {
    run_mvnw --version
}

function mvnw_latest_releases() {
    local params=$(get_params "DEFAULT_USE_LATEST_RELEASES_PARAMETERS")
    params="${params} -Dmaven.version.rules=file://${RULES_XML}"
    run_mvnw "versions:use-latest-releases" ${params}
}

function get_modified_poms() {
    local files=""
    for f in $(git diff --name-only -- '*pom.xml')
    do
        files="$files $f"
    done
    echo $files
}

function has_modified_poms() {
    if [[ -n "$(get_modified_poms)" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function configure_system_account() {
    run git config --global user.email "$USER_EMAIL"
    run git config --global user.name "$USER_NAME"
}

function show_pom_diff() {
    local files=$(get_modified_poms)
    if [[ -n "$files" ]]; then
        run git diff $files
    fi
}

function commit_pom_xml() {
    local files=$(get_modified_poms)
    if [[ -n "$files" ]]; then
        run git add $files
        run git commit -m "\"update dependencies\""
    else
        info "no update for dependencies"
    fi
}

function push_to_remote() {
    run git push origin
}

function get_head_revision() {
    git rev-parse HEAD
}

################################
## from here for testing
################################
function print_header() {
    local message="$1"
    echo "################################################################"
    echo "# ${message}"
    echo "################################################################"
}

function do_test() {
    local path="$1"

    print_header "call mvnw_version"
    mvnw_version
    echo

    print_header "call set_rules_xml"
    set_rules_xml "$(pwd)/rules.xml"
    echo

    print_header "call run_mvnw for displaying updates"
    run_mvnw "versions:display-dependency-updates"
    echo

    print_header "call mvnw_latest_releases"
    mvnw_latest_releases
    echo

    print_header "call has_modified_poms"
    echo $(has_modified_poms)
    echo

    print_header "call commit_pom_xml"
    commit_pom_xml
    echo

    success "test was completed"
}
