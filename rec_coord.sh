#!/bin/bash
# Script to extract addresses, convert to lat / lon and save on a file

api_key=""
# Input file
file_in='places.csv'
# Substitute some wrong abreviation to Google Maps understand (maybe you need do something like that berfore)
sed -i 's/TN\./TÚNEL/g' $file_in
sed -i 's/RV\./ROD./g' $file_in
sed -i 's/;ALTURA DO N\.;/;ALTURA DO N.1;/g' $file_in
sed -i 's/TTE\./TENENTE/g' $file_in
# Output files
file_out='coordinates.csv'
do_later='dolater_'$file_in'_'$(date '+%F_%H%M')
rm -rf $file_out; touch $file_out
rm -rf $do_later; touch $do_later

# Read input file line by line
city='Sao Paulo'
count=0
IFS=''
while read line; do
	date=$(echo $line | awk -F';' '{print $1}')
	hour_ini=$(echo $line | awk -F';' '{print $5}')
	hour_fim=$(echo $line | awk -F';' '{print $6}')
	address1=$(echo $line | awk -F';' '{print $2}')
	address2=$(echo $line | awk -F';' '{print $3}')
	number=$(echo "$address2" | sed 's/[^0-9]//g')
	# Clean temporary files and variables
	rm -rf gmaps*.json
	coordinates=0;link=0;link1=0;link2=0
	# Verify if string has numbers
	if [ -z "$number" ]; then
		# Reverse what's on the left and right of the comma, for "address1" stay after the "address2"
		log1=$(echo $address1 | awk -F',' '{print $2}' | sed -e 's/ //g')' '$(echo $address1 | awk -F',' '{print $1}')
		log2=$(echo $address2 | awk -F',' '{print $2}' | sed -e 's/ //g')' '$(echo $address2 | awk -F',' '{print $1}')

		# Make CROSSING address - ex: AV. GUARAPIRANGA and AV. GUIDO CALOI (obs: THIS DOES NOT WORK IN BRAZIL)
		#info=$log1' and '$log2
		#link="http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=$info,$city"
		
		# If there is a square or bridge, this is the best location
		if [[ "$log1" == *"PÇ"* ]] || [[ "$log1" == *"PTE"* ]] || [[ "$log1" == *"VD"* ]]; then
			log2=$log1
		elif [[ "$log2" == *"PÇ"* ]] || [[ "$log2" == *"PTE"* ]] || [[ "$log2" == *"VD"* ]]; then
			log1=$log2
		fi
		info=$(echo $log1 "AND" $log2)
		echo "Converting" $info

		# Alternative: take lat / lon from the two streets (geometric center of each) and calculate average
		link1="https://maps.googleapis.com/maps/api/geocode/json?key="$api_key"&sensor=false&address=$log1,$city"
		link1=$(echo $link1 | sed 's/ /%20/g')
		link2="https://maps.googleapis.com/maps/api/geocode/json?key="$api_key"&sensor=false&address=$log2,$city"
		link2=$(echo $link2 | sed 's/ /%20/g')
		
		# Download files and see if they have been downloaded correctly, or if needs to download them again
		nlines1=0
		nlines2=0
		count_trouble=0
		while [ "$nlines1" -lt "50" ] || [ "$nlines2" -lt "50" ]; do
			wget -q -O gmaps1.json $link1
			nlines1=$(cat gmaps1.json | wc -l)
			wget -q -O gmaps2.json $link2
			nlines2=$(cat gmaps2.json | wc -l)
			echo "n lines: " $nlines1 "e" $nlines2
			# If there have been a lot of tentatives, probably ther some wrong, then separte to do later
			if [ "$count_trouble" -ge "5" ]; then
				coordinates=0
				break
			fi
			count_trouble=$((count_trouble+1))
		done
		# Only find coordinates if there's a valid value to do that
		if [ "$count_trouble" -lt "5" ]; then
			# Read JSON files and calculate average coordinate
			coordinates=$(python read_json.py gmaps1.json gmaps2.json)
		fi
	else
		# Reverse what's on the left and right of the comma, for "address1" stay after the "address2"
		log=$(echo $address1 | awk -F',' '{print $2}' | sed -e 's/ //g')' '$(echo $address1 | awk -F',' '{print $1}')
		# Make address with NUMBER - ex: AV. RAIMUNDO PEREIRA DE MAGALHAES, 12000
		info=$log', '$number
		echo "Converting" $info
		link="https://maps.googleapis.com/maps/api/geocode/json?key="$api_key"&sensor=false&address=$info,$city"
		link=$(echo $link | sed 's/ /%20/g')
		# Download files and see if they have been downloaded correctly, or if needs to download them again
		nlines=0
		count_trouble=0
		while [ "$nlines" -lt "50" ]; do
			wget -q -O gmaps.json $link
			nlines=$(cat gmaps.json | wc -l)
			echo "n lines: " $nlines
			# If there have been a lot of tentatives, probably ther some wrong, then separte to do later
			if [ "$count_trouble" -ge "5" ]; then
				coordinates=0
				break
			fi
			count_trouble=$((count_trouble+1))
		done
		# Only find coordinates if there's a valid value to do that
		if [ "$count_trouble" -lt "5" ]; then
			# Read JSON files and convert address in lat / lon - as it does not need two files, inform NA for the second
			coordinates=$(python read_json.py gmaps.json NA)
		fi
	fi
	# Print information in the output file (if OK)
	test=$(echo "${coordinates}" | awk -F'.' '{print NF}')
	if [ "$test" -eq "3" ]; then
		echo $date";"$hour_ini";"$hour_fim";\"$info\";"$coordinates >> $file_out
	else
		echo $line >> $do_later
	fi
	#exit
	# Print number of lines from the final file just for monitoring
	echo "lines converted:" $(cat $file_out | wc -l)"/"$(cat $file_in | wc -l)
	echo "------------------------------"
	# Update counter
	count=$((count+1))
done < $file_in
