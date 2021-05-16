#!/bin/bash
# entrypoint.sh
# Used to wait for Postgres and LDAP and to ensure that the LDAP entries assumed by tests are
# available before executing a command. For use when launching the project with Docker Compose.
# Usage: entrypoint.sh [keyword [parameters...] | command...]
# keyword: dev|test|deploy_staging|deploy_production

set -e

function check_prepare {
    bundle exec rake db:create # make sure!

    echo "# Checking LDAP availability"
    ldap_check=0
    until ldapsearch -x -h $LDAP_HOST -p 10389 -s base -b "" "objectclass=*" vendorVersion; do
        >&2 echo "# Waiting for LDAP (${ldap_check}/20)"
        (( ldap_check += 1 ))

        if [ $ldap_check -gt 20 ]; then
            >&2 echo "# LDAP unavailable after 40 seconds"
            exit 1
        fi

        sleep 2
    done

    echo "# Found LDAP"
    echo "# Making sure LDAP is seeded"
    if ! ldapsearch -x -h $LDAP_HOST -p 10389 "uid=user" | grep "numEntries: 1"; then
        echo "# Seeding LDAP"
        ldapadd -v -h $LDAP_HOST -p 10389 -c -x -D uid=admin,ou=system -w secret -f /app/db/ldap.ldif > /dev/null
    else
        echo "# LDAP already seeded"
    fi

    echo "# Done checking dependencies"

    echo "# Ensure yarn dependencies are installed"
    yarn install --frozen-lockfile
}

# just nuke directories that make issues - used after CI tasks
function clean_up {
    if [[ $CI_CLEAN_UP == true ]]; then
        >&2 echo "# Cleaning up"
        rm -rf node_modules/ public/packs-test/ tmp/
    fi
}

if [ -f /root/.ssh/id_rsa ]; then
    echo "# Initialising SSH agent"
    eval $(ssh-agent -s)
    ssh-add /root/.ssh/id_rsa
else
    echo "# No private key found - skipping"
fi

case $1 in
    dev)
        check_prepare
        echo "# Deleting PID file"
        rm -f tmp/pids/server.pid
        echo "# Starting the dev server"
        bundle exec rails server -b 0.0.0.0
        ;;
    test)
        trap 'clean_up' ERR
        export RAILS_ENV=test
        check_prepare
        export DISABLE_SPRING=true
        bundle exec bundle info rake
        bundle exec rails webpacker:compile
        bundle exec rake db:environment:set
        bundle exec rake db:drop
        bundle exec rake db:create
        bundle exec rake db:structure:load
        bundle exec rake rubocop test:system test
        clean_up
        ;;
    *)
        echo "# No action matched: running directly as bash command"
        # check_prepare
        eval "$*"
        clean_up
esac
