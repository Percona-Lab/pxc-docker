#!/bin/bash -ue

then=$(date +%s)
skip=true
NUMC=${NUMC:-3}
SDURATION=${SDURATION:-300}
TSIZE=${TSIZE:-1000}
NUMT=${NUMT:-16}
STEST=${STEST:-oltp}
AUTOINC=${AUTOINC:-off}
TCOUNT=${TCOUNT:-10}
SHUTDN=${SHUTDN:-yes}
DELAY="${DELAY:-3ms}"
CMD=${CMD:-"/pxc/bin/mysqld --defaults-extra-file=/pxc/my.cnf --basedir=/pxc --user=mysql --skip-grant-tables --query_cache_type=0  --wsrep_slave_threads=16 --innodb_autoinc_lock_mode=2  --query_cache_size=0 --innodb_flush_log_at_trx_commit=0 --innodb_file_per_table "}
LPATH=${SPATH:-/usr/share/doc/sysbench/tests/db}
thres=1 
RANDOM=$$
BUILD_NUMBER=${BUILD_NUMBER:-$RANDOM}
SLEEPCNT=${SLEEPCNT:-10}
FSYNC=${FSYNC:-0}
STOSLEEP=${STOSLEEP:-}

TMPD=${TMPDIR:-/tmp}
COREDIR=${COREDIR:-/var/crash}
ECMD=${EXTRA_CMD:-" --wsrep-sst-method=rsync --core-file "}
RSEGMENT=${RSEGMENT:-1}
PROVIDER=${EPROVIDER:-0}

HOSTSF="$PWD/hosts"
VSYNC=${VSYNC:-1}
CATAL=${COREONFATAL:-0}

DIMAGE="ronin/pxc:tarball-$PLATFORM"
SOCKS=""
SOCKPATH="/tmp/pxc-socks"
FORCE_FTWRL=${FORCE_FTWRL:-0}

if [[ ${BDEBUG:-0} -eq 1 ]];then 
    set -x
fi

SDIR="$LPATH"
export PATH="/usr/sbin:$PATH"

linter="eth0"
icoredir="/pxc/crash"

FIRSTD=$(cut -d" " -f1 <<< $DELAY | tr -d 'ms')
RESTD=$(cut -d" " -f2- <<< $DELAY)

echo "
[sst]
sst-initial-timeout=$(( 50*NUMC ))
" > /tmp/my.cnf

if [[ $NUMC -lt 3 ]];then 
    echo "Specify at least 3 for nodes"
    exit 1
fi

if [[ $RSEGMENT == "1" ]];then 
    SEGMENT=$(( RANDOM % (NUMC/2) ))
else 
    SEGMENT=0
fi


if [[ -n ${ADDOP:-} ]];then 
   ADDOP="gmcast.segment=$SEGMENT; evs.auto_evict=3; evs.version=1; gcache.size=256M; $ADDOP"
else 
   ADDOP="gmcast.segment=$SEGMENT; evs.auto_evict=3; evs.version=1; gcache.size=256M"
fi

# Hack for jenkins only. uh.. 
if [[ -n ${BUILD_NUMBER:-} && $(groups) != *docker* ]]; then
    exec sg docker "$0 $*"
fi

if [[ $PROVIDER == '1' ]];then 
    CMD+=" --wsrep-provider=/pxc/libgalera_smm.so"
    PGALERA=" -v $PWD/libgalera_smm.so:/pxc/libgalera_smm.so -v /tmp/my.cnf:/pxc/my.cnf"
    #cp -v $PWD/libgalera_smm.so /pxc/
else 
    PGALERA="-v /tmp/my.cnf:/pxc/my.cnf"
fi


pushd ../docker-tarball
count=$(ls -1ct Percona-XtraDB-Cluster-*.tar.gz | wc -l)

if [[ $count -eq 0 ]];then 
    echo "FATAL: Need tar.gz"
    exit 2
fi


