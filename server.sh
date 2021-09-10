#!/bin/bash
set -euo pipefail

request_http_frame="nothing";
REQ_PATH=""
REQ_METHOD=""
REQ_BODY=""
CONTENT_LENGTH=0
re="(GET|POST) (.*) HTTP/1.1"
content_length_re="Content-Length: (.*)"
#head -n 1 /dev/stdin
read -r -d $'\r' request_http_frame
echo "------------------">&2
echo "$request_http_frame">&2
if [[ $request_http_frame =~ $re ]]
then
    REQ_METHOD="${BASH_REMATCH[1]}">&2
    REQ_PATH="${BASH_REMATCH[2]}">&2
else
    response="wat?"
    response_length="$(echo "$response" | wc -c | tr -d ' ')"
    echo -e "HTTP/1.1 500 What?\r\nContent-Length: $response_length\r\n\r\n$response"
    exit 1
fi
# consume headers
while [[ $request_http_frame != '' ]]
do
    read -r -d $'\r' request_http_frame
    if [[ $request_http_frame =~ $content_length_re ]]
    then
        CONTENT_LENGTH=${BASH_REMATCH[1]}
    fi
done
echo "method: $REQ_METHOD">&2
echo "path: $REQ_PATH">&2
echo "content_length_re: $CONTENT_LENGTH">&2
read -r -N 1 request_http_frame
read -r -n "$CONTENT_LENGTH" REQ_BODY
echo "req body: $REQ_BODY">&2


response=""
if [[ $REQ_PATH == "/" ]]
then
    response="{\"apiversion\": \"1\", \"color\":\"#bada55\", \"head\": \"silly\"}"
else
    HEAD_X=$(echo $REQ_BODY | jq -c -M .you.head.x)
    HEAD_Y=$(echo $REQ_BODY | jq -c -M .you.head.y)
    HEIGHT=$(echo $REQ_BODY | jq -c -M .board.height)
    WIDTH=$(echo $REQ_BODY | jq -c -M .board.width)
    LAST_SAFE_Y=$(($HEIGHT-1))
    LAST_SAFE_X=$(($WIDTH-1))

    for candidate_move in $(cat moves); do
        echo "here">&2
        if [[ $candidate_move == "up" ]]
        then
            NEW_HEAD_Y=$(($HEAD_Y+1))
            NEW_HEAD_JSON="{\"x\":$HEAD_X,\"y\":$NEW_HEAD_Y}"
            if echo $REQ_BODY | jq -c -M .board.snakes | grep -io $NEW_HEAD_JSON >&2
            then
                echo "">&2
            else
                if [[ "$NEW_HEAD_Y" -lt 0 ]]
                then
                    continue
                fi
                if [[ "$NEW_HEAD_Y" -gt $LAST_SAFE_Y ]]
                then
                    continue
                fi
                MOVE=$candidate_move
                break
            fi
        elif [[ $candidate_move == "down" ]]
        then
            NEW_HEAD_Y=$(($HEAD_Y-1))
            NEW_HEAD_JSON="{\"x\":$HEAD_X,\"y\":$NEW_HEAD_Y}"

            if echo $REQ_BODY | jq -c -M .board.snakes | grep -io $NEW_HEAD_JSON >&2
            then
                echo "">&2
            else
                if [[ "$NEW_HEAD_Y" -lt 0 ]]
                then
                    continue
                fi
                if [[ "$NEW_HEAD_Y" -gt $LAST_SAFE_Y ]]
                then
                    continue
                fi
                MOVE=$candidate_move
                break
            fi
        elif [[ $candidate_move == "right" ]]
        then
            NEW_HEAD_X=$(($HEAD_X+1))
            NEW_HEAD_JSON="{\"x\":$NEW_HEAD_X,\"y\":$HEAD_Y}"
            if echo $REQ_BODY | jq -c -M .board.snakes | grep -io $NEW_HEAD_JSON >&2

            then
                echo "">&2
            else
                if [[ "$NEW_HEAD_X" -lt 0 ]]
                then
                    continue
                fi
                if [[ "$NEW_HEAD_X" -gt $LAST_SAFE_X ]]
                then
                    continue
                fi
                MOVE=$candidate_move
                break
            fi
        elif [[ $candidate_move == "left" ]]
        then
            NEW_HEAD_X=$(($HEAD_X-1))
            NEW_HEAD_JSON="{\"x\":$NEW_HEAD_X,\"y\":$HEAD_Y}"
            if echo $REQ_BODY | jq -c -M .board.snakes | grep -io $NEW_HEAD_JSON >&2
            then
                echo "">&2
            else
                if [[ "$NEW_HEAD_X" -lt 0 ]]
                then
                    continue
                fi
                if [[ "$NEW_HEAD_X" -gt $LAST_SAFE_X ]]
                then
                    continue
                fi
                MOVE=$candidate_move
                break
            fi
        fi
    done

fi

response="{\"move\": \"$MOVE\"}"
response_length="$(echo "$response" | wc -c | tr -d ' ')"
echo -e "HTTP/1.1 200 OK\r\nContent-Length: $response_length\r\n\r\n$response"
