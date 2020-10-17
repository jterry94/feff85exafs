      subroutine dfovrg (ncycle, ikap, rmt, jlast, jri, p2, dx,
     1                  ri, vxc, vxcval, dgcn, dpcn, adgc, adpc,
     2                  xnval, pu, qu, ps, qs,
     2                  iz, ihole, xion, iunf, irr, ic3)
c     Dirac equation solver for complex energy
c     coded by a.ankudinov 1996
c     modified by a.ankudinov 1997 to get irregular solution 

c     fully relativistic version of subroutine fovrg.f
c     input:
c        ncycle  times to calculate photoelectron wave function
c                with nonlocal exchange
c        ikap    quantum number kappa for photoelectron
c        rmt     muffin-tin radius
c        jri     first interstitial grid point (imt + 1)
c        jlast   last point for integration of Dirac eq.
c        p2      current complex energy
c        dx      dx in loucks' grid (usually .05)
c        ri(nr)  loucks' position grid, r = exp ((i-1)*dx - 8.8)
c        vxc(nr) coulomb+xc potential for total density
c        vxcval  coulomb+xc potential for valence density
c        both vxc and vxcval include coulomb and nuclear potential
c        dgcn(dpcn) large(small) dirac components for 'iph' atom
c        adgc(adpc) their development coefficients
c     work space:
c        must be dimensioned in calling program.  coded like this
c        to make using different r-grids with different nrmax easy.
c
c     output:
c        pu, qu  upper and lower components at muffin tin
c        ps and qs are  upper and lower components for photoelectron

      implicit double precision (a-h, o-z)
      include '../HEADERS/dim.h'
      include '../HEADERS/const.h'

      complex*16 vxc(nrptx), vxcval(nrptx), p2
      dimension ri(nrptx)
      complex*16 pu, qu, vu, vm(nrptx)
      complex*16 ps(nrptx), qs(nrptx), aps(10),aqs(10)
c      complex*16 ph0, amp

c     all atoms' dirac components and their development coefficients
      dimension dgcn(nrptx,30), dpcn(nrptx,30)
      dimension adgc(10,30), adpc(10,30)
 
c     iph atom's dirac components and their development coefficients
      common/dff/cg(nrptx,30), cp(nrptx,30), bg(10,30), bp(10,30),
     1             fl(30), fix(30), ibgp
c     fl power of the first term of development limits.
c     ibgp first dimension of the arrays bg and bp (=10)

      complex*16 gg,gp,ag,ap,dv,av,bid
      common/comdic/cl,dz,gg(nrptx),ag(10),gp(nrptx),ap(10),
     1              dv(nrptx),av(10),bid(2*nrptx+20)
c      gg,gp are the input and output for solout
      common/itescf/testy,rap(2),teste,nz,norb,norbsc
      common/mulabc/afgkc
      dimension afgkc(-ltot-1:ltot,30,0:3)
      common/messag/dlabpr,numerr
      character*8 dlabpr
c      xnel here - number of core electrons only
      common/ratom1/xnel(30),en(30),scc(30),scw(30),sce(30),
     1nq(30),kap(30),nmax(30)
      common/scrhf1/eps(435),nre(30),ipl
      common/snoyac/dvn(nrptx),anoy(10),nuc
      common/tabtec/hx,dr(nrptx),test1,test2,ndor,np,nes,method,idim
      dimension xnval(30)

c     initialize the data and test parameters
      ndor = 3
      cl = alpinv
      if (irr.gt.0) then
c        for irregular solution
         ndor=2
         aps(1) =  pu
         aqs(1) =  qu
         do i=1, jri
           gg(i) = ps(i)
           gp(i) = qs(i)
        enddo
      endif
      do i = jri+1,nrptx
         vxc(i)=vxc(jri+1)
         vxcval(i)=vxc(jri+1)
      enddo
      ibgp=10
      numerr = 0
      nz = iz
      hx = dx
      idim= 1 + nint(250*0.05/dx)
      if (idim .gt. nrptx) idim = nrptx
      if (mod(idim,2) .eq. 0) idim=idim-1
      
c     numerical integration of Dirac eq. works if you have 6 grid points
c     for one period of oscillations, switch to analytical expression
c     for a steplike potential  at large distances
      aa = 0.5
c     if (irr.gt.0) aa = 0.05
      rwkb = aa / dx / sqrt(abs(2*p2+(p2/cl)**2))
      x0 = 8.8
      iwkb= int((log(rwkb) + x0) / dx)  +  2
      if (iwkb.gt.idim) iwkb = idim
      if (iwkb.lt. 10) iwkb = 10
      
c     copy information into common's of atomic code
      do j=1,30
         do i=1,10
            bg(i,j)=adgc(i,j) 
            bp(i,j)=adpc(i,j)
         enddo
      enddo
      do j=1,30
         do i=1,idim
            cg(i,j)=dgcn(i,j) 
            cp(i,j)=dpcn(i,j) 
         enddo
      enddo
      call inmuac (ihole, xion, iunf, ikap)
      nmax(norb)=jlast
      if (iwkb.ge. jlast-1) iwkb = idim
c     note that here norb correspond to photoelectron

