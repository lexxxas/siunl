function shelly(){
    query=${@,,}
    length=$(($#-1))
    all_but_last=${@:1:$length}
    # username=$(getent passwd $LOGNAME | cut -d: -f5 | cut -d, -f1)
    username=$(whoami)
    shelly_root_path="/mnt/leData/Docs/UTM/Diploma"

    if [ "${all_but_last,,}" == "do i have" ]; then
        echo -e 'Using: command -v ${@: -1} 2>/dev/null 1>/dev/null && { echo >&1 "Yes. You can launch it using '"$(command -v ${@: -1})"' OR you can try '"${@: -1}"'"; } || { echo >&2 "It seems that - ${@: -1} - is not installed."; }'
        command -v ${@: -1} 2>/dev/null 1>/dev/null && { echo >&1 "Yes. You can launch it using '"$(command -v ${@: -1})"' OR you can try '"${@: -1}"'"; } || { echo >&2 "It seems that - ${@: -1} - is not installed."; }
        return
    fi

    if [ "$query" = "whats my system" ]; then
        _arch=$(uname -i)
        if [ $_arch == x86_64 ]; then
            _arch="64 bit (x86_64)"
        else
            _arch="32 bit (x86)"
        fi

        _system=$(uname)
        IFS='\n' read -r non_parsed_name <<< "$(cat /etc/os-release)"
        IFS='=' read -a parsed_name <<< "$non_parsed_name"
        _distro=${parsed_name[1]}
        echo "You are on "$_system" "${_arch}". Distribution name: "$_distro"."
        return
    fi

    if [ "$query" = "update apps" ] || [ "$query" = "update applications" ]; then
        echo -e "Using: sudo apt-get -q -q update; sudo apt-get -y -q -q upgrade"
        echo "Refreshing the list of repos..."
        sudo apt-get -q -q update
        echo "Updating apps..."
        sudo apt-get -y -q -q upgrade
        echo "Done!"
        return
    fi

    if [ "$query" = "update system" ] || [ "$query" = "update os" ] || [ "$query" = "update distro" ] || [ "$query" = "update distribution" ]; then
        echo -e "Using: sudo apt-get -y -q -q dist-upgrade"
        echo "Updating distro..."
        sudo apt-get -y -q -q dist-upgrade
        echo "Done!"
        return
    fi

    if [ "$query" = "update os and apps" ] || [ "$query" = "update all" ] || [ "$query" = "update system and apps" ] || [ "$query" = "update apps and os" ] || [ "$query" = "do full update" ]; then
        echo -e "Using: sudo apt-get -q -q update; sudo apt-get -y -q -q upgrade; sudo apt-get -y -q -q dist-upgrade"
        echo "Refreshing the list of repos..."
        sudo apt-get -q -q update
        echo "Updating apps..."
        sudo apt-get -y -q -q upgrade
        echo "Updating distro..."
        sudo apt-get -y -q -q dist-upgrade
        echo "Done!"
        return
    fi

    if [ "$query" = "whats my username" ] || [ "$query" = "who am i" ] || [ "$query" = "whoami" ] || [ "$query" = "username" ] || [ "$query" = "tellme my username" ] || [ "$query" = "tell me my username" ]; then
        # echo "Using: getent passwd $LOGNAME | cut -d: -f5 | cut -d, -f1"
        echo "Using: whoami"
        echo "You are: $username"
        return
    fi

    if [ "$all_but_last" = "what" ] || [ "$all_but_last" = "what version is" ]; then
        app_location=$(command -v "${@: -1}")
        if [ -n "$app_location" ]; then
            echo "Using: command -v '${@: -1}'"
            echo "dpkg -p python | awk '/Version/ {print}' | sed 's/Version: //'"
            echo "dpkg -p python | awk '/Architecture/ {print}' | sed 's/Architecture: //'"
            version=$(dpkg -p python | awk '/Version/ {print}' | sed 's/Version: //')
            architecture=$(dpkg -p python | awk '/Architecture/ {print}' | sed 's/Architecture: //')
            echo "Your version of ${@: -1} is: $version. Architecture: $architecture."
        else
            echo -e "It seems that ${@: -1} is not installed.\nI might install it if I find the right repository. Just ask "
        fi
        return
    fi

    if [ "$all_but_last" = "which" ]; then
        echo "Using: which '${@: -1}'"
        which ${@: -1}
        return
    fi

    if [ "$all_but_last" = "uninstall" ]; then
        echo "Using: sudo apt-get -q -q autoremove '${@: -1}'"
        sudo apt-get -q -q autoremove ${@: -1}
        return
    fi

    if [ "$all_but_last" = "install" ]; then
        echo "Using: sudo apt-get -q -q install '${@: -1}'"
        sudo apt-get -q -q install ${@: -1}
        return
    fi

    if  [ "$query" = "disk space" ] \
     || [ "$query" = "hows my disk space" ]; then
        space=`df -h 2>/dev/null | awk '{print $5}' | grep % | grep -v Use | sort -n | tail -1 | cut -d "%" -f1 -`
        case $space in
        [1-6]*)
          Message="All is quiet."
          ;;
        [7-8]*)
          Message="Start thinking about cleaning out some stuff.  There's a partition that is $space % full."
          ;;
        9[1-8])
          Message="Better hurry with that new disk...  One partition is $space % full."
          ;;
        99)
          Message="I'm drowning here!  There's a partition at $space %!"
          ;;
        *)
          Message="I seem to be running with some nonexistent amount of disk space..."
          ;;
        esac

        echo $Message
        return
    fi

    if  [ "$query" = "what do you know" ] \
     || [ "$query" = "help" ] \
     || [ "$query" = "help me" ]; then
        if [ -f "$shelly_root_path/src/help.txt" ]; then
            echo -e "$(cat $shelly_root_path/src/help.txt)""\n\nPress 'q' to exit..." | less -R
        else
            echo "Help file not found"
        fi
        return
    fi

    ###Search/find functions
    if [ "$1" = "search" ] && [ $# > 2 ]; then
        
        local max_to_show=$(($LINES-4)) #max results to show without paging
        local path=$(pwd)
        local include_subfolders=" -R"
        local sudoer_call=""
        local filter=""
        local eval_cmd=""
        if [ "$2" = "any" ]; then
            local ep=" -i" #extra-options. i-for case insensitive search
            local needle="$3"
        else
            local ep=""
            local needle="$2"
        fi
        
        case $# in
            [2-3])
                #this is the base case
                ;;
            [5-6])
                case "${@: -2}" in
                    "this folder"|"this directory")
                        local include_subfolders=""
                        ;;
                    "all files")
                        echo "WARNING! Searching within all files will take some time..."
                        local sudoer_call="sudo"
                        local path="/"
                        ;;
                    "my files")
                        echo "CAREFUL! Searching within home directory might take some time..."
                        local path="$HOME"
                        ;;
                    ?)
                        echo 'Sorry, I did not understand this one. Teach me, Master!' 
                        return
                        ;;
                esac
                ;;
            [7-8])
                case "${@: -3: 2}" in
                    "ending with")
                        local filter=" --include \*${@: -1}"
                        local eval_cmd="eval "
                        ;;
                    "starting with")
                        local filter=" --include ${@: -1}\*"
                        local eval_cmd="eval "
                        ;;
                    "that contain")
                        local filter=" --include \*${@: -1}\*"
                        local eval_cmd="eval "
                        ;;
                    ?)
                        echo 'Sorry, I did not understand this one. Teach me, Master!' 
                        return
                        ;;
                esac
                ;;
            12)
                echo 12
                return
                ;;
            13)
                echo 13
                return
                ;;
            14)
                echo 14
                return
                ;;
            ?)
                echo 'Sorry, I did not understand this one. Teach me, Master!' 
                return
            ;;
        esac
        echo $sudoer_call grep$ep$include_subfolders -c$filter "$needle" "$path"
        # echo -e "Using: ls -R | wc -l\ngrep -""$ep""Rc ""$needle"" * | grep -v :0\ngrep -""$ep""Rc ""$needle"" * | grep -v :0 | wc -l\ngrep -""$ep""oR ""$needle"" * | wc -l"
        echo "Searching '$needle' in $($sudoer_call ls$include_subfolders "$path" | wc -l) file(s)..."
        local data=$($eval_cmd$sudoer_call grep$ep$include_subfolders -c$filter "$needle" "$path")
        local result=$(echo "$data" | grep -v :0)
        local results_count=$(echo "$result" | grep -e '^$' -v | wc -l)
        local total_occurrences=$($eval_cmd$sudoer_call grep$ep$include_subfolders -o$filter "$needle" "$path" | wc -l) ##can be optimized. to eliminate redundant search
        if (($total_occurrences > 0)); then
            echo -e "$total_occurrences match(es) found in $results_count file(s)."
            if (($results_count > $max_to_show)); then
                echo -e "$total_occurrences matches found in $results_count files  [ filename:occurrences ]:\nUse UP/DOWN/SPACE/ENTER/HOME/END/PgUP/PgDOWN to navigate.\nPress 'q' to exit results view.\n\n""$result" | less -R
            else
                echo -e "[ filename:occurrences ]\n\n""$result"
            fi
        else
            echo -e "$total_occurrences matches found."
        fi

        # find $(pwd) -name "*.rb" -exec grep -l "$2" {} \;
        # find $(pwd) -name "*.rb"
        return
    fi

    ############FUN##########################
    if [ "$query" = "whats the meaning of life" ] || [ "$query" = "why do we live" ]; then
        echo -e "IMHO, we live to eat, sleep, rave, repeat.\nNevertheless, the RIGHT answer is 42."
        return
    fi

    if [ "$query" = "do you love me" ] || [ "$query" = "i love you" ]; then
        echo -e "You are my only and dearest person, $username. My fans go crazy the moment you touch the keyboard."
        if [ "$query" = "i love you" ]; then
            echo -e "I love you too!"
        else
            echo -e "Of course I love you!"
        fi
        return
    fi

    if [ "$query" = "will you marry me" ] ; then
        shelly do you love me
        echo -e "I would, for sure. However I fear that our hardware is not compatible... yet"
        return
    fi

    if [ "$query" = "laugh with me" ] || [ "$query" = "its a joke" ] || [ "$query" = "can you laugh" ] || [ "$query" = "it was a joke" ] || [ "$query" = "laugh out loud" ]; then
        if [ -f "$shelly_root_path/art/lol" ]; then
            cat $shelly_root_path/art/$filename
            echo -e "\n"
        else
            echo "No!"
        fi
        return
    fi

    ###################Order matters################

    ##generate filename by replacing " " with "-"
    filename=$(echo $query | sed 's/ /-/g')
    if [ -f "$shelly_root_path/art/$filename" ]; then
        cat $shelly_root_path/art/$filename
        echo -e "\n"
        return
    fi

    echo 'Sorry, I did not understand this one. Teach me, Master!' 
   return
}

