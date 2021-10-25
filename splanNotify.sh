#!/bin/sh
shopt -s extglob

# handle parameters and flags
read -d '' usage << EOF
Usage: $0 [OPTION]... <URL>
Notify at change of timetable(from StarPlan)

with no URL, or when URL is -, read standard input.

  -h            shows this help page
  -q            no notifications even on change
  -v            notifications for all lectures
  -n            notifications for next lecture
  -c            notifications for changes since last run
  -o            prints notifications to stdout

NOTE: when used first, there is no output for -c
EOF

while getopts "hvqnoc" opt; do
  case "$opt" in
    h)
      echo "${usage}"
      exit 0
      ;;
    v)  verbose="y"
      ;;
    q)  quiet="y"
      ;;
    n)  nextLecture="y"
      ;;
    o)  outStd="y"
      ;;
    c)  showDiff="y"
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      echo ${usage} >&2
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      echo ${usage} >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift


if [ -z "$1" ] || [ "$1" = "-" ]; then
    if [ -p /dev/stdin ]; then
        read -r url
    else
        echo "No stdin given" >&2
        exit 1
    fi
elif [ ! -z "$1" ]; then
    url="$1"
else
    echo "No url given" >&2
    echo ${usage} >&2
    exit 1
fi




storedTime="timeTable"
storedLecture="lectureTable"
imageFile="$(pwd)/th-rosenheim-logo-klein.png"
notCompare=""
url="${url}&m=getTT"
curlData=$(curl -s "${url}" | sed "s/></>\n</g")


# check directories and files
if [ -z "${XDG_CACHE_HOME}" ]; then
  dataDir="~/.splan"
else
  dataDir="${XDG_CACHE_HOME}/splan"
fi

if [ ! -d "${dataDir}" ]; then
    mkdir -p "${dataDir}"
fi

if [ ! -f "${dataDir}/${storedLecture}" ]; then
    LectureTT=$(echo "${curlData}" | ./ttParser )
    echo "${LectureTT}" > "${dataDir}/${storedLecture}"
fi

if [ ! -f "${dataDir}/${storedTime}" ]; then
    timeTable=$(echo "${curlData}" | ./ttParser -d )
    echo "${timeTable}" > "${dataDir}/${storedTime}"
fi

if [ ! -z "${showDiff}" ]; then
    diffParse=$(echo "${curlData}" | ./ttParser -d)
    diffRes=$(diff  <(echo "${diffParse}") <(cat "${dataDir}/${storedTime}"))

#    echo "${diffRes}"
    while read line; do

        case "$line" in
            +([0-9])[acd]+([0-9])   ) diffType="${line}";;    # matches "met" or "meet"

            "<"*) #TODO: send Notify
                lineNr=$(echo "${diffType}" | grep -oE ^[0-9]+)
                line=$(echo "${diffParse}" | awk -v ind="${lineNr}" '(NR == ind) {print $0}')
                if [ -z ${outStd} ]; then
                    notify-send -i "${imageFile}" "$(echo ${line} | awk -F\; '{print "New:" $2}' | cut -d, -f1)" "$(echo ${line} | awk -F\; '{printf $1 " " $6 "\072 " $3 " @ " $5}')"
                else
                    echo "NEW;${line}"
                fi
                ;;
            ">"*) #TODO: send Notify
                lineNr=$(echo "${diffType}" | grep -oE ^[0-9]+)
                line=$(cat "${dataDir}/${storedTime}" | awk -v ind="${lineNr}" '(NR == ind) {print $0}')
                if [ -z ${outStd} ]; then
                    notify-send -i "${imageFile}" "$(echo ${line} | awk -F\; '{print "Canceled": $2}' | cut -d, -f1)" "$(echo ${line} | awk -F\; '{printf $1 " " $6 "\072 " $3 " @ " $5}')"
                else
                    echo "CANCELED:${line}"
                fi
                ;;
        esac

    done < <(echo "${diffRes}")
    
    LectureTT=$(echo "${curlData}" | ./ttParser )
    echo "${LectureTT}" > "${dataDir}/${storedLecture}"
    timeTable=$(echo "${curlData}" | ./ttParser -d )
    echo "${timeTable}" > "${dataDir}/${storedTime}"
    exit
fi

if [ ! -z "${nextLecture}" ]; then
    while read line; do 
        dt1="$(echo "${line}" | awk -F\; 'match($0, /([0-1]?[0-9]|2[0-3]):[0-5][0-9]/, a) {print $1 " " a[0]}'):00"
        t1=$(date --date="${dt1}" +%s)

        dt2=$(date +%Y-%m-%d\ %H:%M:%S)
        t2=$(date --date="$dt2" +%s)

        let "tDiff=$t1-$t2"
        
        if [ ${tDiff} -gt 0 ] && ([ -z ${nextTime} ] || [ ${tDiff} -eq ${nextTime} ]); then 
            if [ -z "${Notifications}" ]; then
                Notifications="${line}" 
            else
                Notifications="${Notifications}"$'\n'"${line}" 
            fi
            nextTime=${tDiff}
        fi
        # echo $(echo "${line}" | awk -F\; '{print "$2" "$3"}') 
    done < <(echo "${curlData}" | ./ttParser -d )

fi
if [ ! -z "${verbose}" ]; then
    Notifications=$(echo "${curlData}" | ./ttParser -d )
fi


# print stuff:

if [ -z "${quiet}" ]; then
    while read line; do 
        if [ -z "${outStd}" ]; then
            notify-send -i "${imageFile}" "$(echo ${line} | awk -F\; '{print $2}' | cut -d, -f1)" "$(echo ${line} | awk -F\; '{printf $1 " " $6 "\072 " $3 " @ " $5}')"
        else
            echo "${line}"
        fi
    done < <(echo "${Notifications}")
fi
