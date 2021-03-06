#!/bin/bash

pushd $HOME

	# staging server
	apt-get -y install clamav clamav-daemon 

	# virus scanning
	freshclam
	service clamav-daemon restart

	# apache config
	cp /vagrant/configs/apache/apache.westvaultpln.conf /etc/apache2/sites-available/westvaultpln.conf
	ln -s /etc/apache2/sites-available/westvaultpln.conf /etc/apache2/sites-enabled/westvaultpln.conf
	service apache2 restart

	# database
	mysql -e "CREATE USER 'westvaultpln'@'localhost'"
	mysql -e "CREATE DATABASE westvaultpln"
	mysql -e "GRANT ALL ON westvaultpln.* TO 'westvaultpln'@'localhost'"
	mysql -e "SET PASSWORD FOR westvaultpln@localhost = PASSWORD('pln123')"

	# app
	git clone https://github.com/ubermichael/westvault-pln.git westvaultpln
	mv westvaultpln /var/www/westvaultpln
	pushd /var/www/westvaultpln
		chmod a+x app/console
		cp /vagrant/configs/westvaultpln.yml app/config/parameters.yml
		chown -R vagrant:vagrant .
		
		setfacl -R -m u:www-data:rwX -m u:vagrant:rwX app/{cache,logs}
        setfacl -dR -m u:www-data:rwX -m u:vagrant:rwX app/{cache,logs}
            
		/usr/local/bin/composer --no-progress install
		php app/console doctrine:schema:create
		php app/console fos:user:create --super-admin admin@example.com admin Admin example.com
		php app/console fos:user:promote admin@example.com ROLE_ADMIN
		mysql westvaultpln < /vagrant/sql/westvaultpln.sql
		chown -R vagrant:vagrant .		
	popd

popd
