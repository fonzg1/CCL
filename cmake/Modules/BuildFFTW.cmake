include(ExternalProject)

find_package(FFTW)

# If GSL is not installed, lets go ahead and compile it
if(NOT FFTW_FOUND)
    set(FFTWVersion 3.3.7)
    set(FFTWUrl http://www.fftw.org/fftw-${FFTWVersion}.tar.gz)
    set(FFTWMD5 0d5915d7d39b3253c1cc05030d79ac47)
    set(FFTW_USE_STATIC_LIBS TRUE)

    if (WIN32)
        message(STATUS "FFTW not found, downloading a precompiled library")

        # Download precompiled libraries.
        # It is possible to compile it by our own, but FFTW guys have a much better idea about
        # how to compile the library properly.
        # See: http://www.fftw.org/install/windows.html
        set(FFTW_URL ftp://ftp.fftw.org/pub/fftw/fftw-3.3.5-dll64.zip)
        set(FFTW_MD5 cb3c5ad19a89864f036e7a2dd5be168c)
        set(FFTW_DIR ${CMAKE_BINARY_DIR}/FFTW/extracted)

        if(MSVC)
            # To link against FFTW under Visual Studio, we need to create .lib using lib.exe
            #ExternalProject_Add(FFTW
            #        PREFIX FFTW
            #        SOURCE_DIR ${FFTW_DIR}
            #        URL ${FFTW_URL}
            #        URL_MD5 ${FFTW_MD5}
            #        DOWNLOAD_NO_PROGRESS 1
                    #CONFIGURE_COMMAND ";"
                   # BUILD_COMMAND ";"
                    #INSTALL_COMMAND "lib /def:${FFTW_DIR}/libfftw3-3.def"
                   #BUILD_IN_SOURCE 1)

            #add_custom_command(
            #        OUTPUT
            #        ${FFTW_DIR}/libfftw3-3.lib
            #        COMMAND
            #        lib /def:${FFTW_DIR}/libfftw3-3.def
            #        DEPENDS
            #        ${FFTW_DIR}/libfftw3-3.def
            #)

            #add_custom_target(FFTW DEPENDS ${FFTW_DIR}/extracted/libfftw3-3.lib)

            add_custom_target(FFTW)
            set(FFTW_LIBRARY_DIRS ${FFTW_DIR})
            set(FFTW_INCLUDES  ${FFTW_DIR})
            set(FFTW_LIBRARIES ${FFTW_DIR}/libfftw3-3.lib)
        else()
            # To link using GNU toolchains, just extract the archive and take precompiled libraries as is
#            ExternalProject_Add(FFTW
#                    PREFIX FFTW
#                    SOURCE_DIR ${FFTW_DIR}
#                    URL ${FFTW_URL}
#                    URL_MD5 ${FFTW_MD5}
#                    DOWNLOAD_NO_PROGRESS 1
#                    CONFIGURE_COMMAND ""
#                    BUILD_COMMAND ""
#                    INSTALL_COMMAND ""
#                    BUILD_IN_SOURCE 1)
#
#            set(FFTW_LIBRARY_DIRS ${FFTW_DIR})

#            set(FFTW_LIBRARIES ${FFTW_DIR}/libfftw3-3.dll)
            #add_library(FFTW SHARED ${CMAKE_BINARY_DIR}/FFTW/extracted)
            add_custom_target(FFTW)
            set(FFTW_INCLUDES  ${FFTW_DIR})
            set(FFTW_LIBRARIES ${FFTW_DIR}/libfftw3-3.dll)
        endif()

    else()
        message(STATUS "FFTW not found, downloading and compiling from source")
        ExternalProject_Add(FFTW
                PREFIX FFTW
                URL ${FFTWUrl}
                URL_MD5 ${FFTWMD5}
                DOWNLOAD_NO_PROGRESS 1
                CONFIGURE_COMMAND ./configure --prefix=${CMAKE_BINARY_DIR}/extern --enable-shared=no --with-pic=yes
                BUILD_COMMAND           make -j8
                INSTALL_COMMAND         make install
                BUILD_IN_SOURCE 1)
        set(FFTW_LIBRARY_DIRS ${CMAKE_BINARY_DIR}/extern/lib/ )
        set(FFTW_INCLUDES ${CMAKE_BINARY_DIR}/extern/include/)
        set(FFTW_LIBRARIES -lfftw3)
    endif()
endif()
