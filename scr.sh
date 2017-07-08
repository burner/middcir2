#/usr/bin/bash

COUNTER=1
for i in `cat mm_8.tex`
do
	echo $i ${COUNTER}
	sed -i "s/ ${i} / \(${COUNTER}\) /g" m_8.tex
	let COUNTER+=1
done
