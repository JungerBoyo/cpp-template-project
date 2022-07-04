cmake_minimum_required(VERSION 3.20)

set(CMAKE_CXX_STANDARD 20)

# ! configure with ninja as generator

### conan set up ###
find_program(CONAN conan)
if(CONAN)
  execute_process(COMMAND conan install ${CMAKE_CURRENT_SOURCE_DIR} 
    --install-folder ${CMAKE_BINARY_DIR}    # install into cmake build folder
    --build missing                         # build only missing packages
  )
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})
  list(APPEND CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})
else()
  message(FATAL_ERROR "to build, install conan first")
endif()
####################

### static checks options ###
option(STATIC_ANALYSIS "turn on static analysis" OFF)
if(STATIC_ANALYSIS)
  find_program(CLANGTIDY clang-tidy) ### [~!~ do not use PCH headers with clang-tidy without clang ~!~]
  if(CLANGTIDY)
    set(CMAKE_CXX_CLANG_TIDY ${CLANGTIDY} -extra-arg=-Wno-unknown-warning-option)
    option(WARNINGS_AS_ERRORS "treat warnings as errors" OFF) 
    if(WARNINGS_AS_ERRORS)
      list(APPEND CMAKE_CXX_CLANG_TIDY -warnings-as-errors=*)
    endif()
    set(CMAKE_C_CLANG_TIDY ${CMAKE_CXX_CLANG_TIDY})
  else()
    message(WARNING "clang-tidy wasn't found")
  endif()
endif()
#############################

### sanitizers options ###
option(ENABLE_SANITIZERS "have to be set to ON in order to uses any sanitizers" OFF)
if(ENABLE_SANITIZERS)
  option(ENABLE_SANITIZER_ADDRESS            "" OFF)
  option(ENABLE_SANITIZER_LEAK               "" OFF)
  option(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR "" OFF)
  option(ENABLE_SANITIZER_THREAD             "" OFF)
  option(ENABLE_SANITIZER_MEMORY             "" OFF)
  set(SANITIZERS "")      
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_IRD MATCHES ".*Clang")
    if(${ENABLE_SANITIZER_ADDRESS})
      list(APPEND SANITIZERS "address")
    endif()

    if(${ENABLE_SANITIZER_LEAK})
      list(APPEND SANITIZERS "leak")
    endif()

    if(${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR})
      list(APPEND SANITIZERS "undefined")
    endif()

    if(${ENABLE_SANITIZER_THREAD})
      if("address" IN_LIST SANITIZERS OR "leak" IN_LIST SANITIZERS)
        message(WARNING "Thread sanitizer does not work with Address and Leak sanitizer enabled")
      else()
        list(APPEND SANITIZERS "thread")
      endif()
    endif()

    if(${ENABLE_SANITIZER_MEMORY} AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
        message(
          WARNING
            "Memory sanitizer requires all the code (including libc++) to be MSan-instrumented otherwise it reports false positives"
        )
        if("address" IN_LIST SANITIZERS
           OR "thread" IN_LIST SANITIZERS
           OR "leak" IN_LIST SANITIZERS)
          message(WARNING "Memory sanitizer does not work with Address, Thread and Leak sanitizer enabled")
        else()
          list(APPEND SANITIZERS "memory")
        endif()
      endif()
  elseif(MSVC)
    if(${ENABLE_SANITIZER_ADDRESS})
      list(APPEND SANITIZERS "address")
    endif()
    if(${ENABLE_SANITIZER_LEAK} OR ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR} OR ${ENABLE_SANITIZER_THREAD} OR ${ENABLE_SANITIZER_MEMORY})
      message(WARNING "MSVC only supports address sanitizer")
    endif()
  endif()

  list(JOIN SANITIZERS "," LIST_OF_SANITIZERS)
  if(LIST_OF_SANITIZERS AND NOT ${LIST_OF_SANITIZERS} STREQUAL "")
    if(MSVC)
      target_compile_options(${PROJECT_NAME} INTERFACE -fsanitize=${LIST_OF_SANITIZERS})
      target_link_options(${PROJECT_NAME} INTERFACE -fsanitize=${LIST_OF_SANITIZERS})
    else()
      string(FIND "$ENV{PATH}" "$ENV{VSINSTALLDIR}" index_of_vs_install_dir)
      if("${index_of_vs_install_dir}" STREQUAL "-1")
        message(
          SEND_ERROR
            "Using MSVC sanitizers requires setting the MSVC environment before building the project. Please manually open the MSVC command prompt and rebuild the project."
        )
      endif()
      target_compile_options(${project_name} INTERFACE /fsanitize=${LIST_OF_SANITIZERS} /Zi /INCREMENTAL:NO)
      target_link_options(${project_name} INTERFACE /INCREMENTAL:NO)
    endif()
  endif()
endif()
##########################

### set up cache ###
option(ENABLE_CCACHE "enable ccache if available" OFF)
if(ENABLE_CCACHE)
  find_program(CCACHE ccache)
  if(CCACHE)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  else() 
    message(WARNING "ccache isn't installed or couldn't be found")
  endif()
endif()
####################

# no compiler specific extensions #
set(CMAKE_CXX_EXTENSIONS OFF)

### set up project metadata ###
project(template
  VERSION 0.0.1
  DESCRIPTION "C++ template project set up with general structure, tests (catch2), tools and CI"
  HOMEPAGE_URL "https://github.com/JungerBoyo/cpp-template-project"
  LANGUAGES C CXX
)
set(GIT_SHA "Unknown" CACHE STRING "SHA of this build")
set(SUBSTRING "${GIT_SHA}" 0 8 GIT_SHORTENED_SHA)
###############################

### targets ###
add_subdirectory(config)
add_subdirectory(include)
add_subdirectory(src)
###############

### MSVC specific ###
include(cmake/utils.cmake)
if(MSVC)
  set(all_targets)
  get_all_targets(all_targets ${CMAKE_CURRENT_SOURCE_DIR})
  set_target_properties(${all_targets} PROPERTIES VS_DEBUGGER_ENVIRONMENT "PATH=$(VC_ExecutablePath_x64);%PATH%")
endif()
set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})
#####################

### testing ###
option(ENABLE_TESTS "enable tests for this build" OFF)
if(ENABLE_TESTS)
  enable_testing()
  add_subdirectory(test)
endif()
###############

set(CPACK_PACKAGE_FILE_NAME 
  "${PROJECT_NAME}-${CMAKE_PROJECT_VERSION}-${GIT_SHORT_SHA}-${CMAKE_SYSTEM_NAME}-${CMAKE_BUILD_TYPE}-${CMAKE_CXX_COMPILER_ID}-${CMAKE_CXX_COMPILER_VERSION}"
)
include(CPack)