c      subroutine solin (en,fl,agi,api,kap,rmt,jri,imax,ic3,vm, iwkb)
      subroutine solin (en,fl,kap,jri,imax,ic3,vm, iwkb)
c                  resolution of the dirac equation
c                   p' - kap*p/r = - ( en/cl-v )*g - eg/r
c                   g' + kap*g/r = ( 2*cl+en/cl-v )*p + ep/r
c at the origin v approximately is -z/(r*cl) due to the point nucleus
c en one-electron energy in atomic units and negative
c fl power of the first term in development at the origin
c agi (api) initial values of the first development coefficient
c at the origin of the large(small)component
c kap quantum number kappa
c imax the last point of tabulation of the wave function

      implicit double precision (a-h,o-z)
      include '../HEADERS/dim.h'
      include '../HEADERS/const.h'
      parameter (npi=6, test=1.0d+5)
      complex*16 en,c3,vmh
c      complex*16 agi,api
      complex*16 gg,ag,gp,ap,dv,av,eg,ceg,ep,cep, vm(nrptx)
      common/comdic/cl,dz,gg(nrptx),ag(10),gp(nrptx),ap(10),dv(nrptx),
     1   av(10),eg(nrptx),ceg(10),ep(nrptx),cep(10)

      complex*16 ec,eph,f,g,ac,bc,acp,bcp,dg,dp
c      complex*16 egh, vh
c      complex*16 dg2, dp2, dg3, dp3, dg4, dp4
      dimension dg(npi), dp(npi)

c gg,gp -output, dv,eg,ep - input
c
c cl speed of light (approximately 137.037 in atomic units)
c dz nuclear charge
c gg (gp) large (small) component
c dv direct potential (v)     eg and ep exchange potentials
c ag,ap,av,ceg and cep are respectively the
c development coefficients for gg,gp,dv,eg and ep
c
      common/tabtec/hx,dr(nrptx),test1,test2,ndor,np,nes,method,idim
c hx exponential step
c dr radial mesh
c test1,test2,nes,method are dummy.
c  ndor number of terms for the developments at the origin
c np maximum number of the tabulation points
c idim dimension of the block dr
      complex*16 jl(0:ltot+1), hl(0:ltot+1), xkmt, ck, dum1, factor
      external besjh

      ccl=cl+cl
      ihard = 0
      ec=en/cl
      do i=2,ndor
         ag(i)=0.0d0
         ap(i)=0.0d0
      enddo
c     integration of the inhomogenious system
c     no need in normalization, since we can use 
c     normalization agi=ag(1)=const
 
c            solution of the inhomogenios dirac equation
c gg gp initially exch. terms, at the time of return are wave functions
c ag and ap development coefficients of  gg and gp
c en one-electron energy
c fl power of the first development term at the origin
c agi (api) initial values of the first development coefficients
c at the origin of a large (small) component
 
c     started with h_l above jri inside dfovrg
      vmh = cl * dv(jri+1)
      ck = sqrt(2*(en-vmh) + (alphfs*(en-vmh))**2)
      il = abs(kap)
      if (kap.lt. 0) il = il - 1
      ilp = il - 1
      if (kap .lt. 0) ilp = il + 1
      ilx = il+1
      if (ilp.gt.il) ilx=ilp+1
      xsign = -1.d0
      if (kap.gt.0) xsign = 1.d0
      factor = ck*alphfs
      factor = xsign * factor/(1+sqrt(1+factor**2))
      dum1 = 1/ sqrt(1+factor**2)

      iflat = min ( jri, iwkb)
      do i = jri, imax
        j= iflat + npi - i
        xkmt = ck * dr(i)
        call besjh( xkmt, ilx, jl, hl)
        gg(i) = hl(il) * dr(i) * dum1
        gp(i) = hl(ilp) * dr(i) * dum1 * factor
        if (j.gt.0) then
          f = (ec - dv(i))*dr(i)
          g = f + ccl * dr(i)
          c3 = ic3*vm(i)/g**2
          dg(j) = -(  g*gp(i) - kap*gg(i) )
          dp(j) = -(  kap*gp(i) - (f-c3)*gg(i) )
