#!/usr/bin/python

""" DevOps_Orion.py

    This file will be used by the Dev Ops team to automate monitoring in Solarwinds
 
    Functions:
        connect_to_solarwinds       Opens the connection to Solarwinds to interact with the API
        add_node                    Adds a node to Solarwinds
        delete_node                 Removes a node from Solarwinds. All data is deleted
        unmanage_node               Supresses alerts on a particular node for a given amount of time
        manage_node                 Enables alerting on a particular node (only used if unmanaged)
        add_application_template    Adds a specified application template to a specified node
        query_node                  Queries for a node with given parameters 
        add_custom_properties       Adds custom properties to a node
"""

import requests
import sys
import re
from orionsdk import SwisClient
from datetime import datetime, timedelta

""" Commands:
        python DevOps_Orion.py add_node ip snmp_community_string
        python DevOps_Orion.py delete_node ip
        python DevOps_Orion.py unmanage_node ip start_time end_time
        python DevOps_Orion.py manage_node ip
        python DevOps_Orion.py add_app_template ip template_name credential_name
        python DevOps_Orion.py add_custom_properties ip property_name property_value
"""


def connect_to_solarwinds(host_ip, user_name, pass_word):
    """ Connects to the Solarwinds API to allow us to modify the Solarwinds database

        Args:
            host_ip:    String - Orion server's IP or hostname
            user_name:  String - Username of account with access to connect to the Orion host
            pass_word:  String - Password of account with access to connect to the Orion host
            
        Returns:
            connection: SwisClient Connection - Allows access to the Orion API
    """
    return SwisClient(host_ip, user_name, pass_word)


def add_node(connection, ip_address, snmp_community_string):
    """	Adds a node to Solarwinds for monitoring

        Args:
            connection: 			SwisClient Connection - Allows access to the Orion API
            ip_address: 			String - IP Adress of host to be added to monitoring
            snmp_community_string:	String - SNMP community string for Solarwinds to connect over SNMP (Typical string: ss1snmpl1nux)
            
        Returns:
            No return
    """
    props = {
       'IPAddress': ip_address,
       'EngineID': 1,
       'ObjectSubType': 'SNMP',
       'SNMPVersion': 2,
       'Community': snmp_community_string,
    }


    results = connection.create('Orion.Nodes', **props)


    # extract the nodeID from the result
    nodeid = re.search('(\d+)$', results).group(0)

    pollers_enabled = {
        'N.Status.ICMP.Native': True,
        'N.Status.SNMP.Native': False,
        'N.ResponseTime.ICMP.Native': True,
        'N.ResponseTime.SNMP.Native': False,
        'N.Details.SNMP.Generic': True,
        'N.Uptime.SNMP.Generic': True,
        'N.Cpu.SNMP.HrProcessorLoad': True,
        'N.Memory.SNMP.NetSnmpReal': True,
        'N.AssetInventory.Snmp.Generic': True,
        'N.Topology_Layer3.SNMP.ipNetToMedia': False,
        'N.Routing.SNMP.Ipv4CidrRoutingTable': False
    }

    pollers = []
    for k in pollers_enabled:
        pollers.append(
            {
                'PollerType': k,
                'NetObject': 'N:' + nodeid,
                'NetObjectType': 'N',
                'NetObjectID': nodeid,
                'Enabled': pollers_enabled[k]
            }
        )

    pollers = []
    for k in pollers_enabled:
        pollers.append(
            {
                'PollerType': k,
                'NetObject': 'N:' + nodeid,
                'NetObjectType': 'N',
                'NetObjectID': nodeid,
                'Enabled': pollers_enabled[k]
            }
        )

    for poller in pollers:
        response = connection.create('Orion.Pollers', **poller)

def delete_node(connection, ip_address):
    """	Remove a node from Solarwinds
        
        Removes a node from Solarwinds monitoring. This will cause all data to be deleted and no more alerts to trigger.

        Args:
            connection: SwisClient Connection - Allows access to the Orion API
            ip_address: String - IP Adress of host to be removed from monitoring
            
        Returns:
            No return
    """
    results = connection.query("SELECT TOP 1 Uri FROM Orion.Nodes WHERE IP_Address=@ip", ip=ip_address)
    uri = results['results'][0]['Uri']
    
    connection.delete(uri)