if [[ $count -gt $thres ]];then 
    for fl in `ls -1ct Percona-XtraDB-Cluster-*.tar.gz | tail -n +2`;do 
        rm -f $fl || true
    done 
fi

find . -maxdepth 1 -type d -name 'Percona-XtraDB-Cluster-*' -exec rm -rf {} \+ || true 


TAR=`ls -1ct Percona-XtraDB-Cluster-*.tar.gz | head -n1`
BASE="$(tar tf $TAR | head -1 | tr -d '/')"

tar -xf $TAR

rm -rf Percona-XtraDB-Cluster || true

mv $BASE Percona-XtraDB-Cluster

NBASE=$PWD/Percona-XtraDB-Cluster

MD5=$(md5sum < $TAR | cut -d" " -f1)
if [[ ! -e $TMPD/MD5FILE ]];then 
    skip=false
    echo -n $MD5 > $TMPD/MD5FILE
else 
    EMD5=$(cat $TMPD/MD5FILE)

    if [[ $MD5 != $EMD5 ]];then 
        echo -n $MD5 > $TMPD/MD5FILE
        skip=false
    else 
        skip=true
    fi
fi 
popd

#if git log --summary -1 -p  | grep -q '/Dockerfile';then 
    #skip=false
#fi

if [[ $FORCEBLD == 1 ]];then 
    skip=false
fi

LOGDIR="$TMPD/logs/$BUILD_NUMBER"
mkdir -p $LOGDIR

runum(){
    local cmd="$1"
    for x in `seq 1 $NUMC`; do 
        eval $cmd Dock$x
    done 
}
runc(){
    local cont=$1
    shift
    local cmd1=$1
    shift 
    local cmd2=$1
    local ecmd 
    if [[ $cmd1 == 'mysql' ]];then 
        ecmd=-e
    else 
        ecmd=""
    fi
    local hostt=$(docker port $cont 3306)
    local hostr=$(cut -d: -f1 <<< $hostt)
    local portr=$(cut -d: -f2 <<< $hostt)
    $cmd1 -h $hostr -P $portr -u root $ecmd  "$cmd2"

}

