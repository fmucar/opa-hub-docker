###############################################################################
# WebLogic Scripting tool script for Redploying OPA Private Cloud
# Web applications.
#
# This script does the following:
#  - redeploys the web applications: opa-hub, web-determinations,
#    determinations-server
#    retireGracefully is set
#
# Usage:
#
#   wlst.sh wlst_redeploy.py -scriptdir=<dir of this script>
#        -propFile=<path to opahub_wlst.properties>
#        -name=<deployment name>
#        -deploydir=<path to webapp war files>
#        [-action=(all|webapps|datasource)]
#
# Params:
#
#   scriptDir - the location of the opa bin dir
#   propertiesFile - the location of the opahub_wlst.properties file
#     for a deployment this should be something like <deployment-dir>/opahub_wlst.properties
#   deployName - the name for the deployment (eg. customer1)
#   action - the type of deploy:
#     all = redeploy webapps and reconfigure and redeploy datasource
#     datasource =  reconfigure and redeploy datasource only
#     webapps = redeploy webapps only
#
#     NOTE: In the case of redeploy, the default action is 'webapps' to redeploy
#           the webapplications only.
#
#  adminserver and adminurl only need to be provided if they are not
#     present in the specified opahub_wlst.properties file. If set, these take precedence
#     over any existing values in the opahub_wlst.properties files.
#
#   If datasource redeployment is specified, then it is expected that the database password
#   will be provided as standard input, this can be piped via the standard mechanisms
#   eg: wlst.sh wlst_redeploy.py ... <<<password
#
# $Id: wlst_redeploy.py 78746 2013-10-07 21:26:07Z bradleyt $
#

from java.io import FileInputStream


###############################################################################
# get names arguments
def getNameArguments():
    namedArgs = {}

    for arg in sys.argv:
        if arg.startswith("-"):
            valStart = arg.find("=")
            if valStart > 1:
                name = arg[1:valStart]
                value = arg[valStart+1:len(arg)]
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:len(value)-1]
            else:
                name = arg[1:len(arg)]
                value = True

            namedArgs[name] = value

    return namedArgs

###############################################################################
# returns a target MBean (Cluster or Server) got by its Name. This function
# looks for a cluster by name and then a server by name
def getClusterOrServerTarget(targetName):
    target  = getMBean("/Clusters/"+targetName)
    if target is None:
        target  = getMBean("/Servers/"+targetName)
        if target is None:
            raise Exception("Could not find Cluster or Server with name "+targetName)

    return target

###############################################################################
# function: redeploys the application if its current state in running.
# if it is not running it uses distributeApplication
def redeployInCurrentState(webapp, webappPath, webappState, targetName):
    print "stdout: redeploying "+webapp
    print webapp+" state is "+str(webappState)

    # redeploy in admin only mode (testMode="true") if the webapp is stopped or in admin already
    sTestMode="false"
    if "STATE_PREPARED" == webappState or ("STATE_ADMIN" == webappState):
        sTestMode="true"

    # check to see if we are redeploying or doing a new deployment
    check = getMBean("/AppDeployments/"+webapp)

    # if the web application does not exist, deploy as new and
    # add the security policy if necessary
    if check is None:
        progress = deploy(webapp, webappPath,upload="true",targets=targetName)
        progress.getState()
    else:
        progress = redeploy(appName=webapp,appPath=webappPath,upload="true",testMode=sTestMode,retireGracefully="true",securityModel='CustomRolesAndPolicies')
        progress.getState()
    # stop the webapp if it was in state prepared
    if "STATE_PREPARED" == webappState :
        print "stopping web application because of initial state: "+webappState
        stopApplication(appName=webapp,retireGracefully="false")
    #end if

    print "stdout: redeployed successfully"

# end def redployInCurrentState

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

###############################################################################
# main
namedArgs = getNameArguments()

scriptDir=namedArgs.get("scriptdir")
propFile=namedArgs.get("propfile")
deployDir=namedArgs.get("deploydir")
action=namedArgs.get("action", "webapps")

redeploy = True
if ( (action != "webapps") and (action != "all") ):
    redeploy = False

updateDS = True
if ( (action != "datasource") and (action != "all") ):
    updateDS = False


propStream = FileInputStream(propFile)
props = Properties()
props.load(propStream)

dsConnMax = int(props.get("ds.conn.max"))
dsConnTimeout = int(props.get("ds.conn.timeout"))
dsConnTest = props.get("ds.conn.test")
dsConnInitalCapacity = int(props.get("ds.conn.initialcapacity"))
dsConnShrinkFreq = int(props.get("ds.conn.shrinkfreq"))
dsConnWrapTypes = props.get("ds.conn.wraptypes")
dsConnCreateRetyFreq = int(props.get("ds.conn.createRetyFreq"))
dsConnReserveTimeoout = int(props.get("ds.conn.reserveTimeout"))
dsConnInactiveTimeout = int(props.get("ds.conn.inactiveTimeout"))

