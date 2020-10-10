      subroutine fprime( ei, emxs ,ne1, ne3, ne, ik0, xsec, xsnorm,chia,
     1                  vrcorr, vicorr, cchi)
c     calculate f' including solid state and lifetime effects.
c     using algorithm in Ankudinov, Rehr danes paper.
c     the output correction is returned via cchi. The rest is input
c      mu(omega) = xsec + xsnorm*chia  + (cchi)

      implicit double precision (a-h, o-z)
      include '../HEADERS/const.h'
      include '../HEADERS/dim.h'

      dimension  xsnorm(nex), omega(nex)
      complex*16 emxs(nex), xsec(nex), chia(nex), cchi(nex)
      complex*16 xmu(nex), aa, bb, temp
c      complex*16 c1, ec, x1, x2
      complex*16 xmup(nex)
      dimension emp(nex)
      parameter (eps4 = 1.0d-4)
      complex*16 lorenz, funlog, value
      external lorenz, funlog
      dimension dout(7,nex)
c      character*72 string
c      dimension oscstr(14),enosc(14)
      integer ient
      data ient /0/

c$$$c     read data from fpf0.dat
c$$$      open (unit=16, file='fpf0.dat', status='old', iostat=ios)
c$$$      read  (16,*)  string
c$$$      read  (16,*)  eatom
c$$$      read  (16,*)  nosc
c$$$      do 5 i=1, nosc
c$$$        read (16,*) oscstr(i), enosc(i)
c$$$   5  continue
c$$$c     the rest is f0(Q) and is not currently needed
c$$$      close (unit=16)
c$$$      call json_read_fpf0(nosc, oscstr, enosc)

      ient = ient+1
      ifp = 1
      efermi = dble(emxs(ne1+1))
      xloss = dimag(emxs(1))
      ne2 = ne-ne1-ne3
      if (ne2.gt.0) then
c        DANES
         do ie = 1,ne1
            xmu(ie) = coni*xsnorm(ie) +  xsnorm(ie)*chia(ie)
         enddo
         do ie = ne1+1,ne1+ne2
            xmu (ie) = xsnorm(ie)*chia(ie)
         enddo
         do ie = ne-ne3+1, ne
            xmu (ie) =  coni*xsnorm(ie)
         enddo
      else
c        FPRIME
         do ie = 1,ne
            xmu(ie) = xsec(ie) + xsnorm(ie)*chia(ie)
         enddo
      endif

      if (abs(vrcorr).gt.eps4) then
         bb = xmu(ik0)
         efermi = efermi - vrcorr
         do ie = 1,ne1
            omega(ie) = dble(emxs(ie))
         enddo
         call terpc(omega, xmu ,ne1, 1, efermi, bb)
         do ie = 1, ne2
            emxs(ne1+ie) = emxs(ne1+ie) - vrcorr
         enddo
         if (abs(xmu(ik0)).gt. eps4) bb = bb/xmu(ik0)
c        rescale values on vertical axis
         do ie = ne1+1, ne-ne3
            xmu(ie) = xmu (ie) * bb
         enddo
      endif


      if (vicorr.gt.eps4) then
         xloss = xloss + vicorr
         do ie=1,ne2
            omega(ie) = dimag(emxs(ne1+ie))
         enddo
         call terpc(omega, xmu(ne1+1) ,ne2, 1, xloss, aa)
         do ie = 1, ne1
            xx = vicorr**2 /(vicorr**2 + (dble(emxs(ie))-efermi)**2)
            xmu(ie) = xmu(ie)*(1.0d0 - xx) + aa * xx
            emxs(ie) = emxs(ie) + coni*vicorr
         enddo
      endif

      do ie = 1, ne1
c        cycle over energy points on horizontal grid

         dout(1,ie) = dble(emxs(ie)) * hart
         dele = dble(emxs(ie)) - efermi
c        delp correspond to pole with negative frequency
c        see Sakurai for details

         delp = -dele - 2*ei
c        delp = dele
c        dele = delp

         cchi(ie) = 0
         if (ne2.gt.0) then
            if (abs(dele).lt.eps4) dele = 0.0d0
            w1 = dimag(emxs(ne1+1))
            w2 = dimag(emxs(ne1+2))
            w3 = dimag(emxs(ne1+3))

c           matsubara pole
            temp = lorenz(xloss,w1,dele)*xmu(ne1+1)*2*coni*w1
            temp = temp + lorenz(xloss,w1,delp)*xmu(ne1+1)*2*coni*w1
            dout(2,ie)=dble(temp)
c           sommerfeld correction
            temp = coni*w1**2/ 6*(lorenz(xloss,w3,dele)*xmu(ne1+3)-
     2      lorenz(xloss,w2,dele)*xmu(ne1+2)) / (w3-w2)
            dout(3,ie)=dble(temp)

            cchi(ie) = lorenz(xloss,w1,dele)*xmu(ne1+1) *2*coni*w1
     1      + coni * w1**2 / 6 * (lorenz(xloss,w3,dele)*xmu(ne1+3)-
     2      lorenz(xloss,w2,dele)*xmu(ne1+2)) / (w3-w2)
