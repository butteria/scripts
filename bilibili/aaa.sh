# bilibili api details on https://github.com/SocialSisterYi/bilibili-API-collect.
CACHE_DIR=$HOME/.cache/bilibili
[ ! -d $CACHE_DIR ] && { mkdir $CACHE_DIR; }

# load module.
source ./fanju.sh
source ./danmu.sh
source ./live.sh
source ./video.sh


case $1 in
    "--live") watch_live $2 ;;
    "--video")   watch_video   $2 ;;
    "--cv")   watch_fanju   $2 ;;
    "--cvsearch")   search_fanju $2;;
esac
