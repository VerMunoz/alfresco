FROM centos:centos7  
MAINTAINER Vero Muñoz  <vero9508@gmail.com>

# instala repositorios necesarios para alfresco
RUN yum update -y && yum install -y \
    epel-release \
    fontconfig \
    libSM \
    libICE \
    libXrender \
    libXext \
    cups-libs \
    libGLU \    
    supervisor \
    && yum clean all

COPY docker_install/install_alfresco.sh /tmp/install_alfresco.sh
RUN /tmp/install_alfresco.sh

COPY docker_install/install_mysql_connector.sh /tmp/install_mysql_connector.sh
RUN /tmp/install_mysql_connector.sh  

COPY docker_config/alfresco-global.properties.tar.gz /tmp/alfresco-global.properties.tar.gz

RUN mkdir -p /var/alfresco-community/content \
    && tar -zcf /root/alfresco_alfdata.tar.gz /opt/alfresco-community/alf_data  
 
COPY entry-alfresco.sh /root/entry-alfresco.sh
ENTRYPOINT ["/root/entry-alfresco.sh"]

EXPOSE 21 137 138 139 445 7070 8080

