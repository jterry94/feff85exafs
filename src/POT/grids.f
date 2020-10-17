      subroutine  grids ( ecv, xmu, negx, neg, emg , step, nflrx)
c     makes a grid in complex e-plane for scmt calculation
c     add complications for complex cases later. ala
c     emg is comlex energy in hartrees
      implicit double precision (a-h, o-z)

      complex*16 emg(negx), eim, eimmin
      dimension step(nflrx)
      include '../HEADERS/const.h'

c     the choice of e_cv should be automated later
c     all l-dos should be zero at ecv
c     fix it by hand if needed below
c     for some complicated materials may need multiple e_cv
c     it may also depend on core-valence separation

c     eimmin = the lowest im energy to search for fermi level
c     may simulate Fermi distr for occ numbers, thus may want
c     to lower eimmin for low temperatures.
      eimmin = coni*0.05d0/hart
      neg1 = (nflrx+1)/2
      neg3 = nflrx - 1
      neg2mx = negx-neg1-neg3
c     never do calculations on real axis.
      eim = eimmin*neg1**2
      eim = eimmin 
      de = dimag(eim)/4

      do i =1, neg1
c        step linearly increases as one get farther from real axis
         eim = eimmin *i**2
         emg(i) = ecv +eim
      enddo
      step(nflrx) = dimag(eim)/4

c     set energy step for integration eim above real axis
      de = dimag(emg(neg1))/4
      neg2= nint((xmu-ecv)/de)
      if (neg2.gt.neg2mx) neg2=neg2mx
      if (neg2.lt.neg1) neg2 = neg1
      de = (xmu-ecv) / neg2
      do i = neg1+1,neg1+neg2
         emg(i) = emg(i-1) + de
      enddo

      neg = neg1 + neg2 + neg3
      do i =1, neg3
c        step linearly increases as one get farther from real axis
         eim = eimmin *(i+1)**2 /4.d0
         if (i.le.nflrx) step(i) = dimag(eim)/4
         emg(neg-i+1) = xmu + eim
      enddo

      return
      end
