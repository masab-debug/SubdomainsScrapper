#! /bin/bash

read -p "Folder name to save output" gfp
mkdir $gfp

ls ~/.gf | sed 's/[.].*$//' >> $gfp/gf-patterns.txt

cd $gfp
while read LINE
            do 
                cat ../test.txt | gf $LINE >> $LINE-urls.txt
done < gf-patterns.txt

find . -size 0 -delete

cd ../..
cat JsFinder.sh
