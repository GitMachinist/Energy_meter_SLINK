TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#=============================
# Build the IOC application

PROD_IOC = gentec
# gentec.dbd will be created and installed
DBD += gentec.dbd
#DBD += menuScan.dbd

# gentec.dbd will be made up from these files:
gentec_DBD += base.dbd asyn.dbd stream.dbd AsynReg.dbd asSupport.dbd asub.dbd

# Include dbd files from all support applications:
#gentec_DBD += xxx.dbd

# Add all the support libraries needed by this IOC
gentec_LIBS += asyn stream autosave

# gentec_registerRecordDeviceDriver.cpp derives from gentec.dbd
gentec_SRCS += gentec_registerRecordDeviceDriver.cpp
gentec_SRCS += monitor_connection.c

# Build the main IOC entry point on workstation OSs.
gentec_SRCS_DEFAULT += gentecMain.cpp
gentec_SRCS_vxWorks += -nil-

# Add support from base/src/vxWorks if needed
#gentec_OBJS_vxWorks += $(EPICS_BASE_BIN)/vxComLibrary

# Finally link to the EPICS Base libraries
gentec_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

