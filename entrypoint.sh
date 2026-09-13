#!/bin/bash

cd /home/steam/hl2dm

exec ./srcds_run \
    -game hl2mp \
    +map dm_resistance \
    +maxplayers 16 \
    -port 27015