cmake_minimum_required(VERSION 3.4.1)

# now build app's shared lib
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")

add_library(phoslib SHARED
            android_glue.cpp phos.cpp sonne16.cpp)

# add lib dependencies
target_link_libraries(phoslib
                      android
                      log 
                      EGL
                      GLESv3)

