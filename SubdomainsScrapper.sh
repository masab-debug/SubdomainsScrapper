#! /bin/bash

echo "Starting Subdomains Scrapper"
echo "Subdomains Scrapper"
read -p "Enter domain to extract all subdomains: " domain #this is a variable which is getting domain.
echo "Domain": $domain

for d in $domain
do
    host $d 2>&1 > /dev/null
    if [ $? -eq 0 ]
    then
        echo "$d is a Valid Domain [FQDN]"
        
        #script start
        read -p "Location to save files: " location
        echo "Your location and filename of saving subdomains file: " $location

        echo "Starting Sublist3r"
        #sublist3r subdomains
        sublist3r -d $domain -o $location

        echo "Starting Rapiddns"
        #rapiddns subdomains
        curl -s "https://rapiddns.io/subdomain/$domain?full=1#result" | grep -B 1 "<td><a" | sed 's/<td><a.*//g' | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | sort -u | sort -n | cut -d" " -f2- | grep "$domain" >> $location

        echo "Starting Ominsint"
        #ominsint subdomains
        curl -s "https://sonar.omnisint.io/subdomains/$domain" | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | sort -u | grep "$domain" >> $location


        echo "Starting Wayback Url For Subdomains"
        #wayback machine
        waybackurls $domain | grep -oE "[a-zA-Z0-9._-]+\.$domain" |  grep "$domain" | uniq >> $location


        echo "Starting subfinder and httpx"
        #subfinder and httpx
        subfinder -d $domain --silent | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | uniq | grep "$domain" >> $location

        echo "Starting amass"
        #amass subdomain
        amass enum -passive -d $domain | sort -u >> $location

        echo "Starting assetfinder"
        #assetfinder subdomains
        assetfinder -subs-only $domain | sort -u >> $location

        echo "Starting subevil"
        #subevil subdomains
        python3 /opt/Bug\ Bounty\ Scripts/SubEvil/SubEvil.py -d $domain | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | sort -u >> $location

        echo "Starting crh.sh (Domain)"

        #crh.sh subdomains
        echo "Examples: %.yahoo.com, %25.bf1.yahoo.com, %25.%25.%25.%25.%25.yahoo.com, %25internal%25.yahoo.com
                    {you can put %25 wildcard anywhere in search like %25api.yahoo.com}
                    {Put some more wildcard in crt.sh website}
                    "
            
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

        echo "Starting dnsrecon"
        #dnsrecon subdomains
        dnsrecon -d $domain -a | grep -oE "[a-zA-Z0-9._-]+\.$domain" | uniq >> $location

        # echo "Gobuster is out"
        # echo "Starting gobuster"
        # #gobuster vhost bruteforce
        # gobuster vhost --useragent "google" --wordlist "/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt" --url https://$domain | grep -oE "[a-zA-Z0-9._-]+\.$domain" | httpx-toolkit -silent -mc 200,302,301,403  >> $domain-aliveDomains.txt

        echo "FFUF is Starting"

        echo "FFUF enumerating HOSTS"
        sudo ffuf -H "Host: FUZZ" -H "User-Agent: cloudflair" -c -w "/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt" -u https://$domain/ -mc 200,302,403,500,301 >> aliveffufhosts-$location
        
        echo "FFUF enumerating VHOSTS"
        sudo ffuf -H "Host: FUZZ.$domain" -H "User-Agent: cloudflair" -c -w "/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt" -u https://$domain/ -v -mc 200,302,403,500 | grep -A 2 '| URL |' | grep -oE "[a-zA-Z0-9._-]+\.$domain" >> aliveffufvhosts-$location

        echo "Starting GetAllUrls"
        cat $domain-sortedSubdomains.txt | gau | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | grep "$domain" | sort -u >> $location

        cat $location | sort | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-sortedSubdomains.txt


        echo "Pinging using httpx"
        #pinging using httpx
        cat $domain-sortedSubdomains.txt | httpx-toolkit -silent -mc 200,302,301,403 | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-aliveDomains.txt

        echo "Successfully Extracted All Subdomains"

        echo "Starting WayBackUrl"
        #wayback machine
        waybackurls $domain-aliveDomains.txt | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-urls.txt

        echo "Starting GAU for Links"
        cat $domain-aliveDomains.txt | gau | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-urls.txt

        echo "Starting HTTPX"
        cat $domain-urls.txt | httpx-toolkit -silent -mc 200,302,301,403,500 >> $domain-aliveUrls.txt
        


    else
        echo "$d is not a Valid Domain [FQDN]"
    fi
done

#notes:
#add further more tools on requirement basis
#theharvestor
#synapsint subdomains
#virustotal subdomains (Virus Total not supporting the curl so manualy is done)