def unmanage_node(connection, ip_address, start_time, end_time):
    """	Unmanages a node in Solarwinds
        
        Unamanges a node in Solarwinds. Alerts will be suppressed for a certain period of time or until the node is managed again
        
        Note: Use Greenwich Mean Time zone

        Args:
            connection:	SwisClient Connection - Allows access to the Orion API
            ip_address:	String - IP Adress of host to be temporarily removed from alerting
            start_time:	datetime - Time of when maintenance will begin (GMT)
            end_time: 	datetime - Time of when maintenance will end (GMT)
        
        Returns:
            No return
    """
    node_id = 'N:' + str(query_node(connection, ip_address))
    connection.invoke('Orion.Nodes', 'Unmanage', node_id, start_time, end_time, False)


def manage_node(connection, ip_address):
    """	Manages a node in Solarwinds
        
        Re-enables monitoring of a node in Solarwinds. This is only used if a node is unmanaged.

        Args:
            connection: 			SwisClient Connection - Allows access to the Orion API
            ip_address: 			String - IP Adress of host to be added to be alerted on again
            
        Returns:
            No return
    """
    node_id = 'N:' + str(query_node(connection, ip_address))
    connection.invoke('Orion.Nodes', 'Remanage', node_id)

def add_application_template(connection, ip_address, template_name, credential_name):
    """	Adds an application template to a node
        
        Adds an application template to a node in Solarwinds. This will be useful to apply pre-defined monitoring to nodes

        Args:
            connection: 		SwisClient Connection - Allows access to the Orion API
            ip_address: 		String - IP Adress of host that the application template will be added to
            template_name:		String - Name of the application template that will be applied to the node	
            credential_name:	String - Name of the credentials saved in the Orion DB
            
        Returns:
            No return
    """

   
    node_id = query_node(connection, ip_address)


    # Query for application ID and print it
    application = connection.query("SELECT ApplicationTemplateID FROM Orion.APM.ApplicationTemplate WHERE Name=@temp_name", temp_name = template_name)
    application_id = application['results'][0]['ApplicationTemplateID']

    # Query for the Credential's ID and prints it. (SAM Credential)
    credential = connection.query("SELECT ID FROM Orion.Credential WHERE CredentialOwner='APM' AND NAME=@cred", cred = credential_name)
    credential_id = credential['results'][0]['ID']

    # Adds application to specific node.
    # Parameters: Orion Object Type, Function on Object, Nodes ID, Applications ID, Credentials ID, Skip if already exists
    appid = connection.invoke("Orion.APM.Application", "CreateApplication", node_id, application_id, credential_id, "true")

def query_node(connection, ip_address):
    """	Queries for a node
        
        Queries for a specific node from the Orion DB

        Args:
            connection: SwisClient Connection - Allows access to the Orion API
            ip_address: String - IP Address of node that will be queried for
        
        
        Returns:
            node_id: String - Returns the ID of the queried node
    """
    node = connection.query("SELECT NodeID FROM Orion.Nodes WHERE IP_Address=@ip", ip=ip_address)
    node_id = node['results'][0]['NodeID']
    return node_id

def add_custom_properties(connection, ip_address, property_name, property_value):
    """	Adds custom properties to a node
        
        Adds or changes the custom properties of a node in Solarwinds

        Args:
            connection: 		SwisClient Connection - Allows access to the Orion API
            ip_address: 		String - IP Adress of host that will have its' custom properties modified
            property_name:		String - Name of the property that will be modified
            property_value:		String - Value of the property to be set
            
        Returns:
            No return
    """
    node_id = query_node(connection, ip_address)
    results = connection.query("SELECT Uri FROM Orion.Nodes WHERE NodeID=@id", id=node_id)
    uri = results['results'][0]['Uri']

    props = { property_name : property_value }
    connection.update(uri + '/CustomProperties', **props)

def main():
    host_ip = 	'10.1.21.172'
    user_name = 'Orion_SDK'
    pass_word = '37u5K2vTVYe'
    
    swis_connection = connect_to_solarwinds(host_ip, user_name, pass_word)
    
    if sys.argv[1].lower() == 'add_node':
        add_node(swis_connection, sys.argv[2], sys.argv[3])
    elif sys.argv[1].lower() == 'delete_node':
        delete_node(swis_connection, sys.argv[2])
    elif sys.argv[1].lower() == 'unmanage_node':
        unmanage_node(swis_connection, sys.argv[2], sys.argv[3], sys.argv[4])
    elif sys.argv[1].lower() == 'manage_node':
        manage_node(swis_connection, sys.argv[2])
    elif sys.argv[1].lower() == 'add_application_template':
        add_application_template(swis_connection, sys.argv[2], sys.argv[3], sys.argv[4])
    elif sys.argv[1].lower() == 'add_custom_properties':
        add_custom_properties(swis_connection, sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        print("invalid command")
    
requests.packages.urllib3.disable_warnings()


if __name__ == '__main__':
    main()
