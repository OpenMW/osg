
#######################################################################################################
#  macro for linking libraries that come from Findxxxx commands, so there is a variable that contains the
#  full path of the library name. in order to differentiate release and debug, this macro get the
#  NAME of the variables, so the macro gets as arguments the target name and the following list of parameters
#  is intended as a list of variable names each one containing  the path of the libraries to link to
#  The existence of a variable name with _DEBUG appended is tested and, in case it' s value is used
#  for linking to when in debug mode
#  the content of this library for linking when in debugging
#######################################################################################################

MACRO(LINK_WITH_VARIABLES TRGTNAME)
    FOREACH(varname ${ARGN})
        IF(${varname}_DEBUG)
            IF(${varname}_RELEASE)
                TARGET_LINK_LIBRARIES(${TRGTNAME} optimized "${${varname}_RELEASE}" debug "${${varname}_DEBUG}")
            ELSE(${varname}_RELEASE)
                TARGET_LINK_LIBRARIES(${TRGTNAME} optimized "${${varname}}" debug "${${varname}_DEBUG}")
            ENDIF(${varname}_RELEASE)
        ELSE(${varname}_DEBUG)
            TARGET_LINK_LIBRARIES(${TRGTNAME} ${${varname}} )
        ENDIF(${varname}_DEBUG)
    ENDFOREACH(varname)
ENDMACRO(LINK_WITH_VARIABLES TRGTNAME)

MACRO(LINK_INTERNAL TRGTNAME)
    TARGET_LINK_LIBRARIES(${TRGTNAME} ${ARGN})
ENDMACRO(LINK_INTERNAL TRGTNAME)

MACRO(LINK_EXTERNAL TRGTNAME)
    FOREACH(LINKLIB ${ARGN})
        TARGET_LINK_LIBRARIES(${TRGTNAME} "${LINKLIB}" )
    ENDFOREACH(LINKLIB)
ENDMACRO(LINK_EXTERNAL TRGTNAME)


#######################################################################################################
#  macro for common setup of core libraries: it links OPENGL_LIBRARIES in undifferentiated mode
#######################################################################################################

MACRO(LINK_CORELIB_DEFAULT CORELIB_NAME)
    #SET(ALL_GL_LIBRARIES ${OPENGL_LIBRARIES})
    SET(ALL_GL_LIBRARIES ${OPENGL_gl_LIBRARY})
    IF (OSG_GLES1_AVAILABLE OR OSG_GLES2_AVAILABLE OR OSG_GLES3_AVAILABLE)
        SET(ALL_GL_LIBRARIES ${ALL_GL_LIBRARIES} ${EGL_LIBRARY})
    ENDIF()

    LINK_EXTERNAL(${CORELIB_NAME} ${ALL_GL_LIBRARIES})
    LINK_WITH_VARIABLES(${CORELIB_NAME} OPENTHREADS_LIBRARY)
    IF(OPENSCENEGRAPH_SONAMES)
      SET_TARGET_PROPERTIES(${CORELIB_NAME} PROPERTIES VERSION ${OPENSCENEGRAPH_VERSION} SOVERSION ${OPENSCENEGRAPH_SOVERSION})
    ENDIF(OPENSCENEGRAPH_SONAMES)

ENDMACRO(LINK_CORELIB_DEFAULT CORELIB_NAME)


#######################################################################################################
#  macro for common setup of plugins, examples and applications it expect some variables to be set:
#  either within the local CMakeLists or higher in hierarchy
#  TARGET_NAME is the name of the folder and of the actually .exe or .so or .dll
#  TARGET_TARGETNAME  is the name of the target , this get buit out of a prefix, if present and TARGET_TARGETNAME
#  TARGET_SRC  are the sources of the target
#  TARGET_H are the eventual headers of the target
#  TARGET_LIBRARIES are the libraries to link to that are internal to the project and have d suffix for debug
#  TARGET_EXTERNAL_LIBRARIES are external libraries and are not differentiated with d suffix
#  TARGET_LABEL is the label IDE should show up for targets
##########################################################################################################

