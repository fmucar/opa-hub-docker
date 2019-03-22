#
# WebLogic Scripting tool script for Deploying OPA Private Cloud
# Web applications.
#
# This script does the following:
#  - Creates a JNDI Datasource for the web applications
#  - Deploys the web applications: opa-hub, web-determinations,
#    determinations-server
#
# Usage:
#
#   wlst.sh wlst_deploy.py -scriptdir=<dir of this script>
#        -propFile=<path to opahub_wlst.properties>
#        -name=<deployment name>
#        [-action=(all|webapps|datasource)]
#        [-adminserver=<wl admin server name>]
#        [-adminurl=<wladmin url>]
#
# Params:
#
#   scriptDir - the location of the opa bin dir
#   propertiesFile - the location of the wlst.properties file
#     for a deployment this should be something like <deployment-dir>/wlst.properties
#   deployName - the name for the deployment (eg. customer1)
#   action - the type of deploy:
#     all = deploy webapps and create datasource
#     datasource = create datasource only
#     webapps = deploy webapps only
#
#     NOTE: In the case of deploy, the default action is 'all' to deploy
#         web apps and create datasource.
#
#  adminserver and adminurl only need to be provided if they are not
#     present in the specified opahub_wlst.properties file. If set, these take precedence
#     over any existing values in the opahub_wlst.properties files.
#
#   If datasource creation is specified, then it is expected that the database password
#   will be provided as standard input, this can be piped via the standard mechanisms
#   eg: wlst.sh wlst_deploy.py ... <<<password
#
# $Id: wlst_deploy.py 78746 2013-10-07 21:26:07Z bradleyt $
#
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
# returns a map of database parameters based on the type of database being
# configured
def getDatabaseParameters(props):
    databaseArgs = {}
    dbType = props.getProperty("ds.dbtype", "mysql")

    if dbType == "mysql":
        databaseArgs["driver"] = props.get("ds.conn.driver.mysql")
        databaseArgs["dbURL"] = props.get("ds.conn.prefix.mysql")+props.get("ds.url")+props.get("ds.conn.properties.mysql")
    else:
        databaseArgs["driver"] = props.get("ds.conn.driver.oracle")
        databaseArgs["dbURL"] = props.get("ds.conn.prefix.oracle")+props.get("ds.url")+props.get("ds.conn.properties.oracle")

    return databaseArgs

###############################################################################
# main

namedArgs = getNameArguments()

scriptDir=namedArgs.get("scriptdir")
propFile=namedArgs.get("propfile")
deployDir=namedArgs.get("deploydir")
action=namedArgs.get("action", "all")

deploy = True
if ( (action != "webapps") and (action != "all") ):
    deploy = False

createDS = True
if ( (action != "datasource") and (action != "all") ):
    createDS = False


# if createDS and deploy are both false then default to do both
if not createDS and not deploy:
    createDS=True
    deploy=True

from java.io import File, FileInputStream

propStream = FileInputStream(propFile)
props = Properties()
props.load(propStream)
wlAdminServer=namedArgs.get("adminserver", props.get("admin.server"))
wlurl=namedArgs.get("adminurl", props.get("admin.url"))
deployName=props.get("deploy.name")
targetName=props.get("deploy.target")
dbType = props.getProperty("ds.dbtype", "mysql")
dsName = "OPA_Hub_Datasource_"+deployName
appName=deployName+"-opa"
ear=appName
earFile=deployDir+"/"+ear+".ear"




# Print so information for the logs
print "stdout: Creating OPA Private Cloud with the following Parameters:"
print "stdout: OPA Deployment Name: "+deployName
print "stdout: .ear file location "+deployDir
print "stdout: "+appName+".ear"
print "stdout: Deployment target: "+targetName
print "stdout: Datasource name: "+dsName
print "stdout: Database type: " + dbType


# connect to the admin server
print "stdout: connecting to admin server "+wlAdminServer
connect(url=wlurl,adminServerName=wlAdminServer)
configMgr = getConfigManager()
print "stdout: connected"

############# Check for existing datasource
# check to see if the datasouce exists and exit if it does
if createDS:
    check = find(name=dsName,type="JDBCSystemResource")
    if len(check) > 0:
        print "stdout: Data source with name "+dsName+" already exists. Cannot deploy web applications for '"+deployName+"'"
        configMgr.purgeCompletedActivationTasks()
        exit("y", 1)

if deploy:
    # check for existing webapps
    existing = False
    check = find(name=appName, type='AppDeployment')
    if (len(check) > 0):
         print "stdout: Web application with name "+webapp+" already exists. Cannot deploy web applications for '"+deployName+"'"
         existing = True;

    if existing:
        configMgr.purgeCompletedActivationTasks()
        exit("y", 1)

    #check for existing datasource if we arent creating one
    if not createDS:
        check = find(name=dsName,type="JDBCSystemResource")
        if len(check) < 1:
            print "stdout: Data source with name "+dsName+" does not exist. Cannot deploy web applications for '"+deployName+"'"
            configMgr.purgeCompletedActivationTasks()
            exit("y", 1)



