      subroutine ff2chi (ispec, ipr4, idwopt, critcw, s02, sig2g,
     1     tk, thetad, mbconv, absolu, !KJ added absolu 3-06
     1     vrcorr, vicorr, alphat, thetae, iabs, nabs,
     4     ipmin,ipmax,ipstep) !KJ added this line  1-06
c     adds the contributions from each path and absorber, including
c     Debye-Waller factors. Writes down main output: chi.dat and xmu.dat
      implicit double precision (a-h, o-z)

      include '../HEADERS/const.h'
      include '../HEADERS/dim.h'
      parameter (eps4 = 1.0d-4)
      integer ipmin,ipmax,ipstep  !KJ my variables  1-06
      integer absolu !KJ 3-06

c     header from list.dat
      dimension lhead(nheadx)
      character*80  head(nheadx)

      parameter (npx=15000)
!KJ      parameter (npx = 1200)
c     indices of paths to do, read from list.dat
      dimension ip(npx)
      real sig2u(npx)

      parameter (nfinex = 601)
      complex*16 cchi(nfinex), ckck(nfinex), ccc, ckp
c     to keep Im part of cchi 11.18.97 ala
      dimension rchtot(nfinex)
      complex*16 chia(nfinex)
      dimension xkp(nfinex), xk0(nfinex)

      logical dwcorr
      character*512 slog
      character*2 coment
      parameter (coment='# ')

c     Stuff from feff.pad, note that floating point numbers are
c     single precision.  Be careful throughout this routine, especially
c     when passing things to subroutines or intrinsic functions.
      real rnrmav, xmu, edge
      character*80 title(nheadx)
      character*6  potlbl(0:nphx)
      dimension iz(0:nphx)
c     central atom phase shift at l0
      complex phc(nex)
      complex ck(nex)
      real xk(nex)
      dimension index(npx)
      dimension nleg(npx)
      real deg(npx), reff(npx), crit(npx)
      dimension ipot(legtot,npx)
      real rat(3,legtot,npx), beta(legtot,npx), eta(legtot,npx)
      real ri(legtot,npx)
      real achi(nex,npx), phchi(nex,npx)

c     stuff from xsect.bin
      complex*16 emxs(nex), xsec(nex)
      dimension omega(nex), xkxs(nex), xsnorm(nex)
      dimension omegax(nfinex)
c#mn
      external getxk

c !KJ locals  1-06
      integer iip
      logical cross
      character*9 f1,f2
      character*10 f0,f3
      complex*16 kxsec(nex)
!KJ end my variables


c     lines below allow to skip FMS module for DANES
c     after XANES calculations
      open (unit=1, file='phase.pad', status='old', iostat=ios)
      if (ios.le.0 .and. abs(ispec).eq.3) then
        read(1,*) ne3, ne3, ne3, ne3
      endif
      close (unit=1)