MACRO(SETUP_LINK_LIBRARIES)
    ######################################################################
    #
    # This set up the libraries to link to, it assumes there are two variable: one common for a group of examples or plugins
    # kept in the variable TARGET_COMMON_LIBRARIES and an example or plugin specific kept in TARGET_ADDED_LIBRARIES
    # they are combined in a single list checked for unicity
    # the suffix ${CMAKE_DEBUG_POSTFIX} is used for differentiating optimized and debug
    #
    # a second variable TARGET_EXTERNAL_LIBRARIES hold the list of  libraries not differentiated between debug and optimized
    ##################################################################################
    SET(TARGET_LIBRARIES ${TARGET_COMMON_LIBRARIES})

    FOREACH(LINKLIB ${TARGET_ADDED_LIBRARIES})
      SET(TO_INSERT TRUE)
      FOREACH (value ${TARGET_COMMON_LIBRARIES})
            IF ("${value}" STREQUAL "${LINKLIB}")
                  SET(TO_INSERT FALSE)
            ENDIF ("${value}" STREQUAL "${LINKLIB}")
        ENDFOREACH (value ${TARGET_COMMON_LIBRARIES})
      IF(TO_INSERT)
          LIST(APPEND TARGET_LIBRARIES ${LINKLIB})
      ENDIF(TO_INSERT)
    ENDFOREACH(LINKLIB)

    #SET(ALL_GL_LIBRARIES ${OPENGL_LIBRARIES})
    SET(ALL_GL_LIBRARIES ${OPENGL_gl_LIBRARY})
    IF (OSG_GLES1_AVAILABLE OR OSG_GLES2_AVAILABLE OR OSG_GLES3_AVAILABLE)
        SET(ALL_GL_LIBRARIES ${ALL_GL_LIBRARIES} ${EGL_LIBRARY})
    ENDIF()

#    FOREACH(LINKLIB ${TARGET_LIBRARIES})
#            TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} optimized ${LINKLIB} debug "${LINKLIB}${CMAKE_DEBUG_POSTFIX}")
#    ENDFOREACH(LINKLIB)
        LINK_INTERNAL(${TARGET_TARGETNAME} ${TARGET_LIBRARIES})
#    FOREACH(LINKLIB ${TARGET_EXTERNAL_LIBRARIES})
#            TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} ${LINKLIB})
#    ENDFOREACH(LINKLIB)
        TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} ${TARGET_EXTERNAL_LIBRARIES})
        IF(TARGET_LIBRARIES_VARS)
            LINK_WITH_VARIABLES(${TARGET_TARGETNAME} ${TARGET_LIBRARIES_VARS})
        ENDIF(TARGET_LIBRARIES_VARS)
    IF(MSVC  AND OSG_MSVC_VERSIONED_DLL)
        #when using full path name to specify linkage, it seems that already linked libs must be specified
            LINK_EXTERNAL(${TARGET_TARGETNAME} ${ALL_GL_LIBRARIES})
    ENDIF(MSVC AND OSG_MSVC_VERSIONED_DLL)

ENDMACRO(SETUP_LINK_LIBRARIES)

############################################################################################
# this is the common set of command for all the plugins
#

