function [wk1,wk2,ph,vari,F]=lspr(x,y,hifac,ofac)
%///////////////////////////////////////////////////////////////
% Lomb-Scargle periodogram (work version for reconstruction)  
% procedure is based on the Numerical Recipe's programs 
% period.f (please see there for comments and explanations; 
% Numerical Recipes, 2nd edition, Chapter 13.8, by Press et al., Cambridge, 1992)
% Here, the program code is adopted from the related IDL program lnp.pro
% and is translated to Matlab. New features are the 
% phase determination (Hocke, Ann. Geophys. 16, 356-358,1998) 
% and the output of a complex Fourier spectrum F. 
% This spectrum can be used for inverse FFT and reconstruction of an evenly 
% spaced time series (Scargle, 1989).
%    
% ATTENTION: 
% -> Because of the long story of program development and some open problems  
% -> of phase definition and construction of the FFT spectrum, 
% -> the program must be regarded as a working and discussion version 
% -> without any warranty!  
% -> Particularly the phase determination with the Lomb-Scargle
% -> periodogram has been done in a heuristic manner. Switching between 
% -> the phase reference systems may introduce errors which I am not aware yet.   
% -> Scargle (1989) gives more informations on the details  of the problem. 
%    (K. Hocke, Nov. 2007).
%
%  program call: 
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%  [wk1,wk2,ph,vari,hifac,ofac,F]=lspr(x,y);
%;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% 
%  input:
%  x: e.g. time vector 
%  y: observational data y(x)
% 
%  output:
%  wk1: frequency axis ( a vector of increasing linear frequencies)
%  wk2: Lomb normalized power as function of wk1-vector
%  ph:  phase vector as function of wk1-vector. The phase 
%       is in radians and is defined to be the argument 
%       of the cosine wave at the time x=0 ! 
%  vari: sigma^2,  variance of y, necessary to derive 
%       the amplitude from the normalized power wk2 
%  F:   complex Pseudo-Fourier spectrum 
%
%  please check the phases and their signs before interpreting the phases! 
%
%  keywords:
%  ofac: oversampling factor , integer  
%        The default is 4
%  hifac: integer, 1 for frequencies up to the Nyquist frequency 
%         (2 for 2*Nyquist frequency)
% 
% \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
xstart=x(1);
x=x-xstart;   % simplifies the FFT construction (wx(1)=0 ) 

twopi=6.2831853071795865;
n=length(x);
s=size(y); if s(1)==1;y=y';end  % transpose the series if necessary
nout=0.5*ofac*hifac*n;
nmax=nout;

wi=zeros(nmax,1);
wpi=wi;
wpr=wi;
wr=wi;
wtemp=wi;
px=wi;
py=wi;
ph=wi;
ph1=wi;
Fx=wi;
Fy=wi;
ave=mean(y);
vari=var(y);

xmax=max(x);
xmin=min(x);
xdif=xmax-xmin;
xave=0.5*(xmax+xmin);

pymax=0.;
pnow=1/(xdif*ofac);
arg=twopi*((x-xave)*pnow);
wpr=-2.d0*sin(0.5d0*arg).^2;
wpi=sin(arg);
wr=cos(arg);
wi=wpi;
yy=(y-ave)';
for i=1:nout
	px(i)=pnow;	
	sumsh=sum(wr.*wi);
	sumc=sum((wr-wi).*(wr+wi));
	wtau=0.5*atan2(2.*sumsh,sumc);  
	swtau=sin(wtau);            
	cwtau=cos(wtau);
	ss=wi.*cwtau-wr.*swtau;
	cc=wr.*cwtau+wi.*swtau;
	sums=sum(ss.^2);
        sumc=sum(cc.^2);
	sumsy=sum(yy.*ss);
	sumcy=sum(yy.*cc);
	wtemp=wr;
	wr=wr.*wpr-wi.*wpi+wr;
	wi=wi.*wpr+wtemp.*wpi+wi;
	iy=sumsy/sqrt(sums); % imaginary part of Lomb-Scargle spectral component
	ry=sumcy/sqrt(sumc); % real part 
	py(i)=0.5*(ry^2+iy^2)/vari; % power
	% here, the FFT phase is computed from the Lomb-Scargle Phase 
	% at each new frequency 'pnow' by adding the phase shift 'arg0'     
	phLS=atan2(iy,ry);            % phase of Lomb-Scargle spectrum 
	arg0=twopi*(xave+xstart)*pnow +wtau;  % phase shift with respect to 0
	arg1=twopi*xave*pnow +wtau;   % phase shift for FFT reconstruction 
	ph(i)=mod(phLS+arg0, twopi);  % phase with respect to 0
	ph1(i)=mod(phLS+arg1, twopi); % phase for complex FFT spectrum	
	pnow=pnow+1./(ofac.*xdif);    % next frequency
end

dim=2*nout+1;    %dimension of FFT spectrum
fac=sqrt(vari*dim/2);
a=fac*sqrt(py);    % amplitude vector for FFT
Fx=a.*cos(ph1); % real part of FFT spectrum
Fy=a.*sin(ph1); % imaginary part of FFT spectrum 
ph=mod(ph +5*twopi, twopi);    % for value range 0,..., 2 pi	
wk1=px ; wk2=py;

% Fourier spectrum F: arrangement of the Lomb-Scargle periodogram   
% as a Fourier spectrum in the manner of Matlab:
% (it is not fully clear yet if and how the complex Fourier spectrum 
% can be exactly constructed from the Lomb-Scargle periodogram.  
% The present heuristic approach works well for the FFT back transformation   
% of F and reconstruction of an evenly spaced series 'yfit' in the time domain (after 
% multiplication by a constant, 'yfit' fits to 'y') 
  
Fxr=flipud(Fx); Fxr(1)=[];  
Fyr=flipud(Fy); Fyr(1)=[];
%complex Fourier spectrum which corresponds to the Lomb-Scargle periodogram: 
F=[complex(ave,0)' complex(Fx,Fy)' complex(Fxr,-Fyr)'];  


