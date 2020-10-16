      subroutine etotal (io, kap, xnel, xnval, en, eatom)
c combined from original subroutines tabfgk,tabbre,tabrat.
c io  label for output file atomNN.dat
c kap quantum number "kappa"
c xnel occupation of  orbitals
c en one-electron energies
c fdrirk function calculating radial integrals rk
c akeato angular coefficient for integrals  fk, for the
c integrals fk(i;i) gives angular coefficients multiplied by 2
c bkeato angular coefficient for integrals  gk
c coul ener(1) direct coulomb interaction
c ech  ener(2) exchange coulomb interaction
c        * average value of the breit hamiltonian *
c fdrocc function of the orbitals' occupations.
c bkmrdf is a programm to calculate angular coefficients
c ema ener(3) magnetic energy
c ere ener(4) retardation term
c        this program uses akeato,bkeato
c        fdrocc fdrirk bkmrdf

      implicit double precision (a-h,o-z)
      include '../HEADERS/const.h'

      dimension kap(30),xnel(30),en(30), xnval(30)
      common/itescf/testy,rap(2),teste,nz,norb,norbsc
      dimension mk(12),ener(4)
      dimension cer(17),mbi(9),mii(9),mjj(9)
      common/tabre/cmag(3),cret(3)
      common/inelma/nem
      common/print/iprint
      character*4 iner(4)
      logical io_open

      external akeato, bkeato, fdrirk, fdmocc
      data iner/'coul','ech.','mag.','ret.'/

      do i = 1,4
         ener(i)=0.0d0
      enddo
      iv=0
c       fk  integrales
      do i=1,norb
         l= abs(kap(i))-1
         do j=1,i
            a=1.0d 00
            if (j.eq.i) a=a+a
            m= abs(kap(j))-1
            kmi=2* min(l,m)
            k=0
 20         iv=iv+1
            cer(iv)=fdrirk(i,i,j,j,k)
            ener(1) = ener(1) + cer(iv) * akeato(i,j,k) / a
            mk(iv)=k
            if (iv.lt.3) go to 30
            iv=0
 30         k=k+2
            if (k.le.kmi) go to 20
         enddo
      enddo

      iv=0
      if (norb.gt.1) then
c       gk  integrales
         do i=2,norb
            a = 1.0d0
            if (xnval(i) .gt. 0.0d0) a=0.5d0
            i1=i-1
            do j=1,i1
               if (xnval(j) .gt. 0.0d0) goto 70
               l= abs(kap(i))
               m= abs(kap(j))
               k= abs(l-m)
               if ((kap(i)*kap(j)).lt.0) k=k+1
               kmi=l+m-1
 50            iv=iv+1
               cer(iv)=fdrirk(i,j,i,j,k)
               ener(2) = ener(2) - cer(iv) * bkeato(i,j,k) * a
               mk(iv)=k
               if (iv.lt.3) go to 60
               iv=0
 60            k=k+2
               if (k.le.kmi) go to 50
 70            continue
            enddo
         enddo
      endif
c
      nem=1
c       direct  integrals
      ik=0
      do j=1,norb
         jj=2* abs(kap(j))-1
         do i=1,j
            ji=2* abs(kap(i))-1
            k=1
            kma= min(ji,jj)
 110        ik=ik+1
            mbi(ik)=k
            mii(ik)=i
            mjj(ik)=j
            cer(ik)=fdrirk(j,j,i,i,k)
            if (i.ne.j) go to 120
            call bkmrdf (j,j,k)
            ener(3) = ener(3) + (cmag(1) + cmag(2) + cmag(3)) *
     1                cer(ik) * fdmocc(j,j) / 2.0d 00
 120        if (ik.lt.3) go to 130
            ik=0
 130        k=k+2
            if (k.le.kma) go to 110
         enddo
      enddo
      if (norb.gt.1) then
c       echange  integrals
         do j=2,norb
            lj= abs(kap(j))
            na=-1
            if (kap(j).gt.0) go to 121
            na=-na
            lj=lj-1
 121        jp=j-1
            do l=1,jp
               ll= abs(kap(l))
               nb=-1
               if (kap(l).gt.0) go to 131
               nb=-nb
               ll=ll-1
 131           b=fdmocc(j,l)
               nm1= abs(lj+na-ll)
               nmp1=ll+lj+nb
               nmm1=ll+lj+na
               np1= abs(ll+nb-lj)
               k= min(nm1,np1)
               kma=max(nmp1,nmm1)
               if (mod(k+ll+lj,2).eq.0) k=k+1
               nb= abs(kap(j))+ abs(kap(l))
 141           call bkmrdf (j,l,k)
               do i=1,3
                  cer(i)=0.0d 00
               enddo
               if (nb.le.k.and.kap(l).lt.0.and.kap(j).gt.0) go to 161
               cer(1)=fdrirk(l,j,l,j,k)
               cer(2)=fdrirk(0,0,j,l,k)
 161           if (nb.le.k.and.kap(l).gt.0.and.kap(j).lt.0) go to 171
               cer(3)=fdrirk(j,l,j,l,k)
               if (cer(2).ne.0.0d 00) go to 171
               cer(2)=fdrirk(0,0,l,j,k)
 171           do i = 1, 3
                  ener(3) = ener(3) + cmag(i) * cer(i) * b
                  ener(4) = ener(4) + cret(i) * cer(i) * b
               enddo
               k=k+2
               if (k.le.kma) go to 141
            enddo
         enddo
      endif

c     total   energy
      eatom = - (ener(1) + ener(2)) + ener(3) + ener(4)
      do j = 1, norb
         eatom = eatom + en(j) * xnel(j)
      enddo
      inquire(unit=io,opened=io_open)
      if (iprint .ge. 5 .and. io_open)
     .  write (io, '(a,1pd18.7)') 'etot', eatom*hart
      do i = 1, 4
        if (iprint.ge.5 .and. io_open)
     .    write(io, '(a4,1pd18.7)') iner(i), ener(i)*hart
      enddo
      return
      end
