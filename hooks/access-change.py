import subprocess

print(subprocess.check_output('snap run mastodon.access-change', shell=True))

