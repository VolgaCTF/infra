#!/bin/bash
UNIT=$1
UNITSTATUS=$(systemctl status $UNIT)
ALERT=$(echo -e "\u26A0")
MSG="$ALERT $UNIT failed
$UNITSTATUS"
URL="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
curl -s --data-urlencode "chat_id=$TELEGRAM_CHAT_ID" --data-urlencode "disable_web_page_preview=1" --data-urlencode "text=$MSG" $URL > /dev/null
