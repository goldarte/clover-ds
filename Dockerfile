# Use px4 base image for simulation
FROM px4io/px4-dev-ros-melodic

# Use a non-privileged user to make ROS happy
ENV ROSUSER="user"
WORKDIR /home/$ROSUSER
RUN echo "$ROSUSER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ROSUSER

# Install systemd service manager
ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN sed -i 's/# deb/deb/g' /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y systemd systemd-sysv nano \
    && apt-get clean

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
	&& git clone --depth 1 https://github.com/CopterExpress/clever \
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
	&& make posix_sitl_default \
	&& mkdir -p /home/$ROSUSER/sitl/configs \
	&& cp /home/$ROSUSER/Firmware/build/posix_sitl_default/px4 /home/$ROSUSER/sitl \
	&& cp -r /home/$ROSUSER/Firmware/ROMFS /home/$ROSUSER/sitl \
	&& rm -rf /home/$ROSUSER/Firmware

# Copy data from repo
COPY launch/clover.launch /home/$ROSUSER/catkin_ws/src/clever/clover/launch
COPY sitl/configs /home/$ROSUSER/sitl/configs/

# Source environment variables
USER root
COPY --chown=user:root scripts /scripts/

RUN echo "source /opt/ros/melodic/setup.bash" >> /root/.bashrc \
	&& echo "source /home/${ROSUSER}/catkin_ws/devel/setup.bash" >> /root/.bashrc

# Copy services from repo
COPY services/* /lib/systemd/system/
RUN systemctl enable roscore \
	&& systemctl enable clover \
	&& systemctl enable sitl

# Expose ROS and local Mavlink ports
EXPOSE 14556/udp 14557/udp 14560/udp 11311 8080 8081 57575

VOLUME [ "/sys/fs/cgroup" ]

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/sbin/init"]

