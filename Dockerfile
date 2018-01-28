FROM resin/raspberrypi3-debian:latest

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        tesseract-ocr tesseract-ocr-eng imagemagick ghostscript unpaper \
        git python3-pip libpython3-dev gcc libmagic1 vsftpd \
        zlib1g-dev libfreetype6-dev libjpeg-dev openjpeg-tools \
        libtiff-dev liblcms2-dev libwebp-dev libwebpmux1 \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
RUN mkdir -p /usr/src
WORKDIR /usr/src
RUN git clone https://github.com/danielquinn/paperless.git
WORKDIR /usr/src/paperless
RUN pip3 install -r requirements.txt --global-option=build_ext --global-option="-L/usr/lib/arm-linux-gnueabihf" --global-option="-I/usr/include/arm-linux-gnueabihf"

# Add create super user with password Django command
COPY createsuperuser2.py /usr/src/paperless/src/documents/management/commands/

# Migrate database
#WORKDIR /usr/src/paperless/src
#RUN ./manage.py migrate

# Create user
RUN groupadd -g 1000 paperless \
    && useradd -u 1000 -g 1000 -d /usr/src/paperless paperless \
    && chown -Rh paperless:paperless /usr/src/paperless

# Setup entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/src/paperless/scripts/docker-entrypoint.sh

# Mount volumes
#VOLUME ["/usr/src/paperless/data", "/usr/src/paperless/media", "/consume", "/export"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
#CMD ["runserver", "--insecure", "0.0.0.0:8000"]
CMD ["document_consumer"]
