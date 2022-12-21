local name = "mastodon";
local browser = "firefox";
local go = "1.18.5";
local postgresql = "15-bullseye";
local ruby = "3.0.4";
local python = "3.8-slim-buster";
local node = "16.19.0-bullseye-slim";
local mastodon = "4.0.2";

local build(arch, test_ui, dind) = [{
    kind: "pipeline",
    type: "docker",
    name: arch,
    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "version",
            image: "debian:buster-slim",
            commands: [
                "echo $DRONE_BUILD_NUMBER > version"
            ]
        },
	{
	    name: "download",
	    image: "alpine:3.17.0",
            commands: [
	        "./download.sh " + mastodon
            ]
	}, 
        {
            name: "ruby",
            image: "docker:" + dind,
            commands: [
                "./ruby/build.sh " + ruby
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "ruby test",
            image: "debian:buster-slim",
            commands: [
                "build/snap/ruby/bin/ruby.sh -e 'puts \"Hello\"'",
                "build/snap/ruby/current/bin/bundle version"
            ]
        },
        {
            name: "web",
            image: "node:" + node,
            commands: [
                "cd build/snap/ruby/mastodon",
                "apt update",
                "apt install -y python3-dev",
                "yarn install --pure-lockfile",
                "ls -la"
            ]
        },
        {
            name: "postgresql",
            image: "docker:" + dind,
            commands: [
                "./postgresql/build.sh " + postgresql
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "postgresql test",
            image: "debian:buster-slim",
            commands: [
                "./postgresql/test.sh"
            ]
        },
        {
            name: "python",
            image: "docker:" + dind,
            commands: [
                "./python/build.sh " + python
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "node",
            image: "docker:" + dind,
            commands: [
                "./node/build.sh " + node
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "node test",
            image: "debian:buster-slim",
            commands: [
                "./node/test.sh"
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "package",
            image: "debian:buster-slim",
            commands: [
                "VERSION=$(cat version)",
                "./package.sh " + name + " $VERSION "
            ]
        },
        {
            name: "test-integration-buster",
            image: "python:3.8-slim-buster",
            commands: [
              "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
              "cd integration",
              "./deps.sh",
              "py.test -x -s verify.py --distro=buster --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=" + name + ".buster.com --app="  + name + " --arch=" + arch
            ]
        }] +
        ( if test_ui then ([
        {
            name: "selenium-video",
            image: "selenium/video:ffmpeg-4.3.1-20220208",
            detach: true,
            environment: {
                DISPLAY_CONTAINER_NAME: "selenium",
                FILE_NAME: "video.mkv"
            },
            volumes: [
            {
                name: "shm",
                path: "/dev/shm"
            },
            {
                name: "videos",
                path: "/videos"
            }
        ]
       }] +
        [{
            name: "test-ui-" + mode,
            image: "python:3.8-slim-buster",
            commands: [
              "cd integration",
              "./deps.sh",
              "pip install -r requirements.txt",
              "py.test -x -s test-ui.py --distro=buster --ui-mode=" + mode + " --domain=buster.com --device-host=" + name + ".buster.com --app=" + name + " --browser=" + browser,
            ]
        } for mode in ["desktop", "mobile"] 
       ]
        +
       [
        {
            name: "test-upgrade",
            image: "python:3.8-slim-buster",
            commands: [
              "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
              "cd integration",
              "./deps.sh",
              "py.test -x -s test-upgrade.py --distro=buster --ui-mode=desktop --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=" + name + ".buster.com --app=" + name + " --browser=" + browser,
            ],
            privileged: true,
            volumes: [{
                name: "videos",
                path: "/videos"
            }]
        } ] +
        [{
            name: "test-ui-upgrade",
            image: "python:3.8-slim-buster",
            commands: [
              "cd integration",
              "./deps.sh",
              "pip install -r requirements.txt",
              "py.test -x -s test-ui.py --distro=buster --ui-mode=" + mode + " --domain=buster.com --device-host=" + name + ".buster.com --app=" + name + " --browser=" + browser,
            ]
        } for mode in ["desktop"] 
       ]) else [] ) + [
        {
            name: "upload",
            image: "debian:buster-slim",
            environment: {
                AWS_ACCESS_KEY_ID: {
                    from_secret: "AWS_ACCESS_KEY_ID"
                },
                AWS_SECRET_ACCESS_KEY: {
                    from_secret: "AWS_SECRET_ACCESS_KEY"
                }
            },
            commands: [
                "PACKAGE=$(cat package.name)",
                "apt update && apt install -y wget",
                "wget https://github.com/syncloud/snapd/releases/download/1/syncloud-release-" + arch + " -O release --progress=dot:giga",
                "chmod +x release",
                "./release publish -f $PACKAGE -b $DRONE_BRANCH"
            ],
            when: {
                branch: ["stable", "master"]
            }
        },
        {
            name: "artifact",
            image: "appleboy/drone-scp:1.6.4",
            settings: {
                host: {
                    from_secret: "artifact_host"
                },
                username: "artifact",
                key: {
                    from_secret: "artifact_key"
                },
                timeout: "2m",
                command_timeout: "2m",
                target: "/home/artifact/repo/" + name + "/${DRONE_BUILD_NUMBER}-" + arch ,
                source: "artifact/*",
                strip_components: 1
            },
            when: {
              status: [ "failure", "success" ]
            }
        }
        ],
        trigger: {
          event: [
            "push",
            "pull_request"
          ]
        },
        services: [
            {
                name: "docker",
                image: "docker:" + dind,
                privileged: true,
                volumes: [
                    {
                        name: "dockersock",
                        path: "/var/run"
                    }
                ]
            },
            {
                name: name + ".buster.com",
                image: "syncloud/platform-buster-" + arch + ":22.01",
                privileged: true,
                volumes: [
                    {
                        name: "dbus",
                        path: "/var/run/dbus"
                    },
                    {
                        name: "dev",
                        path: "/dev"
                    }
                ]
            }
        ] + ( if test_ui then [
            {
                name: "selenium",
                image: "selenium/standalone-" + browser + ":4.1.2-20220208",
                environment: {
                    SE_NODE_SESSION_TIMEOUT: "999999"
                },
                volumes: [{
                    name: "shm",
                    path: "/dev/shm"
                }]
            }
        ] else [] ),
        volumes: [
            {
                name: "dockersock",
                temp: {}
            },
            {
                name: "dbus",
                host: {
                    path: "/var/run/dbus"
                }
            },
            {
                name: "dev",
                host: {
                    path: "/dev"
                }
            },
            {
                name: "shm",
                temp: {}
            },
            {
                name: "videos",
                temp: {}
            }
        ]
    },
    {
         kind: "pipeline",
         type: "docker",
         name: "promote-" + arch,
         platform: {
             os: "linux",
             arch: arch
         },
         steps: [
         {
                 name: "promote",
                 image: "debian:buster-slim",
                 environment: {
                     AWS_ACCESS_KEY_ID: {
                         from_secret: "AWS_ACCESS_KEY_ID"
                     },
                     AWS_SECRET_ACCESS_KEY: {
                         from_secret: "AWS_SECRET_ACCESS_KEY"
                     }
                 },
                 commands: [
                   "apt update && apt install -y wget",
                   "wget https://github.com/syncloud/snapd/releases/download/1/syncloud-release-" + arch + " -O release --progress=dot:giga",
                   "chmod +x release",
                   "./release promote -n " + name + " -a $(dpkg --print-architecture)"
                 ]
           }
          ],
          trigger: {
           event: [
             "promote"
           ]
         }
     }
];

build("amd64", true, "20.10.21-dind") +
build("arm64", false, "19.03.8-dind") +
build("arm", false, "19.03.8-dind")
