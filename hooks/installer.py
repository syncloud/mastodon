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
PSQL_PORT = 5434
DB_USER = APP_NAME
DB_PASS = APP_NAME
DB_NAME = APP_NAME

logger.init(logging.DEBUG, console=True, line_format='%(message)s')



class Installer:
    def __init__(self):
        self.app_dir = paths.get_app_dir(APP_NAME)
        self.common_dir = paths.get_data_dir(APP_NAME)
        self.data_dir = join('/var/snap', APP_NAME, 'current')
        self.log = logger.get_logger(APP_NAME)
        self.config_dir = join(self.data_dir, 'config')
        self.db = Database(self.app_dir, self.data_dir, self.config_dir, join(self.app_dir, PSQL_PATH), DB_USER, PSQL_PORT)
        self.mastodon_dir = join(self.app_dir, 'ruby', 'mastodon')
        self.rails = join(self.mastodon_dir, 'bin', 'rails')
        self.install_file = join(self.common_dir, 'installed')
        environ['RAILS_ENV'] = 'production'

    def init_config(self):
        linux.useradd(USER_NAME)

        app_config_dir = join(self.app_dir, 'config')
        fs.makepath(join(self.data_dir, 'redis'))
        fs.makepath(join(self.data_dir, 'nginx'))
        fs.makepath(join(self.data_dir, 'nginx', 'cache'))

        storage_dir = storage.init_storage(APP_NAME, USER_NAME)
        variables = {
            'app_dir': self.app_dir,
            'common_dir': self.common_dir,
            'database_dir': self.db.database_dir,
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
        self.log_common('before.install')
        self.init_config()
        self.db.init()
        self.db.init_config()
        self.log_common('after.install')

    def pre_refresh(self):
        self.db.backup()

    def post_refresh(self):
        self.log.info('post refresh')
        self.init_config()
        self.db.remove()
        self.db.init()
        self.db.init_config()

    def installed(self):
        return path.isfile(self.install_file)

    def configure(self):
        self.log_common('before.configure')
        self.log.info('configure')
        if self.installed():
            self.upgrade()
        else:
            self.initialize()
        self.log_common('after.configure')

    def upgrade(self):
        self.log.info('upgrade')
        self.db.restore()
        check_output([self.rails, 'db:migrate'], cwd=self.mastodon_dir)
        self.update_db_version()

    def initialize(self):
        self.log.info('initialize')

        self.db.execute('postgres', "ALTER USER {0} WITH PASSWORD '{1}';".format(DB_USER, DB_PASS))
        check_output([self.rails, 'db:setup'], cwd=self.mastodon_dir)
        check_output([self.rails, 'db:migrate'], cwd=self.mastodon_dir)
        self.update_db_version()
        with open(self.install_file, 'w') as f:
            f.write('installed\n')

    def update_db_version(self):
        shutil.copy(join(self.app_dir, 'version'), self.data_dir)

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

    def log_common(self, name):
        with open(join(self.common_dir, '{0}.log'.format(name)), 'w') as f:
            f.write(str(check_output('ls -la', cwd=self.common_dir, shell=True)))
