#! /bin/bash

echo "Starting Subdomains Scrapper"
echo "Subdomains Scrapper V1.0"
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

        #Starting DNS Recon
        dnsrecon -d $domain -a -t std -j $domain.json
        dnsenum --noreverse --enum $domain -w -p 100 -s 100 -o $domain.xml
        grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' $domain.xml >> ips.txt
        grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' $domain.json >> ips.txt
        dig $domain | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' >> ips.txt
        grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" $domain.xml | sort -u | grep -vE '([0-9]{1,3}){3}' >> $location
        grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" $domain.json | sort -u | grep -vE '([0-9]{1,3}){3}' >> $location
        cat ips.txt | dnsx -ptr -resp-only >> reverse-lookups.json
        cat reverse-lookups.json | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | sort -u | grep "$domain" >> $location

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
        amass enum --passive -norecursive -d $domain | sort -u >> $location

        echo "Starting assetfinder"
        #assetfinder subdomains
        assetfinder -subs-only $domain | sort -u >> $location

        echo "Starting subevil"
        #subevil subdomains
        python3 /opt/tools/SubEvil/SubEvil.py -d $domain | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | sort -u >> $location

        # echo "Starting crh.sh"
        # while true;
        #     do
        #     read -p "Use CRSH quries here: " crsh
        #     curl -s "https://crt.sh/?q=$crsh" | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | grep "$domain" | sort -u >> $location
            
        #     echo "Continue to write [yes], if not press Enter"
        #     read -p "What to perform crsh query again?" cond
        #     if [ "$cond" = "yes" ]; then
        #         continue
        #     else
        #         break;
        #     fi
        # done

        curl -s "https://crt.sh/?q=$crsh" | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | grep "$domain" | sort -u >> $location
        curl -s "https://crt.sh/?q=%25.$crsh" | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | grep "$domain" | sort -u >> $location
        curl -s "https://crt.sh/?q=%25.%25.$crsh" | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | grep "$domain" | sort -u >> $location

        echo "Starting dnsrecon"
        #dnsrecon subdomains
        dnsrecon -d $domain -a | grep -oE "[a-zA-Z0-9._-]+\.$domain" | uniq >> $location

        cat $location | sort | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-sorted.txt
        
        # echo "Starting GetAllUrls"
        # cat $domain-sortedSubdomains.txt | gau | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | grep "$domain" | sort -u >> gau-$location
        
        # echo "again sorting"
        # cat gau-$location >> $domain-sortedSubdomains.txt

        echo "Pinging using httpx"
        #pinging using httpx
        cat $domain-sorted.txt | httpx-toolkit -silent -sc -mc 200,302,301,403,500 -p 80,8080,8443,443 | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-alive.txt
        cat $domain-alive.txt | grep "200" >> 200.txt
        cat $domain-alive.txt | grep "301" >> 301.txt
        cat $domain-alive.txt | grep "302" >> 302.txt
        cat $domain-alive.txt | grep "403" >> 403.txt
        cat $domain-alive.txt | grep "500" >> 500.txt
        echo "Successfully Extracted All Subdomains"

        # echo "Starting WayBackUrl"
        # #wayback machine
        # waybackurls $domain-aliveDomains.txt | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-urls.txt

        # echo "Starting GAU for Links"
        # cat $domain-aliveDomains.txt | gau | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-urls.txt

        # echo "Starting HTTPX"
        # cat $domain-urls.txt | httpx-toolkit -silent -mc 200,302,301,403,500 >> $domain-aliveUrls.txt
        
        # echo "Separating files according to extension"
        # cat $domain-aliveUrls.txt | egrep -i -E -o "\.{1}\w*$" | sort -su >> EndPointsExtension.txt

        # echo "Making files"
        # mkdir urls
        # cd urls

        # ls ~/.gf | sed 's/[.].*$//' >> gf-patterns.txt
        
        # while read LINE
        #             do 
        #                 cat ../$domain-aliveUrls.txt | gf $LINE >> $LINE-urls.txt
        # done < gf-patterns.txt

        # find . -size 0 -delete


        # echo "Making files according to extensions found"
        # while read LINE
        #     do 
        #         cat ../$domain-aliveUrls.txt | grep "$LINE" >> $LINE-files.txt
        # done < ../EndPointsExtension.txt

    else
        echo "$d is not a Valid Domain [FQDN]"
    fi
done

#notes:
#add further more tools on requirement basis
#theharvestor
#synapsint subdomains
#virustotal subdomains (Virus Total not supporting the curl so manualy is done)