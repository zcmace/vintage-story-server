FROM debian:11

EXPOSE 42420

# Username and paths can be overridden from .env when building via docker-compose
# (docker-compose loads .env and passes these as build-args). Defaults below are used for plain `docker build`.
ENV VS_VERSION=1.21.6
ARG USERNAME=vintagestory
ARG VS_HOMEPATH=/home/vintagestory
ARG VSPATH=/home/vintagestory/server
ARG DATAPATH=/var/vintagestory/data

# Install dependencies
RUN apt-get update -q -y
RUN apt-get install -yf \
    screen wget curl vim ca-certificates procps

# .NET 8.0 runtime (required by Vintage Story server 1.19+)
RUN apt-get install -yf \
    wget apt-transport-https
RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
RUN dpkg -i /tmp/packages-microsoft-prod.deb
RUN rm /tmp/packages-microsoft-prod.deb
RUN apt-get update -q -y
RUN apt-get install -yf \
    dotnet-runtime-8.0

# Add user
RUN groupadd -g 1000 $USERNAME
RUN useradd -u 1000 -g 1000 -ms /bin/bash $USERNAME
# Server folder
RUN mkdir -p $VSPATH
RUN chown -R $USERNAME $VSPATH
# Data folder
RUN mkdir -p $DATAPATH
RUN chown -R $USERNAME $DATAPATH

#changes work dir
WORKDIR $VSPATH

# Create container Launch script
ADD launcher.sh $VS_HOMEPATH
RUN chmod +x $VS_HOMEPATH/launcher.sh
RUN chown $USERNAME $VS_HOMEPATH/launcher.sh

# Changes user
USER $USERNAME

# Start the server
# This script hooks the stop command
ENTRYPOINT ../launcher.sh
