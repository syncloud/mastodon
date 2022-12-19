import os
import json
from os.path import dirname, join
from subprocess import check_output

import pytest
import requests
from bs4 import BeautifulSoup
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install, wait_for_installer
from requests.packages.urllib3.exceptions import InsecureRequestWarning

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud'

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


@pytest.fixture(scope="session")
def module_setup(request, data_dir, platform_data_dir, app_dir, device, artifact_dir):
    def module_teardown():
        platform_log_dir = join(artifact_dir, 'platform')
        os.mkdir(platform_log_dir)
        device.scp_from_device('{0}/log/*'.format(platform_data_dir), platform_log_dir)

        device.run_ssh('ls -la {0}'.format(data_dir), throw=False)

        device.run_ssh('top -bn 1 -w 500 -c > {0}/top.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ps auxfw > {0}/ps.log'.format(TMP_DIR), throw=False)
        device.run_ssh('systemctl status snap.mastodon.* > {0}/mastodon.status.log'.format(TMP_DIR), throw=False)
        device.run_ssh('netstat -nlp > {0}/netstat.log'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl | tail -500 > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('tail -500 /var/log/syslog > {0}/syslog.log'.format(TMP_DIR), throw=False)
        device.run_ssh('tail -500 /var/log/messages > {0}/messages.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap > {0}/snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap/mastodon > {0}/snap.mastodon.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap > {0}/var.snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/mastodon > {0}/var.snap.mastodon.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/mastodon/common > {0}/var.snap.mastodon.common.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /data > {0}/data.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /data/mastodon > {0}/data.mastodon.ls.log'.format(TMP_DIR), throw=False)

        app_log_dir = join(artifact_dir, 'app')
        device.scp_from_device('{0}/log/*.log'.format(data_dir), app_log_dir)
        device.scp_from_device('{0}/*.log'.format(TMP_DIR), app_log_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, device, app, domain, device_host, artifact_dir):
    add_host_alias(app, device_host, domain)
    device.run_ssh('date', retries=100, throw=True)
    device.run_ssh('mkdir {0}'.format(TMP_DIR), throw=False)
    app_log_dir = join(artifact_dir, 'app')
    os.mkdir(app_log_dir)


def test_activate_device(device):
    response = device.activate_custom()
    assert response.status_code == 200, response.text


def test_install(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_storage_dir(device):
    device.run_ssh('ls -la /data/mastodon')


def test_psql(device):
    device.run_ssh("snap run mastodon.psql -U mastodon -d postgres -c '\\l'")


def test_storage_change_event(device):
    device.run_ssh('snap run mastodon.storage-change > {0}/storage-change.log'.format(TMP_DIR))


def test_access_change_event(device):
    device.run_ssh('snap run mastodon.access-change > {0}/access-change.log'.format(TMP_DIR))


def test_backup_restore(device, artifact_dir):
    app_log_dir = join(artifact_dir, 'app')
    device.run_ssh("snap run platform.cli backup create mastodon")
    response = device.run_ssh("snap run platform.cli backup list")
    open('{0}/cli.backup.list.json'.format(app_log_dir), 'w').write(response)
    print(response)
    backup = json.loads(response)[0]
    device.run_ssh('tar tvf {0}/{1}'.format(backup['path'], backup['file']))
    device.run_ssh("snap run platform.cli backup restore {0}".format(backup['file']))


def test_reinstall(app_archive_path, app_domain, device_password):
    local_install(app_domain, device_password, app_archive_path)
