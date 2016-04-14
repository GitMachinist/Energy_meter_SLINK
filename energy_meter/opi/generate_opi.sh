#!/bin/bash

set -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

template_file=$(readlink -f $DIR/template.xml)
single_template_file=$(readlink -f $DIR/single_template.xml)
config_file=$(dirname $template_file)/pvs.conf
output_opi=$(dirname $template_file)/energy_meter_select.opi
input_opi=$(readlink -f $DIR/energy_meter_select_single.opi)

#title
label="Energy Meters"

# main dimension
height_main=200
width_main=410

# initial position
x=6
y=48

# distance between linked containers
dy=45

# linked containers dimension
height_linked=$(grep -oPm1 "(?<=<height>)[^<]+" $input_opi)
width_linked=$(grep -oPm1 "(?<=<width>)[^<]+" $input_opi)

# create empty opi file
cp -f $template_file $output_opi

sed -i -e "s|WIDTH_INSERT|$width_main|g" $output_opi
sed -i -e "s|HEIGHT_INSERT|$height_main|g" $output_opi
sed -i -e "s|LABEL_INSERT|$label|g" $output_opi

# populate opi file
echo "Generating selection OPI screen for"
while read -a param ; do

    for pv in "${param[@]}"
    do
        sed -i -e "/WIDGET_INSERT/r$single_template_file" $output_opi
	    sed -i -e "s|OPI_FILE_INSERT|$(basename $input_opi)|g" $output_opi

        if [[ $pv =~ ^@.* ]]; then
            device_name=${pv:1}
            echo "Device" $device_name
        else
            echo ... $pv
            sed -i -e "s|DEVICE_NAME_INSERT|$device_name|g" $output_opi
            sed -i -e "s|HEAD_NAME_INSERT|$pv|g" $output_opi
            sed -i -e "s|X_POSITION_INSERT|$x|g" $output_opi
            sed -i -e "s|Y_POSITION_INSERT|$y|g" $output_opi
            sed -i -e "s|WIDTH_INSERT|$width_linked|g" $output_opi
            sed -i -e "s|HEIGHT_INSERT|$height_linked|g" $output_opi
            y=$((y+dy))
        fi
    done

done < $config_file

