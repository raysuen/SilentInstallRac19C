#!/bin/bash

git add *
git commit -m "`/Users/raysuen/ray/bin/rdate.py -f "%Y%m%d"`"
git push -u origin main 
