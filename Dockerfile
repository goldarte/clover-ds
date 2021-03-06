# Use px4 base image for simulation
FROM px4io/px4-dev-ros-melodic
ENV container=docker

# Use a non-privileged user to make ROS happy
ENV ROSUSER="user"
WORKDIR /home/$ROSUSER
RUN echo "$ROSUSER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ROSUSER

# Set environment
ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
RUN sed -i 's/# deb/deb/g' /etc/apt/sources.list

# Install software
RUN apt-get update \
    && apt-get install -y systemd systemd-sysv nano openjdk-8-jdk \
    && apt-get clean

# Change java version to 8:
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

# Set up systemd service manager
RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*

# Prepare environment
USER $ROSUSER
RUN rosdep update

# Clone clever
RUN mkdir -p /home/$ROSUSER/catkin_ws/src \
	&& cd /home/$ROSUSER/catkin_ws/src \
	&& git clone --depth 1 https://github.com/goldarte/clever -b target-system-id \
	&& git clone --depth 1 https://github.com/CopterExpress/ros_led \
	&& ls /home/$ROSUSER/catkin_ws/src

# Install clever
RUN cd /home/$ROSUSER/catkin_ws \
	&& rosdep install -y --from-paths src --ignore-src -r \
	&& /bin/bash -c '. /opt/ros/melodic/setup.bash; \
	cd /home/${ROSUSER}/catkin_ws; \
	catkin_make; \
	. devel/setup.bash' \
	&& cd /home/$ROSUSER/catkin_ws/src/clever/clover/launch \
	&& mv clover.launch clover-example.launch \
	&& sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Clone and build PX4 firmware
RUN git clone --depth 1 https://github.com/CopterExpress/Firmware -b v1.8.2-clever.10 /home/$ROSUSER/Firmware \
	&& cd /home/$ROSUSER/Firmware \
	&& make posix_sitl_default

# Copy built files
RUN mkdir -p /home/$ROSUSER/sitl/configs \
	&& cp /home/$ROSUSER/Firmware/build/posix_sitl_default/px4 /home/$ROSUSER/sitl \
	&& cp -r /home/$ROSUSER/Firmware/ROMFS /home/$ROSUSER/sitl \
	&& cp -r /home/$ROSUSER/Firmware/posix-configs /home/$ROSUSER/sitl \
	&& cp -r /home/$ROSUSER/Firmware/test_data /home/$ROSUSER/sitl \
	&& rm -rf /home/$ROSUSER/Firmware

# Clone and build jMAVsim
RUN git clone --depth 1 https://github.com/PX4/jMAVSim /home/$ROSUSER/jMAVSim \
	&& cd /home/$ROSUSER/jMAVSim \
	&& git submodule update --init --recursive \
	&& ant create_run_jar copy_res

USER root

# Install required python libs
RUN pip install geographiclib

# Copy data from repo
COPY --chown=user:root launch/clover.launch /home/$ROSUSER/catkin_ws/src/clever/clover/launch
COPY --chown=user:root sitl/configs /home/$ROSUSER/sitl/configs/
COPY --chown=user:root scripts /scripts/

# Source environment variables
RUN echo "source /opt/ros/melodic/setup.bash" >> /root/.bashrc \
	&& echo "source /home/${ROSUSER}/catkin_ws/devel/setup.bash" >> /root/.bashrc

# Copy services from repo and enable them
COPY services/* /lib/systemd/system/
RUN systemctl enable roscore \
	&& systemctl enable clover \
	&& systemctl enable sitl \
	&& systemctl enable jmavsim

# Expose ROS and local Mavlink ports
EXPOSE 14556/udp 14557/udp 14560/udp 11311 8080 8081 57575

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/sbin/init"]

