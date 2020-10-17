      subroutine muatco(xnval) 
c               * angular coefficients *
c        sous programmes utilises  cwig3j
c
      implicit double precision (a-h,o-z)
      dimension xnval(30)
      common/itescf/testy,rap(2),teste,nz,norb,norbsc
      common/mulabk/afgk
      dimension afgk(30,30,0:3)
      common/ratom1/xnel(30),en(30),scc(30),scw(30),sce(30),
     1nq(30),kap(30),nmax(30)
c#mn
       external cwig3j

      do i=1,30
         do j=1,30
            do k=0,3
               afgk(i,j,k)=0.0d00
            enddo
         enddo
      enddo

      do i=1,norb
         li= abs(kap(i))*2-1
         do j=1,i
            lj= abs(kap(j))*2-1
            kmax=(li+lj)/2
            kmin= abs(li-lj)/2
            if ((kap(i)*kap(j)).lt.0) kmin=kmin+1
c calculate a_k(i,j)
            m=0
            if (j.eq.i .and. xnval(i).le.0.0d0) m=1
c           use to test SIC
c           if (j.eq.i) m=1

            afgk(j,i,0)=afgk(j,i,0)+xnel(i)*(xnel(j)-m)
            if (xnval(i).le.0.0d0 .or. xnval(j).le.0.0d0) then
c calculate b_k(i,j)
               b=afgk(j,i,0)
               if (j.eq.i .and. xnval(i).le.0.0d0) then
                  a=li
                  b=-b*(a+1.0d 00)/a
                  kmin = kmin+2
               endif
               do k = kmin, kmax,2
                  afgk(i,j,k/2)=b*(cwig3j(li,k*2,lj,1,0,2)**2)
               enddo
            endif
         enddo
      enddo
      return
      end
