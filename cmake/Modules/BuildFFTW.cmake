include(ExternalProject)

set(FFTWVersion 3.3.7)
set(FFTWMD5 0d5915d7d39b3253c1cc05030d79ac47)

set(FFTW_USE_STATIC_LIBS TRUE)

find_package(FFTW)

# If GSL is not installed, lets go ahead and compile it
if(NOT FFTW_FOUND)
    message(STATUS "FFTW not found, downloading and compiling from source")
    set(FFTWVersion 3.3.7)
    set(FFTWUrl http://www.fftw.org/fftw-${FFTWVersion}.tar.gz)
    set(FFTWMD5 7452f685a49ca9a2ded7213b18d29c4d)
    set(FFTW_USE_STATIC_LIBS TRUE)

    if (WIN32)
        include(cmake/Modules/Windows-GNU.cmake)

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
            ExternalProject_Add(FFTW
                    PREFIX FFTW
                    SOURCE_DIR ${FFTW_DIR}
                    URL ${FFTW_URL}
                    URL_MD5 ${FFTW_MD5}
                    DOWNLOAD_NO_PROGRESS 1
                    CONFIGURE_COMMAND lib /def:libfftw3-3.def
                    BUILD_COMMAND ""
                    INSTALL_COMMAND ""
                    BUILD_IN_SOURCE 1)

            set(FFTW_INCLUDES  ${FFTW_DIR})
            set(FFTW_LIBRARIES ${FFTW_DIR}/libfftw3-3.lib)
        else()
            # To link using GNU toolchains, an *.a file using dlltool
            ExternalProject_Add(FFTW
                                PREFIX FFTW
                                SOURCE_DIR ${FFTW_DIR}
                                URL ${FFTW_URL}
                                URL_MD5 ${FFTW_MD5}
                                DOWNLOAD_NO_PROGRESS 1
                                CONFIGURE_COMMAND dlltool -d libfftw3-3.def -l libfftw3-3.a
                                BUILD_COMMAND ""
                                INSTALL_COMMAND ""
                                BUILD_IN_SOURCE 1)

            set(FFTW_INCLUDES  ${FFTW_DIR})
            set(FFTW_LIBRARIES ${FFTW_DIR}/libfftw3-3.a)
        endif()
    else()
        ExternalProject_Add(FFTW
            PREFIX FFTW
            URL http://www.fftw.org/fftw-${FFTWVersion}.tar.gz
            URL_MD5 ${FFTWMD5}
            DOWNLOAD_NO_PROGRESS 1
            #CONFIGURE_COMMAND ./configure --prefix=${CMAKE_BINARY_DIR}/extern --enable-shared=no --with-pic=yes
            #BUILD_COMMAND           make -j8
            #INSTALL_COMMAND         make install
            BUILD_IN_SOURCE 1)
            set(FFTW_LIBRARY_DIRS ${CMAKE_BINARY_DIR}/extern/lib/ )
            set(FFTW_INCLUDES ${CMAKE_BINARY_DIR}/extern/include/)
            set(FFTW_LIBRARIES -lfftw3)
    endif()
endif()