cleanup(){
    local cnt
    set +e 

    if [[ "$(ls -A $COREDIR)" ]];then
        echo "Core files found"
        for cor in $COREDIR/*.core;do 
            cor=$(basename $cor)
            cnt=$(cut -d. -f1 <<< $cor)
            if docker top ${cnt} &>/dev/null;then
                docker exec ${cnt} gdb /pxc/bin/mysqld --quiet --batch --core=$icoredir/$cor -ex "set logging file $icoredir/${cnt}.trace"  --command=/backtrace.gdb
            else 
                docker start ${cnt}
                docker exec ${cnt} gdb /pxc/bin/mysqld --quiet --batch --core=$icoredir/$cor -ex "set logging file $icoredir/${cnt}.trace"  --command=/backtrace.gdb
            fi
        done 
    fi


    for s in `seq 1 $NUMC`;do 
        docker logs -t Dock$s &>$LOGDIR/Dock$s.log
    done

    echo "Copying trace files"
    cp -v $COREDIR/*.trace $LOGDIR/ || true


    docker logs -t dnscluster > $LOGDIR/dnscluster.log
    if [[ $SHUTDN == 'yes' ]];then 
        docker stop dnscluster  &>/dev/null
        docker rm -f  dnscluster &>/dev/null
        echo "Stopping docker containers"
        runum "docker stop" &>/dev/null
        echo "Removing containers"
        runum "docker rm -f " &>/dev/null
    fi
    pkill -9 -f socat
    rm -rf $SOCKPATH && mkdir -p $SOCKPATH
    #rm -rf $LOGDIR

    now=$(date +%s)
    for s in `seq 1 $NUMC`;do 
        sudo journalctl --since=$(( then-now )) | grep  "Dock${s}-" > $LOGDIR/journald-Dock${s}.log
    done
    sudo journalctl -b  > $LOGDIR/journald-all.log
    tar cvzf $TMPD/results-${BUILD_NUMBER}.tar.gz $LOGDIR  
    set -e 


}

preclean(){
    set +e
    echo "Stopping old docker containers"
    runum "docker stop" &>/dev/null 
    echo "Removing  old containers"
    runum "docker rm -f" &>/dev/null 
    docker stop dnscluster &>/dev/null 
    docker rm -f dnscluster &>/dev/null
    pkill -9 -f socat
    pkill -9 -f mysqld
    rm -rf $SOCKPATH && mkdir -p $SOCKPATH
    set -e 
}

wait_for_up(){
    local cnt=$1
    local count=0
    local hostt=$(docker port $cnt 3306)

    if [[ $? -ne 0 ]];then 
        sleep 5
        hostt=$(docker port $cnt 3306)
        if [[ $count -gt $SLEEPCNT ]];then 
            echo "Failure"
            exit 1
        else 
            count=$(( count+1 ))
        fi
    fi

    local hostr=$(cut -d: -f1 <<< $hostt)
    local portr=$(cut -d: -f2 <<< $hostt)

    set +e 
    while ! mysqladmin -h $hostr -P $portr -u root ping &>/dev/null;do 
        echo "Waiting for $cnt"
        sleep 5
        if [[ $count -gt $SLEEPCNT ]];then 
            echo "Failure"
            exit 1
        else 
            count=$(( count+1 ))
        fi
    done 
    echo "$cnt container up and running!"
    SLEEPCNT=$(( SLEEPCNT+count ))
    set -e
}

spawn_sock(){
    local cnt=$1
    hostt=$(docker port $cnt 3306)
    hostr=$(cut -d: -f1 <<< $hostt)
    portr=$(cut -d: -f2 <<< $hostt)
    local socket=$SOCKPATH/${cnt}.sock
    [[ -f $socket ]] && {
        pkill -9 -f $socket
        rm -f $socket
    }
    socat UNIX-LISTEN:${socket},fork,reuseaddr TCP:$hostr:$portr 2>>$LOGDIR/socat-${cnt}.log &
    echo "$cnt also listening on $socket for $hostr:$portr" 
    if [[ -z $SOCKS ]];then 
        SOCKS="$socket"
    else
        SOCKS+=",$socket"
    fi
}

belongs(){
    local elem=$1
    shift
    local -a arr=$@
    for x in ${arr[@]};do 
        if [[ $elem == $x ]];then 
            return 0
        fi
    done 
    return 1
}


trap cleanup EXIT KILL

preclean

if [[ $skip == "false" ]];then
    pushd ../docker-tarball
    docker build  --rm  -t $DIMAGE -f Dockerfile.$PLATFORM . 2>&1 | tee $LOGDIR/Dock-pxc.log 
    popd
    # Required for core-dump analysis
    # rm -rf Percona-XtraDB-Cluster || true
fi

CSTR="gcomm://Dock1"

#for nd in `seq 2 $NUMC`;do 
    #CSTR="${CSTR},Dock${nd}"
#done 

rm -f $HOSTSF && touch $HOSTSF

# Some Selinux foo
chcon  -Rt svirt_sandbox_file_t  $HOSTSF &>/dev/null  || true
chcon  -Rt svirt_sandbox_file_t  $COREDIR &>/dev/null  || true

docker run  -d  -i -v /dev/log:/dev/log -e SST_SYSLOG_TAG=dnsmasq -v $HOSTSF:/dnsmasq.hosts --name dnscluster ronin/dnsmasq &>$LOGDIR/dnscluster-run.log

dnsi=$(docker inspect  dnscluster | grep IPAddress | grep -oE '[0-9\.]+')

echo "Starting first node"

declare -a segloss

if [[ $RSEGMENT == "1" ]];then 
    segloss[0]=$(( SEGMENT+1 ))
fi

if [[ $FSYNC == '0' || $VSYNC == '1' ]];then 
    PRELOAD="/usr/lib64/libeatmydata.so"
else 
    PRELOAD=""
fi

docker run -P -e LD_PRELOAD=$PRELOAD -e FORCE_FTWRL=$FORCE_FTWRL  -e SST_SYSLOG_TAG=Dock1  -d  -i -v /dev/log:/dev/log -h Dock1 -v $COREDIR:$icoredir $PGALERA   --dns $dnsi --name Dock1 $DIMAGE bash -c "ulimit -c unlimited && chmod 777 $icoredir && $CMD $ECMD --wsrep-new-cluster --wsrep-provider-options='$ADDOP'" &>/dev/null

wait_for_up Dock1
spawn_sock Dock1
FIRSTSOCK="$SOCKPATH/Dock1.sock"

firsti=$(docker inspect  Dock1 | grep IPAddress | grep -oE '[0-9\.]+')
echo "$firsti Dock1" >> $HOSTSF
echo "$firsti Dock1.ci.percona.com" >> $HOSTSF
echo "$firsti meant for Dock1"

sysbench --test=$LPATH/parallel_prepare.lua ---report-interval=10  --oltp-auto-inc=$AUTOINC --mysql-db=test  --db-driver=mysql --num-threads=$NUMT --mysql-engine-trx=yes --mysql-table-engine=innodb --mysql-socket=$FIRSTSOCK --mysql-user=root  --oltp-table-size=$TSIZE --oltp_tables_count=$TCOUNT    prepare 2>&1 | tee $LOGDIR/sysbench_prepare.txt 

mysql -S $FIRSTSOCK -u root -e "create database testdb;" || true


nexti=$firsti
sleep 5

sysbench --test=$SDIR/$STEST.lua --db-driver=mysql --mysql-db=test --mysql-engine-trx=yes --mysql-ignore-errors=1047,1213 --mysql-table-engine=innodb --mysql-socket=$FIRSTSOCK --mysql-user=root  --num-threads=$NUMT --init-rng=on --max-requests=1870000000    --max-time=$(( NUMC*10 ))  --oltp_index_updates=20 --oltp_non_index_updates=20 --oltp-auto-inc=$AUTOINC --oltp_distinct_ranges=15 --report-interval=1  --oltp_tables_count=$TCOUNT run &>$LOGDIR/sysbench-run-0.txt & 
syspid=$!

for rest in `seq 2 $NUMC`; do
    echo "Starting node#$rest"
    lasto=$(cut -d. -f4 <<< $nexti)
    nexti=$(cut -d. -f1-3 <<< $nexti).$(( lasto+1 ))
    echo "$nexti Dock${rest}" >> $HOSTSF
    echo "$nexti Dock${rest}.ci.percona.com" >> $HOSTSF
    echo "$nexti meant for Dock${rest}"
    if [[ $RSEGMENT == "1" ]];then 
        SEGMENT=$(( RANDOM % (NUMC/2) ))
        segloss[$(( rest-1 ))]=$(( SEGMENT+1 ))
    else 
        SEGMENT=0
    fi

    if [[  $FSYNC == '0' || ( $VSYNC == '1'  && $(( RANDOM%2 )) == 0 ) ]];then 
        PRELOAD="/usr/lib64/libeatmydata.so"
    else 
        PRELOAD=""
    fi
    docker run -P -e LD_PRELOAD=$PRELOAD -e FORCE_FTWRL=$FORCE_FTWRL -d  -v /dev/log:/dev/log -i -e SST_SYSLOG_TAG=Dock${rest} -h Dock$rest -v $COREDIR:$icoredir $PGALERA --dns $dnsi --name Dock$rest $DIMAGE bash -c "ulimit -c unlimited && chmod 777 $icoredir && $CMD $ECMD --wsrep_cluster_address=$CSTR --wsrep_node_name=Dock$rest --wsrep-provider-options='$ADDOP'" &>/dev/null
    #CSTR="${CSTR},Dock${rest}"

    if [[ $(docker inspect  Dock$rest | grep IPAddress | grep -oE '[0-9\.]+') != $nexti ]];then 
        echo "Assertion failed  $nexti,  $(docker inspect  Dock$rest | grep IPAddress | grep -oE '[0-9\.]+') "
        exit 1
    fi
    sleep $(( rest*2 ))

done


echo "Waiting for all servers"
for s in `seq 2 $NUMC`;do 
    wait_for_up Dock$s
    spawn_sock Dock$s
done

wait $syspid || true

sleep 10

totsleep=10
echo "Pre-Sanity tests"
runagain=0
while true; do
    runagain=0
    for s in `seq 1 $NUMC`;do 
        stat1=$(mysql -nNE -S $SOCKPATH/Dock${s}.sock -u root -e "show global status like 'wsrep_cluster_status'" 2>/dev/null | tail -1)
        stat2=$(mysql -nNE -S $SOCKPATH/Dock${s}.sock -u root -e "show global status like 'wsrep_local_state_comment'" 2>/dev/null | tail -1)
        stat3=$(mysql -nNE -S $SOCKPATH/Dock${s}.sock -u root -e "show global status like 'wsrep_local_recv_queue'" 2>/dev/null | tail -1)
        stat4=$(mysql -nNE -S $SOCKPATH/Dock${s}.sock -u root -e "show global status like 'wsrep_local_send_queue'" 2>/dev/null | tail -1)
        stat5=$(mysql -nNE -S $SOCKPATH/Dock${s}.sock -u root -e "show global status like 'wsrep_evs_delayed'" 2>/dev/null | tail -1)
        if [[ $stat1 != 'Primary' || $stat2 != 'Synced' || $stat3 != '0' || $stat4 != '0' ]];then 
            echo "Waiting for Dock${s} (or some other node to empty) to become really synced or primary: $stat1, $stat2, $stat3, $stat4, $stat5"
            runagain=1
            break
        else 
            echo "Dock${s} is synced and is primary: $stat1, $stat2, $stat3, $stat4, $stat5"
        fi
    done
    if [[ $runagain -eq 1 ]];then 
        sleep 10
        totsleep=$(( totsleep+10 ))
        continue
    else 
        break
    fi
done 

echo "Slept for $totsleep in total"


for s in `seq 1 $NUMC`;do 
    for x in `seq 1 $TCOUNT`;do
        if ! mysql -S $SOCKPATH/Dock${s}.sock -u root -e "select count(*) from test.sbtest$x" &>>$LOGDIR/sanity-pre.log;then 
            echo "FATAL: Failed in pre-sanity state for Dock${s} and table $x"
            exit 1
        fi
    done 
done



declare -a ints
declare -a intf

intf=(`seq 1 $NUMC`)

for int in ${intf[@]};do 
    echo "Adding delay to Dock${int} out of ${intf[@]}"

    dpid=$(docker inspect -f '{{.State.Pid}}' Dock${int})

    sudo nsenter  -t $dpid -n tc qdisc replace dev $linter root handle 1: prio
    if [[ $RSEGMENT == "1" ]];then 
        DELAY="$(( FIRSTD*${segloss[$(( int-1 ))]} ))ms $RESTD"
    else 
        DELAY="${FIRSTD}ms $RESTD"
    fi
    echo "Setting delay as $DELAY for Dock${int}"
    sudo nsenter  -t $dpid -n tc qdisc add dev $linter parent 1:2 handle 30: netem delay $DELAY
done



echo "Rules in place"

for s in `seq 1 $NUMC`;do 
    dpid=$(docker inspect -f '{{.State.Pid}}' Dock${s})
    sudo nsenter -t $dpid -n tc qdisc show
done
if [[ ! -e $SDIR/${STEST}.lua ]];then 
    pushd /tmp

    rm $STEST.lua || true
    wget -O $STEST.lua  http://files.wnohang.net/files/${STEST}.lua
    SDIR=/tmp/
    popd
fi


mysql -S $FIRSTSOCK -u root -e "drop database testdb;" || true
mysql -S $FIRSTSOCK -u root -e "drop database test;" || true
mysql -S $FIRSTSOCK -u root -e "create database test;" || true
mysql -S $FIRSTSOCK -u root -e "create database testdb;" || true

echo "Preparing again!"
sysbench --test=$LPATH/parallel_prepare.lua ---report-interval=10  --oltp-auto-inc=$AUTOINC --mysql-db=test  --db-driver=mysql --num-threads=$NUMT --mysql-engine-trx=yes --mysql-table-engine=innodb --mysql-socket=$SOCKS --mysql-user=root  --oltp-table-size=$TSIZE --oltp_tables_count=$TCOUNT    prepare 2>&1 | tee $LOGDIR/sysbench_prepare-2.txt 


    timeout -k9 $(( SDURATION+200 )) sysbench --test=$SDIR/$STEST.lua --db-driver=mysql --mysql-db=test --mysql-engine-trx=yes --mysql-table-engine=innodb --mysql-socket=$SOCKS --mysql-user=root  --num-threads=$NUMT --init-rng=on --max-requests=1870000000    --max-time=$SDURATION  --oltp_index_updates=20 --oltp_non_index_updates=20 --oltp-auto-inc=$AUTOINC --oltp_distinct_ranges=15 --report-interval=1  --oltp_tables_count=$TCOUNT run 2>&1 | tee $LOGDIR/sysbench_rw_run.txt


nd=""

if [[ $NUMC -eq 3 ]];then 
    intf=(`shuf -i 2-$NUMC -n 1`)
else 
    intf=(`shuf -i 2-$NUMC -n $(( NUMC/2 - 1 ))`)
fi
nume=${#intf[@]}

for x in ${intf[@]};do 
    nd+=" Dock${x} "
done

echo "Running sysbench while nodes $nd are down"

set -x
(    timeout -k9 $(( STSLEEP+200 )) sysbench --test=$SDIR/$STEST.lua --db-driver=mysql --mysql-db=test --mysql-engine-trx=yes --mysql-table-engine=innodb --mysql-socket=$FIRSTSOCK --mysql-user=root  --num-threads=$NUMT --init-rng=on --max-requests=1870000000    --max-time=$STSLEEP  --oltp_index_updates=20 --oltp_non_index_updates=20 --oltp-auto-inc=$AUTOINC --oltp_distinct_ranges=15 --report-interval=1  --oltp_tables_count=$TCOUNT run 2>&1 | tee $LOGDIR/sysbench_rw_run-2.txt ) &

set +x

set -x
for x in ${intf[@]};do 
    runc Dock$x  mysqladmin shutdown
    sleep ${STOSLEEP:-$(( RANDOM % $nume + 1 ))}
done
set +x

docker stop -t 60 $nd || true


echo "Starting nodes $nd again"

set -x
for x in ${intf[@]};do 
    docker restart -t 1 Dock${x}
    sleep ${STOSLEEP:-$(( RANDOM % $nume + 1 ))}
done 
set +x

for x in ${intf[@]};do 
    wait_for_up Dock${x}
    spawn_sock Dock${x}
    sleep 1
done 


sleep 5

for s in `seq 1 $NUMC`;do 

    stat1=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2) -u root -e "show global status like 'wsrep_cluster_status'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
    stat2=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "show global status like 'wsrep_local_state_comment'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
    stat3=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "show global status like 'wsrep_local_recv_queue'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
    stat4=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "show global status like 'wsrep_local_send_queue'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
    stat5=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "show global status like 'wsrep_evs_delayed'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
    if [[ $stat1 != 'Primary' || $stat2 != 'Synced'  ]];then 
        echo "Dock${s} seems to be not stable: $stat1, $stat2, $stat3, $stat4, $stat5"
    else 
        echo "Dock${s} is synced and is primary: $stat1, $stat2, $stat3, $stat4, $stat5"
    fi
done

echo "Sanity tests"
echo "Statuses"
maxsleep=300
totsleep=0

while true;do 
    exitfatal=0
    whichisstr=""
    for s in `seq 1 $NUMC`;do 

        stat1=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2) -u root -e "show global status like 'wsrep_cluster_status'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
        stat2=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "show global status like 'wsrep_local_state_comment'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
        stat3=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "show global status like 'wsrep_local_recv_queue'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
        stat4=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "show global status like 'wsrep_local_send_queue'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
        stat5=$(mysql -nNE -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "show global status like 'wsrep_evs_delayed'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
        if [[ $stat1 != 'Primary' || $stat2 != 'Synced'  ]];then 
            echo "FATAL: Dock${s} seems to be STILL unstable: $stat1, $stat2, $stat3, $stat4, $stat5"
            stat=$(mysql -nNE -S $SOCKPATH/Dock${s}.sock -u root -e "show global status like 'wsrep_local_state'" 2>>$LOGDIR/mysql-Dock${s}.log | tail -1)
            echo "wsrep_local_state of Dock${s} is $stat"
            if  [[ $stat1 == 'Primary' && ( $stat == '2' || $stat == '1' || $stat == '3' || $stat2 == *Join* || $stat2 == *Don* ) ]];then 
                exitfatal=3
                whichisstr="Dock${s}"
                break
            else
                exitfatal=1
            fi
        else 
            echo "Dock${s} is synced and is primary: $stat1, $stat2, $stat3, $stat4, $stat5"
        fi
    done
    if [[ $exitfatal -eq 1 || $totsleep -gt $maxsleep ]];then 
        exitfatal=1
        break
    elif [[ $exitfatal -eq 3 ]];then
        echo " $whichisstr is still donor/joiner, sleeping 60 seconds"
        sleep 60
        totsleep=$(( totsleep+60 ))
    else 
        break
    fi
    echo 
    echo
done 


echo "Sanity queries"

for s in `seq 1 $NUMC`;do 

    for x in `seq 1 $TCOUNT`;do
        echo "For table test.sbtest$x from node Dock${s}" &>>$LOGDIR/sanity.log
        mysql -h $(docker port Dock${s} 3306 | cut -d: -f1) -P $(docker port Dock${s} 3306 | cut -d: -f2)  -u root -e "select count(*) from test.sbtest$x" &>>$LOGDIR/sanity.log || exitfatal=1
    done 
done

if [[ $exitfatal -eq 1 ]];then 
    echo "Exit fatal"
    if [[ $CATAL == '1' ]];then 
        echo "Killing with SIGSEGV for core dumps"
        pkill -11 -f mysqld || true 
        sleep 60
    fi
    exit 1
fi

echo "Sleeping 5s before drop table"
sleep 5

 timeout -k9 $(( SDURATION+200 )) sysbench --test=$LPATH/parallel_prepare.lua ---report-interval=5  --oltp-auto-inc=$AUTOINC --mysql-db=test  --db-driver=mysql --num-threads=$NUMT --mysql-engine-trx=yes --mysql-table-engine=innodb --mysql-socket=$SOCKS --mysql-user=root  --oltp-table-size=$TSIZE --oltp_tables_count=$TCOUNT    cleanup 2>&1 | tee $LOGDIR/sysbench_cleanup.txt 

mysql -S $FIRSTSOCK  -u root -e "drop database testdb;" || true

sleep 10 

if [[ $SHUTDN == 'no' ]];then 
    echo "Exit before cleanup"
    exit
fi

echo "Shutting down servers"
for s in `seq 1 $NUMC`;do 
    runc Dock$s  mysqladmin shutdown
done

