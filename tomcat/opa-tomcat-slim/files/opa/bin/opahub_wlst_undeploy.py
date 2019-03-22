##
# WebLogic Scripting tool script for Undeploying customer web applications
# and datasource from the Weblogic server. 
#
# Usage:
#
#   wlst.sh wlst_undeploy.py -scriptdir=<dir of this script> 
#        -propFile=<path to opahub_wlst.properties>  
#        -name=<deployment name>
#        [-adminserver=<wl admin server name>]
#        [-adminurl=<wladmin url>]
#        [-keepds]
# 
#   -adminserver and -adminurl only need to be provided if they are not 
#     present in the specified opahub_wlst.properties file.
#
#   If the -keepds switch is present then the datasource is not deleted.
#
# $Id: wlst_undeploy.py 78746 2013-10-07 21:26:07Z bradleyt $
#

###############################################################################
# get names arguments
def getNameArguments() :
    namedArgs = {}
            
    for arg in sys.argv:
        if arg.startswith("-"):
            valStart = arg.find("=")
            if valStart > 1:
                name = arg[1:valStart]
                value = arg[valStart + 1:len(arg)]
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:len(value) - 1]
            else:
                name = arg[1:len(arg)]
                value = True
                
            namedArgs[name] = value
            
    return namedArgs

###############################################################################
# function: undeploy a web application if it exists
def undeployIfExists(webapp): 
    if not webAppExists(webapp):
        print "stdout: web application '"+webapp+"' not found"
    else:
        try:
            print "stdout: Attempting to undeploy "+webapp
            undeploy(webapp)
            print "stdout: "+webapp+" undeployed successfully."
        except Exception, e:
            print "stdout: Error undeploying "+webapp+" "+str(e)
            dumpStack()
            return False
    #end if
    return True

# end def undeployIfExists

def webAppExists(webapp):
    return len(find(name=webapp,type="Appdeployment")) > 0
# end def deploymentExists

namedArgs = getNameArguments()

scriptDir=namedArgs.get("scriptdir")
propFile=namedArgs.get("propfile")
deployName=namedArgs.get("name")
keepDS = namedArgs.get("keepds", False)

from java.io import FileInputStream
propStream = FileInputStream(propFile)
props = Properties()
props.load(propStream)

dsPrefix=props.get("ds.prefix")
dsName = dsPrefix+deployName
wlAdminServer=namedArgs.get("adminserver", props.get("admin.server"))
wlurl=namedArgs.get("adminurl", props.get("admin.url"))

hub=deployName+"-opa-hub"
owd=deployName+"-web-determinations"
ods=deployName+"-determinations-server"
doc=deployName+"-document-generation-server"
appName=deployName+"-opa"
ear=appName

# Print so information for the logs
print "stdout: Undeploying OPA runtime"
print "stdout: OPA Deployment Name: "+deployName
if keepDS:
    print "stdout: Keep Datasource "+dsName
else:
    print "stdout: Delete Datasource: "+dsName




# connect to the admin server
print "stdout: connecting to admin server "+wlAdminServer
connect(url=wlurl,adminServerName=wlAdminServer)
configMgr = getConfigManager()
print "stdout: connected"

edit()

returnCode = 0
appsRemoved = False
dataSourceSuccess = False

try:

    appsRemoved = undeployIfExists(hub)
    appsRemoved = undeployIfExists(owd) and appsRemoved
    appsRemoved = undeployIfExists(ods) and appsRemoved
    appsRemoved = undeployIfExists(doc) and appsRemoved
    appsRemoved = undeployIfExists(ear) and appsRemoved

    dsNotFound = getMBean("JDBCSystemResources/"+dsName) is None
    if dsNotFound:
        print "stdout: Datasource '"+dsName+"' not found"
    else:
        if keepDS:
            print "stdout: Keeping datasource "+dsName
            dataSourceSuccess = True
        else:
            print "stdout: Deleting datasource "+dsName
            # delete the jndi datasource if it exists
            startEdit()
            print "stdout: Attempting to delete Datasource: 'JDBCSystemResources/"+dsName+"'"
            delete(dsName,'JDBCSystemResource')
            print "stdout: Datasource: 'JDBCSystemResources/"+dsName+"' deleted successfully."
            dataSourceSuccess = True
            
            save()
            activate()

except Exception, e:
    returnCode = 1
    print "stdout: Error undeploying. "+str(e)
    dumpStack()
    cancelEdit('y')

# overview of task completion
print "stdout: \n\n"
if appsRemoved:
    print "stdout: Web applications undeployed and deleted."
else:
    returnCode = 1
    print "stdout: Web application undeployment encountered possible errors."
    

if dataSourceSuccess:
    if keepDS:
        print "stdout: Datasource "+dsName+" kept."
    else:
        print "stdout: Datasource "+dsName+" deleted."
else:
    print "stdout: Removing Datasource "+dsName+" encountered possible errors."
    if dsNotFound:
        print "stdout: Datasource was not found."
    
if (appsRemoved and dataSourceSuccess):
    print "stdout: \n\nUndeployment completed successfully"
else:
    print "stdout: \n\nUndeployment completed with possible errors." 
    
configMgr.purgeCompletedActivationTasks()
exit("y", returnCode)
