#/usr/bin/bash

COUNTER=1
for i in `cat mm.tex`
do
	echo $i ${COUNTER}
	sed -i "s/ ${i} / \(${COUNTER}\) /g" mcs_8.tex
	let COUNTER+=1
done