c           from negative pole has additional minus sign
            cchi(ie) = cchi(ie) +
     1      lorenz(xloss,w1,delp)*xmu(ne1+1) *2*coni*w1
     1      + coni * w1**2 / 6 * (lorenz(xloss,w3,delp)*xmu(ne1+3)-
     2      lorenz(xloss,w2,delp)*xmu(ne1+2)) / (w3-w2)

c           theta funcion contribution only for positive pole
            if (dele .lt. eps4)    cchi(ie) = cchi(ie) - xmu(ie)
            if (abs(dele).lt.eps4) cchi(ie) = cchi(ie) + xmu(ie)/2

c           anomalous contribution
            temp = 0
            wp = 2*ei
            if (dele.ge.eps4) temp = xmu(ie)
            if (abs(dele).lt.eps4) temp = xmu(ie)/2
            temp = temp + xmu(ik0)*  funlog(1,xloss,wp,dele)
c               xmu(iko) + xsec(ik0)  if n3 >0
            dout(4,ie)=dble(temp)

c           integration over vertical axis to final point
            n1 = ne1+2
            n2 = ne-ne3
            call fpint (emxs, xmu, n1, n2, dele, xloss, eps4, efermi,
     1                  value)
            cchi(ie) = cchi(ie) + value
c           add contribution from other pole
            call fpint (emxs, xmu, n1, n2, delp, xloss, eps4, efermi,
     1                  value)
            cchi(ie) = cchi(ie) + value
         endif

c        integration over horizontal axis to final point
         temp = 0
         if (ne2.gt.0) then
c           DANES
            n1 = ne1-ik0 + 1
            do i = ik0, ne1
              emp(i-ik0+1) = dble(emxs(i))
              xmup(i-ik0+1) = coni*xsnorm(i)
           enddo
            do i = 1, ne3
              emp(i+n1) = dble(emxs(i+ne-ne3))
              xmup(i+n1) = xmu(i+ne-ne3)
           enddo
            n2 = n1 + ne3
         else
c           FPRIME
            n1 = 0
            do i = 1, ne1
              if (n1.eq.0 .and. dble(emxs(i)).gt. dble(emxs(ne1+1)))
     1            n1 = i
           enddo
            do i = 1, ne3
               emp(i) =  dble(emxs(ne1+i))
               xmup(i) =  xmu(ne1+i)
            enddo
            n2 = ne3
         endif
         call fpintp (emp, xmup , n2, dele, xloss, efermi, value)
         temp  = temp + value
c        add contribution from other pole
         call fpintp (emp, xmup , n2, delp, xloss, efermi, value)
         temp  = temp + value

c         was used before
cc          contribution to fp from poles of the core states
c           temp=0
c           do 110  i=2, nosc
cc             eif = E_f- E_i  in hartrees
cc             eif = enosc(i)-enosc(1)
cc             deltaf = deltaf - oscstr(i)*2*alpinv**2/eif
c              temp = temp + alpinv**2 * oscstr(i)* (dele -
c    1      enosc(i)+efermi-1)/ ((dele-enosc(i)+efermi-1)**2+xloss**2)
c              temp = temp + alpinv**2 * oscstr(i)* (delp -
c    1      enosc(i)+efermi-1)/ ((delp-enosc(i)+efermi-1)**2+xloss**2)
c 110       continue

         dout(5,ie) = dble(temp)
         cchi(ie) = cchi(ie) + temp

c        total contribution (not normalized)
         temp = xmu(ie) + cchi(ie)
         dout(6,ie) = dble(temp)
c        (integral w2 to wmax) minus (cusp formula)
         dout (7,ie) = dout(6,ie)-dout(4,ie)
      enddo

c     restore the input energy mesh
      if (vicorr.gt.eps4) then
         do ie = 1, ne1
            emxs(ie) = emxs(ie) - coni*vicorr
         enddo
      endif
      if (abs(vrcorr).gt.eps4) then
         do ie = 1, ne2
            emxs(ne1+ie) = emxs(ne1+ie) + vrcorr
         enddo
      endif

c     if (ient.eq.1) then
      open(unit=3,file='danes.dat', status='unknown', iostat=ios)
      write(3,310) '# E  matsub. sommerf. anomal. tale, total, differ.'
  310 format (a)
      do ie = 1, ne1
         write(3,320) (dout(i,ie), i=1,7)
  320    format ( 7(1x,1pe11.4))
      enddo
      close(unit=3)
c     endif

      return
      end

      complex*16 function funlog (icase, xloss, w, dele)
