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

git_cmd = subprocess.Popen(['which', 'git'], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()[0].strip()

def _github_get(cmd):
    '''
    Do a get request against the github api, and convert the
    json result to a python dict
    '''
    url = "https://api.github.com/" + cmd
    f = urllib.urlopen(url)
    json_data = f.read()
    return json.loads(json_data)

def _get_all_orgs(user):
    '''
    Return a list with all organizations a user is involved in.
    '''
    orgs = []
    for org in _github_get("users/" + user + "/orgs"):
        orgs.append(org['login'])
    return orgs

def _get_all_repos(user):
    '''
    Return a list with all repos a user owns.

    Each list item contains a list with name and git clone_url.
    '''
    clone_urls = []
    for repo in _github_get("users/" + user + "/repos"):
        clone_urls.append([repo['name'], repo['clone_url']])
    return clone_urls

def _git_clone(clone_url, repo_path):
    '''
    Executes git shell command to clone a repo.
    '''
    cmd =  git_cmd + " clone " + clone_url
    print cmd
    subprocess.Popen(cmd, shell=True, cwd=repo_path).communicate()[0]
    print

def _git_pull(clone_url, repo_path):
    '''
    Executes git shell command to pull a repo.
    '''
    cmd =  git_cmd + " pull " + clone_url + " master"
    print cmd
    print
    subprocess.Popen(cmd, shell=True, cwd=repo_path).communicate()[0]
    print

def _download_github_repos(user, repos_path):
    '''
    git clone/pull all repos from a user or organizatin.
    '''
    for name, clone_url in  _get_all_repos(user):
        repo_path = os.path.abspath(repos_path + "/" + name)
        print "---------------------"
        print "Download/Update " + repo_path
        if (os.path.exists(repo_path)):
            _git_pull(clone_url, repo_path)
        else:
            _git_clone(clone_url, repos_path)

def download_my_github_repos(user):
    '''
    git clone/pull all repos from a user and his organizatins.
    '''
    repos_path = os.path.dirname(__file__) + '/../github/'
    repos_path = os.path.realpath(repos_path)
    subprocess.Popen("mkdir " + repos_path, shell=True).communicate()[0]
    _download_github_repos(user, repos_path)
    for org in _get_all_orgs(user):
        print "Download from organization: " + org
        _download_github_repos(org, repos_path)

if (__name__ == '__main__'):
    download_my_github_repos("arlukin")
