""" Setup file """
from setuptools import setup
from setuptools import find_packages
from glob import glob
from os.path import splitext
from os.path import basename
import versioneer

setup(
    name = 'an0016001-gsfc-compensacionprovision',
    description = 'Consolida movimientos de CEAUTOEDT y CEAUTOE asigna cuentas BankVision mediante ALLINF y las homologa con cuentas SAPFI',
    url = 'https://GrupoBancolombia@dev.azure.com/GrupoBancolombia/Vicepresidencia%20de%20Innovaci%C3%B3n%20y%20Transformaci%C3%B3n%20Digital/_git/an0016001-gsfc-compensacionprovision',
    author = 'emzulu',
    author_email = 'emzulu@bancolombia.com.co',
    license = '...',
    packages = find_packages('src'),
    package_dir={'': 'src'},
    py_modules=[splitext(basename(path))[0] for path in glob('src/*.py')],
    python_requires='>=3.9.12',
    entry_points = {
        'console_scripts': ['an0016001_gsfc_compensacionprovision = an0016001_gsfc_compensacionprovision.ejecucion:main']
    },
    install_requires = [
        'future_fstrings',
        'orquestador2>=1.4.0'
    ],
    include_package_data = True,
    version=versioneer.get_version(),
    cmdclass=versioneer.get_cmdclass(),
)