c     anomalous fp should have all main features of total fp
c     except smooth difference
c     analytic expression for anomalous fp (without integral)
c     is obtained by adding and subtracting G(Ef + i*Gamma) / E-w
c     and performing integral for Im axis analytically
c     icase = 1 simplified expression (compared to 2)
c     icase=2  use real w
c     icase=3  pure imaginary w (absolute value is input)
      implicit double precision (a-h, o-z)
      include '../HEADERS/const.h'
      parameter (eps4 = 1.0d-4)
      funlog = (0.d0,0.d0)

      if (icase.eq.1) then
         if (abs(dele).ge.eps4) then
            funlog= coni/2/pi*
     1      (log((-xloss+coni*dele)/w)+ log((xloss+coni*dele)/w))

         else
            funlog= coni/pi*log(abs(xloss/w))
         endif

      elseif (icase.eq.2) then
        if (abs(dele).ge.eps4) then
          funlog= coni/2/pi* (w+coni*xloss) * (
     1    ( log((-xloss+coni*dele)/w)) / (w+dele+coni*xloss) +
     2    ( log(( xloss+coni*dele)/w)) / (w+dele-coni*xloss))
        else
          funlog= coni/pi*(log(abs(xloss/w)))*
     1    (1 + coni*xloss/(w-coni*xloss))
        endif

      elseif (icase.eq.3) then
        if (abs(dele).ge.eps4) then
          funlog= -(w+xloss)/2/pi* (
     1    log((-xloss+coni*dele)/w) / (dele+coni*(w+xloss)) +
     2    log(( xloss+coni*dele)/w) / (dele+coni*(w-xloss)) )
        else
          funlog= coni/pi* log(abs(xloss/w))*
     1    (1 + xloss/(w-xloss))
        endif

      endif

      return
      end

      subroutine fpint (emxs, xmu, n1, n2, dele, xloss, eps4, efermi,
     1                  value)
c     performs integral for fp calculations between points n1 and n2.
      implicit double precision (a-h, o-z)
      include '../HEADERS/const.h'
      include '../HEADERS/dim.h'

      complex*16 emxs(nex), xmu(nex), value
      complex*16  z1, z2, aa, bb, c1

c     last interval - similar to Matsubara pole ( shift and - sign)
c     notice that this also works for horizontal axis if last value
c     is small
      z1 = emxs(n2)-efermi
      z2 = emxs(n2-1)-efermi
      value =  - coni/pi * (z1-dele) / (xloss**2+(z1-dele)**2)
     1          *xmu(n2) * (2 * (z1-z2))
c     all other intervals
      do  300 i = n1, n2-2
         z1 = emxs(i) - efermi
         z2 = emxs(i+1) - efermi
         bb=(xmu(i+1)*(z2-dele) - xmu(i)*(z1-dele)) / xloss / (z2-z1)
         aa = xmu(i)*(z1-dele)/xloss - bb * z1
         c1 = (aa+bb*(dele+coni*xloss )) / 2 /coni
         if (abs(dele-dble(z1)).lt.eps4 .and.
     1       abs(dele-dble(z2)).lt.eps4) then
            value = value  -  coni/pi *c1*
     1      log( abs((z2-dele-coni*xloss)/(z1-dele-coni*xloss)) )
         else
            value    = value   -  coni/pi *c1*
     1      log((z2-dele-coni*xloss)/(z1-dele-coni*xloss))
         endif
         c1 = -(aa+bb*(dele-coni*xloss )) / 2 /coni
         value    = value    -  coni/pi *c1*
     1   log((z2-dele+coni*xloss)/(z1-dele+coni*xloss))
  300  continue

      return
      end

      subroutine fpintp (em, xmu, n2, dele, xloss, efermi, value)
c     performs integral for fp calculations between points 1 and n2.
c     and adds tail to infinity
      implicit double precision (a-h, o-z)
      include '../HEADERS/const.h'
      include '../HEADERS/dim.h'

      dimension em(nex)
      complex*16 xmu(nex), value
      complex*16  z1, z2, aa, bb, cc

      value = 0
c     all intervals
      do  300 i = 1, n2-1
         x1 = em(i) - efermi
         x2 = em(i+1) - efermi
         de = (x2-x1)/2
         x0 = (em(i) + em(i+1)) / 2
         call terpc(em, xmu, n2, 3, x0, aa)
         bb=(xmu(i+1) - xmu(i)) / (x2-x1)
         cc = (xmu(i+1) - aa - bb * de) / de**2
         z1 =  dele - x0 + efermi - coni*xloss
         z2 =  dele - x0 + efermi + coni*xloss
         value    = value  + 2*de*bb + 2*z1*de*cc +
     1    log((de-z1)/(-de-z1)) * (aa+bb*z1+cc*z1**2)
         value    = value  + 2*de*bb + 2*z2*de*cc +
     1    log((de-z2)/(-de-z2)) * (aa+bb*z2+cc*z2**2)
  300 continue

c     tail of xmu to infinity approximated by aa/(w-bb)**2
      x1 = em(n2-1)
      x2 = em(n2)
      a = sqrt ( dble(xmu(n2-1)/xmu(n2)) )
      b = ( a*x1 - x2) / (a-1)
      if (b.gt. x1) b = 0
      aa = xmu(n2) * (x2-b)**2
      z1 = dele -coni*xloss - b
      z2 = dele +coni*xloss - b
      x0 = x2 - b
      value = value + log( x0/(x0-z1) ) *aa/z1**2 - aa/z1/x0
      value = value + log( x0/(x0-z2) ) *aa/z2**2 - aa/z2/x0

c     multiply by constant factor
      value = - coni /2 /pi *value

      return
      end
