#!/usr/bin/env python

from requests import Request, Session
import urllib3

def python_version_check():
    #python3 import urllib3
    #python2 import ssl 
    print('hello')

def request_get():
    urllib3.disable_warnings()
    url = 'https://ctvcsa.surveysampling.com/rest/vcenter/network/'
    s = Session()
    #s.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
    # #s.auth = ('surveysampling\andrew_nascimento', 'pass')
    response = s.get(url, verify=False, auth=('surveysampling\andrew_nascimento','pass'))
    response

