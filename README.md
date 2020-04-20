# clover-ds

Clover docker image with roscore, clever and sitl services running inside.

This container includes:

* [px4 toolchain for simulation](https://dev.px4.io/v1.9.0/en/setup/dev_env.html)
* px4 sitl binary with version [v1.8.2-clever.10](https://github.com/CopterExpress/Firmware/releases/tag/v1.8.2-clever.10)
* [ROS Melodic](http://wiki.ros.org/melodic)
* [clover](https://github.com/CopterExpress/clever) ROS package
* [roscore](services/roscore.service) service
* [clover](services/clover.service) service
* [sitl](services/sitl.service) service

## Running

It is assumed that you have installed latest `docker` version. Instruction is [here](https://docs.docker.com/get-docker/).

Clone this repository and cd into it

```cmd
git clone https://github.com/goldarte/clover-ds.git
cd <cloned repo>
```

Execute this command to run container with name and hostname `sim`:

```cmd
docker run \
    -it \
    --rm \
    --name sim-1 \
    --hostname sim-1 \
    --tmpfs /tmp \
    --tmpfs /run \
    --tmpfs /run/lock \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -p 14561:14560/udp \
    goldarte/clover-ds
```

Or simple execute `run` bash script to run container with name and hostname `sim-1`.

```cmd
./run
```

There will be 3 services running inside the container: roscore, clover and sitl. Sitl service will listen UDP messages from external simulator (like Gazebo or Airsim) on UDP port 14561.

You can manage them using `systemctl` and watch their logs with `journalctl -u <service name>`. For example if you want to restart the service `clover`, just use `systemctl restart clover`.

If you want to run more copies of this container you can specify options for `run` script:

```cmd
./run [options]
Options:
    -h --help       Print this message
    -i --id=ID      Set container name and hostname to sim-<id> (default: 1)
    -p --port=PORT  Set UDP listening port for simulator data (default: 14601)

```

> Each time you want to run new container it must have UDP port for simulator data that differs from the UDP ports for simulator data of the other running containers!

If you want to open new terminal session in working container, use following command:

```cmd
docker exec -it <container name> bash
```

To stop or kill containers you can use

```cmd
docker stop <container name>
docker kill <container name>
```

To get information about running containers you can use

```cmd
docker ps
```