# Sets the output directory property for CMake >= 2.6.0, giving an output path RELATIVE to default one
MACRO(SET_OUTPUT_DIR_PROPERTY_260 TARGET_TARGETNAME RELATIVE_OUTDIR)
    
    # Using the output directory properties

    # Global properties (All generators but VS & Xcode)
    FILE(TO_CMAKE_PATH TMPVAR "CMAKE_ARCHIVE_OUTPUT_DIRECTORY/${RELATIVE_OUTDIR}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${TMPVAR}")
    FILE(TO_CMAKE_PATH TMPVAR "CMAKE_RUNTIME_OUTPUT_DIRECTORY/${RELATIVE_OUTDIR}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${TMPVAR}")
    FILE(TO_CMAKE_PATH TMPVAR "CMAKE_LIBRARY_OUTPUT_DIRECTORY/${RELATIVE_OUTDIR}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${TMPVAR}")

    # Per-configuration property (VS, Xcode)
    FOREACH(CONF ${CMAKE_CONFIGURATION_TYPES})        # For each configuration (Debug, Release, MinSizeRel... and/or anything the user chooses)
        STRING(TOUPPER "${CONF}" CONF)                # Go uppercase (DEBUG, RELEASE...)

        # We use "FILE(TO_CMAKE_PATH", to create nice looking paths
        FILE(TO_CMAKE_PATH "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "ARCHIVE_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
        FILE(TO_CMAKE_PATH "${CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "RUNTIME_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
        FILE(TO_CMAKE_PATH "${CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "LIBRARY_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
    ENDFOREACH(CONF ${CMAKE_CONFIGURATION_TYPES})
ENDMACRO(SET_OUTPUT_DIR_PROPERTY_260 TARGET_TARGETNAME RELATIVE_OUTDIR)



#######################################################################################################
#  macro for common setup of libraries it expect some variables to be set:
#  either within the local CMakeLists or higher in hierarchy
#  LIB_NAME  is the name of the target library
#  TARGET_SRC  are the sources of the target
#  TARGET_H are the eventual headers of the target
#  TARGET_H_NO_MODULE_INSTALL are headers that belong to target but shouldn't get installed by the ModuleInstall script
#  TARGET_LIBRARIES are the libraries to link to that are internal to the project and have d suffix for debug
#  TARGET_EXTERNAL_LIBRARIES are external libraries and are not differentiated with d suffix
#  TARGET_LABEL is the label IDE should show up for targets
##########################################################################################################

MACRO(SETUP_LIBRARY LIB_NAME)
    IF(GLCORE_FOUND)
        INCLUDE_DIRECTORIES( ${GLCORE_INCLUDE_DIR} )
    ENDIF()

        SET(TARGET_NAME ${LIB_NAME} )
        SET(TARGET_TARGETNAME ${LIB_NAME} )
        ADD_LIBRARY(${LIB_NAME}
            ${OPENSCENEGRAPH_USER_DEFINED_DYNAMIC_OR_STATIC}
            ${TARGET_H}
            ${TARGET_H_NO_MODULE_INSTALL}
            ${TARGET_SRC}
        )
        SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES FOLDER "OSG Core")
        IF(APPLE)
            IF(OSG_BUILD_PLATFORM_IPHONE)
                SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE ${IPHONE_ENABLE_BITCODE})
            ENDIF()
            SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES XCODE_ATTRIBUTE_WARNING_CFLAGS "")
        ENDIF()
        IF(TARGET_LABEL)
            SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PROJECT_LABEL "${TARGET_LABEL}")
        ENDIF(TARGET_LABEL)

        IF(TARGET_LIBRARIES)
            LINK_INTERNAL(${LIB_NAME} ${TARGET_LIBRARIES})
        ENDIF()
        IF(TARGET_EXTERNAL_LIBRARIES)
            LINK_EXTERNAL(${LIB_NAME} ${TARGET_EXTERNAL_LIBRARIES})
        ENDIF()
        IF(TARGET_LIBRARIES_VARS)
            LINK_WITH_VARIABLES(${LIB_NAME} ${TARGET_LIBRARIES_VARS})
        ENDIF(TARGET_LIBRARIES_VARS)
        LINK_CORELIB_DEFAULT(${LIB_NAME})

    INCLUDE(ModuleInstall OPTIONAL)
ENDMACRO(SETUP_LIBRARY LIB_NAME)

