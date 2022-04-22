# this is the location of the main server from a docker image
export cache_server=${cache_server:-172.17.0.1}
echo "cache server: ${cache_server}"
export timeout_exit=0
timeout 1 bash -c 'cat < /dev/null > /dev/tcp/'$cache_server'/3128' || export timeout_exit=1

pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1${PATH:+":$PATH"}"
    fi
}

if [ $timeout_exit == 0 ] ; then
    echo "running proxy"
export http_proxy=http://$cache_server:3128/
export https_proxy=http://$cache_server:3128/
export ftp_proxy=http://$cache_server:3128/
export HTTP_PROXY=http://$cache_server:3128/
#cache with devpi-server
export PIP_INDEX_URL=http://127.0.0.1:3141/root/pypi/+simple/
#cache with git-cache-http-server
export GIT_PROXY=http://127.0.0.1:8080/
#cache with verdacchio
export NPM_CONFIG_REGISTRY=http://127.0.0.1:4873/
export YARN_REGISTRY=http://127.0.0.1:4873/
#'
fi

export timeout_exit=0
timeout 1 bash -c 'cat < /dev/null > /dev/tcp/$cache_server/3632' || export timeout_exit=1
: '
if [ $timeout_exit == 0 ] ; then
    echo "running distcc"
    pathadd "/usr/lib64/distcc"
    export DISTCC_HOSTS="$cache_server"
fi
'
if [ $timeout_exit == 0 ] ; then
    echo "running distcc (pump mode)"
    pathadd "/usr/lib64/distcc"
    export DISTCC_HOSTS='$cache_server,cpp,lzo'
    eval `pump --startup`
fi
