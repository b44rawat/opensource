#!/bin/bash

# Configuration
PUSHGATEWAY_URL="http://localhost:9091"
JOB="http_simulation"
ENDPOINT="/metrics/job/$JOB"
INTERVAL=15  # seconds between pushes
TOTAL_POINTS=20

# Use string-safe keys
declare -A START_VALUES
declare -A SECOND_LAST_VALUES
declare -A END_VALUES

# Assign values
START_VALUES["v1"]=255
SECOND_LAST_VALUES["v1"]=352
END_VALUES["v1"]=355

START_VALUES["v2"]=64
SECOND_LAST_VALUES["v2"]=97
END_VALUES["v2"]=104

START_VALUES["v3"]=109
SECOND_LAST_VALUES["v3"]=281
END_VALUES["v3"]=289

# List of keys
PATHS=("v1" "v2" "v3")

echo "Starting simulated metric push to Pushgateway..."
echo "Each path will push $TOTAL_POINTS values spaced by $INTERVAL seconds."

for ((i=0; i<TOTAL_POINTS; i++)); do
  echo "Push #$((i+1))"
  METRIC_PAYLOAD=""

  for key in "${PATHS[@]}"; do
    start=${START_VALUES[$key]}
    second_last=${SECOND_LAST_VALUES[$key]}
    end=${END_VALUES[$key]}

    if [ $i -eq 0 ]; then
      val=$start
    elif [ $i -eq $((TOTAL_POINTS-2)) ]; then
      val=$second_last
    elif [ $i -eq $((TOTAL_POINTS-1)) ]; then
      val=$end
    else
      val=$(( start + ( (second_last - start) * i / (TOTAL_POINTS - 2) ) ))
    fi

    METRIC_PAYLOAD+="testpath_requests_total{path=\"/$key\"} $val"$'\n'
    echo "  /$key → $val"
  done

  # Push to Pushgateway
  echo -e "$METRIC_PAYLOAD" | curl --silent --data-binary @- "$PUSHGATEWAY_URL$ENDPOINT" > /dev/null

  sleep $INTERVAL
done

echo "Metric simulation completed successfully!"
