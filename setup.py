#!/usr/bin/env python
from setuptools.command.build_py import build_py as _build
from setuptools.command.develop import develop as _develop
from setuptools import setup, find_packages
from subprocess import call, Popen, PIPE
from io import open
import numpy
import os
import shutil
import sys

def _check_cmake():
    if call(["cmake", "--version"]) != 0:
        raise RuntimeError("Could not run CMake configuration. "
                           "Make sure CMake is installed." )

def _check_mingw():
    if call(["mingw32-make", "--version"]) != 0:
        raise RuntimeError("Could not run mingw32-make. "
                           "Make sure mingw-w64 is installed and "
                           " added to the system PATH variable.")

def _check_vswhere():
    p = Popen(["vswhere.exe", "-h"], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    output, err = p.communicate()
    if p.returncode != 0:
        raise RuntimeError("Could not run vswhere.exe. "
                           "Make sure vswhere is installed (try `conda install vswhere`).")


def _find_msbuild():
    p = Popen(["vswhere.exe", 
               "-latest",
               "-requires", "Microsoft.Component.MSBuild",
               "-find", "MSBuild\**\Bin\MSBuild.exe"], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    output, err = p.communicate()
    if p.returncode != 0:
        raise RuntimeError("vswhere.exe could not find msbuild.exe. Make sure Visual Studio is installed.") 
    return output


def _compile_ccl():
    # create a build folder if not yet
    if not os.path.exists("build"):
        os.makedirs("build")

    v = sys.version_info

    # Windows build
    if os.name == 'nt':

        # Check if CMake is available
        _check_cmake()

        # At the moment pyccl is only compilable by Visual Studio compilers
        use_msvc = True
        if use_msvc:

            # Check if vswhere.exe is available
            # It is needed to find where Visual Studio is located
            _check_vswhere()

            # Find MSBuild.exe of the latest Visual Studio available
            msbuild_path = _find_msbuild().decode('utf-8').strip()
            print("Found MSBuild.exe:", msbuild_path)
            
            # Run CMake to create Visual Studio solution
            if call(["cmake", 
                    "-H.", "-Bbuild",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DPYTHON_VERSION=%d.%d.%d" % (
                        v.major, v.minor, v.micro)]) != 0:
                raise RuntimeError("Could not run CMake configuration.")

            # Run MSBuild.exe to compile the shared library
            cclpyd_output_dir = "build\\pyccl\\Release"
            script_dir = os.path.dirname(os.path.realpath(__file__))
            if call([msbuild_path, "build\\pyccl\\_ccllib.vcxproj", "-p:Configuration=Release"]) != 0:
                raise RuntimeError("Could not build CCL.")

            # Find the compiled library and copy it to the target folder
            pyd_file = os.path.join(cclpyd_output_dir, "_ccllib.pyd")
            destination = os.path.join("pyccl", os.path.basename(pyd_file))
            if not os.path.exists(pyd_file) or (not shutil.copyfile(pyd_file, destination)):
                raise RuntimeError("Could not find wrapper shared library, "
                                "compilation must have failed.")
        else:
            
            #_check_mingw()
            raise RuntimeError("MinGW is not supported yet.")           
    # Linux build
    else:
        if call(["cmake", "-H.", "-Bbuild",
                "-DPYTHON_VERSION=%d.%d.%d" % (
                    v.major, v.minor, v.micro)]) != 0:
            raise Exception(
                "Could not run CMake configuration. Make sure "
                "CMake is installed !")

        if call(["make", "-Cbuild", "_ccllib"]) != 0:
            raise Exception("Could not build CCL")

        # Finds the library under its different possible names
        if os.path.exists("build/pyccl/_ccllib.so"):
            call(["cp", "build/pyccl/_ccllib.so", "pyccl/"])
        else:
            raise Exception("Could not find wrapper shared library, "
                            "compilation must have failed.")

class build(_build):
    """Specialized Python source builder."""
    def run(self):
        _compile_ccl()
        _build.run(self)


class develop(_develop):
    """Specialized Python develop mode."""
    def run(self):
        _compile_ccl()
        _develop.run(self)


def get_shared_library_name():
    return '_ccllib.dll' if os.name == 'nt' else '_ccllib.so'
        

# read the contents of the README file
with open('README.md', encoding="utf-8") as f:
    long_description = f.read()

setup(
    name="pyccl",
    description="Library of validated cosmological functions.",
    long_description=long_description,
    long_description_content_type='text/markdown',
    author="LSST DESC",
    url="https://github.com/LSSTDESC/CCL",
    packages=find_packages(),
    provides=['pyccl'],
    package_data={
        'pyccl': ['_ccllib.so']
    },
    include_package_data=True,
    use_scm_version=True,
    setup_requires=['setuptools_scm'],
    install_requires=['numpy', 'pyyaml'],
    include_dirs=[numpy.get_include()],
    cmdclass={'build_py': build, 'develop': develop},
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved',
        'Operating System :: MacOS :: MacOS X',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: C',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Topic :: Scientific/Engineering :: Physics'
      ]
    )
