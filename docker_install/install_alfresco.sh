#!/bin/bash                                                                                                                                                                                     
mkdir -p Alfresco

cd /tmp
curl -OL https://download.alfresco.com/release/community/201707-build-00028/alfresco-community-installer-201707-linux-x64.bin
chmod +x alfresco*
./alfresco-community-installer-201707-linux-x64.bin --mode unattended --alfresco_admin_password admin --disable-components postgres

