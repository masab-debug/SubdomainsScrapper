        echo "Separating files according to extension"
        read -p "Location to file: " $domain
        echo "Your location and filename of subdomains file: " $domain
        mkdir urls
        cat $domain | egrep -i -E -o "\.{1}\w*$" | sort -su >> urls/EndPointsExtension.txt
                echo "Making files"
        cd urls

        ls ~/.gf | sed 's/[.].*$//' >> gf-patterns.txt
        
        while read LINE
                    do 
                        cat ../$domain | gf $LINE >> $LINE-urls.txt
        done < gf-patterns.txt

        find . -size 0 -delete


        echo "Making files according to extensions found"
        while read LINE
            do 
                cat ../$domain | grep "$LINE" >> $LINE-files.txt
        done < EndPointsExtension.txt