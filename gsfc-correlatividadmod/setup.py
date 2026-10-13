""" Setup file """
from setuptools import setup
import versioneer


setup(    
    name = 'an0016001-gsfc-correlatividadmod',
    version=versioneer.get_version(),
    cmdclass=versioneer.get_cmdclass(),
)
