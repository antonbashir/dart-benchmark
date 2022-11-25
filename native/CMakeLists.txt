cmake_minimum_required(VERSION 2.8)

project(benchmark_library C CXX)

set(CMAKE_REQUIRED_DEFINITIONS "-D_GNU_SOURCE")

file(GLOB TEST_SOURCES
	test/**.h
	test/**.c
)

add_library(benchmark SHARED ${TEST_SOURCES})

set_target_properties(benchmark PROPERTIES COMPILE_FLAGS "-fPIC")

add_custom_command(TARGET benchmark POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:benchmark> ${CMAKE_CURRENT_SOURCE_DIR}/../dart/bin
)
