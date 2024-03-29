									*************************************************************
									* OpenMobster - Mobile Backend as a Service Platform
									*************************************************************

********************									
Project Layout:    *
********************									

Each generated project has the following 3 maven modules:

* app-android - Contains the App for the Android OS

* cloud - Contains the "OpenMobster Cloud Server" based artifacts which will be deployed on the server side

* moblet - Represents a "OpenMobster Moblet" which combines both the device side and server side artifacts into one single
artifact. The moblet is deployed as a simple jar file into the "OpenMobster Cloud Server". When the moblet is deployed into the Cloud
server it is registered with the built-in App store. Once registered with the App Store, this moblet can be easily downloaded, installed, and
managed on the actual device via the "App Store" functionality under the "Cloud Manager" app 


****************************									
Helpful Development Tips:  *
****************************

Build All the artifacts:
------------------------------
mvn install

This command builds all the artifacts. 


Build and Deploy the Android App on a device
---------------------------------------------
To hot deploy your Android App, use the following command:
cd app-android
mvn -Papp-hot-deploy install



**********************************************									
Standalone "Development Mode" Cloud Server:  *
**********************************************

On the Cloud-side of things, there is a fully functional Standalone "Development Mode" Cloud Server provided 
that you can run right from inside your Maven environment.

Command to run the standalone "Development Mode" Cloud Server:
---------------------------------------------------------------
mvn -PrunCloud integration-test


Command to run the standalone "Development Mode" Cloud Server in *debug mode*:
-------------------------------------------------------------------------------
mvn -PdebugCloud integration-test


************************************
JBoss AS Deployment				   *
************************************

Once the App and its corresponding Cloud artifacts are developed and tested end-to-end, you can aggregate all these artifacts into
a single moblet jar ready for deployment into a JBoss AS based Cloud Server.

This single artifact when deployed into the JBoss AS based Cloud Server performs all necessary registrations with the system
and is ready for deploying the app onto a real phone via the Internet.

Commands:

	* Generate an the app and deploy into the JBoss AS instance:
		cd moblet
		mvn -Pjboss-install install