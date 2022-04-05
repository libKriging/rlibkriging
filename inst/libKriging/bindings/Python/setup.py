import os
import re
import sys
import platform
import subprocess
import argparse

from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from distutils.version import LooseVersion


def find_in_path(filename):
    fpath, fname = os.path.split(filename)
    if fpath:
        if os.path.isfile(fpath):
            return filename
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            test_file = os.path.join(path, filename)
            if os.path.isfile(test_file):
                return test_file
    raise RuntimeError(f"Cannot find required file '{filename}'")


extra_libs = []
if platform.system() == "Windows":
    extra_libs = [find_in_path(f) for f in ['flang.dll', 'flangrti.dll', 'libomp.dll', 'openblas.dll']]

argparser = argparse.ArgumentParser(add_help=False)
argparser.add_argument('--debug', action="store_true", help='compile in debug mode')
args, unknown = argparser.parse_known_args()
sys.argv = [sys.argv[0]] + unknown


class CMakeExtension(Extension):
    def __init__(self, name, sourcedir=''):
        Extension.__init__(self, name, sources=[])
        self.sourcedir = os.path.abspath(sourcedir)


class CMakeBuild(build_ext):
    def run(self):
        try:
            out = subprocess.check_output(['cmake', '--version'])
        except OSError:
            raise RuntimeError("CMake must be installed to build the following extensions: " +
                               ", ".join(e.name for e in self.extensions))

        cmake_version = LooseVersion(re.search(r'version\s*([\d.]+)', out.decode()).group(1))
        if cmake_version < '3.1.0':
            raise RuntimeError("CMake >= 3.1.0 is required on Windows")

        for ext in self.extensions:
            self.build_extension(ext)

    def build_extension(self, ext):
        extdir = os.path.abspath(os.path.dirname(self.get_ext_fullpath(ext.name)))
        # required for auto-detection of auxiliary "native" libs
        if not extdir.endswith(os.path.sep):
            extdir += os.path.sep

        print('extdir:', extdir)
        print('Python executable', sys.executable)

        cmake_args = ['-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=' + extdir,
                      '-DENABLE_PYTHON_BINDING=on',
                      '-DBUILD_SHARED_LIBS=off',
                      '-DPYTHON_EXECUTABLE=' + sys.executable,
                      f'-DKRIGING_VERSION={self.distribution.get_version()}'
                      ]

        cfg = 'Debug' if args.debug else 'Release'
        print('build mode:', cfg)
        build_args = ['--config', cfg]

        if platform.system() == "Windows":
            cmake_args += ['-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_{}={}'.format(cfg.upper(), extdir)]
            if sys.maxsize > 2 ** 32:
                cmake_args += ['-A', 'x64']
            build_args += ['--', '/m']
        else:
            cmake_args += ['-DCMAKE_BUILD_TYPE=' + cfg]
            build_args += ['--', '-j2']

        print("version", self.distribution.get_version())

        env = os.environ.copy()
        env['CXXFLAGS'] = env.get('CXXFLAGS', '')
        print('env:', env['CXXFLAGS'])

        if not os.path.exists(self.build_temp):
            os.makedirs(self.build_temp)
        subprocess.check_call(['cmake', ext.sourcedir] + cmake_args, cwd=self.build_temp, env=env)
        subprocess.check_call(['cmake', '--build', '.'] + build_args, cwd=self.build_temp)


with open("cmake/version.cmake", "r") as file:
    data = file.read()

version_major = re.search(r"^set\(KRIGING_VERSION_MAJOR (\d+)\)$", data, re.M)
version_minor = re.search(r"^set\(KRIGING_VERSION_MINOR (\d+)\)$", data, re.M)
version_patch = re.search(r"^set\(KRIGING_VERSION_PATCH (\d+)\)$", data, re.M)
version = f"{version_major.group(1)}.{version_minor.group(1)}.{version_patch.group(1)}"

# with open("README.md", "r", encoding="utf-8") as fh:
#     long_description = fh.read()

setup(
    name='pylibkriging',
    packages=['pylibkriging'],
    version=version,
    author='Pascal Havé',
    author_email='hpwxf@haveneer.com',
    url="https://github.com/libKriging/libKriging",
    description='Python binding for LibKriging',
    long_description='Python support for libKriging, the kriging library for performance and wide language support',
    # long_description_content_type="text/markdown",
    ext_modules=[CMakeExtension('pylibkriging', sourcedir=".")],
    cmdclass=dict(build_ext=CMakeBuild),
    script_name='./bindings/Python/setup.py',
    package_dir={'pylibkriging': 'bindings/Python/src/pylibkriging'},
    # https://docs.python.org/3/distutils/setupscript.html#installing-package-data
    package_data={'pylibkriging': []},
    # https://docs.python.org/3/distutils/setupscript.html#installing-additional-files
    data_files=[('lib/site-packages/pylibkriging/shared_libs', extra_libs)],
    python_requires='>=3.6',
    install_requires=["numpy>=1.17"],
    zip_safe=False,
)