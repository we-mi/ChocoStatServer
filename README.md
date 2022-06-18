# WIP: choco-stat-server

Gather information about chocolatey packages and more installed on remote machines in your network

> :warning: **This project is currently just a proof-of-concept and may not work for you. It lacks most documentation right now but feel free to try it out yourself**

## Overview

This project aims to store information about chocolatey packages, sources and configs for computers in a central database.

The project consists of:

- a database and a powershell-module to interact directly with the database [mostly finished; needs more documentation]
- a REST-API for sending/retrieving the information over HTTP(S) to/from the central server [not more than a proof-of-concept right now]
- an agent which can be installed or remotely executed over powershell remoting (or any other way) on the client. This agents gathers the information and send it over the REST-API to the server. [Simple powershell-script right now; needs more parameters/functions/documentation]
- a GUI which uses the REST-API is also planned [does not exist yet]
