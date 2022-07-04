find_package(Catch2 REQUIRED)

include(CTest)
include(Catch)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
  target_compile_options(${PROJECT_NAME} INTERFACE --coverage -O0 -g)
  target_link_libraries(${PROJECT_NAME} INTERFACE --coverage)
endif()

# 1. see conan for full set up, read CI section in conan dcs
# 2. write CI

# add_test( ... )
# ...
# set_tests_properties ( ... )

add_executable(catch2_main config.cpp)

add_subdirectory(hello_world)
# ...

target_link_libraries(catch2_main
  PRIVATE
    Catch2::Catch2
    hello_world_TEST
  # ...  
)