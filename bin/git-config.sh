#!/bin/sh
git config --global user.name "Arlukin"
git config --global user.email daniel@cybercow.se
git config --global github.user "Arlukin"
echo -n "May I know your github.token? "
read githubtoken
git config --global github.token "$githubtoken"

echo "export PATH=$PATH:$HOME/cchome/bin:$HOME/cchome/bin/araxis" >> $HOME/.bash_profile

#[difftool "araxis"]
#    path = "/Users/dali/cchome/bin/araxis/compare"
#    renames = true
#    trustExitCode = true
#
#[diff]
#    tool = araxis
#    stat = true
#
#[mergetool "araxismergetool"]
#    cmd = '/Users/dali/cchome/bin/araxis/araxisgitmerge' "$REMOTE" "$BASE" "$PWD/$LOCAL" "$PWD/$MERGED"
#    trustExitCode = false
#
#[mergetool]
#    keepBackup = false
#
#[merge]
#    tool = araxismergetool
#    stat = true
#[branch "master"]
    # This is the list of cmdline options that should be added to git-merge                                     
    # when I merge commits into the master branch.                                                              
    #                                                                                                           
    # First off, the option --no-commit instructs git not to commit the merge                                   
    # by default. This allows me to do some final adjustment to the commit log                                  
    # message before it gets commited. I often use this to add extra info to                                    
    # the merge message or rewrite my local branch names in the commit message                                  
    # to branch names sensible to the casual reader of the git log.                                             
    #                                                                                                           
    # Option --no-ff instructs git to always record a merge commit, even if                                     
    # the branch being merged into can be fast-forwarded. This is often the                                     
    # case when you create a short-lived topic branch which tracks master, do                                   
    # some changes on the topic branch and then merge the changes into the                                      
    # master which remained unchanged while you were doing your work on the                                     
    # topic branch. In this case the master branch can be fast-forwarded (that                                  
    # is the tip of the master branch can be updated to point to the tip of                                     
    # the topic branch) and this is what git does by default. With --no-ff                                      
    # option set git creates a real merge commit which records the fact that                                    
    # another branch was merged. I find this easier to understand and read in                                   
    # the log.                                                                                                  
    #mergeoptions = --no-commit --no-ff