MACRO(SETUP_PLUGIN PLUGIN_NAME)
    IF(GLCORE_FOUND)
        INCLUDE_DIRECTORIES( ${GLCORE_INCLUDE_DIR} )
    ENDIF()

    SET(TARGET_NAME ${PLUGIN_NAME} )

    #MESSAGE("in -->SETUP_PLUGIN<-- ${TARGET_NAME}-->${TARGET_SRC} <--> ${TARGET_H}<--")

    ## we have set up the target label and targetname by taking into account global prfix (osgdb_)

    IF(NOT TARGET_TARGETNAME)
            SET(TARGET_TARGETNAME "${TARGET_DEFAULT_PREFIX}${TARGET_NAME}")
    ENDIF(NOT TARGET_TARGETNAME)
    IF(NOT TARGET_LABEL)
            SET(TARGET_LABEL "${TARGET_DEFAULT_LABEL_PREFIX} ${TARGET_NAME}")
    ENDIF(NOT TARGET_LABEL)

    ## plugins gets put in libopenscenegraph by default
    IF(${ARGC} GREATER 1)
      SET(PACKAGE_COMPONENT libopenscenegraph-${ARGV1})

      # add cpack config variables for plugin with own package
      IF(BUILD_OSG_PACKAGES)
        IF("${CPACK_GENERATOR}" STREQUAL "DEB")
            STRING(TOUPPER ${PACKAGE_COMPONENT} UPPER_PACKAGE_COMPONENT)
            SET(CPACK_${UPPER_PACKAGE_COMPONENT}_DEPENDENCIES
                "libopenscenegraph"
                CACHE STRING
                "Dependend packages for the ${PACKAGE_COMPONENT} package with all components (uses deb dependecy format), e.g., 'libc6, libcurl3-gnutls, libgif4, libjpeg8, libpng12-0'"
            )
            SET(CPACK_${UPPER_PACKAGE_COMPONENT}_CONFLICTS
                ""
                CACHE STRING
                "Conflicting packages for the ${PACKAGE_COMPONENT} package (uses deb dependecy format), e.g., 'libc6, libcurl3-gnutls, libgif4, libjpeg8, libpng12-0'"
            )
        ENDIF()
      ENDIF()
    ELSE(${ARGC} GREATER 1)
      SET(PACKAGE_COMPONENT libopenscenegraph)
    ENDIF(${ARGC} GREATER 1)

    # Add the VisualStudio versioning info
    SET(TARGET_SRC ${TARGET_SRC} ${OPENSCENEGRAPH_VERSIONINFO_RC})

    # here we use the command to generate the library

    IF   (DYNAMIC_OPENSCENEGRAPH)
        ADD_LIBRARY(${TARGET_TARGETNAME} MODULE ${TARGET_SRC} ${TARGET_H})
    ELSE (DYNAMIC_OPENSCENEGRAPH)
        ADD_LIBRARY(${TARGET_TARGETNAME} STATIC ${TARGET_SRC} ${TARGET_H})
    ENDIF(DYNAMIC_OPENSCENEGRAPH)

    IF(MSVC)
        SET_OUTPUT_DIR_PROPERTY_260(${TARGET_TARGETNAME} "${OSG_PLUGINS}")        # Sets the ouput to be /osgPlugin-X.X.X ; also ensures the /Debug /Release are removed
    ENDIF(MSVC)

    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PROJECT_LABEL "${TARGET_LABEL}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES FOLDER "Plugins")
    IF(APPLE)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES XCODE_ATTRIBUTE_WARNING_CFLAGS "")
        IF(OSG_BUILD_PLATFORM_IPHONE)
            SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE ${IPHONE_ENABLE_BITCODE})
        ENDIF()
    ENDIF()
    SETUP_LINK_LIBRARIES()

