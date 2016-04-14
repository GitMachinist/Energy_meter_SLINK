#!/bin/bash

set -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

if [ -z "$*" ]; then
    echo "no arguments supplied. 1:configfile 2:destination"
    exit 1
fi

# read config file
CONFIG=$(readlink -f $1)

# source directory is one level up from the script folder
SOURCE=$(readlink -f $DIR/..)
echo Source folder: $SOURCE

ROOT=$(readlink -f $2)
# create the destination folder if it does not exists
DESTINATION=$ROOT/energy_meter
echo Destination folder: $DESTINATION

if [ ! -d $DESTINATION ]; then
    echo "Specified destination directory does not exist. Will create it now."
    mkdir -p $DESTINATION
fi



# monitoring command file
monitoring_file=$DESTINATION/monitoring_energy_meter.cmd
touch $monitoring_file
> $monitoring_file

# traffic light command file
traffic_light_file=$DESTINATION/traffic_light_energy_meter.cmd
touch $traffic_light_file
> $traffic_light_file

# list of devices command file
devices_config_file=$DESTINATION/devices_energy_meter.cmd
touch $devices_config_file
> $devices_config_file
devices=""

while read -a param ; do

    # skip empty line
    [[ -z ${param[0]} ]] && continue

    # skip line starting with #
    [[ ${param[0]} =~ ^#.* ]] && continue

    # get parameters from config file
    machine_name=${param[0]}
    pv_name_ch1=${param[1]}
    ip_addr=${param[3]}
    tcp_port=${param[4]}

#create autosave folder if it does not exist
AUTOSAVE=$ROOT/../autosave/energy_meter/$machine_name
if [ ! -d $AUTOSAVE ]; then
    echo "Autosave directory does not exist. Will create it now."
    mkdir -p $AUTOSAVE
fi

    echo "setting up" $machine_name "with IP address" $ip_addr "and port" $tcp_port

    # copy IOC (cannot be a 'cp' as this would copy the .svn files as well)
    rsync -arvud --exclude=".svn*" $SOURCE/ $DESTINATION/$machine_name

    # setup for second channel:
    if [ "${param[2]}" != "#NOTUSED#" ]; then
        pv_name_ch2=${param[2]}
        cp -f   $SOURCE/gentecApp/Db/energy_meter_double_channel.db $DESTINATION/$machine_name/gentecApp/Db/energy_meter.db 
 
    else 

        cp -f   $SOURCE/gentecApp/Db/energy_meter_single_channel.db $DESTINATION/$machine_name/gentecApp/Db/energy_meter.db 

        #only one channel - unnecessary lines in st.cmd
        sed -i -e '/epicsEnvSet("HEAD2","TEST-HEAD2")/s/^/#/g' $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd 
        sed -i -e '/epicsEnvSet("CH2", "2")/s/^/#/g' $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd        
        sed -i -e 's/, head2=$(HEAD2)//g' $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd 
        sed -i -e '/dbLoadRecords(\"db\/channel.db\",\"device=\$(DEVICE), port=\$(PORT), channel=\$(CH2), head=\$(HEAD2)\")/s/^/#/g' $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd
        ##sed -i -e '/dbLoadRecords("\db\/heartbeat.db", \"DEVICE=\$(HEAD2)\")/s/^/#/g' $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd
        sed -i -e '/dbLoadRecords("\db\/state.db", \"DEVICE=\$(HEAD2), CHANNEL=\$(CH2), port=\$(PORT)\")/s/^/#/g' $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd
        sed -i -e '/create_monitor_set(\"energy_meter.req\", 5, \"device=$(HEAD2), channel=2\")/s/^/#/g' $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd
    fi 


	# remove opi folder
    rm -rf $DESTINATION/$machine_name/opi

    # set PV name
    find $DESTINATION/$machine_name -type f -exec sed -i "s/TEST-EM/$machine_name/g" {} +
    find $DESTINATION/$machine_name -type f -exec sed -i "s/TEST-HEAD1/$pv_name_ch1/g" {} +
    find $DESTINATION/$machine_name -type f -exec sed -i "s/TEST-HEAD2/$pv_name_ch2/g" {} +

	# set autosave path
	sed -i -e "/set_savefile_path(\"/ s|\$(TOP)/autoSaveRestore|$AUTOSAVE|" $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd
	
    # set ip and tcp port
    sed -i -e "/drvAsynIPPortConfigure(\"P1\"/ s|[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}:[0-9]\+|$ip_addr:$tcp_port|" $DESTINATION/$machine_name/iocBoot/iocgentec/st.cmd

    # build code
    pushd $DESTINATION/$machine_name/
    make
    popd

    echo "dbLoadRecords(\"db/monitor_ioc.db\", \"DEVICE=MONITOR, NAME=$machine_name, IOC=$machine_name\")" >> $monitoring_file

    if [ "${param[2]}" != "#NOTUSED#" ]; then

        # generate st.cmd commands for the traffic light IOC
        echo "dbLoadRecords(\"db/traffic_light.db\",\"NAME=$pv_name_ch1\")" >> $traffic_light_file
        echo "dbLoadRecords(\"db/energy_meter_adapter.db\",\"NAME=$pv_name_ch1, BOX=$machine_name, MONITOR=MONITOR\")" >> $traffic_light_file

        echo "dbLoadRecords(\"db/traffic_light.db\",\"NAME=$pv_name_ch2\")" >> $traffic_light_file
        echo "dbLoadRecords(\"db/energy_meter_adapter.db\",\"NAME=$pv_name_ch2, BOX=$machine_name, MONITOR=MONITOR\")" >> $traffic_light_file

    else

        # generate st.cmd commands for the traffic light IOC
        echo "dbLoadRecords(\"db/traffic_light.db\",\"NAME=$pv_name_ch1\")" >> $traffic_light_file
        echo "dbLoadRecords(\"db/energy_meter_adapter.db\",\"NAME=$pv_name_ch1, BOX=$machine_name, MONITOR=MONITOR\")" >> $traffic_light_file

    fi

    # add to the list of IOCs to be launched
    echo $machine_name $DESTINATION/$machine_name/ >> $(readlink -f $DIR/../../manage/process/iocBoot/iocprocess/iocs.conf)

    # make a list of PV names
    machine_name_opi="@$machine_name" 
    if [ "${param[2]}" != "#NOTUSED#" ]; then
        devices="$devices $machine_name"   
        machines="$machines $machine_name_opi $pv_name_ch1 $pv_name_ch2"
        devices_count=$((devices_count+1))
    else
        devices="$devices $machine_name"
        machines="$machines $machine_name_opi $pv_name_ch1"
        devices_count=$((devices_count+1))
    fi

done < $CONFIG

# add pv name to list of devices
echo "system \"caput -a -s DEVICES:ENERGY_METERS" $devices_count $devices"\"" >> $devices_config_file

# add list of PV prefixes to config file used by Manager OPI
echo $devices >> $DIR/../../manage/opi/pvs.conf

# deploy the CSS opi screens
> $SOURCE/opi/pvs.conf
echo $machines >> $SOURCE/opi/pvs.conf
$SOURCE/opi/generate_opi.sh
mkdir -p $DESTINATION/opi
cp -f $SOURCE/opi/*.opi $DESTINATION/opi

