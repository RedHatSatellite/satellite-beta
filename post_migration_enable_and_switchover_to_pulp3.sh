#!/bin/bash

set -e

echo
echo "Starting Pulp 3 services..."
systemctl start pulpcore-resource-manager pulpcore-api pulpcore-content pulpcore-worker@1 pulpcore-worker@2 pulpcore-worker@3 pulpcore-worker@4

echo
echo "Enabling Pulp 3 services..."
systemctl enable pulpcore-resource-manager pulpcore-api pulpcore-content pulpcore-worker@1 pulpcore-worker@2 pulpcore-worker@3 pulpcore-worker@4

echo
echo "Perform switchover of content from Pulp 2 to Pulp 3..."
foreman-rake katello:pulp3_content_switchover

echo
echo "Updating Satellite configuration..."
sed -i -e 's/pulpcore::service_ensure: false/pulpcore::service_ensure: true/g' -e 's/pulpcore::service_enable: false/pulpcore::service_enable: true/g' /usr/share/foreman-installer/config/foreman.hiera/scenario/satellite.yaml || echo "Already set"

echo
echo "Running installer for Pulp 3..."
satellite-installer --foreman-proxy-content-proxy-pulp-isos-to-pulpcore=true --katello-use-pulp-2-for-file=false --katello-use-pulp-2-for-docker=false --katello-use-pulp-2-for-yum=false --foreman-proxy-content-proxy-pulp-yum-to-pulpcore=true

echo
echo "Restart Satellite services..."
satellite-maintain service restart

echo
echo "All steps completed!"
