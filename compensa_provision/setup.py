""" Setup file """
from setuptools import setup
import versioneer


setup(
    name = 'compensa-provision',
    version=versioneer.get_version(),
    cmdclass=versioneer.get_cmdclass(),
)
