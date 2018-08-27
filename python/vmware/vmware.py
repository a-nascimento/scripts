#!/usr/bin/env python2

from requests import Request, Session

def python_version_check():
    import platform

    version = platform.python_version().split('.')[0]
    try:
        if  version == '2':
            print('version 2')
            import requests
            from requests.packages.urllib3.exceptions import InsecureRequestWarning
            requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
            request_get()
        elif version == '3':
            print('version 3')
            import urllib3
            urllib3.disable_warnings()
            request_get()
        else:
            raise ValueError        
    except ValueError:
        print('Not a valid version')
        
def request_get():
    global
    print('in request_get')
    #urllib3.disable_warnings()
    url = 'https://ctvcsa.surveysampling.com/rest/vcenter/network/'
    print(url)
    s = Session()
    #s.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
    # #s.auth = ('surveysampling\andrew_nascimento', 'pass')
    
    requests.get(url, verify=False)
    

# Maint Script
python_version_check()
