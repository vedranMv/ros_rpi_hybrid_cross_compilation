Hybrid cross-compilation for ROS-based projects for Raspberry Pi*
==================================
## *(and other linux-armhf platforms)

## Table of content
1. [Summary](#summary)
1. [Intro and motivation](#intro-and-motivation)
1. [Repository structure](#repository-structure)
1. [Requirements](#requirements)
1. [Preparing the host system](#preparing-the-host-system)
1. [Preparing the target system](#preparing-the-target-system)
1. [Cross-compiling ROS](#cross-compiling-ros)
1. [Cross-compiling ROS projects](#cross-compiling-ros-projects)
1. [Additional info](#additional-info)

## Summary
This project outlines an approach for docker-based cross-compiling environment, suitable for building ROS projects for armhf architecture``*`` on a system with a different architecture. The method proposed here can also be used to cross-compile _ROS comm_ and _ROS robot_ variants.

``*`` Other target architectures should work as long as they run linux, but they haven't been tested yet

## Intro and motivation
I recently started a project which I believe could produce a large code repository that I don't want to compile (and write) on the raspberry pi. Instead, I wanted to cross compile my code on a PC and move the executables to the Pi afterwards.

I was surprized realizing that there are no (simple) available solutions to achieve this. There is the [section on cross compiling on ROS web page](https://wiki.ros.org/ROS/CrossCompiling), but it mentions an abandoned _Eros stack_ which I couldn't setup. There are also some attempts on various webpages and forums, none of which offered a satisfying (simple, step-by-step user-friendly) solution:
* [How to cross-compile ROS for BeagleBoard-xM](https://answers.ros.org/question/9232/how-to-cross-compile-ros-for-beagleboard-xm-arm/)
* [Cross-compiling ROS2](https://index.ros.org/doc/ros2/Tutorials/Cross-compilation/)
* [Catkin - ROS CrossCompiling](https://answers.ros.org/question/208621/catkin-ros-crosscompiling/)
* [ROS indigo cross compile for ARM architecture](https://github.com/mktk1117/ROS_ARM_CROSSCOMPILE)
* [Cross-Compiling ROS Melodic on RaspberryPi 3B+ Problem](https://stackoverflow.com/questions/55081522/cross-compiling-ros-melodic-on-raspberrypi-3b-problem)

The last article on the list sparked an idea of a "hybrid" environment for cross compilation. All dependencies and libraries are resolved natively on target system and afterwards imported into the build server where all the muscle work (compilation & linking) takes place. It would go something like this:
1. Install dependencies on the target system same as if you were to do the compilation there
1. Create a docker container running build server on the host system
1. Import part of the target filesystem (e.g. raspbian) to build server
1. Create/import catkin workspace in build server
1. Use customized toolchain and gcc-linux-armhf (or compiler for your target system) to compile the workspace
1. Pack the compilation outcome and send it to the target system

## Repo structure

Here's a brief overview of flies in the repository and their significance

```
ros_rpi_hybrid_cross_compilation
    |
    ├- buildroot/  --Content copied into a shared folder
    |   ├- bin/  --Useful bash scripts
    |   ├- img_processing/  --Scripts for importing target filesystem
    |   |   ├- process_img.bash  --Wrapper script which runs everything else inside this folder
    |       └...
    |   ├- build.env  --Definition of environment variables for cross-compilation
    |   ├- toolchain.cmake  --Toolchain file for cross-compilation
    ├- profile/  --Customized bash profiles
    |   ├- profile  --/etc/profile patched to start ssh-agent
    |   └- .bashrc  --/root/.bashrc patched to source build.env file
    ├- ssh/  --SSH keys imported into the build server
    |   ├- buildserver_rsa
    |   ├- buildserver_rsa.pub
    |   └- known_hosts
    ├- Dockerfile  --Dockerfile for building a docker image of the build server
    ├- entrypoint.sh  --Entry point for docker container
    └- start-buildserver.sh  --Script that creates and starts a docker container
```

SSH keys are not important unless you plan to often connect to a remote server from the container (``ssh/`` folder is copied to ``/root/.ssh``)

## Requirements
1. Host computer with architecture & operating system that supports docker, preferably linux
    * On windows, get a linux-like terminal (e.g. cygwin) or install windows subsystem for linux
    * On Mac, I don't know :D 
1. Physical raspberry pi running raspbian or a QEMU-emulated raspberry pi (check [Additional info](#additional-info) section)
## Preparing the host system

Preparing the host system comes down to installing docker, pulling the image of the build server and finally, creating the container. 

1. Start by cloning this repository to your machine 
    ```bash
    user@host:~$ git clone https://github.com/vedranMv/ros_rpi_hybrid_cross_compilation
    ```

1. Then install docker: https://docs.docker.com/install/

1. Get the docker image of the build server, here you have two options:
    * Pull the existing image from https://hub.docker.com/r/vedranmv/buildserver by running:
    ```bash
    user@host:~$ docker pull vedranmv/buildserver:2.0
    ```
    *  **[OR]** Use a Dockerfile file supplied in the root of this repo to build an image of the build server
        1. Open the cloned repo
        1. Run 
    ```bash
    user@host:~$ /ros_rpi_hybrid_cross_compilation$ docker build -t vedranmv/buildserver:latest .
    ```

1. Select a folder on the host system which you want to share with docker. This will be the build directory, containing the workspace to be compiled, toolchain and compilation outcome. I used ``/usr/local/build`` folder on the host system which was mapped to the same folder inside the docker container. If you prefer different folder, change ``$WS`` variable inside ``buildroot/build.env`` file.

1. Start docker container with the command below. If everything went okay, there should be only container ID and name printed on the terminal. 
    ```bash
    user@host:~/ros_rpi_hybrid_cross_compilation$ ./start-buildserver.sh
    ```
1. Open the container terminal with
    ```bash
    user@host:~$ docker exec -ti <container_name> bash
    ```
1. Exit and stop the container in preparation for next step
    ```bash
    root@buildserver:~$ exit
    user@host:~$ docker stop <container_name>
    ```
## Preparing the target system

As the name hinted, this is a hybrid cross compilation which means that part of the work needs to be done on the target system as well. More precisely, collect all ROS dependencies and those of a project being compiling. It's tricky to do that directly on the host system, instead we install them on the target system first, and then copy them from there into the toolchain. First, ensure you have raspbian running, either natively or emulated (check [Additional info](#additional-info) for how to use emulated raspbian).

Once on the target system, follow the instructions in the [guide for installing ROS from source](https://wiki.ros.org/kinetic/Installation/Source) up until section _2.1.2 Resolving Dependencies_. There we have to slightly modify the command:
```bash
pi@raspberry:~/ros_catkin_ws$ rosdep install --from-paths src --ignore-src --rosdistro kinetic -y --os=debian:stretch
```
This will run for a while and install all required libraries for compiling ROS from source. To compile ROS on the target system, this would be fine and we could proceed with the instructions from the link above. For cross-compilation, however, there seems to be an issue with newer boost libraries which, for some reason``*``, cause the cross-compilation later on [to fail with error message](https://answers.ros.org/question/246227/librosconsoleso-undefined-reference-to-boostre_detail_106100cpp_regex_traits_implementation/):
```
.../librosconsole.so: undefined reference to `boost::re_detail_106200::cpp_regex_traits_implementation<char>::transform(char const, char const) const'
.../librosconsole.so: undefined reference to `boost::re_detail_106200::cpp_regex_traits_implementation<char>::transform_primary(char const, char const) const'
collect2: error: ld returned 1 exit status
```
``*``It seems like the cmake-related problem. Ubuntu 16.04 from build server comes with cmake-3.5 which is not compatible with boost-1.62. Rapsbian stretch, on the other hand, uses cmake-3.7. (Installing cmake-3.7 on build server doesn't resolve the issue)

To fix it, swap Boost 1.62, which is by default installed through rosdep, with the older version 1.58. So, on the target system do the following:
```bash
pi@raspberry:~$ sudo apt-get remove libboost-*-dev
pi@raspberry:~$ sudo apt-get install libboost*1.58-dev libboost-mpi-python1.58*
```

If you choose _ros_comm_ or _ros_robot_ variant, you can stop here as we can compile these versions of ROS on the build server. For other versions (desktop, desktop_full), the only way to go is to compile them directly on the target system. For native compilation, it's a good idea to use standard install path during compilation ``/opt/ros/<ros_version>``.

At the end of this step, your target system should have all dependencies installed for the selected ROS variant, and, if you compiled ROS on the target system, ROS installed in ``/opt/ros/<ros_version>``.

## Importing data into docker build server
Now we need to import & process the target filesystem. What we're doing here is copying all system libraries and include directories (and ROS, if exists). This is a bit tricky as almost all libraries on linux are symlinks and become invalid the moment you mount the SD-card with a filesystem to your PC. So, as a part of processing, we setup a _chroot_ on the root of the SD card and make a hard copy of all files. This converts all symlinks to their respective files. Step-by-step, the procedure goes:

1. In previous step, while setting up the host system, we copied ``img_processing/`` folder to our build directory ($WS) together with ``build.env``. Now we navigate there on the host system (not docker) and run ``process_img.bash`` with root privileges. This has to be run on the host computer directly because docker has no access to mounted drives.``*`` After the script has finished, you should see a ``piroot/`` folder appear in the $WS folder. Process can take a while.

```bash
~user@host$ source /path/to/build.env
~user@host$ cd $WS/img_processing
~user@host$ sudo process_img.bash /media/user/rootfs
Copying data from mounted directory...done
Prepring environment for chroot...done
Executing the script in chroot..../cp: cannot stat '/lib_orig/./cpp': No such file or directory
<a lot of "No such file" warnings>
done
Housekeeping...done
Your environment is now ready for crosscompiling
```

``*``If you don't like running this script outside docker, you could try manually copy the folders into the shared build directory and then run the script from within docker

## Cross-compiling ROS (comm & robot)

For now, only _ros_comm_ and _ros_robot_ variants can be built by this method. In _ros_robot_, _collada_urdf_ package stubbornly fails to compile with errors about missing include files. Fixing include files yields an error about pkg-config. As of this writing, the only solution is to skip building _collada_urdf_.


* _ros_comm_
    ```bash
    root@buildserver:~$ cd $WS
    root@buildserver:~$ mkdir ros_cross_comm
    root@buildserver:~$ cd ros_cross_comm
    root@buildserver:~/ros_cross_comm$ rosinstall_generator ros_comm --rosdistro kinetic --deps --wet-only --tar > kinetic-ros_comm-wet.rosinstall
    root@buildserver:~/ros_cross_comm$ wstool init -j8 src kinetic-ros_comm-wet.rosinstall
    ```

* _ros_robot_
    ```bash
    root@buildserver:~$ cd $WS
    root@buildserver:~$ mkdir ros_cross_robot
    root@buildserver:~$ cd ros_cross_robot
    root@buildserver:~/ros_cross_robot$ rosinstall_generator robot --rosdistro kinetic --deps --wet-only --tar > kinetic-robot-wet.rosinstall
    root@buildserver:~/ros_cross_robot$ wstool init -j8 src kinetic-robot-wet.rosinstall
    root@buildserver:~/ros_cross_robot$ mv src/collada_urdf .
    ```
And in either case finish with:

```bash
root@buildserver:~/ros_cross_xxx$ ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$WS/toolchain.cmake -DCATKIN_SKIP_TESTING=ON
```

The command above is similar to the one used during normal ROS installation but with addition of a custom toolchain file. This file tell cmake which compiler to use and where all the libraries and include files are located at. In addition, building unit test has to be disabled (``-DCATKIN_SKIP_TESTING=ON``) because gtest and other required packages are not installed so the build fails.

Having ROS compiled, symlink the install directory to the same folder where the ROS in on the target system. By default, ``/opt/ros/<ros_version>`` and source the ROS environment (check next section for how to do that).

Quick sanity check at this point confirms that the cross-compiler is indeed working as intended:
```bash
root@buildserver:~$ file /opt/ros/kinetic/lib/ibcpp_common.so 
libcpp_common.so: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, BuildID[sha1]=b69cc700533a051b6efa2e8d6b34cc5f370c04ff, not stripped
```


## Cross-compiling ROS projects
Before continuing, ensure that ROS install directory on the build server is the same as the one on the target system. This is important due to the nature of catkin workspaces overlaying:
* If you've cross-compiled ROS in previous step, symlink the install folder and source the environment:
    ```bash
    root@buildserver:~$ mkdir /opt/ros
    root@buildserver:~$ ln -s $WS/ros_cross_robot /opt/ros/kinetic
    root@buildserver:~$ source /opt/ros/kinetic/setup.bash
    ```
* If you've imported precompiled ROS from the target system (usually installed in /opt/ros/...), create symlink to it and source the environment:
    ```bash
    root@buildserver:~$ mkdir /opt/ros
    root@buildserver:~$ ln -s $WS/piroot/opt/ros/kinetic /opt/ros/kinetic
    root@buildserver:~$ source /opt/ros/kinetic/setup.bash
    ```

From this point, we follow the usual procedure for making a catkin workspace, putting the code in it and compiling the workspace. Again, toolchain file needs to be specified in order to make cmake aware of the compiler and libraries we want to use:

```bash
root@buildserver:~$ cd $WS
root@buildserver:~$ mkdir catkin_project_ws
root@buildserver:~$ cd catkin_project_ws

root@buildserver:~catkin_project_ws$ mkdir src
root@buildserver:~catkin_project_ws/src$ cd src
root@buildserver:~catkin_project_ws/src$ catkin_init_workspace
Creating symlink "/usr/local/build/catkin_project_ws/src/CMakeLists.txt" pointing to "/opt/ros/kinetic/share/catkin/cmake/toplevel.cmake"

root@buildserver:~catkin_project_ws/src$ cd ..
root@buildserver:~catkin_project_ws$ catkin_make_isolated --install -DCMAKE_TOOLCHAIN_FILE=$WS/toolchain.cmake 
```
Once the compilation is done, zip the _install_isolated_ folder and unpack it on the target system. If the ROS has been cross-compiled as well, copy _install_isolated_ folder from _ros_cross*_ workspace to ``/opt/ros/<ros version>`` on the target system and source the environment there.

## Additional info


### QEMU emulation
_TODO_


## Things that don't work
* compiling _collada_urdf_ package from _ros_robot_ variant
* compile desktop - fails when linking some graphical libraries that require QT executables in the linking process
* use multiarch support in dpkg to install ros for armhf directly in docker with all of its dependencies

