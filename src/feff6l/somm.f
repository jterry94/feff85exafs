      subroutine somm (dr,dp,dq,dpas,da,m,np)
c
c integration by the method of simpson of (dp+dq)*dr**m from
c 0 to r=dr(np)
c dpas=exponential step;
c for r in the neighborhood of zero (dp+dq)=cte*r**da
c **********************************************************************
      implicit double precision (a-h,o-z)
      save
      dimension dr(251), dp(251), dq(251)
      mm=m+1
      d1=da+mm
      da=0.0
      db=0.0
      do i=1,np
         dl=dr(i)**mm
         if (i.ne.1.and.i.ne.np) then
            dl=dl+dl
            if ((i-2*(i/2)).eq.0) dl=dl+dl
         endif
         dc=dp(i)*dl
         if (dc.lt.0) then
            db=db+dc
         elseif(dc.gt.0) then
            da=da+dc
         endif
         dc=dq(i)*dl
         if (dc.lt.0) then
            db=db+dc
         elseif (dc.gt.0) then
            da=da+dc
         endif
      enddo
      da=dpas*(da+db)/3.0
      dc=exp(dpas)-1.0
      db=d1*(d1+1.0)*dc*exp((d1-1.0)*dpas)
      db=dr(1)*(dr(2)**m)/db
      dc=(dr(1)**mm)*(1.0+1.0/(dc*(d1+1.0)))/d1
      da=da+dc*(dp(1)+dq(1))-db*(dp(2)+dq(2))
      return
      end
