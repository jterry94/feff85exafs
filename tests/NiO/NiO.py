
from os.path import realpath, exists, join

from larch import Group
from larch.fitting import param_group, Parameter
from larch.io import read_xdi
from larch.xafs import feffit_dataset, feffit_transform, feffit, feffit_report, feffpath
from larch.wxlib import _newplot, _plot

def do_fit(self, which):

    if which == 'testrun':
        folder = self.testrun
    else:
        folder = self.baseline

    data = read_xdi(join(self.path, 'NiO.chik'))
    if hasattr(data, 'wavenumber'):
        data.k = data.wavenumber

    gds = param_group(amp    = Parameter(1,      vary=True),
                      enot   = Parameter(0.01,   vary=True),
                      alpha  = Parameter(0.0001, vary=True),
                      sso    = Parameter(0.003,  vary=True),
                      ssni   = Parameter(0.003,  vary=True),
                      sso2   = Parameter(0.003,  vary=True),
                      #sso3   = Parameter(0.003,  vary=True),
                      ssni2  = Parameter(0.003,  vary=True),
                      #ssni3  = Parameter(0.003,  vary=True),
                      #ssni4  = Parameter(0.003,  vary=True),
                      )

    paths = list()
    paths.append(feffpath(realpath(join(folder, "feff0001.dat")), # 1st shell O SS
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'sso',
                          deltar = 'alpha*reff'))

    paths.append(feffpath(realpath(join(folder, "feff0002.dat")), # 2nd shell Ni SS
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'ssni',
                          deltar = 'alpha*reff'))
    paths.append(feffpath(realpath(join(folder, "feff0003.dat")), # O-O triangle
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = '1.5*sso',
                          deltar = 'alpha*reff'))
    paths.append(feffpath(realpath(join(folder, "feff0004.dat")), # O-Ni triangle
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'sso+ssni',
                          deltar = 'alpha*reff'))
    paths.append(feffpath(realpath(join(folder, "feff0005.dat")), # 3rd shell O SS
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'sso2',
                          deltar = 'alpha*reff'))
    paths.append(feffpath(realpath(join(folder, "feff0006.dat")), # 4th shell Ni SS
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'ssni2',
                          deltar = 'alpha*reff'))
    paths.append(feffpath(realpath(join(folder, "feff0007.dat")), # O-O non-forward linear
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'sso*2',
                          deltar = 'alpha*reff'))
    paths.append(feffpath(realpath(join(folder, "feff0008.dat")), # O-Ni forward scattering
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'ssni2',
                          deltar = 'alpha*reff'))
    paths.append(feffpath(realpath(join(folder, "feff0009.dat")), # O-O forward through absorber
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'sso*2',
                          deltar = 'alpha*reff'))
    paths.append(feffpath(realpath(join(folder, "feff0010.dat")), # O-Ni-O double forward
                          s02    = 'amp',
                          e0     = 'enot',
                          sigma2 = 'ssni2',
                          deltar = 'alpha*reff'))


    trans = feffit_transform(kmin=3, kmax=15.938, kw=(2,1,3), dk=1, window='hanning', rmin=1.5, rmax=4.2)
    dset  = feffit_dataset(data=data, pathlist=paths, transform=trans)
    fit   = feffit(gds, dset)

    if self.doplot:
        offset = 0.6*max(dset.data.chir_mag)
        _newplot(dset.data.r,  dset.data.chir_mag+offset, xmax=8, win=2,
              xlabel=r'$R \rm\,(\AA)$', label='data',
              ylabel=r'$|\chi(R)| \rm\,(\AA^{-3})$',
              title='Fit to '+self.folder, show_legend=True)
        _plot(dset.model.r, dset.model.chir_mag+offset, label='fit', win=2)
        _plot(dset.data.r,  dset.data.chir_re, label='data', win=2)
        _plot(dset.model.r, dset.model.chir_re, label='fit', win=2)
    #end if

    if self.verbose:
        print(feffit_report(fit))
    #end if

    return fit
#end def
