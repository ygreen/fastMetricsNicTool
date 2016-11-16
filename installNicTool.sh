#!/bin/bash
clear;
echo "";
echo "";
echo "########################### FastMetrics(TM) NicTool Installer ###########################";
echo "##                                                                                     ##";
echo "## Important Note: You absolutely MUST enter a password for the 'root' user for MySQL. ##";
echo "##                 Otherwise the NicTool seed data DB init scripts will have problems. ##";
echo "##                                                                                     ##";
echo "##                 This installation also assumes that the box you are running it on   ##";
echo "##                 is a dedicated single purpose NicTool machine, and makes certain    ##";
echo "##                 assumptions about the exclusive availability of certain service     ##";
echo "##                 configurations such as the Apache installation, etc.                ##";
echo "##                                                                                     ##";
echo "#########################################################################################";
read -n1 -r -p "Press any key to continue..." key
echo "";

tar -xvzf FastMetricsNicTool-2.33.tar.gz;

# Make sure the local OS package library and all currently installed packages are up to date
sudo apt-get update;
sudo apt-get upgrade -y;

# Configure CPAN to follow each modules dependency tree when installing new Perl modules
(echo y;echo o conf prerequisites_policy follow;echo o conf commit)|cpan > /dev/null;

# Install the latest CPAN
sudo cpan CPAN;

# Install all of the required OS level packages we can for NicTool through APT; The order of these is intentional and CRITICAL
sudo apt-get install -y gcc;
sudo apt-get install -y libssl-dev;
sudo apt-get install -y libtool;
sudo apt-get install -y mysql-server libmysqlclient-dev; 
sudo apt-get install -y apache2 apache2-dev;
sudo apt-get install -y libapache2-mod-perl2 libapache2-mod-perl2-dev;
sudo apt-get install -y libpcre3 libpcre3-dbg libpcre3-dev libpcre32-3 libpcre2-32-0 libpcre2-dev libgdbm-dev libexpat1 libexpat1-dev lib64expat1 lib64expat1-dev libxml-parser-perl libxml-sax-expat-perl;

# Do a forced install on a few Perl modules from CPAN that are currently checked in with broken unit tests, so CPAN wont let you install them normally
sudo cpan -i -f Net::DNS::Zone::Parser
sudo cpan -i -f TestConfig

# Install all of the other less problematic but required Perl modules through CPAN
sudo cpan Log::Log4perl; sudo cpan Test::More; sudo cpan Shell; sudo cpan BIND::Conf_Parser; sudo cpan Time::TAI64; sudo cpan YAML; sudo cpan IO::Socket::SSL; sudo cpan IO::Socket::INET6; sudo cpan MIME::Tools; sudo cpan LWP::Protocol::https; sudo cpan Net::DNS::SEC; sudo cpan APR::Table; sudo cpan Test::Fatal; sudo cpan XML::Parser::Lite; sudo cpan CGI; sudo cpan JSON; sudo cpan LWP::UserAgent; sudo cpan RPC::XML; sudo cpan CryptX;

# Install all required dependencies, compile, and deploy NicTool
NICTOOL_DIR=`pwd`;
sudo mv nictool /usr/local/;
cd /usr/local/nictool/server;
sudo perl bin/nt_install_deps.pl;
cd ../client;
sudo perl bin/install_deps.pl;
cd ../server/sql;
perl create_tables.pl
cd ../
sudo perl Makefile.PL && sudo make && sudo make install clean;
test -f lib/nictoolserver.conf || cp lib/nictoolserver.conf.dist lib/nictoolserver.conf;
cd ../client;
sudo perl Makefile.PL && sudo make && sudo make install clean;
test -f lib/nictoolclient.conf || cp lib/nictoolclient.conf.dist lib/nictoolclient.conf;
cd ../..;

# Configure Apache to have only the NicTool HTTPS instance as the only active virtual host
sed -i "s/REPLACE/`hostname |sed 's/\./\\./g'`/g" nictool/etc/000-nictool.conf
sudo mv nictool/etc/000-nictool.conf /etc/apache2/sites-available/
sudo chown root:root /etc/apache2/sites-available/000-nictool.conf
sudo rm -rf /etc/apache2/sites-enabled/*
sudo ln -s /etc/apache2/sites-available/000-nictool.conf /etc/apache2/sites-enabled/000-nictool.conf

# Configure a local self-signed SSL certificate for the instance
sudo mv nictool/etc/server.key /etc/ssl/private/
sudo mv nictool/etc/server.crt /etc/ssl/certs/
sudo chown root:root /etc/ssl/private/server.key
sudo chown root:root /etc/ssl/certs/server.crt
sudo chmod o-r /etc/ssl/private/server.key
sudo rm -rf nictool/etc
sudo chown -R www-data:adm /usr/local/nictool;
sudo a2enmod ssl
sudo apache2ctl -t
sudo service apache2 restart
echo "";
echo "################################ Installation Complete!!! ###############################";
echo "##                                                                                     ##";
echo "## NicTool has been installed to: /usr/local/nictool                                   ##";
echo "## The NicTool client lives in:   /usr/local/nictool/client                            ##";
echo "## The NicTool server lives in:   /usr/local/nictool/server                            ##";
echo "##                                                                                     ##";
echo "## The server configuration (DB): /usr/local/nictool/server/lib/nictoolserver.conf     ##";
echo "##                                                                                     ##";
echo "## The server is now running and should be accessible at: https://`hostname`           ##";
echo "##                                                                                     ##";
echo "#########################################################################################";
echo "";
