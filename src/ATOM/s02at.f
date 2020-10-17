      subroutine s02at(ihole, norb, nk, xnel, ovpint, dval)
      implicit double precision (a-h,o-z)
      double precision  m1(7,7), m2(7,7)
      dimension nk(30), xnel(30), iorb(30), ovpint(30,30)

      dval = 1.0
c     loop over possible kappa for existing atoms
      do kap = -4,3

c        initialize matrices and other stuff
         do i = 1,7
            do j = 1,7
               m1(i,j) = 0
               m2(i,j) = 0
            enddo
         enddo
         do i= 1,7
            iorb(i) = 0
            m1(i,i) = 1.0
            m2(i,i) = 1.0
         enddo
c        morb - number of orbitals with quantum number kappa
         morb = 0
         nhole = 0

c        construct the largest possible matrix for given value of kappa.
         do i = 1, norb
            if (nk(i) .eq. kap) then
               morb = morb + 1
               iorb(morb) = i
               do j = 1, morb
c                 print overlap integrals
c                 print*, kap,' ', iorb(j),' ', iorb(morb), '
c    1                            ovp= ',ovpint(iorb(j), iorb(morb))
                  m1(j,morb) = ovpint(iorb(j), iorb(morb))
               enddo
               do j = 1, morb - 1
                  m1(morb,j) = m1(j,morb)
               enddo
               if (ihole .eq. i) nhole = morb
            endif
         enddo
         if (morb .ne. 0) then
            dum1 = determ(m1, morb, 7)
            dum1 = dum1**2
            
            dum3 = determ(m1, morb-1, 7)
            dum3 = dum3**2
            xn = xnel(iorb(morb))
            nmax = 2*abs(kap)
            xnh = nmax - xn
            if (nhole .eq. 0) then 
               dval = dval * dum1**xn * dum3**xnh
            elseif (nhole .eq. morb) then
               dval = dval * dum1**(xn-1) * dum3**(xnh+1)
            else
               call elimin(m1,nhole,m2)
               dum2 = determ(m2,morb,7)
               dum2 = dum2**2
               dum4 = determ(m2,morb-1,7)
               dum4 = dum4**2
               dum5 = (dum4*dum1*xnh + dum2*dum3*xn)/nmax
               dval = dval * dum5 * dum1**(xn-1) * dum3**(xnh-1)
            endif
         endif
      enddo
      return
      end

      subroutine elimin(d1,n,d2)
      implicit double precision (a-h,o-z)
      dimension d1(7,7), d2(7,7)

      do i = 1,7
         do j = 1,7
            if (i .ne. n) then
               if (j .ne. n) then
                  d2(i,j)=d1(i,j)
               else
                  d2(i,j) = 0
               endif
            else
               if (j .ne. n) then
                  d2(i,j) = 0
               else
                  d2(i,j) = 1.0
               endif
            endif
         enddo
      enddo
      return
      end