# get the target cluster as the deployment target
target = getClusterOrServerTarget(targetName)
cd("../../")

############# Create datasource
if createDS:
    try:
        # db password piped
        dbPassword=raw_input("Datasource user password:")
        dbParams = getDatabaseParameters(props)
        dbURL=dbParams.get("dbURL")
        dsDriver=dbParams.get("driver")
        dbUser=props.get("ds.user")
        dsJndiPrefix=props.get("ds.jndi.prefix")
        dsConnTest=props.get("ds.conn.test")
        dsConnInitalCapacity=int(props.get("ds.conn.initialcapacity"))
        dsConnMax=int(props.get("ds.conn.max"))        
        dsJNDIName=dsJndiPrefix+deployName

        edit()
        startEdit()

        jdbcRes = create(dsName, "JDBCSystemResource")
        theJDBCRes = jdbcRes.getJDBCResource()
        theJDBCRes.setName(dsName)

        dsParams = theJDBCRes.getJDBCDataSourceParams()
        dsParams.addJNDIName(dsJNDIName)

        # connection pool parameters
        connPoolParams = theJDBCRes.getJDBCConnectionPoolParams()
        connPoolParams.setTestTableName(dsConnTest)
        connPoolParams.setInitialCapacity(dsConnInitalCapacity)
        connPoolParams.setMaxCapacity(dsConnMax)
        
        cd("/JDBCSystemResources/"+dsName+"/JDBCResource/"+dsName+"/JDBCConnectionPoolParams/"+dsName)
        # Driver parameters (including password)
        driverParams = theJDBCRes.getJDBCDriverParams()
        driverParams.setUrl(dbURL)
        driverParams.setDriverName(dsDriver)
        driverParams.setPassword(dbPassword)

        # driver properties (user)
        driverProperties = driverParams.getProperties()
        proper = driverProperties.createProperty("user")
        proper.setValue(dbUser)

        # set the target to target cluster
        jdbcRes.addTarget(target)

        # activate the jdbc
        save()
        activate()

        print "stdout: Datasource "+dsName+" created successfully"

    except Exception, e:
        print "Error creating datasource: "+str(e)
        print dumpStack()

        print "Error activating Datasource - rolling back changes."
        print "- Check the datasource connection details"
        print "- Check that the database is running and can be contacted"

        # delete the jndi datasource if it exists
        check = find(name=dsName,type="JDBCSystemResource")
        if len(check) > 0:
            startEdit()
            print "stdout: Attempting to delete Datasource: 'JDBCSystemResources/"+dsName+"'"
            delete(dsName,'JDBCSystemResource')
            print "stdout: Datasource: 'JDBCSystemResources/"+dsName+"' deleted successfully."

            save()
            activate()
        else:
            print "stdout: Datasource '"+dsName+"' not found"

        configMgr.purgeCompletedActivationTasks()
        exit('y', 1)

############# Deploy webapps
if deploy:

    checkFile = File(earFile)
    print "Checking that the web application file "+earFile+" exists"
    if not checkFile.exists():
        raise Exception("stdout: Web application file "+earFile+" could not be found")

    try:
        # domainConfig tree required for policy/role creation
        domainConfig()

        print "stdout: deploying "+ear
        deploy(appName=ear,path=earFile,targets=targetName,libraryModule='false',upload='true',securityModel='CustomRolesAndPolicies')
        print "stdout: Web applications deployed successfully"

    except Exception, e:
        print "stdout: Error occurred deploying web applications rollback set to true. "+str(e)
        print dumpStack()

        print "stdout: Undeploying... Web applications"

        try:

            # delete the jndi datasource if it exists, if we created it
            if createDS:
                check = getMBean("JDBCSystemResources/"+dsName)
                if check is not None:
                    edit()
                    startEdit()
                    editing = True
                    print "stdout: Attempting to delete Datasource: 'JDBCSystemResources/"+dsName+"'"
                    delete(dsName,'JDBCSystemResource')
                    print "stdout: Datasource: 'JDBCSystemResources/"+dsName+"' deleted successfully."

                    save()
                    activate()
                    editing = False
                else:
                    print "stdout: Datasource '"+dsName+"' not found"

        except Exception, e:
            print "stdout: Error rolling back deployment: "+str(e)
            dumpStack()
            if editing:
                cancelEdit('y')

        configMgr.purgeCompletedActivationTasks()
        exit('y', 1)

#exit cleanly if no errors
configMgr.purgeCompletedActivationTasks()

print "stdout: Deployment successful."
if createDS:
    print "DataSource '"+dsName+"' created"
if deploy:
    print "stdout: Webapplications deployed to target '"+targetName+"'"
    print

exit('y', 0)