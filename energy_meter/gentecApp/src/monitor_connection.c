#include <stdio.h>
#include <aSubRecord.h>
#include <registryFunction.h>
#include <epicsExport.h>

static long connection_status(aSubRecord *precord)
{
    char *stat, *sevr;
    int status = 0;

    // get SEVR info from INPA
    sevr = (char *) precord->a;

    // get STAT info from INPB
    stat = (char *) precord->b;

    // analysis values of STAT and SEVR
    if(strcmp(stat,"NO_ALARM")==0 && strcmp(sevr,"NO_ALARM")==0)
    {
        status = 1; // connected
    }

    return status;
}

// register functions
epicsRegisterFunction(connection_status);

