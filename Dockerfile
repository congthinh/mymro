FROM ubuntu:14.04
MAINTAINER Thinh Huynh <thinh.hc@mobivi.vn>

## Add RStudio binaries to PATH 
ENV PATH /usr/lib/rstudio-server/bin/:$PATH 

#RUN useradd docker \
#	&& mkdir /home/docker \
#	&& chown docker:docker /home/docker \
#	&& addgroup docker staff

RUN DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
RUN echo "deb http://archive.ubuntu.com/ubuntu/ trusty multiverse" >> /etc/apt/sources.list

RUN apt-get update && \
apt-get upgrade -y

## Install some useful tools and dependencies for MRO
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
    	ca-certificates \
	curl \
	nano \
	# MRO dependencies dpkg does not install on its own:
	libcairo2 \
	libgfortran3 \
	libglib2.0-0 \
	libgomp1 \
	libjpeg8 \
	libpango-1.0-0 \
	libpangocairo-1.0-0 \
	libtcl8.6 \
	libtcl8.6 \
	libtiff5 \
	libtk8.6 \
	libx11-6 \
	libxt6 \
	# needed for installation of RevoMath:
	build-essential \
	make \
	gcc \
	wget \
	g++ \
	file \ 
	git \ 
	libapparmor1 \ 
	libedit2 \ 
	libcurl4-openssl-dev \ 
	#libmariadb-client-lgpl-dev \
	libssl1.0.0 \ 
	libssl-dev \ 
	psmisc \ 
	python-setuptools \ 
	sudo \
	&& rm -rf /var/lib/apt/lists/*

## https://mran.revolutionanalytics.com/documents/rro/installation/#revorinst-lin
ENV MRO_VERSION 3.2.4

## Download & Install MRO
RUN curl -LO -# https://mran.revolutionanalytics.com/install/mro/$MRO_VERSION/MRO-$MRO_VERSION-Ubuntu-14.4.x86_64.deb

#RUN wget https://mran.revolutionanalytics.com/install/mro/$MRO_VERSION/MRO-$MRO_VERSION-Ubuntu-14.4.x86_64.deb
RUN dpkg -i MRO-$MRO_VERSION-Ubuntu-14.4.x86_64.deb

#RUN rm MRO-*.deb

## Download and install MKL as user docker so that .Rprofile etc. are properly set
#RUN wget https://mran.revolutionanalytics.com/install/mro/$MRO_VERSION/RevoMath-$MRO_VERSION.tar.gz \
RUN curl -LO -# https://mran.revolutionanalytics.com/install/mro/$MRO_VERSION/RevoMath-$MRO_VERSION.tar.gz \
	&& tar -xzf RevoMath-$MRO_VERSION.tar.gz
WORKDIR /home/docker/RevoMath
COPY ./RevoMath_install.sh RevoMath_install.sh
RUN ./RevoMath_install.sh \
	|| (echo "\n*** RevoMath Installation log ***\n" \
	&& cat mkl_log.txt \
	&& echo "")

#RUN rm RevoMath-*.tar.gz
#RUN rm -r RevoMath

# print MKL license on every start
#COPY mklLicense.txt mklLicense.txt
#RUN echo 'cat("\n", readLines("/home/docker/mklLicense.txt"), "\n", sep="\n")' >> /usr/lib64/MRO-3.2.4/R-3.2.4/lib/R/etc/Rprofile.site

#COPY demo.R demo.R

#CMD ["/usr/bin/R"]

RUN apt-get update
RUN wget -q http://download2.rstudio.org/rstudio-server-0.99.902-amd64.deb
RUN dpkg -i rstudio-server-0.99.902-amd64.deb
#RUN rm rstudio-server-*-amd64.deb \

#RUN useradd mobivi \
#&& chown mobivi:mobivi /home/docker \
#&& addgroup mobivi staff

## Configure default locale 
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
&& locale-gen en_US.utf8 \
&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8 

#Add rstudio/rstudio username/password
#RUN usermod -l rstudio docker \ 
#&& usermod -m -d /home/rstudio rstudio \ 
#&& groupmod -n rstudio docker \ 
#&& echo '"\e[5~": history-search-backward' >> /etc/inputrc \ 
#&& echo '"\e[6~": history-search-backward' >> /etc/inputrc \ 
#&& echo "rstudio:rstudio" | chpasswd

#RUN useradd docker \
#&& mkdir /home/docker \
#&& chown docker:docker /home/docker \
#&& addgroup docker staff

RUN useradd mobivi
RUN mkdir /home/rdata
RUN chown mobivi:mobivi /home/rdata
RUN passwd rstudio <<EOF\
rstudio \
rsdutio \
EOF

COPY userconf.sh /etc/cont-init.d/conf 
COPY run.sh /etc/services.d/rstudio/run 
COPY add-users.sh /usr/local/bin/add-users 

## Use s6 
RUN wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/v1.11.0.1/s6-overlay-amd64.tar.gz \
&& tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

EXPOSE 8787 

## Expose a default volume for Kitematic 
VOLUME /home/docker 
CMD ["/init"]
