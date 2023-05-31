#! /bin/bash

mkdir -p urls
cd urls
echo "Starting WayBackUrl"
wayback machine
waybackurls $domain-aliveDomains.txt | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-urls.txt

echo "Starting GAU for Links"
cat $domain-aliveDomains.txt | gau | uniq | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- >> $domain-urls.txt

echo "Starting HTTPX"
cat $domain-urls.txt | httpx-toolkit -silent -mc 200,302,301,403,500 >> $domain-aliveUrls.txt

rm $domain-urls.txt