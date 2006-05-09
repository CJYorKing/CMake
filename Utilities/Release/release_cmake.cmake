set(CVSROOT ":pserver:anonymous@www.cmake.org:/cvsroot/CMake")
get_filename_component(SCRIPT_PATH "${CMAKE_CURRENT_LIST_FILE}" PATH)

if(DEFINED EXTRA_COPY)
  set(HAS_EXTRA_COPY 1)
endif(DEFINED EXTRA_COPY)
if(NOT DEFINED CMAKE_RELEASE_DIRECTORY)
  set(CMAKE_RELEASE_DIRECTORY "~/CMakeReleaseDirectory")
endif(NOT DEFINED CMAKE_RELEASE_DIRECTORY)
if(NOT DEFINED FINAL_PATH )
  set(FINAL_PATH ${CMAKE_RELEASE_DIRECTORY}/${CMAKE_VERSION}-build)
endif(NOT DEFINED FINAL_PATH )
if(NOT DEFINED SCRIPT_NAME)
  set(SCRIPT_NAME "${HOST}")
endif(NOT DEFINED SCRIPT_NAME)
if(NOT DEFINED MAKE_PROGRAM)
  message(FATAL_ERROR "MAKE_PROGRAM must be set")
endif(NOT DEFINED MAKE_PROGRAM)
if(NOT DEFINED MAKE)
  set(MAKE "${MAKE_PROGRAM}")
endif(NOT DEFINED MAKE)
if(NOT DEFINED RUN_SHELL)
  set(RUN_SHELL "/bin/sh")
endif(NOT DEFINED RUN_SHELL)
if(NOT DEFINED INSTALLER_SUFFIX)
  set(INSTALLER_SUFFIX "*.sh")
endif(NOT DEFINED INSTALLER_SUFFIX)
if(NOT DEFINED PROCESSORS)
  set(PROCESSORS 1)
endif(NOT DEFINED PROCESSORS)
if(NOT DEFINED CMAKE_VERSION)
  message(FATAL_ERROR "CMAKE_VERSION not defined")
endif(NOT DEFINED CMAKE_VERSION)
if(NOT DEFINED CVS_COMMAND)
  set(CVS_COMMAND cvs)
endif(NOT DEFINED CVS_COMMAND)

if("${CMAKE_VERSION}" STREQUAL "CVS")
  set( CMAKE_CHECKOUT "${CVS_COMMAND} -q -z3 -d ${CVSROOT} export -D now ")
  set( CMAKE_VERSION "CurrentCVS")
else("${CMAKE_VERSION}" STREQUAL "CVS")
  set( CMAKE_CHECKOUT "${CVS_COMMAND} -q -z3 -d ${CVSROOT} export -r ${CMAKE_VERSION} ")
endif("${CMAKE_VERSION}" STREQUAL "CVS")

if(NOT HOST)
  message(FATAL_ERROR "HOST must be specified with -DHOST=host")
endif(NOT HOST)
if(NOT DEFINED MAKE)
  message(FATAL_ERROR "MAKE must be specified with -DMAKE=\"make -j2\"")
endif(NOT DEFINED MAKE)
  
message("Creating CMake release ${CMAKE_VERSION} on ${HOST} with parallel = ${PROCESSORS}")

# define a macro to run a remote command
macro(remote_command comment command)
  message("${comment}")
  if(${ARGC} GREATER 2)
    message("ssh ${HOST} ${EXTRA_HOP} ${command}")
    execute_process(COMMAND ssh ${HOST} ${EXTRA_HOP} ${command} RESULT_VARIABLE result INPUT_FILE ${ARGV2})
  else(${ARGC} GREATER 2)
    message("ssh ${HOST} ${EXTRA_HOP} ${command}") 
    execute_process(COMMAND ssh ${HOST} ${EXTRA_HOP} ${command} RESULT_VARIABLE result) 
  endif(${ARGC} GREATER 2)
  if(${result} GREATER 0)
    message(FATAL_ERROR "Error running command: ${command}, return value = ${result}")
  endif(${result} GREATER 0)
endmacro(remote_command)

# set this so configure file will work from script mode
set(CMAKE_BACKWARDS_COMPATIBILITY 2.4)
# create the script specific for the given host
set(SCRIPT_FILE release_cmake-${SCRIPT_NAME}.sh)
configure_file(${SCRIPT_PATH}/release_cmake.sh.in ${SCRIPT_FILE} @ONLY)

# run the script by starting a shell on the remote machine
# then using the script file as input to the shell
remote_command("run release_cmake-${HOST}.sh on server"
  "${RUN_SHELL}" ${SCRIPT_FILE})

message("copy the .gz file back from the machine")
message("scp ${HOST}:${FINAL_PATH}/*.gz .")
execute_process(COMMAND scp ${HOST}:${FINAL_PATH}/*.gz .
  RESULT_VARIABLE result) 

message("copy the ${INSTALLER_SUFFIX} file back from the machine")
message("scp ${HOST}:${FINAL_PATH}/${INSTALLER_SUFFIX} .")
execute_process(COMMAND scp ${HOST}:${FINAL_PATH}/${INSTALLER_SUFFIX} .
  RESULT_VARIABLE result) 

