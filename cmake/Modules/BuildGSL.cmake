include(ExternalProject)


# The conda package of GSL has problems on Windows.
# See: https://github.com/conda-forge/gsl-feedstock/issues/50
# Download and compile it from sources
if (WIN32)    
    set(GSL_VERSION 2.4)
    set(GSLMD5 7452f685a49ca9a2ded7213b18d29c4d)

    message(STATUS "downloading and compiling GSL from source")
    ExternalProject_Add(GSL
        PREFIX GSL
        URL https://github.com/ampl/gsl/archive/v2.4.0.tar.gz
        URL_MD5 c27ad8325d16fbddd530b3829f9c135b
        DOWNLOAD_NO_PROGRESS 1
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/extern
        BUILD_IN_SOURCE 1)

    if(MSVC)
        set(GSL_LIBRARY_DIRS ${CMAKE_BINARY_DIR}/extern/lib/)
        set(GSL_LIBRARIES ${GSL_LIBRARY_DIRS}/gsl.lib ${GSL_LIBRARY_DIRS}/gslcblas.lib)
        set(GSL_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/extern/include/)
    else()
        set(GSL_LIBRARY_DIRS ${CMAKE_BINARY_DIR}/extern/lib/)
        set(GSL_LIBRARIES ${GSL_LIBRARY_DIRS}/libgsl.a ${GSL_LIBRARY_DIRS}/libgslcblas.a)
        set(GSL_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/extern/include/)
    endif()
else()
    find_package(GSL 2.1)

    # If GSL is not installed, lets go ahead and compile it
    if(NOT GSL_FOUND)
        message(STATUS "GSL not found, downloading and compiling from source")

        set(GSLVersion 2.4)
        set(GSLMD5 dba736f15404807834dc1c7b93e83b92)

        ExternalProject_Add(GSL
            PREFIX GSL
            URL ftp://ftp.gnu.org/gnu/gsl/gsl-${GSLVersion}.tar.gz
            URL_MD5 ${GSLMD5}
            DOWNLOAD_NO_PROGRESS 1
            CONFIGURE_COMMAND ./configure
                                                                --prefix=${CMAKE_BINARY_DIR}/extern
                                                                --enable-shared=no
                                                                --with-pic=yes
            BUILD_COMMAND           make -j8 > out.log 2>&1
            INSTALL_COMMAND         make install
            BUILD_IN_SOURCE 1)
        set(GSL_LIBRARY_DIRS ${CMAKE_BINARY_DIR}/extern/lib/ )
        set(GSL_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/extern/include/)
        set(GSL_LIBRARIES -lgsl -lgslcblas -lm)
    endif()
endif()