c !KJ loop over iip added to process several spectra at once  1-06
c !KJ reading of feff.pad and list.dat moved inside the loop (used to be before reading
c !KJ xsect.bin
      do iip=ipmin,ipmax,ipstep
        cross=(.not.(iip.eq.1.or.iip.eq.10.or.iip.eq.5.or.iip.eq.9))

c !KJ choose different filename for each spectrum.
        if(iip.eq.1) then
           f1(1:9)='chi.dat  '
           f2(1:9)='xmu.dat  '
           f0(1:10)='feff.pad  '
           f3(1:10)='list.dat  '
        elseif(iip.eq.10) then
           f1(1:9)='chi10.dat'
           f2(1:9)='xmu10.dat'
           f0(1:10)='feff10.bin'
           f3(1:10)='list10.dat'
        elseif(iip.gt.1.and.iip.lt.10) then
           f1(1:4)='chi0'
           f1(5:5)= char(48+iip)
           f1(6:9)='.dat'
           f2(1:4)='xmu0'
           f2(5:5)= char(48+iip)
           f2(6:9)='.dat'
           f0(1:5)='feff0'
           f0(6:6)= char(48+iip)
           f0(7:10)='.bin'
           f3(1:5)='list0'
           f3(6:6)= char(48+iip)
           f3(7:10)='.dat'
        else
           stop 'crazy iip in ff2xmu'
        endif

c     open list.dat and read list of paths we want
      open (unit=1, file = f3, status='old', iostat=ios) !KJ changed 'list.dat' to f3 1-06
      call chopen (ios, f3, 'ff2chi') !KJ id.
      nhead = nheadx
      call rdhead (1, nhead, head, lhead)
c     skip a label line
      read(1,*)
      ntotal = 0
c     ip is index of path, sig2u is debye-waller from user
      do i = 1, npx
         read(1,*,end=110)  ip(i), sig2u(i)
         ntotal = i
      enddo
  110 continue
      close (unit=1)


c     read 'xsect.bin'
      call  rdxbin (s02p, erelax, wp, edgep, s02, gamach, ne1, ik0,
     2  emxs, omega, xkxs, xsnorm, xsec, nxsec, mbconv, title, ntitle)
c !KJ I have put rdxbin inside the loop since omega is 'recycled' below,
c !KJ which is a problem if the loop executes more than once.
c !KJ Simply reading the file again and again is the lazy solution,
c !KJ but it avoids confusing changes to the code (eg., new variables).

       call rdfbin (f0, nphx, nex, npx, legtot,  !KJ changed 'feff.pad' to f0  1-06
     $      nptot, ne, npot, ihole, iorder, ilinit,
     $      rnrmav, xmu, edge, potlbl, iz, phc, ck, xk, index,
     $      nleg, deg, reff, crit, ipot,
     $      rat, beta, eta, ri, achi, phchi)

c     make combined title
      do ihead = 1, nhead
         title(ntitle+ihead) = head(ihead)
      enddo
      ntitle = ntitle + nhead

c     write feffnnnn.dat
      if (ipr4.eq.3) then
         call feffdt(ntotal,ip,nptot,ntitle,title,ne1,
     $        iorder, ilinit, rnrmav, edge, potlbl,
     $        iz,phc,ck,xk,index,
     $        nleg,deg,reff,crit,ipot,rat,achi,phchi)
       end if

      if (iabs.eq.1) then
c        compare grids in xsect.bin and feff.pad
         do i = 1, nxsec
           del = xk(i)**2 - xkxs(i)**2
           if (abs(ispec).ne.3 .and. abs(del) .gt. 10*eps4)  then
             call wlog(' Emesh in feff.pad and xsect.bin different.')
             call wlog
     1       (' Results may be meaningless, check input files.')
             call wlog
     1       (' Either use XANES card or remove xsect.bin file.')
             write(slog,670)  i, xk(i)/bohr, xkxs(i)/bohr, del
             call wlog(slog)
  670        format(i7, 1p, 3e13.5)
             call par_stop('FF2CHI-1')
           endif
        enddo
      endif

c     If there is a vicorr, will need a mean free path factor xlam0.
c     Use it as  chi(ie) * exp (2 * reff * xlam0)
c     ckp is ck' = ck prime.
      if (abs(vicorr) .ge. eps4) then
         do ipath = 1, nptot
            do ie = 1, ne
               ckp = sqrt (ck(ie)**2 + coni*2*vicorr)
               xlam0 = aimag(ck(ie)) - dimag(ckp)
               achi(ie,ipath) = achi(ie,ipath) *
     1              real(exp (2 * reff(ipath) * xlam0))
            enddo
         enddo
      endif

c     Decide on fine grid.  We need two, k' evenly spaced by
c     delk (0.05 invA) and k0 being the place in the original k
c     grid corresponding to each k'.  k0 will not in general be on
c     an original grid point.  Define k' by k'**2 = k**2 + vr.
c     If there is no real correction (vrcorr = 0), these two grids
c     will be the same.
c           k' is value for output, k0 is k value used for
c           interpolations with original grid.

c     vrcorr shifts the edge and the k grid
      if (abs(vrcorr) .gt. eps4)  then
         edge = edge - real(vrcorr)
      endif

c     Find xkmin, beginning of k' grid
      delk = 0.05 * bohr
      tmp = sign (real(one), xk(1))
      e = tmp * xk(1)**2 / 2 + vrcorr
      xkpmin = getxk (e)
      n = int(xkpmin / delk)
c     need 1st int ABOVE xkpmin/delk
      if (xkpmin .gt. 0)  n = n + 1
c     First k grid point moved by vrcorr
      xkmin = n * delk

c     Make xkp (k') and xk0 (k0) fine grids
c     ik0 is index at fermi level
      if (abs(ispec).ne.3) ik0 = 1
      ik0p = 1
      do i = 1, nfinex
         xkp(i) = xkmin + delk * (i - 1)
         tmp = sign (one, xkp(i))
         e = tmp * xkp(i)**2 /2 - vrcorr
         xk0(i) = getxk(e)
         if (xk0(i).lt.eps4)  ik0p = i
         if (xk0(i) .gt. xk(ne1)+eps4)  goto 260
         nkx = i
      enddo
  260 continue

      dwcorr = .false.
      if (tk .gt. 1.0e-3)  dwcorr = .true.

c     Open chi.dat and xmu.dat (output) and start headers
      if (iabs.eq.nabs) then
         open (unit=3, file=f1, status='unknown', iostat=ios) !KJ changed chi.dat to f1 1-06
         call chopen (ios, f1, 'ff2chi') !KJ id.
         open (unit=8, file=f2, status='unknown', iostat=ios) !KJ changed xmu.dat to f2  1-06
         call chopen (ios, f2, 'ff2chi') !KJ id.

c        write miscellaneous staff into headers  !KJ corrected typo
         call wrhead (3, ntitle, title, dwcorr, s02,
     1        tk, thetad, sig2g, alphat, vrcorr, vicorr, critcw)

         call wrhead (8, ntitle, title, dwcorr, s02,
     1        tk, thetad, sig2g, alphat, vrcorr, vicorr, critcw)

c        also write information on the screen
         if (alphat .gt. zero)  then
            write(slog,322) alphat
  322       format ('    1st and 3rd cumulants, alphat = ', 1pe20.4)
            call wlog(slog)
         endif
         if (abs(vrcorr).ge.eps4 .or. abs(vicorr).ge.eps4)  then
            write(slog,343) vrcorr*hart, vicorr*hart
  343       format ('    Energy zero shift, vr, vi ', 1p, 2e14.5)
            call wlog(slog)
         endif

         write(slog,370) critcw
         call wlog(slog)
  370    format ('    Use all paths with cw amplitude ratio', f7.2, '%')
         if (dwcorr)  then
            write(slog,380) s02, tk, thetad, sig2g
  380       format('    S02', f7.3, '  Temp', f8.2, '  Debye temp',f8.2,
     1           '  Global sig2', f9.5)
            call wlog(slog)
         else
            write(slog,381) s02, sig2g
  381       format('    S02', f7.3, '  Global sig2', f9.5)
            call wlog(slog)
         endif
      endif


c     make chi and sum it
      do i = 1, nfinex
         cchi(i) = 0
      enddo

c     add Debye-Waller factors
      call dwadd (ntotal, nptot, idwopt, ip, index, crit, critcw, sig2g,
     1  sig2u, dwcorr, rnrmav, nleg, deg, reff, iz, ipot,rat, tk,thetad,
     2  alphat, thetae, mbconv, s02, ne1, ck, achi, phchi, nkx, xk, xk0,
     3  xkp, cchi, iabs, nabs, ispec, ipr4, ntitle,
     4  title, vrcorr, vicorr, nused)

c     read or initialize chia - result of configuration average
      if (iabs.eq.1) then
         do ie =1, nfinex
            chia(ie) = 0
         enddo
      else
         open (unit=1, file='chia.bin', status='old',
     1   access='sequential', form='unformatted', iostat=ios)
         do ie = 1,nkx
            read(1) chia(ie)
         enddo
         close (unit=1, status='delete')
      endif

c     add contribution from an absorber iabs
c     present scheme assumes that xsec is the same for all iabs.
      do ik = 1, nkx
         chia(ik)   = chia(ik)   + cchi(ik)/ nabs
      enddo
      if (iabs.lt.nabs) then
c        save chia in chia.bin for averaging
         open (unit=1, file='chia.bin', status='unknown',
     1   access='sequential', form='unformatted', iostat=ios)
         do ie=1,nkx
            write(1) chia(ie)
         enddo
         close(unit=1)
      endif

      if (iabs.eq.nabs) then
c        the loop over absorbers finished, ready to report results

c        Write it out
         write(3,600)  coment, nused, ntotal
         write(8,600)  coment, nused, ntotal
  600    format (a2, 1x, i4, '/', i4, ' paths used')
         write(3,610) coment
  610    format (a2, 1x, 71('-'))
         write(3,620) coment
  620    format(a2,
     1         '      k          chi          mag           phase @#')

         do ik = 1, nkx
           if (abs(ispec).ne.3) then
            rchtot(ik) = dimag (chia(ik))
           else
            rchtot(ik) = dble (chia(ik))
           endif
        enddo
c        prepare the output grid omegax
         efermi = edge + omega(1) - dble(emxs(1))
         do ik = 1, nkx
            if (xkp(ik) .lt. 0.0) then
               omegax(ik) = - xkp(ik) * xkp(ik) / 2  + efermi
            else
               omegax(ik) = xkp(ik) * xkp(ik) / 2  + efermi
            endif
         enddo

c        do convolution with excitation spectrum
c        it is currently screwed up since xsnorm is rewritten
c        fix later
         if (mbconv .gt. 0) then
            wp = wp / 2.
            call  exconv
     1      (omega, ne1, efermi, s02p, erelax, wp, xsnorm)
            call  exconv
     1      (omegax, nkx, efermi, s02p, erelax, wp, rchtot)
         endif


c        write to 'chi.dat'
         do ik = 1, nkx
            ccc = chia(ik)
            phase = 0
            if (abs(ccc) .gt. 0)  then
               phase = atan2 (dimag(ccc), dble(ccc))
            endif
            if (ik .gt. 1)  call pijump (phase, phase0)
            phase0 = phase
            if (ipr4.ne.4) then
              write(3,630)  xkp(ik)/bohr, rchtot(ik), abs(ccc), phase0
  630         format (1x, f10.4, 3x, 3(1pe13.6,1x))
            else
c             need to report ck into chi.dat for Conradson's program
c             complex*16 should be used in terpc
              do i=1,ne
                 ckck(i) = dble(real(ck(i))) +coni*dble(aimag(ck(i)))
              enddo
              call terpc (xkxs, ckck, ne, 3, xk0(ik), ckp)
              write(3,650)  xkp(ik)/bohr, rchtot(ik), abs(ccc), phase0,
     1        dble(ckp)/bohr, dimag(ckp)/bohr
  650         format (1x, f10.4, 3x, 5(1pe13.6,1x))
            endif
         enddo
         close (unit=3)

c        write to 'xmu.dat'
c        normalize to xsec at 50 eV above edge
c        and prepare the output energy grid omegax
         edg50 = efermi + 50 / hart
         call terp (omega, xsnorm,  ne1, 1, edg50, xsedge)
         if (absolu.eq.1) xsedge=dble(1) !KJ 1-06 don't normalize
         write(8,690)  coment, xsedge
  690    format (a2, ' xsedge+50, used to normalize mu ', 1pe20.4)
         write(8,610) coment
         write(8,695) coment
  695    format (a2,' omega    e    k    mu    mu0     chi     @#')

         do i=1,nex
            if (.not.cross) then !KJ I added this block 1-06
               kxsec(i)=xsec(i)
            else
               kxsec(i)=dcmplx(0,0)
            endif               !KJ end my code
         enddo

c        do edge correction and write down results to xmu.dat, chi.dat
         do ie = 1, ne
            chia(ie) = 0
         enddo
         if (abs(ispec).eq.3) then
c          transform from cross section in Angstrom**2 to f"/m*c**2
           do ie = 1,ne
             energy = dble(emxs(ie)) + efermi
             prefac = 4 * pi * alpinv / energy * bohr**2
c            add alpha**2 to convert to units for f'
             kxsec(ie) = kxsec(ie) / prefac * alpinv**2   !KJ changed xsec to kxsec  1-06
             xsnorm(ie) = xsnorm(ie) / prefac * alpinv**2
          enddo
           ne2 = ne - ne1 - ne3
           call fprime(efermi, emxs, ne1, ne3,ne,ik0, kxsec,xsnorm,chia,
     1       vrcorr, vicorr, cchi)  !KJ changed xsec to kxsec 1-06
           do ie=1,ne1
             omega(ie) = dble(cchi(ie))
          enddo
         else
           call xscorr (ispec, emxs, ne1, ne, ik0, kxsec, xsnorm, chia,
     1       vrcorr, vicorr, cchi) !KJ xsec to kxsec 7/06
c          omega is not used as energy array, but as xsec array below
           do ie = 1, ne1
              omega(ie) = dimag(kxsec(ie)+cchi(ie)) !KJ xsec to kxsec 7/06
           enddo
         endif

         do ik = 1, nkx
            em0 = omegax(ik) - efermi + edge
            call terp (xkxs, omega,  ne1, 1, xk0(ik), xsec0)
            call terp (xkxs, xsnorm,  ne1, 1, xk0(ik), xsnor0)
            if (omegax(ik).ge.efermi) then
              chi0 = xsnor0 * rchtot(ik)
            else
              chi0 = xsnor0 * rchtot(ik0p)
            endif
            if (abs(ispec).ne.3) then
              write(8,700)  omegax(ik)*hart, em0*hart, xkp(ik)/bohr,
     1              ( chi0 + dble(xsec0) )/xsedge,
     1              xsec0 /xsedge, rchtot(ik)
            else
c             signs to comply with Cromer-Liberman notation for f', f"
              write(8,700)  omegax(ik)*hart, em0*hart, xkp(ik)/bohr,
     1             -(xsec0+chi0), -xsec0, -chi0
            endif
  700       format (1x, 2f11.3, f8.3, 1p, 3e13.5)
         enddo
         close (unit=8)
      endif
c     for if (iabs=abs); or the last absorber


      enddo !KJ of my iip=ipmin,ipmax,ipstep loop   1-06

      return
      end