# installation paths are differentiated for win32 installing in bin versus other architectures that install in ${CMAKE_INSTALL_LIBDIR}/${OSG_PLUGINS}
    IF(WIN32)
        INSTALL(TARGETS ${TARGET_TARGETNAME}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT ${PACKAGE_COMPONENT}
            LIBRARY DESTINATION ${CMAKE_INSTALL_BINDIR}/${OSG_PLUGINS} COMPONENT ${PACKAGE_COMPONENT}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}/${OSG_PLUGINS} COMPONENT libopenscenegraph-dev)
        IF(MSVC AND DYNAMIC_OPENSCENEGRAPH)
            INSTALL(FILES $<TARGET_PDB_FILE:${TARGET_TARGETNAME}> DESTINATION bin/${OSG_PLUGINS} COMPONENT ${PACKAGE_COMPONENT})
        ENDIF()
    ELSE()
        INSTALL(TARGETS ${TARGET_TARGETNAME}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT ${PACKAGE_COMPONENT}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/${OSG_PLUGINS} COMPONENT ${PACKAGE_COMPONENT}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}/${OSG_PLUGINS} COMPONENT libopenscenegraph-dev)
    ENDIF()
ENDMACRO(SETUP_PLUGIN)


#################################################################################################################
# this is the macro for example and application setup
###########################################################

MACRO(SETUP_EXE IS_COMMANDLINE_APP)
    #MESSAGE("in -->SETUP_EXE<-- ${TARGET_NAME}-->${TARGET_SRC} <--> ${TARGET_H}<--")
    IF(GLCORE_FOUND)
        INCLUDE_DIRECTORIES( ${GLCORE_INCLUDE_DIR} )
    ENDIF()

    IF(NOT TARGET_TARGETNAME)
            SET(TARGET_TARGETNAME "${TARGET_DEFAULT_PREFIX}${TARGET_NAME}")
    ENDIF(NOT TARGET_TARGETNAME)
    IF(NOT TARGET_LABEL)
            SET(TARGET_LABEL "${TARGET_DEFAULT_LABEL_PREFIX} ${TARGET_NAME}")
    ENDIF(NOT TARGET_LABEL)

    IF(${IS_COMMANDLINE_APP})

        ADD_EXECUTABLE(${TARGET_TARGETNAME} ${TARGET_SRC} ${TARGET_H})

    ELSE(${IS_COMMANDLINE_APP})

        IF(APPLE)
            # SET(MACOSX_BUNDLE_LONG_VERSION_STRING "${OPENSCENEGRAPH_MAJOR_VERSION}.${OPENSCENEGRAPH_MINOR_VERSION}.${OPENSCENEGRAPH_PATCH_VERSION}")
            # Short Version is the "marketing version". It is the version
            # the user sees in an information panel.
            SET(MACOSX_BUNDLE_SHORT_VERSION_STRING "${OPENSCENEGRAPH_MAJOR_VERSION}.${OPENSCENEGRAPH_MINOR_VERSION}.${OPENSCENEGRAPH_PATCH_VERSION}")
            SET(MACOSX_BUNDLE_INFO_STRING "OpenSceneGraph ${OSGOS_VERSION_STRING}")
            # Bundle version is the version the OS looks at.
            SET(MACOSX_BUNDLE_BUNDLE_VERSION "${OPENSCENEGRAPH_MAJOR_VERSION}.${OPENSCENEGRAPH_MINOR_VERSION}.${OPENSCENEGRAPH_PATCH_VERSION}")
            SET(MACOSX_BUNDLE_GUI_IDENTIFIER "org.openscenegraph.${TARGET_TARGETNAME}" )
            # replace underscore by hyphen
            STRING(REGEX REPLACE "_" "-" MACOSX_BUNDLE_GUI_IDENTIFIER ${MACOSX_BUNDLE_GUI_IDENTIFIER})
            SET(MACOSX_BUNDLE_BUNDLE_NAME "${TARGET_NAME}" )
            # SET(MACOSX_BUNDLE_ICON_FILE "myicon.icns")
            # SET(MACOSX_BUNDLE_COPYRIGHT "")
            # SET(MACOSX_BUNDLE_INFO_STRING "Info string, localized?")
        ENDIF(APPLE)

        IF(WIN32)
            IF (REQUIRE_WINMAIN_FLAG)
                SET(PLATFORM_SPECIFIC_CONTROL WIN32)
            ENDIF(REQUIRE_WINMAIN_FLAG)
        ENDIF(WIN32)

        IF(APPLE)
            IF(OSG_BUILD_APPLICATION_BUNDLES)
                SET(PLATFORM_SPECIFIC_CONTROL MACOSX_BUNDLE)
            ENDIF(OSG_BUILD_APPLICATION_BUNDLES)
        ENDIF(APPLE)

        ADD_EXECUTABLE(${TARGET_TARGETNAME} ${PLATFORM_SPECIFIC_CONTROL} ${TARGET_SRC} ${TARGET_H})

    ENDIF(${IS_COMMANDLINE_APP})

    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PROJECT_LABEL "${TARGET_LABEL}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES OUTPUT_NAME ${TARGET_NAME})
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES DEBUG_OUTPUT_NAME "${TARGET_NAME}${CMAKE_DEBUG_POSTFIX}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RELEASE_OUTPUT_NAME "${TARGET_NAME}${CMAKE_RELEASE_POSTFIX}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RELWITHDEBINFO_OUTPUT_NAME "${TARGET_NAME}${CMAKE_RELWITHDEBINFO_POSTFIX}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES MINSIZEREL_OUTPUT_NAME "${TARGET_NAME}${CMAKE_MINSIZEREL_POSTFIX}")

    IF(MSVC_IDE AND OSG_MSVC_VERSIONED_DLL)
        SET_OUTPUT_DIR_PROPERTY_260(${TARGET_TARGETNAME} "")        # Ensure the /Debug /Release are removed
    ENDIF(MSVC_IDE AND OSG_MSVC_VERSIONED_DLL)

    IF(APPLE)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES XCODE_ATTRIBUTE_WARNING_CFLAGS "")
        IF(OSG_BUILD_PLATFORM_IPHONE)
            SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE ${IPHONE_ENABLE_BITCODE})
        ENDIF()
    ENDIF()

    IF(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND DYNAMIC_OPENSCENEGRAPH)
        # templated types used in OSG plugins and applications need to get the same type ID
        # based on investigation for https://gitlab.com/OpenMW/openmw/-/issues/8039 by the OpenMW team, this is believed to only be necessary for Clang on Linux
        # i.e. not for GCC anywhere, MSVC on Windows or for AppleClang on MacOS
        # it's possible that this is really required by the C++ spec for all platforms and we're just getting away with it everywhere else
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES ENABLE_EXPORTS ON)
    ENDIF()

    SETUP_LINK_LIBRARIES()

