# Target system name
SET(CMAKE_SYSTEM_NAME Linux)

#  On systems that support uname, this variable is set to the output of uname -r
#SET(CMAKE_HOST_SYSTEM_VERSION )

# Specify location of the cross compiler
SET(CMAKE_C_COMPILER /usr/bin/arm-linux-gnueabihf-gcc)
SET(CMAKE_CXX_COMPILER /usr/bin/arm-linux-gnueabihf-g++)

# More verbose output (useful for troubleshooting)
#SET(CMAKE_VERBOSE_MAKEFILE TRUE)

# Disable tests (causes issues in cross compiling)
#SET(CATKIN_ENABLE_TESTING OFF)
#SET(CATKIN_SKIP_TESTING ON)

# Fixes issue when compiling collada_parser
include_directories(${PIROOT}/usr/include ${PIROOT}/usr/include/collada-dom2.4 ${PIROOT}/usr/include/collada-dom2.4/1.5)

# Workaround to get Boost properly detected
SET(DBoost_NO_BOOST_CMAKE TRUE)
SET(BOOST_ROOT ${PIROOT}/usr)
SET(BOOST_INCLUDEDIR ${PIROOT}/usr/include)
SET(BOOST_LIBRARYDIR ${PIROOT}/usr/lib/arm-linux-gnueabihf)
SET(Boost_NO_SYSTEM_PATHS TRUE)

# Manually specify lib directories
SET(FLAGS "-Wl,-rpath-link,${PIROOT}/lib -Wl,-rpath-link,${PIROOT}/usr/lib -Wl,-rpath-link,${PIROOT}/usr/lib/arm-linux-gnueabihf -Wl,-rpath-link,/usr/arm-linux-gnueabihf")

# Tell Cmake where to look for target-specific libraries and include files
SET(CMAKE_SYSROOT ${PIROOT})
SET(CMAKE_FIND_ROOT_PATH ${PIROOT})

# Prevent cmake for using executables from the target system
# (they can't run because of incompatible architecture)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Look for libraries and include files in the target filesystem only
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