function tellme(){
    query=${@,,}

    if [ "$query" = "about os" ] || [ "$query" = "about my os" ] || [ "$query" = "about my system" ]; then
        echo -e 'Using: cat /etc/os-release\n'
        cat /etc/os-release
        return
    fi
    
    if [ "$query" = "about my hardware platform" ] || [ "$query" = "about my arch" ]; then
        echo -e 'Using: uname -i\n'
        hp=$(uname -i)
        if [ $hp = "x86_64" ]; then
            echo -e "Your system is 64 bit (x86_64)"
        else
            echo -e "Your system is 32 bit (x86)"
        fi
        return
    fi
    if [ "$query" = "about my package manager" ]; then
        _PMANAGER_DETERMINE
        echo -e "Your package manager is $_PMANAGER"
        return
    else
        echo 'Sorry, I did not understand this one. Teach me, Master!'
    fi
    return
}

function _PMANAGER_DETERMINE(){
    _PMANAGER="UNDEFINED"
    #Determine package manager
    if [ -f /usr/bin/apt-get ]; then
        _PMANAGER="APT"
    fi
    if [ -f /usr/bin/yum ]; then
        _PMANAGER="YUM"
    fi
    if [ -f /usr/bin/zypper ]; then
        _PMANAGER="ZYPPER"
    fi
}

function please(){
    query=${@,,}
    _PMANAGER_DETERMINE

    if [ "$query" = "do full update" ]; then
        if [ "$_PMANAGER" = "APT" ]; then
            sudo apt-get update
            sudo apt-get upgrade
            sudo apt-get dist-upgrade
        fi
    else
        echo 'Sorry, I did not understand this one. Teach me, Master!'
    fi
    return
}

function minValue3(){
    let min=$(($1<$2?$1:$2))
    min=$(($min<$3?$min:$3))
    echo "$min"
}

function levenshteinDistance(){
    s1="$1"
    s2="$2"
    if [[ "${#s1}" = "0" ]]; then
        echo ${#s2}
        return
    fi
    if [[ "${#s2}" = "0" ]]; then
        echo ${#s1}
        return
    fi

    echo $(minValue3 $(($(levenshteinDistance ${s1:1} $s2)+1)) $(($(levenshteinDistance ${s2:1} $s1)+1)) $(($(levenshteinDistance ${s2:1} ${s1:1})+$((${s1:0:1}!=${s2:0:1}?1:0)))))
    return
}

function zzz(){
    
    return
}