ENDMACRO(SETUP_EXE)

# Takes optional second argument (is_commandline_app?) in ARGV1
MACRO(SETUP_APPLICATION APPLICATION_NAME)

        SET(TARGET_NAME ${APPLICATION_NAME} )

        IF(${ARGC} GREATER 1)
            SET(IS_COMMANDLINE_APP ${ARGV1})
        ELSE(${ARGC} GREATER 1)
            SET(IS_COMMANDLINE_APP 0)
        ENDIF(${ARGC} GREATER 1)

        SETUP_EXE(${IS_COMMANDLINE_APP})

        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES FOLDER "Applications")

        IF(APPLE)
            INSTALL(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin BUNDLE DESTINATION bin)
        ELSE(APPLE)
            INSTALL(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin COMPONENT openscenegraph  )
            IF(MSVC)
                INSTALL(FILES $<TARGET_PDB_FILE:${TARGET_TARGETNAME}> DESTINATION bin COMPONENT openscenegraph)
            ENDIF(MSVC)
        ENDIF(APPLE)

ENDMACRO(SETUP_APPLICATION)

MACRO(SETUP_COMMANDLINE_APPLICATION APPLICATION_NAME)

    SETUP_APPLICATION(${APPLICATION_NAME} 1)

ENDMACRO(SETUP_COMMANDLINE_APPLICATION)

