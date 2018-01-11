#!/bin/bash

source "./sources/shell/utils.lib"
source "./deploy.conf"

declare -r GEM_HOME="${PWD}/_vender/bundle"

declare -r workDir=${PWD}
declare -r siteDir="${workDir}/_site"

function _rm_site_dir(){
    cd ${workDir}

    if [ -d ${siteDir} ]; then
        rm -rf '${siteDir}'
    fi
    git worktree prune
}

function __add_site_dir(){
    cd ${workDir}

    if [ -d ${siteDir} ]; then
        msg_error "${siteDir} exist, should not add again"
        return
    fi

    git worktree add  ${siteDir} ${branchSite}

    cd ${siteDir}
    git pull origin ${branchSite}
}

function __clean_site_dir(){
    cd ${siteDir}
    keepArray=( "\.git" "\.gitignore" "README.md"  '\.'  '\..')
    allFiles=$(ls -a)
    
    msg_info "will remove file under ${siteDir}"
    msg_info "origin files ${allFiles}"
    for checkFile in ${keepArray[@]}
    do
        allFiles=$(echo ${allFiles}| 
            # sed  -e "s/[^ ]${checkFile}[ $]/ /g"  |
            sed  -e "s/ ${checkFile} / /g"  |
            sed  -e "s/^${checkFile}[ |$]/ /g" |
            sed  -e "s/ ${checkFile}$/ /g")
        
    done

    allFileArray=($(echo ${allFiles}))
    
    msg_info "will remove "
    msg_warning "${allFileArray[@]}"
    

    for actualFile in ${allFileArray[@]}    
    do
        rm -rf ${actualFile}
    done
    msg_info "after remove, path ${PWD}"

    msg_info "$(ls -a)"
}

function _refresh_site_dir(){
    _rm_site_dir
    __add_site_dir
    __clean_site_dir
}

function _deploy_site(){
  
  if [[ $isCompile=="yes" ]]; then
    cd ${workDir}
    _refresh_site_dir

    msg_warning "will build site, wait ..."

    cd ${workDir}
    bundle exec jekyll b
  fi

  cd ${siteDir}
  git add -A .
  
  if [[ ${siteSave}=='no' ]]; then
      git commit --amend -m "$commit - $(date)"
      git push -f -u origin ${branchSite}
  else
      git commit -m "$commit - $(date)"
      git push origin -u ${branchSite}
  fi

  msg_finish "Done!"
}



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
        _rm_site_dir
        rm -rf ".sass-cache"
        bundle exec jekyll b
        bundle exec jekyll s
        msg_finish "Done!"
        ;;
    build:trace )
        msg_header "Will clean last build. Wait ..."
        _rm_site_dir
        rm -rf ".sass-cache"
        bundle exec jekyll b --trace        
        msg_finish "Done!"
        ;;
    build:watch )
        msg_header "Will clean last build. Wait ..."
        _rm_site_dir
        rm -rf ".sass-cache"
        bundle exec jekyll b --watch
        bundle exec jekyll s 
        msg_finish "Done!"
        ;;
    reset)
        msg_header "Reset all the pure settings. Wait ..."
        rm -rf "Gemfile.lock"
        _refresh_site_dir
        rm -rf ".sass-cache"
        msg_finish "Done!"
        ;;
    deploy:site)
        _deploy_site
        ;;
    *|help)
     msg_warning "Usage: $0 { install | install:update | build | build:clean | deploy:site| serve | reset }"
  ;;
esac