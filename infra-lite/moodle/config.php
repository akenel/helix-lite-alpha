<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'postgres';
$CFG->dbname    = 'infralite';
$CFG->dbuser    = 'infra_user';
$CFG->dbpass    = 'infra_pass';
$CFG->prefix    = 'mdl_';

$CFG->wwwroot   = 'http://localhost:8081';
$CFG->dataroot  = '/var/moodledata';

$CFG->directorypermissions = 02777;

require_once(__DIR__ . '/lib/setup.php');
