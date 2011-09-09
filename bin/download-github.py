#!/usr/bin/env python
'''
Downloading all github repos or a user and all his organizations.

'''

__author__ = "daniel.lindh@cybercow.se"
__copyright__ = "Copyright 2011, Amivono AB"
__maintainer__ = "daniel.lindh@cybercow.se"
__license__ = "We pwn it all."
__version__ = "0.1"
__status__ = "Production"

import urllib
import json
import subprocess
import os

git_cmd = "/usr/local/git/bin/git"

def github_get(cmd):
    '''
    Do a get request against the github api, and convert the 
    json result to a python dict
    '''    
    url = "https://api.github.com/" + cmd
    f = urllib.urlopen(url)
    json_data = f.read()
    return json.loads(json_data)    
    
def get_all_orgs(user):
    '''
    Return a list with all organizations a user is involved in.
    '''    
    orgs = []
    for org in github_get("users/" + user + "/orgs"):        
        orgs.append(org['login'])    
    return orgs

def get_all_repos(user):   
    clone_urls = []
    for repo in github_get("users/" + user + "/repos"):
        clone_urls.append([repo['name'], repo['clone_url']])    
    return clone_urls

def git_clone(clone_url, repo_path):
    cmd =  git_cmd + " clone " + clone_url
    print cmd
    subprocess.Popen(cmd, shell=True, cwd=repo_path).communicate()[0]
    print   

def git_pull(clone_url, repo_path):
    cmd =  git_cmd + " pull " + clone_url
    print cmd
    print
    subprocess.Popen(cmd, shell=True, cwd=repo_path).communicate()[0]
    print
                     
def download_github_repos(user):
    for name, clone_url in  get_all_repos(user):
        repos_path = os.path.abspath('../github/')
        repo_path = os.path.abspath(repos_path + "/" + name)
        print "---------------------"
        print "Download/Update " + repo_path
        if (os.path.exists(repo_path)):
            git_pull(clone_url, repo_path)
        else:
            git_clone(clone_url, repos_path)

def download_my_github_repos(user):
    download_github_repos("arlukin")
    for org in get_all_orgs("arlukin"):
        print "Download from organization: " + org
        download_github_repos(org)
        
if (__name__ == '__main__'):
    download_my_github_repos("arlukin")      