# Takes optional second argument (is_commandline_app?) in ARGV1
MACRO(SETUP_EXAMPLE EXAMPLE_NAME)

        SET(TARGET_NAME ${EXAMPLE_NAME} )

        IF(${ARGC} GREATER 1)
            SET(IS_COMMANDLINE_APP ${ARGV1})
        ELSE(${ARGC} GREATER 1)
            SET(IS_COMMANDLINE_APP 0)
        ENDIF(${ARGC} GREATER 1)

        SETUP_EXE(${IS_COMMANDLINE_APP})

        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES FOLDER "Examples")

        IF(APPLE)
            INSTALL(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION share/OpenSceneGraph/bin BUNDLE DESTINATION share/OpenSceneGraph/bin )
        ELSE(APPLE)
            INSTALL(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION share/OpenSceneGraph/bin COMPONENT openscenegraph-examples )
            IF(MSVC)
                INSTALL(FILES $<TARGET_PDB_FILE:${TARGET_TARGETNAME}> DESTINATION share/OpenSceneGraph/bin COMPONENT openscenegraph-examples)
            ENDIF(MSVC)
        ENDIF(APPLE)

ENDMACRO(SETUP_EXAMPLE)


MACRO(SETUP_COMMANDLINE_EXAMPLE EXAMPLE_NAME)

    SETUP_EXAMPLE(${EXAMPLE_NAME} 1)

ENDMACRO(SETUP_COMMANDLINE_EXAMPLE)

# Takes two optional arguments -- osg prefix and osg version
MACRO(HANDLE_MSVC_DLL)
        #this is a hack... the build place is set to lib/<debug or release> by LIBARARY_OUTPUT_PATH equal to OUTPUT_LIBDIR
        #the .lib will be crated in ../ so going straight in lib by the IMPORT_PREFIX property
        #because we want dll placed in OUTPUT_BINDIR ie the bin folder sibling of lib, we can use ../../bin to go there,
        #it is hardcoded, we should compute OUTPUT_BINDIR position relative to OUTPUT_LIBDIR ... to be implemented
        #changing bin to something else breaks this hack
        #the dll are versioned by prefixing the name with osg${OPENSCENEGRAPH_SOVERSION}-

        # LIB_PREFIX: use "osg" by default, else whatever we've been given.
        IF(${ARGC} GREATER 0)
                SET(LIB_PREFIX ${ARGV0})
        ELSE(${ARGC} GREATER 0)
                SET(LIB_PREFIX osg)
        ENDIF(${ARGC} GREATER 0)

        # LIB_SOVERSION: use OSG's soversion by default, else whatever we've been given
        IF(${ARGC} GREATER 1)
                SET(LIB_SOVERSION ${ARGV1})
        ELSE(${ARGC} GREATER 1)
                SET(LIB_SOVERSION ${OPENSCENEGRAPH_SOVERSION})
        ENDIF(${ARGC} GREATER 1)

        SET_OUTPUT_DIR_PROPERTY_260(${LIB_NAME} "")        # Ensure the /Debug /Release are removed
        IF(NOT MSVC_IDE)
            SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES PREFIX "${LIB_PREFIX}${LIB_SOVERSION}-")
        ELSE(NOT MSVC_IDE)
            SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES PREFIX "${LIB_PREFIX}${LIB_SOVERSION}-")
        ENDIF(NOT MSVC_IDE)

#     SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES PREFIX "../../bin/osg${OPENSCENEGRAPH_SOVERSION}-")
#     SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES IMPORT_PREFIX "../")
ENDMACRO(HANDLE_MSVC_DLL)

MACRO(REMOVE_CXX_FLAG flag)
  STRING(REPLACE "${flag}" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
ENDMACRO()
