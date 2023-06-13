# Dockerfile Base
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /var/www/

# Selecciona la zona horaria
ENV TZ=America/Bogota

# Instalamos apache2, php8.0, software properties ppa:ondrej/php, curl, composer, git, nodejs, npm, yarn
RUN apt-get update && apt-get install -y apache2 software-properties-common && \
    apt-get update && apt-get install -y nano && \
    add-apt-repository -y ppa:ondrej/php && apt-get update && \
    apt-get install -y php8.0 php8.0-mysql php8.0-curl php8.0-gd php8.0-intl php8.0-mbstring php8.0-soap \
    php8.0-xml php8.0-xmlrpc php8.0-zip && apt-get update && apt-get install -y curl && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    apt-get update && apt-get install -y git && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs

RUN apt-get update && apt-get install -y openssh-server && mkdir /var/run/sshd && \
    echo 'changeme:changeme' | chpasswd && \
    useradd -m -d /home/dev -s /bin/bash dev && \
    sudo echo 'changeme:changeme' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "export VISIBLE=now" >> /etc/profile

# Descargamos el proyecto de github
RUN git clone https://github.com/DementesWeb/sccseypre.git

# Instalamos las dependencias del proyecto
RUN cd sccseypre && composer install && npm install

# Copiamos el archivo .env.example a .env
RUN cd sccseypre && cp .env.example .env

# Generamos la key
RUN cd sccseypre && php artisan key:generate

# Modificamos el archivo .env para que apunte a la base de datos de postgresql
RUN cd sccseypre && sed -i 's/DB_CONNECTION=mysql/DB_CONNECTION=pgsql/' .env && sed -i 's/DB_HOST=127.0.0.1/DB_HOST=postgres/' .env && sed -i 's/DB_PORT=3306/DB_PORT=5432/' .env && sed -i 's/DB_DATABASE=laravel/DB_DATABASE=seypre/' .env 

# En el archivo .env modificamos el cache_driver a redis
RUN cd sccseypre && sed -i 's/CACHE_DRIVER=file/CACHE_DRIVER=redis/' .env && sed -i 's/SESSION_DRIVER=file/SESSION_DRIVER=redis/' .env && sed -i 's/QUEUE_DRIVER=sync/QUEUE_DRIVER=redis/' .env

# Configuramos apache2 para que apunte a la carpeta public del proyecto
RUN sed -i's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/sccseypre\/public/' /etc/apache2/sites-available/000-default.conf

# Toma el codigo de la linea 52 y mejoralo
RUN sed -i's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/sccseypre\/public/' /etc/apache2/sites-available/000-default.conf

# Habilitamos mod_rewrite
RUN a2enmod rewrite

# Habilitamos mod_headers
RUN a2enmod headers

# Exponemos los puertos
EXPOSE 80

# Iniciamos apache2
CMD ["apache2ctl", "-D", "FOREGROUND"]