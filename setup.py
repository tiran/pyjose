import os
import shlex
import subprocess
import sys

from setuptools import setup
from setuptools.extension import Extension

try:
    from Cython.Build import cythonize
except ImportError:
    def cythonize(extensions, **kwargs):
        for extension in extensions:
            for i, filename in enumerate(extension.sources):
                if filename.endswith('.pyx'):
                    extension.sources[i] = filename[:-4] + '.c'
                    if not os.path.isfile(extension.sources[i]):
                        raise
        return extensions

test_requires = ['pytest']
test_pep8_requires = ['flake8', 'flake8-import-order', 'pep8-naming']
test_docs_requires = ['docutils', 'markdown']
extra_compile_args = []
extra_link_args = []


def pkgconfig(flags, *pkgs):
    cmd = ['pkg-config', flags]
    cmd.extend(pkgs)
    out = subprocess.check_output(cmd)
    if isinstance(out, bytes):
        out = out.decode(sys.getfilesystemencoding())
    return shlex.split(out)


JOSE_DIR = os.environ.get('JOSE_DIR')
if JOSE_DIR and os.path.isdir(JOSE_DIR):
    JOSE_DIR = os.path.abspath(JOSE_DIR)
    JOSE_LIBRARY_DIR = os.path.join(JOSE_DIR, '.libs')
    os.environ['PKG_CONFIG_PATH'] = JOSE_DIR
    extra_compile_args.append('-I' + JOSE_DIR)
    extra_link_args.append('-L' + JOSE_LIBRARY_DIR)
    extra_link_args.append('-Wl,-rpath,' + JOSE_LIBRARY_DIR)


extra_compile_args.extend(
    pkgconfig('--cflags', 'jose-openssl', 'jose-zlib'))
extra_link_args.extend(
    pkgconfig('--libs', 'jose-openssl', 'jose-zlib'))


extensions = [
    Extension(
        'jose._jose',
        sources=['_jose.pyx'],
        depends=['src/jose/jansson.pxd', 'src/jose/jose.pxd', 'setup.py'],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
    ),
]


setup(
    name='jose',
    description='Cython wrapper for libjose',
    ext_modules=cythonize(extensions, include_path=['src/jose']),
    version='4',
    license='Apache 2.0',
    maintainer='Latchset Contributors',
    maintainer_email='cheimes@redhat.com',
    url='https://github.com/latchset/pyjose',
    packages=['jose'],
    package_dir={'jose': 'src/jose'},
    package_data={'jose': ['*.pxd']},
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Programming Language :: Cython',
        'Programming Language :: C',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3.5',
        'Intended Audience :: Developers',
        'Topic :: Security',
        'Topic :: Software Development :: Libraries :: Python Modules'
    ],
    tests_require=test_requires,
    extras_require={
        'test': test_requires,
        'test_docs': test_docs_requires,
        'test_pep8': test_pep8_requires,
    },
)
