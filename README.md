# Bulk convert from address to latitude/longitude

Bash script "rec_coord.sh" read CSV file line by line to extract address at two formats: STREET, NUMBER and STREET crossing STREET. An URL is mounted to use API Google Maps Geocoding and a JSON file is downloaded. This file is read by "read_json.py" python script to obtain geographical coordinates (latitude and longitude).

- Put your API key from Google Maps Geocoding at "rec_coord.sh" shell script
- Input file: places.csv (according with places_ex.csv example)
- Output files: coordinates.csv (conversion OK) and dolater_coordinates.csv_YYY-mm-DD_HH:MM (conversion not OK)

More details at comments on scripts and this link (in portuguese): https://www.monolitonimbus.com.br/como-converter-endereco-em-latitude-e-longitude/
