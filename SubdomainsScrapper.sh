#! /bin/bash

# Create subdomains directory if it doesn't exist
mkdir -p subdomains
cd subdomains

# Starting Subdomains Scrapper
echo "Starting Subdomains Scrapper"
echo "Subdomains Scrapper V1.0"

# Read the domain from user input
read -p "Enter domain to extract all subdomains: " domain  # This variable stores the domain
echo "Domain: $domain"

# Loop through each domain
for d in $domain
do
    # Check if the domain is valid
    host $d 2>&1 > /dev/null
    if [ $? -eq 0 ]
    then
        echo "$d is a Valid Domain [FQDN]"
        
        # Prompt the user for the location to save files
        read -p "Location to save files: " location
        echo "Your location and filename of saving subdomains file: $location"

        # Starting DNS Recon
        dnsrecon -d $domain -a -t std -j $domain.json
        dnsenum --noreverse --enum $domain -w -p 100 -s 100 -o $domain.xml
        grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' $domain.xml >> ips.txt
        grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' $domain.json >> ips.txt
        dig $domain | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' >> ips.txt
        cat $domain.xml | gf domains  | sort -u | grep -vE '([0-9]{1,3}){3}' >> $location
        cat $domain.json | gf domains | sort -u | grep -vE '([0-9]{1,3}){3}' >> $location
        cat ips.txt | dnsx -ptr -resp-only >> reverse-lookups.json
        cat reverse-lookups.json | gf domains | sort -u | grep "$domain" >> $location

        # Starting Sublist3r
        echo "Starting Sublist3r"
        sublist3r -d $domain -o $location

        # Starting Rapiddns
        echo "Starting Rapiddns"
        curl -s "https://rapiddns.io/subdomain/$domain?full=1#result" | grep -B 1 "<td><a" | sed 's/<td><a.*//g' | gf domains | sort -u | sort -n | cut -d" " -f2- | grep "$domain" >> $location

        # Starting Ominsint
        echo "Starting Ominsint"
        curl -s "https://sonar.omnisint.io/subdomains/$domain" | gf domains | sort -u | grep "$domain" >> $location

        # Starting Wayback Url For Subdomains
        echo "Starting Wayback Url For Subdomains"
        waybackurls $domain | grep -oE "[a-zA-Z0-9._-]+\.$domain" | grep "$domain" | uniq >> $location

        # Starting subfinder and httpx
        echo "Starting subfinder and httpx"
        subfinder -d $domain --silent | gf domains | uniq | grep "$domain" >> $location

        # Starting amass
        echo "Starting amass"
        amass enum --passive -norecursive -d $domain | sort -u >> $location

        # Starting assetfinder
        echo "Starting assetfinder"
        assetfinder -subs-only $domain | sort -u >> $location

        # Starting subevil
        echo "Starting subevil"
        python3 /opt/tools/SubEvil/SubEvil.py -d $domain | gf domains | sort -u >> $location

        # Starting dnsrecon
        echo "Starting dnsrecon"
        dnsrecon -d $domain -a | grep -oE "[a-zA-Z0-9._-]+\.$domain" | uniq >> $location

        # Sort and deduplicate the results
        cat $location | sort | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-sorted.txt

        # Remove temporary files
        rm $location

        # # Starting GetAllUrls
        # echo "Starting GetAllUrls"
        # cat $domain-sorted.txt | gau | gf domains | grep "$domain" | sort -u >> $domain-sorted.txt
        
        # Append the sorted results to a new file
        cat $domain-sorted.txt | sort -u | tee -a $domain-sort.txt

        # Remove temporary files
        rm $domain-sorted.txt

        # Pinging using httpx
        echo "Pinging using httpx"
        cat $domain-sort.txt | httpx-toolkit -silent -mc 200,302,301,403,500 -p 80,8080,8443,443 | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-alive.txt

        echo "Successfully Extracted All Subdomains"

        # Perform permutations
        echo "Permutations are happening"
        altdns -i $domain-alive.txt -o $domain-altdns.txt -w /usr/share/wordlists/permutations.txt
        shuffledns -i $domain-altdns.txt -r /usr/share/wordlists/resolvers/resolvers-trusted.txt -o $domain-shuffledns.txt
        cat $domain-shuffledns.txt >> $domain-alldomains.txt

        # Pinging using httpx for all domains
        echo "Pinging using httpx for all domains"
        cat $domain-alldomains.txt | httpx-toolkit -silent -sc -title -mc 200,302,301,403,500 -p 80,8080,8443,443 | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-alive-1.txt

        # Separate the results based on the status code
        cat $domain-alive-1.txt | grep "200" >> 200.txt
        cat $domain-alive-1.txt | grep "301" >> 301.txt
        cat $domain-alive-1.txt | grep "302" >> 302.txt
        cat $domain-alive-1.txt | grep "403" >> 403.txt
        cat $domain-alive-1.txt | grep "500" >> 500.txt
         
        # Remove temporary files
        rm $domain.xml
        rm $domain.json
        rm reverse-lookups.json
        rm $domain-sorted.txt
        rm $domain-alive-1.txt
        rm $domain-permutations.txt
        rm $domain-permutations-1.txt
        rm $domain-nostatuscode.txt

    else
        echo "$d is not a Valid Domain [FQDN]"
    fi
done