c         neglect exchage term outside jri
c         dg(j) = -(  g*gp(i) - kap*gg(i) + ep(i) )
c         dp(j) = -(  kap*gp(i) - (f-c3)*gg(i) - eg(i) )
        endif
      enddo

c     use flatv between iwkb and jri
      do i = jri-1, iflat, -1
         j= iflat + npi - i
         if (i.eq.iwkb) then
            eph = cl* ( 3*dv(iwkb+1) - dv(iwkb+2)) /2
            if (iwkb.eq.jri-1) eph=  cl* (dv(i) + dv(i+1)) /2
         else
            eph = cl* (dv(i) + dv(i+1)) /2
         endif
         if (ic3.gt.0) then
           rav = (dr(i)+dr(i+1)) / 2
           ec = rav**3 * ( ccl+ (en - eph) / cl )**2
           eph = eph + ic3 * cl / ec * (vm(i) + vm(i+1)) / 2
         endif
         call flatv( dr(i+1), dr(i), gg(i+1), gp(i+1), en, eph, kap,
     1               gg(i), gp(i))
         if (j.gt.0) then
          f = (ec - dv(i))*dr(i)
          g = f + ccl * dr(i)
          c3 = ic3*vm(i)/g**2
          dg(j) = -(  g*gp(i) - kap*gg(i) + ep(i) )
          dp(j) = -(  kap*gp(i) - (f-c3)*gg(i) - eg(i) )
         endif
      enddo

c     integration of the inhomogenious system
      a1 = hx * 3.3
      a2 = -hx * 4.2
      a3 = hx * 7.8
      a4 = hx * 14.0/45.0
      a5 = hx * 64.0/45.0
      a6 = hx * 24.0/45.0
c     do 55 i = jri - npi + 1 , 2, -1
      do i = iflat, 2, -1
         nit = 0
c        predictor
         acp=gg(i+5)+a1*(dg(npi)+dg(npi-4))+a2*(dg(npi-1)+dg(npi-3))
     1       +a3*dg(npi-2)
         bcp=gp(i+5)+a1*(dp(npi)+dp(npi-4))+a2*(dp(npi-1)+dp(npi-3))
     1       +a3*dp(npi-2)
c        ac,bc -corrector w/o contribution from derivatives at i+1
         ac=gg(i+3)+a4*dg(npi-3)+a5*(dg(npi)+dg(npi-2))+a6*dg(npi-1)
         bc=gp(i+3)+a4*dp(npi-3)+a5*(dp(npi)+dp(npi-2))+a6*dp(npi-1)
         do j=1,npi-1
            dg(j)=dg(j+1)
            dp(j)=dp(j+1)
         enddo
         f=(ec-dv(i-1))*dr(i-1)
         g=f+ccl*dr(i-1)
         c3 = ic3*vm(i-1)/g**2
 64      continue
         dg(npi)= -( g*bcp-kap*acp+ep(i-1) )
         dp(npi)= -( kap*bcp-(f-c3)*acp-eg(i-1) )
c        corrected values
         gg(i-1)=ac+a4*dg(npi)
         gp(i-1)=bc+a4*dp(npi)
         if ( abs(test*(gg(i-1)-acp)) .gt. abs(gg(i-1)) .or.
     1        abs(test*(gp(i-1)-bcp)) .gt. abs(gp(i-1)) ) then
c           test failed
            if (nit.lt.40) then
               acp = gg(i-1)
               bcp = gp(i-1)
               nit = nit + 1
               goto 64
            else
               ihard = ihard+1
            endif
         endif
      enddo

      do i=imax+1,np
         gg(i)=0.0d 00
         gp(i)=0.0d 00
      enddo
      ag(1)=gg(1)* dr(1)**(-fl)
      ap(1)=gp(1)* dr(1)**(-fl)

      return
      end
