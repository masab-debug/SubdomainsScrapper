#! /bin/bash

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


        #sublist3r subdomains
        sublist3r -d $domain -o $location

        #rapiddns subdomains
        curl -s "https://rapiddns.io/subdomain/$domain?full=1#result" | grep -B 1 "<td><a" | sed 's/<td><a.*//g' | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | sort -u | sort -n | cut -d" " -f2- | grep "$domain" >> $location

        #ominsint subdomains
        curl -s "https://sonar.omnisint.io/subdomains/$domain" | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | sort -u | grep "$domain" >> $location

        #wayback machine
        waybackurls $domain | grep -oE "[a-zA-Z0-9._-]+\.$domain" |  grep "$domain" | uniq >> $location

        #subfinder and httpx
        subfinder -d $domain --silent | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | uniq | grep "$domain" >> $location

        #crh.sh subdomains
        echo "Examples: %.yahoo.com, %.bf1.yahoo.com, %25.%25.%25.%25.%25.yahoo.com, %internal%.yahoo.com
                {you can put % wildcard anywhere in search like %api.yahoo.com}
                {Put some more wildcard in crt.sh website}
                "
        read -p "Use CRSH quries here: " crsh
        curl -s "https://crt.sh/?q=$crsh" | grep -Po "([a-z0-9][a-z0-9\-]{0,61}[a-z0-9]\.)+[a-z0-9][a-z0-9\-]*[a-z0-9]" | grep "$domain" | sort -u >> $location

        #dnsrecon subdomains
        dnsrecon -d $domain -a | grep -oE "[a-zA-Z0-9._-]+\.$domain" | uniq >> $location

        #gobuster vhost bruteforce
        gobuster vhost --useragent "google" --wordlist "/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt" --url https://$domain | grep -oE "[a-zA-Z0-9._-]+\.$domain" >> $location


        cat $location | sort | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> sortedSubdomains.txt

        #pinging using httpx
        cat $location | httpx-toolkit -silent -mc 200,302,301,403 | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> aliveDomains.txt


        echo "Successfully Extracted All Subdomains"
    else
        echo "$d is not a Valid Domain [FQDN]"
    fi
done



#notes:
#add further more tools on requirement basis
#theharvestor
#synapsint subdomains
#virustotal subdomains (Virus Total not supporting the curl so manualy is done)