find_package(fmt REQUIRED)

add_library(hello_world_IMPL STATIC hello_world.cpp)
target_link_libraries(hello_world_IMPL
  PRIVATE
    fmt::fmt
  PUBLIC  
    hello_world_INC
)