
echo grub-pc hold | dpkg --set-selections
apt update && apt upgrade -y

# want to use pwmake. pwmake generate password following os security policy. 
apt install -y libpwquality-tools

# ghost owner
user=vagrant
# sitename = ghost sitename
sitename=sitename
apt -y install git 

# Add the NodeSource APT repository for Node 12
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash

# Install Node.js
apt-get install -y nodejs

npm install ghost-cli@latest -g

# enabla ufw.
systemctl enable ufw
systemctl start ufw

# because expect is complex, you use pexpect
apt install -y expect
apt install -y python3-pip
pip3 install pexpect

python3 << END
import pexpect
prc = pexpect.spawn("ufw enable")
prc.expect("Command may disrupt existing ssh connections. Proceed with operation")
prc.sendline("y")
prc.expect( pexpect.EOF )
END

ufw allow 22
# port forwarding mariadb port 3306.
ufw allow 3306

ufw allow 'Nginx Full'

# reload firewall settings.
ufw reload

apt-get -y install nginx
systemctl enable nginx
systemctl start nginx

# install mariadb
apt-get -y install mariadb-server

systemctl enable mariadb
systemctl start mariadb

MYSQL_ROOT_PASSWORD=`pwmake 128`

python3 << END
import pexpect
password = "$MYSQL_ROOT_PASSWORD"
shell_cmd = "/usr/bin/mysql_secure_installation"
prc = pexpect.spawn('/bin/bash', ['-c', shell_cmd],timeout=120)
prc.expect("Enter current password for root")
prc.sendline("")

prc.expect("Set root password")
prc.sendline("Y")

prc.expect("New password")
prc.sendline(password)

prc.expect("Re-enter new password")
prc.sendline(password)

prc.expect("Remove anonymous users")
prc.sendline("Y")

prc.expect("Disallow root login remotely")
prc.sendline("Y")

prc.expect("Remove test database and access to it")
prc.sendline("Y")

prc.expect("Reload privilege tables now")
prc.sendline("Y")

prc.expect( pexpect.EOF )
END

# root
echo '# set mariadb environment variable'  >> ~/.bash_profile
echo export MYSQL_ROOT_PASSWORD=\"$MYSQL_ROOT_PASSWORD\" >> ~/.bash_profile
echo '' >> ~/.bash_profile

# CREATE ROLE DBADMIN.
# this role has all priviledge except Server administration inpacting database system.
# see official document.[Mysql oracle document](https://dev.mysql.com/doc/refman/5.7/en/privileges-provided.html)
mysql << END
CREATE ROLE dbadmin;
GRANT ALL PRIVILEGES ON *.* TO dbadmin;
REVOKE CREATE TABLESPACE,CREATE USER,SHUTDOWN,SUPER,PROCESS,REPLICATION SLAVE,RELOAD ON *.* FROM dbadmin;
END

# CREATE USER connecting from local network.
MYSQL_USER=ghost
MYSQL_USER_PASSWORD=`pwmake 128`
MYSQL_DB=ghost
mysql << END
-- if you are in production environement, you use username@host_ip/netmask. 
-- see official document [mysql oracle document](https://dev.mysql.com/doc/refman/8.0/en/account-names.html)
CREATE USER $MYSQL_USER@localhost IDENTIFIED BY '$MYSQL_USER_PASSWORD';
GRANT dbadmin TO $MYSQL_USER@localhost;

CREATE USER $MYSQL_USER IDENTIFIED BY '$MYSQL_USER_PASSWORD';
-- 
CREATE DATABASE $MYSQL_DB;
GRANT ALL ON $MYSQL_DB.* to $MYSQL_USER;
END


echo '# set mariadb environment variable'  >> /home/$user/.bash_profile
echo export MYSQL_USER_PASSWORD=\"$MYSQL_USER_PASSWORD\" >> /home/$user/.bash_profile
echo '' >> /home/$user/.bash_profile

# Create directory: Change `sitename` to whatever you like
mkdir -p /var/www/$sitename

# Set directory owner: Replace $user with the name of your user
chown $user:$user /var/www/$sitename

# Set the correct permissions
sudo chmod 775 /var/www/$sitename

# Then navigate into it
cd /var/www/$sitename

# install ghost
# ghost install

su - vagrant << END
python3 << EOF
import pexpect
user ="$MYSQL_USER"
user_password = "$MYSQL_USER_PASSWORD"
user_db = "$MYSQL_DB"

shell_cmd = "/usr/bin/ghost install"
prc = pexpect.spawn('/bin/bash', ['-c', shell_cmd],timeout=900)

# default: (http://localhost:2368)
prc.expect("Enter your blog URL")
prc.sendline("")

# default: localhost
prc.expect("Enter your MySQL hostname")
prc.sendline("")

# ghost use username
prc.expect("Enter your MySQL username")
prc.sendline(user)

# ghost password
prc.expect("Enter your MySQL password")
prc.sendline(user_password)

# default: (sitename_prod)
prc.expect("Enter your Ghost database name")
prc.sendline(user_db)

# Setting up Nginx
# Setting up SSL

prc.expect("Do you wish to set up Systemd")
prc.sendline("Y")

prc.expect("Do you want to start Ghost")
prc.sendline("Y")

prc.expect( pexpect.EOF )
EOF
END


# erase fragtation funciton. this function you use vagrant package.
cat << END >> ~/.bash_profile
# eraze fragtation.
function defrag () {
    dd if=/dev/zero of=/EMPTY bs=1M; rm -f /EMPTY
}
END

echo "finish install!"

echo "MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD"
echo "MYSQL_USER_PASSWORD: $MYSQL_USER_PASSWORD"

reboot
