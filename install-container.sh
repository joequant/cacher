#!/bin/bash

. /tmp/proxy.sh
pip3 install devpi-server --prefix /usr
npm install -g git-cache-http-server
npm install -g verdaccio
