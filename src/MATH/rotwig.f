      double precision function rotwig (beta, jj, m1, m2, ient)
c     uses Wigner formula (Messiah eq.C.72) to calculate rotation matrix
c     for integers  (ient=1)  or semiintegers (ient=2)
c     other arguments (except beta) should be multiplied by ient

      implicit double precision (a-h,o-z)
      parameter (idim = 58)
c     dimensions  modified for larger arguments by ala 12.12.94
      dimension al(idim+1),m(12)
      save ini, al
      data ini/1/
c     idim-1 is the largest argument of factorial to calculate

      if (((ient-1)*(ient-2)).ne.0) stop ' Illegal ient in rotwig.'

      if (ini.eq.1) then
c       initialisation of the log's of the factorials
        ini=0
        al(1)=0.0d 00
        do i=1,idim
           b=i
           al(i+1)=al(i)+ log(b)
        enddo
      endif
      rotwig = 0.d0

      if ( m1.ge.0 .and. abs(m1).ge.abs(m2)) then
         m1p = m1
         m2p = m2
         betap = beta
         isign = 1
      elseif (m2.ge.0 .and. abs(m2).ge.abs(m1)) then
         m1p = m2
         m2p = m1
         betap = - beta
         isign = 1
      elseif (m1.le.0 .and. abs(m1).ge.abs(m2)) then
         m1p = - m1
         m2p = - m2
         betap = beta
         isign = (-1)**( (m1-m2)/ient )
      else
         m1p = - m2
         m2p = - m1
         betap = - beta
         isign = (-1)**( (m2-m1)/ient )
      endif

      temp = 0.d0
      zeta = cos ( betap / 2.d0 )
      eta  = sin ( betap / 2.d0 )
      do it = m1p - m2p, jj - m2p, ient
        m(1) = 1 + (jj+m1p) / ient
        m(2) = 1 + (jj-m1p) / ient
        m(3) = 1 + (jj+m2p) / ient
        m(4) = 1 + (jj-m2p) / ient
        m(5) = 1 + (jj+m1p-it) / ient
        m(6) = 1 + (jj-m2p-it) / ient
        m(7) = 1 + it / ient
        m(8) = 1 + (m2p-m1p+it) / ient
        m(9)  = (2*jj+m1p-m2p-2*it) / ient
        m(10) = (2*it-m1p+m2p) / ient
        factor = 0.d0
        do i = 1,4
           factor = factor + al(m(i))/2.d0 - al(m(i+4))
        enddo
c       special cases to resolve 0.d0**0 problem (a.ankudinov, may 2001)
        if (m(10).eq.0 .and. m(9).eq.0) then
          temp = temp + (-1)**(it/ient)*exp(factor)
        elseif (m(10).eq.0) then
          temp = temp + (-1)**(it/ient)*zeta**m(9)*exp(factor)
        elseif (m(9).eq.0) then
          temp = temp + (-1)**(it/ient)*eta**m(10)*exp(factor)
        else
c         general expression
          temp = temp+ (-1)**(it/ient)*zeta**m(9)*eta**m(10)*exp(factor)
        endif
      enddo

      rotwig = isign * temp

      return
      end
