
#!/usr/bin/env bash

###################################################################
#
# Install Programs via Asdf
# -------------------------
#
# https://asdf-vm.com/#/
# https://github.com/asdf-vm/asdf
#
###################################################################

export SUPPORT_DIR="${HOME}/.dotfiles/support"
source "${SUPPORT_DIR}/common-utilities.sh"

CONFIG_FILE="${dotfilesDirectory}/asdf/config-asdf"

main() {
    start=$(date +%s)
    echo "$LINE_BREAK"
    start "$0 Started"

    print_info "› Reading config file '${CONFIG_FILE}'..."
    while read -r line
    do
        # Skip header file
        if [[ "${line}" == "#"* ]]
        then
            continue
        fi

        plugin=$(echo "${line}" | cut -d' ' -f1)
        plugin_git_url=$(echo "${line}" | awk -F' ' '{print $2}')
        plugin_version=$(echo "${line}" | awk -F' ' '{print $3}')

        echo "-----------------------------------------------------------------"
        print_info "› PLUGIN:${plugin}|PLUGIN_VERSION:${plugin_version}|PLUGIN_GIT_URL:${plugin_git_url}"

        asdf_add_plugin "${plugin}" "${plugin_git_url}"

        # check plugin version
        if [[ "${plugin_version}" == '' ]]
        then
            print_info "› No plugin version set. Finding latest version..."
            plugin_version=$(asdf latest "${plugin}")
            print_info "› Plugin version set to '$plugin_version'"
        fi

        # check if installed
        result=$(asdf where "${plugin}" "${plugin_version}" 2>&1)
        print_info "› Result:^${result}^"
        if [[ "${result}" != *"Version not installed"* ]]
        then
            warn "› Plugin '${plugin} ${plugin_version}' already installed"
            continue
        fi

        # TODO: Check against latest
        asdf_install_plugin "${plugin}" "${plugin_version}"

        asdf_set_global "${plugin}" "${plugin_version}"

    done < "${CONFIG_FILE}"

    print_info "› Show 'asdf current' output:"
    asdf current

    end=$(date +%s)
    runtime=$((end-start))
    runtime_min=$(convert_seconds_to_min $runtime)

    finished "$0 Completed with $runtime seconds ($runtime_min mins)"
    echo "${LINE_BREAK}"
}


# ################### ASDF UTILITIES #################################


function asdf_add_plugin() {
    local plugin=$1
    local plugin_git_url=$2
    print_info "› Trying to add '${plugin}'..."
    is_present=$(asdf plugin-list | grep "${plugin}" | wc -l | sed 's/ //g')
    print_info "› Result: ${plugin}|${is_present}"

    if [[ "${is_present}" -ne 0 ]]
    then
        warn "› Plugin '${plugin}' already added"
        return
    fi

    print_info "› Plugin '${plugin}' is not list. Adding plugin..."
    asdf plugin-add "${plugin}" "${plugin_git_url}"
    success "› Completed adding '${plugin}'!"
}


function asdf_install_plugin() {
    local plugin=$1
    local plugin_version=$2
    print_info "› Installing '$plugin $plugin_version'..."

    # Import the Node.js release team's OpenPGP keys to main keyring
    if [[ "${plugin}" == "nodejs" ]]
    then
        bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
    fi

    asdf install $plugin $plugin_version
    print_info "› Completed installing '$plugin $plugin_version'!"
}


function asdf_set_global() {
    local plugin=$1
    local plugin_version=$2
    print_info "› Setting '$plugin $plugin_version' as global..."

    asdf global $plugin $plugin_version
    print_info "› Completed setting '$plugin $plugin_version' as global!"
}



main