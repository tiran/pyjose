import os

from setuptools import setup
from setuptools.extension import Extension
try:
    from Cython.Build import cythonize
except ImportError:
    def cythonize(extensions):
        return extensions


requirements = []
test_requires = ['pytest']
test_pep8_requires = ['flake8', 'flake8-import-order', 'pep8-naming']
test_docs_requires = ['docutils', 'markdown']

JOSE_DIR = os.path.abspath(os.environ.get('JOSE_DIR', '../jose'))
JOSE_LIBRARY_DIR = os.path.join(JOSE_DIR, '.libs')

extensions = [
    Extension(
        'jose',
        sources=['jose.pyx'],
        depends=['jansson.pxd', 'jose.pxd', 'setup.py'],
        include_dirs=[JOSE_DIR],
        libraries=['jose', 'jose-openssl', 'jose-zlib'],
        library_dirs=[JOSE_LIBRARY_DIR],
        extra_link_args=['-Wl,-rpath,' + JOSE_LIBRARY_DIR],
    ),
]

with open('README') as f:
    long_description = f.read()

setup(
    name='jose',
    description='Cython wrapper for libjose',
    long_description=long_description,
    ext_modules=cythonize(extensions),
    version='4',
    license='Apache 2.0',
    maintainer='Latchset Contributors',
    maintainer_email='cheimes@redhat.com',
    url='https://github.com/latchset/pyjose',
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
    install_requires=requirements,
    tests_require=test_requires,
    extras_require={
        'test': test_requires,
        'test_docs': test_docs_requires,
        'test_pep8': test_pep8_requires,
    },
)
