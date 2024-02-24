#!/bin/bash

RED="\033[1;31m"
RESET="\033[0m"

domain=$1
if [ $# -eq 0 ]; then
        help
        exit 1
fi

subdomain_path=$domain/subdomains
screenshot_path=$domain/screenshots
scan_path=$domain/scans

if [ ! -d "$domain" ]; then
        mkdir $domain
fi

if [ ! -d "$subdomain_path" ]; then
        mkdir $subdomain_path
fi

if [ ! -d "$screenshot_path" ]; then
        mkdir $screenshot_path
fi

if [ ! -d "$scan_path" ]; then
        mkdir $scan_path
fi

echo -e "${RED} [+] We are starting subfinder ... ${RESET}"
subfinder -d $domain > $subdomain_path/found.txt

echo -e "${RED} [+] We are starting assetfinder ... ${RESET}"
assetfinder $domain | grep $domain >> $subdomain_path/found.txt

echo -e "${RED} [+] We are starting crt.sh ... ${RESET}" 
curl -s https://crt.sh/\?q\=%25.$domain\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u >> $subdomain_path/found.txt

echo -e "${RED} [+] We are finding alive subdomains ... ${RESET}"
cat $subdomain_path/found.txt | grep $domain | sort -u | httprobe | tee -a $subdomain_path/alive.txt
cat $subdomain_path/alive.txt | sed 's/https\?:\/\///' | sed 's/https\?:\/\///' > $subdomain_path/alive2.txt

echo -e "${RED} [+] We are Taking screensort of alive subdomains ... ${RESET}"
gowitness file -f $subdomain_path/alive2.txt -P $screenshot_path/ --no-http

echo -e "${RED} [+] We are Running nmap on alive subdomains ... ${RESET}"
nmap -iL $subdomain_path/alive2.txt -p21,22,25,80,8080,443,8433,8000,10000 -oN $scan_path/nmap.txt

