# -*- coding: utf-8 -*-

import os
import sys
import json
from pprint import pprint
from math import sqrt

arq1 = sys.argv[1]
arq2 = sys.argv[2]

# Check if will work with 1 or 2 files

if arq2 == 'NA':
	
	# Open file
	data = json.load(open(arq1))
	# Extract lat/lon values
	lat_med = data['results'][0]['geometry']['location']['lat']
	lon_med = data['results'][0]['geometry']['location']['lng']

else:
	
	# Open files
	data1 = json.load(open(arq1))
	data2 = json.load(open(arq2))
	
	# Make list with lat/lon values (in cases where there is ambiguity, Google Maps will return more than one result)
	nresults1 = len(data1['results'])
	lat1 = []
	lon1 = []
	nresults2 = len(data2['results'])
	lat2 = []
	lon2 = []
	i = 0
	while (i < nresults1):
		#print str(data['results'][i]['geometry']['location']['lat']) + ',' + str(data['results'][i]['geometry']['location']['lng'])
		lat1.append(data1['results'][i]['geometry']['location']['lat'])
		lon1.append(data1['results'][i]['geometry']['location']['lng'])
		i = i + 1
	i = 0
	while (i < nresults2):
		lat2.append(data2['results'][i]['geometry']['location']['lat'])
		lon2.append(data2['results'][i]['geometry']['location']['lng'])
		i = i + 1
	
	# Find lat/lon pair nearest between cj1 and cj2
	dist_comp = 9999
	for x1 in range(0, nresults1):
		for x2 in range(0, nresults2):
			# Calculate distance between point x1-th and point y1-th
			dist = sqrt(pow(lat1[x1]-lat2[x2],2) + pow(lon1[x1]-lon2[x2],2))
			# If the distance is less than that calculated before, choose that pair
			if dist < dist_comp:
				dist_comp = dist
				lat1_best = lat1[x1]
				lat2_best = lat2[x2]
				lon1_best = lon1[x1]
				lon2_best = lon2[x2]
	
	# Calculate mean between two coordinates
	lat_med = (lat1_best + lat2_best)/2
	lon_med = (lon1_best + lon2_best)/2

# Print solution
print str(lat_med)+';'+str(lon_med)

#sys.exit("exit test")
