function V = ValleyDet(fRetinaCol,del)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

n=length(fRetinaCol);

V=zeros(n,1);

Lmax=0; imax=1; imin=1;

for i=2:n
    if fRetinaCol(i)>fRetinaCol(imax)
        imax=i;
    end
    
    if fRetinaCol(i)<fRetinaCol(imin)
        imin=i;
    end
    
    if Lmax
        if fRetinaCol(i)<fRetinaCol(imax)-del
            imin=i;
            Lmax=0;
        end
    else
        if fRetinaCol(i)>fRetinaCol(imin)+del
            V(imin:i-1)=1;
            imax=i;
            Lmax=1;
        end
    end    
end

V=logical(V);
