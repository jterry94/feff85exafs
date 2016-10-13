

FORTRAN  = gfortran
F90      = -std=f2008
F90FLAGS = -c -O2 -fbacktrace -g -Wall -Wextra -Wno-maybe-uninitialized -pedantic
FJSON    = -I/home/bruce/git/feff85exafs/src/json-fortran -J/home/bruce/git/feff85exafs/src/json-fortran
AR       = ar
ARFLAGS  = rc
RANLIB   = ranlib
RM       = rm

all:	json_module.mod json_module.o libjsonfortran.a

json_module.mod json_module.o:	json_module.f90
	$(FORTRAN) $(F90) $(F90FLAGS) -o $@ $<

libjsonfortran.a:
	$(AR) $(ARFLAGS) libjsonfortran.a json_module.o
	$(RANLIB) libjsonfortran.a

clean:
	$(RM) *.a *.o *.mod

.PHONEY:	clean all