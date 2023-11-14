#!/bin/bash

git add *
git commit -m "`/Users/raysuen/raysuen/bin/rdate.py -f "%Y%m%d"`"
#git remote add origin https://gitee.com/raysuen/silent-install-rac19c.git
git push -u origin "master"
