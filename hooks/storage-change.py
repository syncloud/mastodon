import subprocess

print(subprocess.check_output('snap run mastodon.storage-change', shell=True))
