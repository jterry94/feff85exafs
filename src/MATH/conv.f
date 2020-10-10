      subroutine conv(omega,xsec,ne1,vicorr)
c     multiply xsec by theta(omega-efermi) and
c     convolute xsec(omega) with  xloss/((omega-omega0)**2+xloss**2)/pi
c     the result is xsec0(omega0)

      implicit double precision (a-h, o-z)
      include '../HEADERS/const.h'
      include '../HEADERS/dim.h'
      dimension  omega(nex)
      complex*16 xsec(nex), xsec0(nex), xsecdx

      complex*16 conv1
      external conv1

      do ie = 1,ne1
         xsec0(ie) = 0.0d0
         omega0 = omega(ie)
c        Add one more point to correct for the finite grid
c        at large energies. Use linear interpolation.
         dx = max( omega(ne1) - omega(ne1-1), 50*vicorr)
         xlast = omega(ne1)+dx
         dx = dx / ( omega(ne1) - omega(ne1-1))
         xsecdx = xsec(ne1)+ (xsec(ne1)-xsec(ne1-1)) * dx

c        first interval
         do i = 1, ne1-1
            xsec0(ie) = xsec0(ie) +
     1      conv1(omega(i),omega(i+1),xsec(i),xsec(i+1),omega0,vicorr)
         enddo
c        last interval
         xsec0(ie) = xsec0(ie) +
     1   conv1(omega(ne1),xlast,xsec(ne1),xsecdx,omega0,vicorr)
         xsec0(ie) = xsec0(ie) /real(pi)
      enddo
      do ie = 1, ne1
         xsec(ie) = xsec0(ie)
      enddo
      return
      end

      complex*16 function conv1(x1,x2,y1,y2,x0,xloss)
c     convolution of function 1/(omega-omega0-i*xloss)/pi
c     makes linear interpolation for function between x1,x2 and
c     takes advantage that the integral can be taken analytically.
      implicit double precision (a-h, o-z)
      complex*16  y1, y2, t, coni,dum, a, b
      parameter (coni = (0.d0,1.d0))

      d = (x2-x1) / 2.d0
      a = dble(y2-y1) / 2.d0
      b = dble(y2+y1) / 2.d0
      t = d / ( (x1+x2)/2 - x0 - coni*xloss )
      if (abs(t) .ge. 0.1) then
         dum = 2.d0*a + (b - a/t) * log((1+t)/(1-t))
      else
         dum = 2.d0*b*(t+t**3 / 3.d0) - 2.d0/3.d0 * a*t**2
      endif
      conv1 = dimag (dum)

      d = (x2-x1) / 2.d0
      a = dimag(y2-y1) / 2.d0
      b = dimag(y2+y1) / 2.d0
      t = d / ( (x1+x2)/2 - x0 - coni*xloss )
      if (abs(t) .ge. 0.1) then
         dum = 2.d0*a + (b - a/t) * log((1+t)/(1-t))
      else
         dum = 2.d0*b*(t+t**3 / 3.d0) - 2.d0/3.d0 * a*t**2
      endif
      conv1 = conv1 + coni* dimag( dum)

      return
      end
