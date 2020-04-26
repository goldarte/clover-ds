# clover-ds

Docker image for [Clover](coex.tech/clover) drone simulation with roscore, clover and px4 SITL services running inside.

This container includes:

* [ROS Melodic](http://wiki.ros.org/melodic)
* [px4 toolchain for simulation](https://dev.px4.io/v1.9.0/en/setup/dev_env.html)
* px4 sitl binary with version [v1.8.2-clever.10](https://github.com/CopterExpress/Firmware/releases/tag/v1.8.2-clever.10)
* [clover](https://github.com/CopterExpress/clever) ROS package
* [jMAVSim](https://github.com/PX4/jMAVSim) lightweight simulator
* [roscore](services/roscore.service) service
* [clover](services/clover.service) service
* [sitl](services/sitl.service) service
* [jmavsim](services/jmavsim.service) service

## Prepare

It is assumed that you have installed latest `docker` version. Instruction is [here](https://docs.docker.com/get-docker/).

Clone this repository and cd into it:

```cmd
git clone https://github.com/goldarte/clover-ds.git
cd <cloned repo>
```

## Run container for connecting to external simulator

Execute `run` bash script to run container with name and hostname `sim-1`:

```cmd
./run
```

Sitl service will listen UDP messages from external simulator (like [Gazebo](https://dev.px4.io/master/en/simulation/gazebo.html) or [Airsim](https://dev.px4.io/master/en/simulation/airsim.html)) on UDP port 14561.

## Run container with lightweight simulation inside

Execute `run` bash script with `--headless` option:

```cmd
./run --headless
```

Sitl service will connect to headless version of [jMAVSim](https://dev.px4.io/master/en/simulation/jmavsim.html) simulator with simple simulation of outdoor conditions.

## Configure

You can specify next options for `run` script:

```cmd
./run [options]

Options:
  -h --help         Print this message
  -i --id=ID        ID of simulated copter. Used as MAV_SYS_ID.
                    Container name and hostname are set to sim-<ID> (default: 1)
  -p --port=PORT    Initial UDP port (default: 14560)
                    UDP listening port for simulator data is set to <PORT>+<ID>
  --headless        Set this option to run lightweight jmavsim simulator directly in container
  --lat=LATITUDE    Set initial latitude (default: 55.703712)
  --lon=LONGITUDE   Set initial longitude (default: 37.724518)
  --dx=DX           Set dx shift in meters to East (default: 0)
  --dy=DY           Set dy shift in meters to North (default: 0)
```

> Each time you want to run new container it must have unique ID and UDP port for simulator data!

There will be 3 services running inside the container: roscore, clover, sitl. If you set `--headless` option, there will be running jmavsim service also.

You can manage running services inside the container using `systemctl` and watch their logs with `journalctl -u <service name>`. For example if you want to restart the service `clover`, just use `systemctl restart clover`.

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
