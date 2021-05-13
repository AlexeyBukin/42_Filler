cmake_minimum_required(VERSION 3.10)

project(kcharla.filler)

set(CMAKE_C_STANDARD  90)
set(CMAKE_C_STANDARD_REQUIRED True)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2")

# find src -type f -name '*.c' -not -path "src/libft/*" | sed 'N;N;s/\n/ /g' | column -t
set(${PROJECT_NAME}_SOURCES
        src/main.c
        src/utils.c
        )

set(SDL2_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/libsdl/include)
#execute_process(COMMAND ${PROJECT_SOURCE_DIR}/libsdl/bin/sdl2-config --cflags OUTPUT_VARIABLE SDL_CFLAGS)
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SDL_CFLAGS}")

add_executable(${PROJECT_NAME}  ${${PROJECT_NAME}_SOURCES})

target_include_directories(${PROJECT_NAME} PUBLIC
        ${SDL2_INCLUDE_DIR}                      )

target_include_directories(${PROJECT_NAME} PUBLIC
        ${PROJECT_SOURCE_DIR}            )

target_include_directories(${PROJECT_NAME} PUBLIC
        ${PROJECT_SOURCE_DIR}/src/libft/include      )

add_subdirectory(src/libft)
target_link_libraries(${PROJECT_NAME} ft)
target_link_libraries(${PROJECT_NAME} m)

#execute_process(COMMAND
#        ${PROJECT_SOURCE_DIR}/libsdl/bin/sdl2-config --libs | tr -d '\n\t\r' | tr -d [:space:]
#        OUTPUT_VARIABLE SDL_LIBS)
#string(REGEX REPLACE "\n$" "" SDL_LIBS "${SDL_LIBS}")

#message(WARNING "'${SDL_LIBS}'")
#message(WARNING "flags ${SDL_FLAGS}")
#message(WARNING "libs ${SDL_LIBS}")
#target_link_libraries(${PROJECT_NAME} ${SDL_LIBS})
