#!/bin/bash
################################################################################
#                                                                              #
#        EOSeoul Testnet builder for developers                                #
#        made by Sungmin.Ma @2018.04                                           #
#                                                                              #
#        visit to http://eoseoul.io                                            #
#        Contact to Telegram (https://t.me/eoseoul_testnet)                    #
#                                                                              #
################################################################################

#RPC="http://user-api.eoseoul.io"
RPC="http://localhost:6601"
CLE_BIN="$(pwd)/cleos/cleos"
WLT_DIR="$(pwd)/_WLTDIR"
CLE="$CLE_BIN -u $RPC --wallet-url=http://127.0.0.1:54321"
_sleeptime="0.5"

echo_f ()
{
  message=${1:-"[ Failed ]"}
  printf "\033[1;31m%s\033[0m\n" "$message"
}
echo_s ()
{
  message=${1:-"[ Success ]"}
  printf "\033[1;32m%s\033[0m\n" "$message"
}
echo_ret () {
  echo -ne "$1"
  [ $2 -eq 0 ] && echo_s || echo_f
}

if [ $# -lt 2 ]; then
  echo
  echo " Usage: $0 [keyfile] [Producer]"
  echo "  > Keyfile < "
  echo "  PUBLIC_KEY1,PRIVATE_KEY1"
  echo "  PUBLIC_KEY2,PRIVATE_KEY2"
  echo "      .............       "
  echo
  exit 1
fi


if [ ! -x $CLE_BIN ]; then
  echo " >> cleos binary is not found. please script set on 'eos_source/build/programs' directory"
  exit 1
fi

if [ ! -f $1 ]; then
  echo " >> Key file is not exists."
  exit 1
fi

keosd_stop() {
  _pid=$(cat $WLT_DIR/keosd.pid)
  kill -9 $_pid
  rm -rf $WLT_DIR
  exit 1
}
#RPC_CHK=$($CLE get info | grep "843ed645" | wc -l)
RPC_CHK=1
if [ $RPC_CHK -eq 0 ]
then
  echo " >> RPC url is not correct or RPC server version is not EOS mainnet version"
  exit 1
fi


echo " >> Run keosd daemon"
mkdir $WLT_DIR
echo "$(pwd)/keosd/keosd --data-dir $WLT_DIR --http-server-address=127.0.0.1:54321 >> $WLT_DIR/stdout.txt 2>> $WLT_DIR/stderr.txt & echo \$! > $WLT_DIR/keosd.pid" >> $WLT_DIR/wlt.sh
chmod +x $WLT_DIR/wlt.sh
$WLT_DIR/wlt.sh
sleep 1;

producer_chk=$($CLE system listproducers | awk '{print $1}' | grep $2 | wc -l);
if [ $producer_chk -eq 0 ]; then
  echo " >> Producer is not found"
  exit 1
else 
_producer=$2
fi

while IFS=, read PUBKEY PRIVKEY; do
  _account=$(echo -n $($CLE get accounts $PUBKEY) | awk -F"\"" '{print $4}';)
  $CLE wallet create -n $_account >> $WLT_DIR/stdout.txt 2>&1
  echo_ret " -- Wallet Create - $_account : " $?
  $CLE wallet import -n $_account ${PRIVKEY}  >> $WLT_DIR/stdout.txt 2>&1
  echo_ret " -- Wallet Key Import  - $_account : " $?
  KEY_CHK=$($CLE wallet keys | grep $PUBKEY | wc -l)
  if [ $KEY_CHK -eq 0 ]; then
    echo " >> $_account KEY is not registered. Check to keylist file."
    echo " >> Remove all wallet data and stop keosd daemon"
    keosd_stop
  fi
  $CLE system voteproducer approve $_account $_producer  >> $WLT_DIR/stdout.txt 2>&1
  echo_ret " -- Producer Voting $_account to $_producer : " $?
  sleep $_sleeptime
echo "======================================================"
done < <( cat $1 | sed "s/\ //g") 

echo "======================================================"

while IFS=, read PUBKEY PRIVKEY; do
  _account=$(echo -n $($CLE get accounts $PUBKEY) | awk -F"\"" '{print $4}';)
  echo "  -- Verify - $_account voted $($CLE get account $_account | tail -n2)"
done < <( cat $1 | sed "s/\ //g") 
echo "======================================================"
echo " >> Remove all wallet data and stop keosd daemon"
_pid=$(cat $WLT_DIR/keosd.pid)
kill -9 $_pid
rm -rf $WLT_DIR
echo "Complete!"
