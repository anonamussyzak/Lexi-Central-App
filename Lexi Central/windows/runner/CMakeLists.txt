cmake_minimum_required(VERSION 3.14)
project(lexi_central LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "lexi_central")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()

# Set library names based on build mode
if(CMAKE_BUILD_TYPE STREQUAL "Profile")
  set(PROFILE_MODE ON)
  set(BUILD_SUFFIX "profile")
else()
  set(PROFILE_MODE OFF)
  if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(BUILD_SUFFIX "release")
  else()
    set(BUILD_SUFFIX "debug")
  endif()
endif()

# If Windows platform application, set subsystem to console.
if(WIN32)
  set(CMAKE_WIN32_EXECUTABLE TRUE)
elseif(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "10.14")
endif()

# Define library paths.
set(PLUGIN_BUNDLE_DIR "${PROJECT_OUT_DIR}/plugins")
set(PLUGIN_BUNDLE_LIB_DIR "${PLUGIN_BUNDLE_DIR}/${BUILD_SUFFIX}")

# List of absolute paths to libraries that should be bundled with the application.
set(PLUGIN_BUNDLED_LIBRARIES)

# Generated include file.
set(PLUGIN_MANIFEST "${PROJECT_OUT_DIR}/plugin_manifest.cmake")

# File containing the list of bundled libraries.
set(PLUGIN_BUNDLED_LIBRARIES_FILE "${PLUGIN_BUNDLE_DIR}/bundled_libraries.cmake")

# Configure plugins.
include(${PLUGIN_MANIFEST})

# === Flutter Library ===
set(FLUTTER_LIBRARY "${EP_FLUTTER_LIBRARY}")

if(FLUTTER_LIBRARY)
  # Published to parent scope for install rules.
  set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
  set(PLUGIN_BUNDLED_LIBRARIES ${PLUGIN_BUNDLED_LIBRARIES} PARENT_SCOPE)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${FLUTTER_LIBRARY})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${AppLibraryDependencies})
endif()

# === Application ===
list(APPEND PLUGIN_BUNDLED_LIBRARIES
  # Add any additional bundled libraries here.
)

# === Testing ===
if(BUILD_TESTING)
  # Find the test framework.
  find_package(GTest CONFIG REQUIRED)

  # Add test executable.
  add_executable(unit_tests EXCLUDE_FROM_ALL
    test/test_runner.cc
    test/flutter_test.cc
  )

  # Link the test executable.
  target_link_libraries(unit_tests
    ${BINARY_NAME}
    GTest::gtest
    GTest::gtest_main
  )

  # Enable test execution.
  enable_testing()
endif()

# === Installation ===
if(BUILD_TESTING)
  # Install the test executable.
  install(TARGETS unit_tests
    RUNTIME DESTINATION "${INSTALL_BUNDLE_DIR}/test"
  )
endif()

# Install the AOT library on Windows.
if(WIN32 AND BUILD_SHARED_LIBS)
  install(TARGETS ${BINARY_NAME}_aot
    RUNTIME DESTINATION "${INSTALL_BUNDLE_DIR}"
  )
endif()

# Install the library.
install(TARGETS ${BINARY_NAME}
  RUNTIME DESTINATION "${INSTALL_BUNDLE_DIR}"
)

# Install the bundled libraries.
install(FILES ${PLUGIN_BUNDLED_LIBRARIES}
  DESTINATION "${INSTALL_BUNDLE_DIR}"
)

# Install the assets.
install(DIRECTORY "${PROJECT_BUILD_DIR}/${BUILD_SUFFIX}/assets"
  DESTINATION "${INSTALL_BUNDLE_DIR}"
)

# Install the Flutter assets.
install(DIRECTORY "${PROJECT_BUILD_DIR}/${BUILD_SUFFIX}/flutter_assets"
  DESTINATION "${INSTALL_BUNDLE_DIR}"
)

# Install the ICU data.
install(FILES "${PROJECT_BUILD_DIR}/${BUILD_SUFFIX}/icudtl.dat"
  DESTINATION "${INSTALL_BUNDLE_DIR}"
)
