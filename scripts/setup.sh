#!/bin/bash
set -o errexit -o nounset -o pipefail
cd "$(dirname "$0")/.."

################################################################################
# (Re-)install and configure Redmine and plugins.
#
# This avoids adding all of the files to Git.
################################################################################

#===============================================================================
# Configuration
#===============================================================================

# https://redmine.org/projects/redmine/wiki/Download
redmine_version='5.0.3'

# https://github.com/mrliptontea/PurpleMine2/releases
purplemine_version='2.15.0'

# https://github.com/AlphaNodes/additionals/tags
additionals_version='3.0.7'

# https://www.redmineup.com/pages/plugins/agile#pricing (free version)
agile_url='http://email.redmineup.com/c/eJyFkMFqxSAQRb8mWQZ1HKOLLArl7foNweiYZxs15Bny-_XBg3ZTCrM6nHu5DE1cKQWjkBJ7PwU0GpY-TgpQeMAFlFNilqPhEhC11oxjJ9lBPsVM5z4kG7f-Pmk7BljIQcDFOCEkU4Tc0AImgHS636Z7rXsHb524tbuua_gpcSU1tkVH-UFzstmudDTChUSQHdxq-aLcwTs446VQDpAZRqSt9krRyJTn6MPIBQYROqHOmuZHOQ9HLfRhY36xRD6eqTF67n5BZ9Nu4_rs9-XKW7F-3rdzjXn-rVU60j-KK7lSrn9Z_TH59jz_mYZE30fSej8'

# https://github.com/Loriowar/redmine_issues_tree/branches
issues_tree_version='5.0.x'

# https://github.com/davidegiacometti/redmine_shortcuts/releases
shortcuts_version='0.6.0'


#===============================================================================
# Helpers
#===============================================================================

RESET="\e[0m"
LCYAN="\e[96m"

header() {
    echo
    echo -e "${LCYAN}${1}${RESET}"
}


#===============================================================================
# Install
#===============================================================================

# Redmine core
# https://redmine.org/projects/redmine/wiki/RedmineInstall
header "Downloading Redmine $redmine_version..."

curl -L "https://redmine.org/releases/redmine-${redmine_version}.tar.gz" | tar zx

rm -rf redmine
mv "redmine-${redmine_version}" redmine

mkdir -p redmine/tmp/pdf redmine/public/plugin_assets
chmod -R g+w redmine/files redmine/log redmine/tmp redmine/public/plugin_assets

# Redmine database config
header 'Configuring database...'

cp -f redmine/config/database.yml.example config/database.yml.example

if [[ ! -f config/database.yml ]]; then
    cp config/database.yml.example config/database.yml
fi

ln -s ../../config/database.yml redmine/config/database.yml

# PurpleMine 2 theme
header 'Installing PurpleMine 2 theme...'

curl -L "https://github.com/mrliptontea/PurpleMine2/archive/refs/tags/v${purplemine_version}.tar.gz" | tar zx
mv "PurpleMine2-${purplemine_version}" redmine/public/themes/PurpleMine2

# Additionals plugin
header 'Installing Additionals plugin...'

curl -L "https://github.com/AlphaNodes/additionals/archive/refs/tags/${additionals_version}.tar.gz" | tar zx
mv "additionals-${additionals_version}" redmine/plugins/additionals

# Redmine Agile plugin
header 'Installing Redmine Agile plugin...'

(
    cd redmine/plugins
    # '--insecure' is required because the intermediate certificate is missing (28 Oct 2022)
    curl -L --insecure "$agile_url" > redmine_agile.zip
    unzip redmine_agile.zip
    rm -f redmine_agile.zip
)

# Redmine Issues Tree plugin
header 'Installing Redmine Issues Tree plugin...'

curl -L "https://github.com/Loriowar/redmine_issues_tree/archive/refs/heads/${issues_tree_version}.tar.gz" | tar zx
mv "redmine_issues_tree-${issues_tree_version}" redmine/plugins/redmine_issues_tree

# Redmine Shortcuts plugin
header 'Installing Redmine Shortcuts plugin...'

curl -L "https://github.com/davidegiacometti/redmine_shortcuts/archive/refs/tags/${shortcuts_version}.tar.gz" | tar zx
mv "redmine_shortcuts-${shortcuts_version}" redmine/plugins/redmine_shortcuts

# Customisations
header 'Installing customisations plugin...'

ln -s ../../customisations redmine/plugins/customisations

# Install dependencies
header 'Installing dependencies...'

(
    cd redmine
    bundle config set --local without 'development test'
    bundle config set --local path 'vendor/bundle'
    bundle install
)

# Redmine secret token
header 'Configuring secret token...'

if [[ ! -f config/secret_token.rb ]]; then
    (cd redmine && bundle exec rake generate_secret_token)
    mv redmine/config/initializers/secret_token.rb config/secret_token.rb
fi

ln -s ../../../config/secret_token.rb redmine/config/initializers/secret_token.rb

# Database migrations
header 'Running database migrations...'
(cd redmine && bundle exec rake redmine:plugins:migrate RAILS_ENV=production)

# Restart Redmine
header 'Restarting Redmine...'
scripts/restart.sh

echo 'Done.'
