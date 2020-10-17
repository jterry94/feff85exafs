      subroutine intout (en,i0, kap,max0,ic3,vm)
c                  resolution of the dirac equation
c                   p' - kap*p/r = - ( en/cl-v )*g - eg/r
c                   g' + kap*g/r = ( 2*cl+en/cl-v )*p + ep/r
c at the origin v approximately is -z/(r*cl) due to the point nucleus
c en one-electron energy in atomic units and negative
c at the origin of the large(small)component
c kap quantum number kappa
c max0 the last point of tabulation of the wave function
 
      implicit double precision (a-h,o-z)
      include '../HEADERS/dim.h'
      include '../HEADERS/const.h'
      parameter (npi=6, test=1.0d+5)
      complex*16 en,c3,vmh
      complex*16 gg,ag,gp,ap,dv,av,eg,ceg,ep,cep, vm(nrptx)
      common/comdic/cl,dz,gg(nrptx),ag(10),gp(nrptx),ap(10),dv(nrptx),
     1   av(10),eg(nrptx),ceg(10),ep(nrptx),cep(10)

      complex*16 ec,eph,egh,f,g,ac,bc,acp,bcp,dg,dp, dv1,dv2,vh
      complex*16 dg2, dp2, dg3, dp3, dg4, dp4
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


      ccl=cl+cl
      exphx = exp (hx/2)
      ihard = 0
      ec=en/cl
 
c            solution of the inhomogenios dirac equation
c gg gp initially exch. terms, at the time of return are wave functions
c ag and ap development coefficients of  gg and gp
c en one-electron energy
c fl power of the first development term at the origin

c     runge-kutta for first npi points
      i = i0
      j=1
      f = (ec - dv(i))*dr(i)
      g = f + ccl * dr(i)
      c3 = ic3*vm(i)/g**2
      dg(j) = hx * (g*gp(i) - kap*gg(i) + ep(i))
      dp(j) = hx * (kap*gp(i) - (f-c3)*gg(i) - eg(i))

 44   continue
      if (i.lt.max0) then
         ac = gg(i) + 0.5d0 * dg(j)
         bc = gp(i) + 0.5d0 * dp(j)
         rh = dr(i) *exphx
c     find potential and exchange terms between 2 points
c     use linear interpolation with imp. nonlinearity correction
         xm1 = (dr(i+1)-rh) / (dr(i+1)-dr(i))
         xm2 = (rh - dr(i)) / (dr(i+1)-dr(i))
         if (dble(av(1)) .lt. 0.0 .and. i0.eq.1) then
c        point nucleus case
c        important nonlinearity from z/r term
            dv1 = dv(i) - av(1)/dr(i)
            dv2 = dv(i+1) - av(1)/dr(i+1)
            vh = dv1*xm1 + dv2*xm2
            vh = vh + av(1)/rh
            vmh = (xm1*vm(i)*dr(i) +xm2*vm(i+1)*dr(i+1))/rh
         elseif (i0.eq.1) then
c     finite nucleus
c     important nonlinearity from z*r**2 term
            dv1 = dv(i) - av(4)*dr(i)**2
            dv2 = dv(i+1) - av(4)*dr(i+1)**2
            vh = (dv1*(dr(i+1)-rh)+dv2*(rh-dr(i))) / (dr(i+1)-dr(i))
            vh = vh + av(4)*rh**2
            vmh = (xm1*vm(i)/dr(i)**2 +xm2*vm(i+1)/dr(i+1)**2)*rh**2
         else
c     outward integration of irregular solution near jri
            vh = dv(i)*xm1 + dv(i+1)*xm2
            vmh = xm1*vm(i) +xm2*vm(i+1)
         endif
         eph = ep(i) * xm1 + ep(i+1) * xm2
         egh = eg(i) * xm1 + eg(i+1) * xm2
         
         f = (ec - vh)*rh
         g = f + ccl * rh
         c3 = ic3*vmh/g**2
         dg2 = hx * (g*bc - kap*ac + eph)
         dp2 = hx * (kap*bc - (f-c3)*ac - egh)
         ac = ac + 0.50*(dg2-dg(j))
         bc = bc + 0.50*(dp2-dp(j))
         dg3 = hx * (g*bc - kap*ac + eph)
         dp3 = hx * (kap*bc - (f-c3)*ac - egh)
         ac = ac + dg3 - 0.50*dg2
         bc = bc + dp3 - 0.50*dp2
         
         i=i+1
         j=j+1
         f = (ec - dv(i))*dr(i)
         g = f + ccl * dr(i)
         c3 = ic3*vm(i)/g**2
         dg4 = hx * (g*bc - kap*ac + ep(i))
         dp4 = hx * (kap*bc - (f-c3)*ac - eg(i))
         gg(i) = gg(i-1)+(dg(j-1) + 2.0*(dg2+dg3)+dg4)/6.0
         gp(i) = gp(i-1)+(dp(j-1) + 2.0*(dp2+dp3)+dp4)/6.0
         dg(j) = hx * (g*gp(i) - kap*gg(i) + ep(i))
         dp(j) = hx * (kap*gp(i) - (f-c3)*gg(i) - eg(i))
         if (j.lt.npi) goto 44
         
c     scale derivatives for milne method
         do i = 1,npi
            dg(i) = dg(i)/hx
            dp(i) = dp(i)/hx
         enddo
c     integration of the inhomogenious system
         a1 = hx * 3.3
         a2 = -hx * 4.2
         a3 = hx * 7.8
         a4 = hx * 14.0/45.0
         a5 = hx * 64.0/45.0
         a6 = hx * 24.0/45.0
         do i = npi+i0-1,max0-1
            nit = 0
c     predictor
            acp=gg(i-5)+a1*(dg(npi)+dg(npi-4))+a2*(dg(npi-1)+dg(npi-3))
     1           +a3*dg(npi-2)
            bcp=gp(i-5)+a1*(dp(npi)+dp(npi-4))+a2*(dp(npi-1)+dp(npi-3))
     1           +a3*dp(npi-2)
c     ac,bc -corrector w/o contribution from derivatives at i+1
            ac=gg(i-3)+a4*dg(npi-3)+a5*(dg(npi)+dg(npi-2))+a6*dg(npi-1)
            bc=gp(i-3)+a4*dp(npi-3)+a5*(dp(npi)+dp(npi-2))+a6*dp(npi-1)
            do j=1,npi-1
               dg(j)=dg(j+1)
               dp(j)=dp(j+1)
            enddo
            f=(ec-dv(i+1))*dr(i+1)
            g=f+ccl*dr(i+1)
            c3 = ic3*vm(i+1)/g**2
 64         continue
            dg(npi)=g*bcp-kap*acp+ep(i+1)
            dp(npi)=kap*bcp-(f-c3)*acp-eg(i+1)
c     corrected values
            gg(i+1)=ac+a4*dg(npi)
            gp(i+1)=bc+a4*dp(npi)
            if ( abs(test*(gg(i+1)-acp)) .gt. abs(gg(i+1)) .or.
     1           abs(test*(gp(i+1)-bcp)) .gt. abs(gp(i+1)) ) then
c     test failed
               if (nit.lt.40) then
                  acp = gg(i+1)
                  bcp = gp(i+1)
                  nit = nit + 1
                  goto 64
               else
                  ihard = ihard+1
               endif
            endif
         enddo
      endif
      do i=max0+1,np
         gg(i)=0.0d 00
         gp(i)=0.0d 00
      enddo

      return
      end
