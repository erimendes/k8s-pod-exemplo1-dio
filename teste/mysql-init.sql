-- mysql-init.sql

ALTER USER 'root'@'%' IDENTIFIED BY 's3cr3ta';
ALTER USER 'root'@'localhost' IDENTIFIED BY 's3cr3ta';

GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

FLUSH PRIVILEGES;
-- --- IGNORE ---