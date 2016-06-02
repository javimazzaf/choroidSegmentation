function Iout=ImageCompensation(I,nx,lim,method,output)

[m,n]=size(I);
I=im2double(I);

I=I.^4;
%%
switch output
    case 'Comp'
        compcoeff=flipud(cumsum(flipud(I)));
        Imethod=I;
    case 'CompExp'
        compcoeff=(flipud(cumsum(flipud(I)))).^nx;
        Imethod=I.^nx;
    case 'ExpComp'
        compcoeff=flipud(cumsum(flipud(I.^nx)));
        Imethod=I.^nx;
end

switch method
    case 'Standard'
        Iout=Imethod./compcoeff;
    case 'Adaptive'
        E=flipud(cumsum(flipud(I.^2)));
%         Eend=E(round(3/5*m):end,:);
%         artif=sum(Eend<repmat(mean(Eend,2),1,size(Eend,2)))/size(Eend,1);
%         artifind=find(artif<0.5);
        Emax=max(E,[],2);%(:,setdiff(1:size(E,2),artifind))
        %         nElimit=find(Emax<lim*max(Emax),1,'first');
        %         if isempty(nElimit)
        %             Elimit=0;
        %         else
        %             Elimit=Emax(nElimit);
        %         end
        
        %         compcoeff=flipud(cumtrapz(flipud(I)));
        compcoeff=max(compcoeff,lim*max(Emax));
        
        %         i=1:5:m;
        %         j=1:5:n;
        %
        %         figure
        %         hold all
        %         plot(i,E(i,j))
        %         plot(i,Emax(i),'linewidth',3,'linestyle','-.','color','k','marker','+')
        
        %         figure
        %         hold all
        %         plot(i,compcoeff(i,j),'-')
        %         plot(i,Emax(i),'linewidth',3,'linestyle','-.','color','k','marker','+')
        
        Iout=Imethod./compcoeff;
end
Iout=Iout.^.25;
Iout=mat2gray(Iout);
% figure(1)
% imshow(Iout);
end





