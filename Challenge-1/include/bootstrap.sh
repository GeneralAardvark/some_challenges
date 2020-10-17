#!/bin/bash
#

ENVNAME=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/attributes/envname)
DOMAIN=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/attributes/domain)

# Mount nfs share
mkdir -p /var/www/html/
mount | grep /var/www/html/ || sudo mount -t nfs nfs.${DOMAIN}:/nfs/wordpress /var/www/html

# Set servername
sudo sed -i "s/SOME_SERVERNAME/wordpress.${DOMAIN}/" /etc/apache2/sites-available/wordpress.conf
sudo systemctl restart apache2

