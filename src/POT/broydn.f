      subroutine broydn( iscmt, ca, nph, xnvmu,
     1          ilast, xnatph, rnrm, qnrm, edenvl, rhoval, dq)
c     calculates new density using Broyden algorithm
c     (J.Phys.A, 17,L317(1984))
c     
c      Also handes the charge inside each norman sphere properly.
c     INPUT:
c       ca     - convergence accelerator factor
c       rhoval - new density from integration up to mu
c       edenvl - old valence density
c       qnrm   - the charge inside each norman sphere
c       xnvmu  - valence electron counts in getorb.f
c       also some information from feff.inp file.(nph,etc.)
c     Output:
c       rhoval - new valence density after mixing
c                notice that at input rhoval = density*4*pi*r**2
c       dq     - change of the charge inside each norman sphere
      implicit double precision (a-h, o-z)

      include '../HEADERS/const.h'
      include '../HEADERS/dim.h'

      dimension ilast(0:nphx),xnatph(0:nphx), xnvmu(0:lx, 0:nphx+1)
      dimension ri05(251)
      dimension rhoval(251,0:nphx+1), edenvl(251,0:nphx)
      dimension dq(0:nphx)
      dimension qnrm(0:nphx), rnrm(0:nphx)

c     work space
      dimension xpc(251)
c     work space for Broyden algorithm
      parameter (nbr=30)
      dimension cmi(nbr,nbr), frho(251,0:nphx,nbr), urho(251,0:nphx,nbr)
      dimension xnorm(nbr), wt(251), rhoold(251,0:nphx)
      save cmi, frho, urho, xnorm, wt, rhoold, ri05

c     make  radial grid with 0.05 step
      dx05=0.05d0
      if(iscmt.eq.1) then
        do i=1,251
           ri05(i) = exp(-8.8d0+dx05*(i-1))
           wt(i) = ri05(i)**3
        enddo
      endif

c     record F(\rho_i)
      do iph = 0, nph
         do ir = 1, ilast(iph)
            frho(ir,iph,iscmt)=rhoval(ir,iph)*ri05(ir)-
     $           edenvl(ir,iph)*wt(ir)
         enddo
      enddo

c     dq here is set to the total number of valence electron for
c     the initial (atomic overlap) density inside corresponding
c     norman sphere, and xnferm is  the total number for the cluster.
      xnferm = 0
      do ip= 0,nph
         dq(ip) = 0
         do il = 0,lx
            dq(ip) = dq(ip) + xnvmu(il, ip)
         enddo
         xnferm = xnferm + dq(ip)*xnatph(ip)
      enddo

      if (iscmt.gt.1) then
c       get normalization factor
        xnorm(iscmt) = 0
        do iph = 0, nph
           do ir = 1,ilast(iph)
              xnorm(iscmt) = xnorm(iscmt) +
     1             (frho(ir,iph,iscmt)-frho(ir,iph,iscmt-1))**2
           enddo
        enddo

c       calculate c_m,i
        do j = 2, iscmt
          cmi(iscmt,j) = 0
          do iph = 0, nph
             do ir = 1,ilast(iph)
                cmi(iscmt,j) = cmi(iscmt,j) + frho(ir,iph,iscmt) *
     1               (frho(ir,iph,j)-frho(ir,iph,j-1))
             enddo
          enddo
          cmi(iscmt,j) = cmi(iscmt,j)/xnorm(j)
       enddo

c       calculate U_i - vector of lagrange multipliers
        do iph = 0, nph
           do ir = 1,ilast(iph)
              urho(ir,iph,iscmt)=ca*(frho(ir,iph,iscmt)-
     $             frho(ir,iph,iscmt-1)) + (edenvl(ir,iph)
     $             - rhoold(ir,iph))*wt(ir)
           enddo
        enddo

        do j = 2, iscmt-1
           do iph = 0, nph
              do ir = 1,ilast(iph)
                 urho(ir,iph,iscmt)= urho(ir,iph,iscmt)
     $                - urho(ir,iph,j) * (cmi(iscmt,j)-cmi(iscmt-1,j))
              enddo
           enddo          
        enddo          
      endif

c     construct new density, finally
      do iph = 0, nph
         do ir = 1, ilast(iph)
            rhoold(ir,iph) = edenvl(ir,iph)
            rhoval(ir,iph) = edenvl(ir,iph) +
     $           ca*frho(ir,iph,iscmt)/wt(ir)
            do j = 2, iscmt
               rhoval(ir,iph)=rhoval(ir,iph)-cmi(iscmt,j)*
     $              urho(ir,iph,j)/wt(ir)
            enddo
         enddo
      enddo


c     calculate e charge inside norman sphere
c     dq - extra number of e (charge transfer) 
      x0 = 8.8d0
      dqav=0.0d0
      xnat = 0.d0
      do iph = 0, nph
         jnrm =  int((log(rnrm(iph)) + x0) / dx05)  +  2
         i0=jnrm+1
         xirf = 2
         do ir = 1, ilast(iph)
            xpc(ir) = rhoval(ir,iph)*ri05(ir)**2
         enddo
         
         call somm2 (ri05, xpc, dx05, xirf, rnrm(iph),0,i0)
c     dq is how many new electrons are within norman sphere
         dq(iph) = xirf - qnrm(iph) - dq(iph)
         dqav=dqav+xnatph(iph)*dq(iph)
         xnat = xnat + xnatph(iph)
      enddo


c     to keep charge neutrality add/subtract part of previous density
      aa = dqav/xnferm
      dqav=dqav/xnat
      do iph = 0, nph
         dq(iph) = dq(iph) - dqav
         qnrm(iph) = qnrm(iph) + dq(iph)
         do ir = 1, ilast(iph)
            rhoval(ir,iph) = rhoval(ir,iph) - aa*edenvl(ir,iph)
         enddo
      enddo

      return
      end
