CREATE USER infra_user WITH PASSWORD 'infra_pass';
CREATE DATABASE infralite OWNER infra_user;
GRANT ALL PRIVILEGES ON DATABASE infralite TO infra_user;
