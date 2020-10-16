      subroutine wfirdf (en,ch,nq,kap,nmax,ido)
c     calculate initial orbiatls from integration of dirac equation
c cg (cp) large (small) radial components
c bg (bp) development coefficients at the origin of cg (cp)
c en one-electron energies
c fl power of the first term of development at the origin
c ch ionicity (nuclear charge - number of electrons)
c nq principal quantum number
c kap quantum number "kappa"
c nmax number of tabulation points for the orbitals
c ibgp first dimension of the arrays bg and bp
c        this programmes utilises nucdev,dentfa,soldir et messer

      implicit double precision (a-h,o-z)
      common cg(251,30), cp(251,30), bg(10,30), bp(10,30),
     1         fl(30), fix(30), ibgp
      dimension en(30),nq(30),kap(30),nmax(30)
      common/comdir/cl,dz,dg(251),ag(10),dp(251),ap(10),
     1dv(251),av(10),eg(251),ceg(10),ep(251),cep(10)
      common/itescf/testy,rap(2),teste,nz,norb,norbsc
      common/inelma/nem
      common/messag/dlabpr,numerr
      character*8 dlabpr
      character*512 slog
      common/snoyau/dvn(251),anoy(10),nuc
      common/tabtes/hx,dr(251),test1,test2,ndor,np,nes,method,idim
c#mn
       external dentfa

      cl=1.370373d+02
c    speed of light in atomic units
      dz = nz
c make r-mesh and calculate nuclear potential
c hx exponential step
c dr1 first tabulation point multiplied by nz
      hx=5.0d-02
      dr1= nz*exp(-8.8)
      call nucdev (anoy,dr,dvn,dz,hx,nuc,idim,ndor,dr1)
c notice that here nuc=1,
c unless you specify nuclear mass and thickness in nucdev.f

      a=(dz/cl)**2
      if (nuc.gt.1) a=0.0d 00
      do j=1,norb
         b=kap(j)*kap(j)-a
         fl(j)= sqrt(b)
c        quick fix of development coefficients. ala
         fix(j) = dr(1)**(fl(j)-abs(kap(j)))
      enddo
c calculate potential from thomas-fermi model
      do i=1,idim
         dv(i)=(dentfa(dr(i),dz,ch)+dvn(i))/cl
      enddo
      if (numerr.ne.0) return
      do i=1,idim
         eg(i)=0.0d 00
         ep(i)=0.0d 00
      enddo
      do i=1,ibgp
         ceg(i)=0.0d 00
         cep(i)=0.0d 00
         av(i)=anoy(i)/cl
      enddo
      av(2)=av(2)+dentfa(dr(nuc),dz,ch)/cl
      test1=testy/rap(1)
      b=test1

c resolution of the dirac equation to get initial orbitals
      if (ido.ne.1) then
         call wlog('only option ido=1 left')
         ido = 1
      endif
c  here was a piece to read orbitals from cards
      do j=1,norb
         bg(1,j)=1.0d 00
         i=nq(j)- abs(kap(j))
         if (kap(j).lt.0) i=i-1
         if (mod(i,2).eq.0) bg(1,j)=-bg(1,j)
         if (kap(j).ge.0) then
            bp(1,j)=bg(1,j)*cl*(kap(j)+fl(j))/dz
            if (nuc.gt.1) bg(1,j)=0.0d 00
            go to 211
         endif
         bp(1,j)=bg(1,j)*dz/(cl*(kap(j)-fl(j)))
         if (nuc.gt.1) bp(1,j)=0.0d 00
 211     continue
         np=idim
         en(j)=-dz*dz/nq(j)*nq(j)
         method=0
         ifail = 0
         call soldir
     1     (en(j),fl(j),bg(1,j),bp(1,j),b,nq(j),kap(j),nmax(j),ifail)

         if (numerr.ne.0) then
            call messer
            write(slog,'(a,2i3)')
     1  'soldir failed in wfirdf for orbital nq,kappa ',nq(j),kap(j)
            call wlog(slog)
         else
            do i=1,ibgp
               bg(i,j)=ag(i)
               bp(i,j)=ap(i)
            enddo
            do i=1,np
               cg(i,j)=dg(i)
               cp(i,j)=dp(i)
            enddo
         endif
      enddo

      nem=0
      return
      end
