#!/bin/bash

source "./sources/shell/utils.lib"
source "./deploy.conf"

declare -r GEM_HOME="${PWD}/_vender/bundle"

declare -r siteHome="$(dirname $PWD)/${localSiteDir}"
declare -r workDir=${PWD}

function _clean_site_dir(){
    cd ${siteHome}
    keepArray=( "\.git" "\.gitignore" "README.md"  '\.'  '\..')
    allFiles=$(ls -a)
    
    msg_header "origin files ${allFiles}"
    for checkFile in ${keepArray[@]}
    do
        allFiles=$(echo ${allFiles}| 
            # sed  -e "s/[^| ]${checkFile}[ |$]/ /g"  |
            sed  -e "s/ ${checkFile} / /g"  |
            sed  -e "s/^${checkFile}[ |$]/ /g" |
            sed  -e "s/ ${checkFile}$/ /g")
        
    done

    allFileArray=($(echo ${allFiles}))
    
    msg_header "will remove "
    msg_warning "${allFileArray[@]}"
    

    for actualFile in ${allFileArray[@]}    
    do
        rm -rf ${actualFile}
    done
}
function _check_site(){    
    if [ ! -d ${siteHome} ]; then
        msg_warning "will clone ${remoteURL} to ${siteHome}"
        
        cd "$(dirname $PWD)"
        echo $PWD
        git clone -b ${branchSite} ${remoteURL} ${localSiteDir}
        
    else
        msg_warning "will clean ${siteHome}"
        cd ${siteHome}
        git clean -f
        git checkout ${branchSite}
        git pull origin ${branchSite}
    fi
}

function _deploy_site(){
  cd ${workDir}
  
  if [[ $isCompile == "yes" ]]; then
    msg_warning "will build site, wait ..."
    bundle exec jekyll b
  fi

  _check_site
  _clean_site_dir
  cd ${workDir}
  echo "current $PWD"
  mv -f "${workDir}/_site/"  "${siteHome}/"
}

echo '--'
_deploy_site

# Menu
case $1 in
    install )
        gem install bundler --pre
        bundle install 
        msg_finish "Done!"
        ;;
    install:update )
        msg_header "remove Gemfile.lock"
        rm -rf "Gemfile.lock"
        bundle update 
        msg_finish "Done!"
        ;;
    build )
        bundle exec jekyll b
        # jekyll build
        msg_finish "Done!"
        ;;
    serve )
        bundle exec jekyll s
        # jekyll serve
        msg_finish "Done!"
        ;;
    build:clean )
        msg_header "Will clean last build. Wait ..."
        rm -rf "_site"
        rm -rf ".sass-cache"
        bundle exec jekyll b
        bundle exec jekyll s
        msg_finish "Done!"
        ;;
    reset)
        msg_header "Reset all the pure settings. Wait ..."
        rm -rf "Gemfile.lock"
        rm -rf "_site"
        rm -rf ".sass-cache"
        msg_finish "Done!"
        ;;
    deploy:site)
        _deploy_site
        ;;
    *|help)
     msg_warning "Usage: $0 { install | install:update | build | build:clean | serve | reset }"
  ;;
esac