#!/bin/bash
#Copyright 2015 Fabian Ebner
#Published under the GPLv3 or any later version, see the file COPYING for details

for dir in $@
do
	tar cf $dir.cbt $dir
done