c     calculate initial photoelectron orbital using lda
      call diff (vxc,ri,ikap,cl,hx,jri,vm)
      do i = jri, nrptx
         vm(i)=0.0d0
      enddo
      call wfirdc (p2,kap,nmax,vxc,ps,qs,aps,aqs,irr,ic3,vm,
     1     jri, iwkb)
c     1             rmt,jri, iwkb)

      if (numerr .ne. 0) call par_stop('error in wfirdc')
      if (ncycle .eq. 0) go to 999

c     to get orthogonalized photo e w.f., use alternative exit below
c     in general it should not be orthogonolized. Use for testing only 
c     ala

c     further need only core electrons for exchange term
      do i=1, norb-1
         xnel(i) = xnel(i) - xnval(i)
      enddo
c     take vxcval at the origin as vxcval=vcoul +const1 + i*const2
      av(2)=av(2)+(vxcval(1)-vxc(1))/cl
      do i=1,iwkb
         dv(i)=vxcval(i)/cl
      enddo
c     keep dv=vxc/cl above iwkb

      nter=0
 
c     angular coefficients 
      call muatcc(xnval)

c     no orthogonalization needed. Looking for g.f., not w.f.
c     if (ipl.ne.0) call ortdac (ikap,ps,qs,aps,aqs)
c     ortdac orthogonalizes photoelectron orbital to core orbitals
c     have to use exchange 5 card to exit here; also want vxc=vxcval
c     if (ncycle .eq. 0) go to 999

c     iteration over the number of cycles
 101  continue
         nter=nter+1
c        calculate exchange potential
         jriwkb = min (jri, iwkb)
         call potex( ps, qs, aps, aqs, jriwkb)
c         call potex( ps, qs, aps, aqs, jriwkb, p2)

c        resolution of the dirac equation
         if (irr.lt.0) then
c            call solout (p2, fl(norb), aps(1), aqs(1), ikap, rmt,
c     1        jri, nmax(norb), ic3, vm, iwkb)
            call solout (p2, fl(norb), aps(1), aqs(1), ikap,
     1        jri, nmax(norb), ic3, vm, iwkb)
         else
c            call solin (p2, fl(norb), pu, qu, ikap, rmt,
c     1        jri, nmax(norb), ic3, vm, iwkb)
            call solin (p2, fl(norb), ikap,
     1        jri, nmax(norb), ic3, vm, iwkb)
         endif

c     no orthogonalization needed. Looking for g.f., not w.f.
c        if (ipl.ne.0) call ortdac (ikap,gg,gp,ag,ap)

c        acceleration of the convergence 
         scc(norb)=1.0d0
         do i=1,idim
            ps(i)=gg(i)
            qs(i)=gp(i)
         enddo
         do i=1,ndor
            aps(i) =ag(i) 
            aqs(i) =ap(i) 
         enddo
      if (nter.le.ncycle) go to 101

 999  if (numerr .eq. 0) then
        if (irr.lt.0 ) then
cc        need pu, qu for regular solution
cc        want to have vxc(jri)-smooth and vxc(jri+1)=v_mt
cc        assume no exchange beyond jri 
           vu=vxc(jri+1)
           call flatv 
     1     (ri(jri), rmt, ps(jri), qs(jri), p2, vu, ikap, pu, qu)
           jlast = nmax(norb)
c          jlast might change on very rare occasion
        endif

      else
        call par_stop('error in dfovrg.f')
      endif

      return
      end

      subroutine flatv (r1, r2, p1, q1, en, vav, ikap, p2, q2)
      implicit double precision (a-h, o-z)
      include '../HEADERS/const.h'
      include '../HEADERS/dim.h'
c     solution of Dirac equation for flat potential for ikap is known
c     exactly (see e.g. in Loucks T.L. eq. 4-19)
c     given p1 and q1 at point r1 this subrotuine finds p2, q2 at r2
c     for given energy(en) and average potential (vav)
c     en and vav in hartrees
      external besjn, atancc

      complex*16 p1, q1, en, vav, p2, q2
      complex*16 ck, xkr, jl(ltot+2), nl(ltot+2), a,b, factor 

c     initialize staff
      ck = sqrt(2*(en-vav) + (alphfs*(en-vav))**2)
      xkr = ck*r1
      if (ikap.lt.0) then
        isign = -1
        lp = -ikap - 1
        lq = lp + 1
      else
        isign = 1
        lp = ikap
        lq = lp - 1
      endif
      a = ck * alphfs
      factor = isign*a/(1+sqrt(1+a**2))

c     find a and b that p1 = r1*(a*jl+b*nl), q1=factor*r1*(a*jl'+b*nl')
      call besjn (xkr, jl, nl)
      a = isign*ck*xkr* (p1*nl(lq+1) - q1*nl(lp+1)/factor)
      b = isign*ck*xkr* (q1*jl(lp+1)/factor - p1*jl(lq+1))

c     get values at r2
      xkr = ck * r2
      call besjn (xkr, jl, nl)
      p2 =  r2 * (jl(lp+1)*a + nl(lp+1)*b)
      q2 =  r2* factor * (jl(lq+1)*a + nl(lq+1)*b)

      return
      end

