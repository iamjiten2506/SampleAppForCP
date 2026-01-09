#!/bin/bash
cd /var/www/myapp/src
npm install
nohup node app.js > /var/log/myapp.log 2>&1 &