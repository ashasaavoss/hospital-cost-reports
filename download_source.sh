#!/bin/bash

# download source HCRIS data from CMS

# download data for the years specified below
# note that for the synthetic calendar year files, the output will run from STARTYEAR+1
# to ENDYEAR-1
STARTYEAR=2019
ENDYEAR=2024

# where to put HCRIS files. by default store in the source folder, but since files
# can get quite large, you might want to store them elsewhere

OUTFOLDER="./source"

# check that curl is installed
if ! [ -x "$(command -v curl)" ]; then
  echo 'error: curl is not installed.' >&2
  exit 1
fi

# check that unzip is installed
if ! [ -x "$(command -v unzip)" ]; then
  echo 'error: unzip is not installed.' >&2
  exit 1
fi

# credit to user nyuszika7h on stackoverflow
# https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script

mkdir -p ${OUTFOLDER}/

for ((year=$STARTYEAR; year <= $ENDYEAR; year++))
do
	echo "downloading reports for $year"
	if [ $year -le 2011 ]
	then
		curl -L -o ${OUTFOLDER}/HOSPFY${year}.zip \
			http://downloads.cms.gov/Files/hcris/HOSPFY${year}.zip

		unzip -o -C ${OUTFOLDER}/HOSPFY${year}.zip \
			-d ${OUTFOLDER}/ \
			HOSP_${year}_RPT.CSV HOSP_${year}_NMRC.CSV HOSP_${year}_ALPHA.CSV

		# rename to standardized lowercase names (handles any case from CMS)
		for f in ${OUTFOLDER}/HOSP_${year}_*.[Cc][Ss][Vv]; do
			lc=$(echo "$f" | tr '[:upper:]' '[:lower:]')
			[ "$f" != "$lc" ] && mv "$f" "$lc"
		done
		mv ${OUTFOLDER}/hosp_${year}_rpt.csv ${OUTFOLDER}/hosp_rpt2552_96_${year}.csv
		mv ${OUTFOLDER}/hosp_${year}_nmrc.csv ${OUTFOLDER}/hosp_nmrc2552_96_${year}_long.csv
		mv ${OUTFOLDER}/hosp_${year}_alpha.csv ${OUTFOLDER}/hosp_alph2552_96_${year}_long.csv

		rm ${OUTFOLDER}/HOSPFY${year}.zip
	fi

	if [ $year -ge 2010 ]
	then
		curl -L -o ${OUTFOLDER}/HOSP10FY${year}.zip \
			http://downloads.cms.gov/Files/hcris/HOSP10FY${year}.zip

		unzip -o -C ${OUTFOLDER}/HOSP10FY${year}.zip \
			-d ${OUTFOLDER}/ \
			HOSP10_${year}_RPT.CSV HOSP10_${year}_NMRC.CSV HOSP10_${year}_ALPHA.CSV

		# rename to standardized lowercase names (handles any case from CMS)
		for f in ${OUTFOLDER}/HOSP10_${year}_*.[Cc][Ss][Vv]; do
			lc=$(echo "$f" | tr '[:upper:]' '[:lower:]')
			[ "$f" != "$lc" ] && mv "$f" "$lc"
		done
		mv ${OUTFOLDER}/hosp10_${year}_rpt.csv ${OUTFOLDER}/hosp_rpt2552_10_${year}.csv
		mv ${OUTFOLDER}/hosp10_${year}_nmrc.csv ${OUTFOLDER}/hosp_nmrc2552_10_${year}_long.csv
		mv ${OUTFOLDER}/hosp10_${year}_alpha.csv ${OUTFOLDER}/hosp_alph2552_10_${year}_long.csv

		rm ${OUTFOLDER}/HOSP10FY${year}.zip
	fi
done
