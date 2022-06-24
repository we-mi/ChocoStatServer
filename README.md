# WIP: ChocoStatServer

Host a server which saves statistics about installed chocolatey packages on your machines.

> :warning: **This project is currently just a proof-of-concept and may not work for you. It lacks most documentation right now but feel free to try it out yourself.  
> A good starting point may be [demo-api-server.ps1](demo-api-server.ps1) for the ChocoStatServer (The API-Server) or [demo-db-module.ps1](demo-db-module.ps1) for some examples on how to use the database cmdlets**

## Overview

This project aims to store information about chocolatey packages, sources and configs for computers in a central database.

The project consists of:

- a database and a powershell-module to interact directly with the database [mostly finished; needs more documentation] -> **ChocoStatDB**
- a REST-API-Server for sending/retrieving the information over HTTP(S) to/from the central server [not more than a proof-of-concept right now] -> **ChocoStatServer**
- an agent which can be installed or remotely executed over powershell remoting (or any other way) on the client. This agents gathers the information and send it over the REST-API to the server. [Simple powershell-script right now; needs more parameters/functions/documentation] -> **ChocoStatClient**
- a GUI which uses the REST-API is also planned [does not exist yet] -> **ChocoStatGUI**
