import logging
import shutil
import time
from os import environ
import uuid
from os import path
from os.path import isdir, join
from subprocess import check_output

import requests_unixsocket
from bs4 import BeautifulSoup
from syncloudlib import fs, linux, gen, logger
from syncloudlib.application import paths, urls, storage, users

from database import Database

APP_NAME = 'mastodon'
USER_NAME = APP_NAME
PSQL_PATH = 'postgresql/bin/psql.sh'
PSQL_DATA_PATH = 'database'
PSQL_PORT = 5434
DB_USER = APP_NAME
DB_PASS = APP_NAME
DB_NAME = APP_NAME

logger.init(logging.DEBUG, console=True, line_format='%(message)s')

install_file = join(paths.get_data_dir(APP_NAME), 'installed')


class Installer:
    def __init__(self):
        self.app_dir = paths.get_app_dir(APP_NAME)
        self.common_dir = paths.get_data_dir(APP_NAME)
        self.data_dir = join('/var/snap', APP_NAME, 'current')
        self.database_path = join(self.common_dir, PSQL_DATA_PATH)
        self.log = logger.get_logger(APP_NAME)
        self.config_dir = join(self.data_dir, 'config')
        self.db = Database(self.app_dir, self.data_dir, self.config_dir, join(self.app_dir, PSQL_PATH), DB_USER, self.database_path, PSQL_PORT)
        self.mastodon_dir = join(self.app_dir, 'ruby', 'mastodon')
        self.rails = join(self.mastodon_dir, 'bin', 'rails')
        environ['RAILS_ENV'] = 'production'

    def init_config(self):
        home_folder = join(self.common_dir, USER_NAME)
        linux.useradd(USER_NAME, home_folder=home_folder)

        app_config_dir = join(self.app_dir, 'config')
        fs.makepath(join(self.data_dir, 'redis'))

        storage_dir = storage.init_storage(APP_NAME, USER_NAME)
        variables = {
            'app_dir': self.app_dir,
            'common_dir': self.common_dir,
            'database_dir': self.database_path,
            'db_psql_port': PSQL_PORT,
            'db_name': DB_NAME,
            'db_user': DB_USER,
            'db_password': DB_PASS,
            'storage_dir': storage_dir,
            'data_dir': self.data_dir,
            'app_url': urls.get_app_url(APP_NAME),
            'app_domain': urls.get_app_domain_name(APP_NAME),
            'secret': uuid.uuid4().hex,
            'secret_base': uuid.uuid4().hex,
            'disable_registration': False
        }
        gen.generate_files(app_config_dir, self.config_dir, variables)
        fs.chownpath(self.common_dir, USER_NAME, recursive=True)
        fs.chownpath(self.data_dir, USER_NAME, recursive=True)

    def install(self):
        self.init_config()
        self.db.init()
        self.db.init_config()

    def pre_refresh(self):
        self.db.backup()

    def post_refresh(self):
        self.log.info('post refresh')
        self.init_config()
        self.db.remove()
        self.db.init()
        self.db.init_config()

    def installed(self):
        return path.isfile(install_file)

    def configure(self):
        self.log.info('configure')
        if self.installed():
            self.upgrade()
        else:
            self.initialize()

    def upgrade(self):
        self.log.info('upgrade')
        self.db.restore()
        check_output([self.rails, 'db:migrate'], cwd=self.mastodon_dir)

    def initialize(self):
        self.log.info('initialize')

        self.log.info('creating database')
        self.db.execute('postgres', "ALTER USER {0} WITH PASSWORD '{1}';".format(DB_USER, DB_PASS))
        self.db.execute('postgres', "CREATE DATABASE {0} WITH OWNER={1};".format(DB_NAME, DB_USER))
        check_output([self.rails, 'db:setup'], cwd=self.mastodon_dir)
        check_output([self.rails, 'db:migrate'], cwd=self.mastodon_dir)
        with open(install_file, 'w') as f:
            f.write('installed\n')

    def prepare_storage(self):
        storage.init_storage(APP_NAME, USER_NAME)

    def on_domain_change(self):
        self.log.info('domain change')
        self.init_config()

    def backup_pre_stop(self):
        self.pre_refresh()

    def restore_pre_start(self):
        self.post_refresh()

    def restore_post_start(self):
        self.configure()
