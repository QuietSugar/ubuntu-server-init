#!/bin/bash

. ./utils.sh

PROFILE_FILE="${HOME}/.profile"

source $PROFILE_FILE

# Install java
command -v java > /dev/null
if [ $? != 0 ]; then
	l_info "installing java..."
	http --download https://repo.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz -o jdk8.tar.gz
	sudo tar -C /usr/local -xzf jdk8.tar.gz
	sudo chmod a+x /usr/local/jdk1.8.0_202/bin/java
	echo 'export JAVA_HOME=/usr/local/jdk1.8.0_202' >> "${PROFILE_FILE}"
	echo 'export PATH=$PATH:$JAVA_HOME' >> "${PROFILE_FILE}"
	source "${PROFILE_FILE}"
	l_success "java $(java -version 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}') installed."
	rm -f jdk8.tar.gz
else
	l_skip "java $(java -version 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}') already installed"
fi