wlAdminServer=namedArgs.get("adminserver", props.get("admin.server"))
wlurl=namedArgs.get("adminurl", props.get("admin.url"))
deployName=props.get("deploy.name")
dsName = "OPA_Hub_Datasource_"+deployName

hub=deployName+"-opa-hub"
owd=deployName+"-web-determinations"
ods=deployName+"-determinations-server"
doc=deployName+"-document-generation-server"
appName=deployName+"-opa"
ear=appName
earFile=deployDir+"/"+ear+".ear"

# Print so information for the logs
print "stdout: Redploying OPA Private Cloud with the following Parameters:"
print "stdout:  OPA Deployment Name: "+deployName
print "stdout: Webapplication (.ear) file location "+deployDir
print "stdout: "+ear+".ear"
print "stdout: Datasource name: "+dsName


exitCode = 0

# connect to the admin server
print "stdout: connecting to admin server "+wlAdminServer
connect(url=wlurl,adminServerName=wlAdminServer)
configMgr = getConfigManager()
print "stdout: connected"

try:
    edit()
    
    targets = None
    dataSource = getMBean("/JDBCSystemResources/"+dsName)
    if dataSource is None:
        print "stdout No datasource dsName found"
        exit('y', 1)
        
    targets = dataSource.getTargets()
        
    if len(targets) < 1:
        print "No targets found for datasource "+dsName+". Getting target from webapp "+hub
        hubWebApp = getMBean("/AppDeployments/"+hub)
        if hubWebApp is not None:
            targets = hubWebApp.getTargets()

    if len(targets) < 1:
        raise Exception("target could not be found for data source "+dsName+" or webapp "+hub)

    targetName = targets[0].getName()
    print "target for existing deployment is "+targetName

    if updateDS:
        startEdit()
        editing = true

        #update datasource properites
        cd("/JDBCSystemResources/"+dsName)

        connPoolParams = cmo.getJDBCResource().getJDBCConnectionPoolParams()
        connPoolParams.setTestTableName(dsConnTest)
        connPoolParams.setConnectionReserveTimeoutSeconds(dsConnTimeout)
        connPoolParams.setMaxCapacity(dsConnMax)
        connPoolParams.setInitialCapacity(dsConnInitalCapacity)
        connPoolParams.setShrinkFrequencySeconds(dsConnShrinkFreq)
        connPoolParams.setConnectionCreationRetryFrequencySeconds(dsConnCreateRetyFreq)
        connPoolParams.setConnectionReserveTimeoutSeconds(dsConnReserveTimeoout)
        connPoolParams.setInactiveConnectionTimeoutSeconds(dsConnInactiveTimeout)

        cd("/JDBCSystemResources/"+dsName+"/JDBCResource/"+dsName+"/JDBCConnectionPoolParams/"+dsName)
        set('WrapTypes', dsConnWrapTypes)

        save()
        activate()

        print "stdout: Saved datasource changes"


        startEdit()
        cd("/JDBCSystemResources/"+dsName)
        set('Targets',jarray.array([], ObjectName))
        save()
        activate()

        print "Target removed from datasource"

        # re-add all targets, and activate to redeploy resource with new settings
        startEdit()
        target = getClusterOrServerTarget(targetName)

        cd("/JDBCSystemResources/"+dsName)
        set('Targets',jarray.array([target], Class.forName("weblogic.management.configuration.TargetMBean")))

        print "Target readded to data source"

        save()
        activate()
        editing = false

        print "stdout: Datasource updated"

except Exception, e:
    print dumpStack()
    print "stdout: Exception occurred: "+str(e)
    print "stdout: Error occurred updating data source."
    print "stdout: continuing to redeploy web applications"
    exitCode = 1

    if editing:
        cancelEdit('y')

#end if updateDS

if redeploy:
    try:   
        
        cd("domainRuntime:/AppRuntimeStateRuntime/AppRuntimeStateRuntime")
        opaState = cmo.getIntendedState(ear)
    
        # domainConfig tree required for policy/role creation
        domainConfig()

        # undeploy the old war webapps if they exist
        print "stdout: Undeploying old web applications"
        returnCode = undeployIfExists(hub)
        returnCode = undeployIfExists(owd)
        returnCode = undeployIfExists(ods)
        returnCode = undeployIfExists(doc)

        redeployInCurrentState(ear, earFile, opaState, targetName)
        print "Web applications deployed successfully"

    except Exception, e:
        print dumpStack()
        print "stdout: Exception occurred: "+str(e)
        print "stdout: Error occurred redeploying web applications."

        exitCode = 1

        if editing:
            cancelEdit('y')
#end if redeploy

configMgr.purgeCompletedActivationTasks()
exit('y', exitCode)