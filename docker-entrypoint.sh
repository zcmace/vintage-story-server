#!/bin/bash
set -e
chown -R vintagestory:vintagestory /var/vintagestory/data
exec gosu vintagestory /home/vintagestory/launcher.sh
