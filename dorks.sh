#! /bin/bash
        while true;
            do
            read -p "Use CRSH quries here: " crsh
            curl -s "https://crt.sh/?q=$crsh" | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | grep "$domain" | sort -u >> $location
            
            echo "Continue to write [yes], if not press Enter"
            read -p "What to perform crsh query again?" cond
            if [ "$cond" = "yes" ]; then
                continue
            else
                break;
            fi
        done