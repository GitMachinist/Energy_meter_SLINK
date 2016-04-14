#!../../bin/linux-x86_64/gentec

## You may have to change gentec to something else
## everywhere it appears in this file

< envPaths

cd ${TOP}

## Register all support components
dbLoadDatabase "dbd/gentec.dbd"
gentec_registerRecordDeviceDriver pdbbase

## Setup Autosave
set_savefile_path("$(TOP)/autoSaveRestore")
set_requestfile_path("$(TOP)/autoSaveRestore")
set_pass1_restoreFile("energy_meter.sav")

epicsEnvSet("STREAM_PROTOCOL_PATH", "$(TOP)/protocols")
drvAsynIPPortConfigure("P1", "192.168.42.203:10001")

epicsEnvSet("DEVICE","TEST-EM")
epicsEnvSet("HEAD1","TEST-HEAD1")
epicsEnvSet("HEAD2","TEST-HEAD2")
epicsEnvSet("CH1", "1")
epicsEnvSet("CH2", "2")
epicsEnvSet("PORT","P1")

## Load record instances
dbLoadRecords("db/energy_meter.db","device=$(DEVICE), port=$(PORT), head1=$(HEAD1), head2=$(HEAD2),chn_dis_1=$(CH1),chn_dis_2=$(CH2)")
dbLoadRecords("db/heartbeat.db", "DEVICE=$(DEVICE)")

#CHANNEL 1
dbLoadRecords("db/channel.db","device=$(DEVICE), port=$(PORT), channel=$(CH1), head=$(HEAD1), chn_dis=$(CH2)")
dbLoadRecords("db/state.db", "DEVICE=$(HEAD1), CHANNEL=$(CH1), port=$(PORT)")

#CHANNEL 2
dbLoadRecords("db/channel.db","device=$(DEVICE), port=$(PORT), channel=$(CH2), head=$(HEAD2), chn_dis=$(CH1)")
dbLoadRecords("db/state.db", "DEVICE=$(HEAD2), CHANNEL=$(CH2), port=$(PORT)")


cd ${TOP}/iocBoot/${IOC}
iocInit

## Start any sequence programs
#seq sncxxx,"user=marcinHost"

create_monitor_set("energy_meter.req", 5, "device=$(HEAD1), channel=1")
create_monitor_set("energy_meter.req", 5, "device=$(HEAD2), channel=2")
