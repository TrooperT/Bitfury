#!/bin/sh

while : ; do
	cp -f s1r.ncd s1.ncd
	./rpar.sh
	echo done PAR rerun
	sleep 5
done
