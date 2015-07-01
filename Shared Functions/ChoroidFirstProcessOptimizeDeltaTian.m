function [messedup,error,runtime] = ChoroidFirstProcessOptimizeDeltaTian(varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if length(varargin)==1
    dirlist=varargin{1};
else
    if ispc
        load(fullfile([filesep filesep 'HMR-BRAIN'],'Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    else
        load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
    end
    [missdata,missraw,missprocessim,missregims,missresults]=CheckDirContents(dirlist);
    dirlist=dirlist(~missregims);
    if isempty(dirlist)
        errordlg('No diretories prerequisite data. Run required registration program first')
        return
    end
end

c=parcluster('local');
if isempty(gcp('nocreate'))
    pool=parpool(c);
end

clock=tic;
messedup=[];
error=cell(length(dirlist),1);
for iter=1:length(dirlist)
    try
        directory=dirlist{iter};
        % Loop frames of current movie
        
        load(fullfile(directory,'Data Files','RegisteredImages.mat'));
        numframes=length(bscanstore);
        if exist(fullfile(directory,'Data Files','OrientedGradient.mat'),'file')
            load(fullfile(directory,'Data Files','OrientedGradient.mat'))
        else
            OG=cell(numframes,1);
        end
        
        bscanstore=bscanstore;
        skippedind=skippedind;
        
        %Initialize Variables
        nodes=cell(numframes,1);
        EndHeights=nan(numframes,2);
        traces=struct('RET',[],'RPE',[],'BM',[],'CSI',[],'nCSI',[],'usedCSI',[]);
        traces(numframes).CSI=[];
        other=struct('colshifts',[],'shiftsize',[],'smallsize',[],'bigsize',[]);
        other(numframes).colshifts=[];
        
        start=1;
        skippedind=[];
        %%
        parfor frame=start:numframes
            try
                if ismember(frame,skippedind)
                    continue
                else
                    bscan=bscanstore{frame};
                end
                %% Equalize Intensity
                [m,n]=size(bscan);
                %             bscan=uint8(ImageCompensation(bscan,1.3,0.03,'Adaptive','Comp')*255);
                %% Bruchs Membrane
                %             [yret]=FindRetina(bscan);
                
                [yret,~,yRPE,yBM]=FindAllMembranes(bscan,directory);
                %             figure(1)
                %             imshow(bscan)
                %             hold all
                %             plot(yret,'g','linewidth',1.5)
                %             plot(yRPE,'r','linewidth',1.5)
                %             plot(yBM,'b','linewidth',1.5)
                %             drawnow
                
                %[yret,yRPE,yBM,subBMmask]=FindMembranes(bscan);
                
                %% Flattening of Image According to BM
                midlevel=round(mean(yBM));
                colshifts=-(yBM-midlevel*ones(length(yBM),1));
                shiftsize=double(max(abs(colshifts)));
                
                shiftbscan=BMImageShift(bscan,colshifts,shiftsize,'Pad');
                
                [k,l]=size(shiftbscan);
                
                %% Edge Probability
%                 if ~exist(fullfile(directory,'Data Files','OrientedGradient.mat'),'file')
%                     scalesize=[10 15 20];
%                     angles=[-20 0 20];
%                     [~,padPb]=EdgeProbability(shiftbscan,scalesize,angles,midlevel,shiftsize);
%                     OG{frame}=padPb;
%                 end
                %% Inflection Points
%                 Infl2=zeros(k,l);
%                 shiftffbscan=imfilter(shiftbscan,OrientedGaussian([3 3],0));
%                 colspacing=2;
%                 for j=1:l
%                     grad=gradient(smooth(double(shiftffbscan(:,j)),10)); %10
%                     grad2=del2(smooth(double(shiftffbscan(:,j)),10)); %10
%                     z=find(grad2<1E-16 & grad>.7);
%                     Infl2(z(z>midlevel+shiftsize+15),j)=1; %%%%%%%%%%%%%% 15 before
%                 end
%                 Infl2=bwmorph(Infl2,'clean');
%                 Infl2=imfill(Infl2,'holes');
%                 Infl2=bwmorph(Infl2,'skel','inf');%,...
%                 Infl2(:,setdiff((1:l),(1:colspacing:l)))=0;
%                 Infl2=bwmorph(Infl2,'shrink','inf');
%                 g=imextendedmin(shiftffbscan,10);
%                 Infl2(Infl2&g)=0;
%                 
%                 nodes{frame}=Infl2;
                
                %% Find CSI
%                 [yCSI] = FindCSI(nodes{frame},OG{frame},shiftsize,colshifts);
                %             if isnan(yCSI)
                %                 [yCSI]=FindOCB(shiftbscan,OG{frame},shiftsize,midlevel);
                %                 yCSI=yCSI-colshifts-shiftsize;
                %             end
                
                %% TIAN CSI w/ Optimized Delta
                
                fbscan=wiener2(shiftbscan,[5 5]);
                fbscan=imfilter(fbscan,fspecial('average',[5,1]),'replicate');
                favgbscan=imfilter(fbscan,fspecial('average',[1,3]),'replicate');
                
                increments=[1:1:100];
                
%                 colorset=varycolor(length(increments));
%                 h1=figure(1);
%                 imshow(shiftbscan)
%                 set(gca,'colororder',colorset)
%                 hold all
%                 figure(2)
%                 hold all
%                 set(gca,'colororder',colorset)

                for p=1:length(increments)
                    del=increments(p);
                    
                    vals=zeros(size(fbscan));
                    for i=1:3:size(vals,2)
                        vals(shiftsize+midlevel:end,i)=ValleyDet(favgbscan(shiftsize+midlevel:end,i),del);
                    end
                    
                    PathPts=GraphSearchTian(vals,2,20000,25,30,5);
                    
                    if ~isnan(PathPts)
                        [y{frame,p},~]=ind2sub([k l],PathPts);
                        yCSI=y{frame,p}'-colshifts-shiftsize;
                    else
                        break
                    end
                    
%                     figure(1)
%                     line=plot(y,'linewidth',2);
%                     
%                     figure(2)
%                     plot(del,mean(y),'markersize',40,'marker','.')   
                end
                    
%                 figure(1)
%                 legend(num2str(increments'))
%                 figure(2)
%                 legend(num2str(increments'))              
%             
%                 minlost=increments(p-1);
%                 nodes=vals;
                
                %% Error Checking
                if isempty(yCSI)
                    continue
                else
                    EndHeights(frame,:)=[yCSI(1)-yBM(1),yCSI(end)-yBM(end)];
                end
                
                %% Store Other Relevant Variables
                traces(frame).RET=yret;
                traces(frame).RPE=yRPE;
                traces(frame).BM=yBM;
                traces(frame).CSI=yCSI;
                other(frame).colshifts=colshifts;
                other(frame).shiftsize=shiftsize;
                other(frame).smallsize=[m,n];
                other(frame).bigsize=[k,l];
            catch
                mkdir(fullfile(directory,'Error Folder'))
                if exist('yret','var')
                    im1=repmat(bscan,1,1,3);
                    for j=1:n
                        im1(yret(j),j,1)=255;
                        im1(yret(j),j,[2,3])=0;
                        im1(yRPE(j),j,2)=255;
                        im1(yRPE(j),j,[1,3])=0;
                        im1(yBM(j),j,3)=255;
                        im1(yBM(j),j,[1,2])=0;
                    end
                    imwrite(im1,fullfile(directory,'Error Folder','Errfig.jpg'))
                end
                if exist('Infl2','var') 
                im2=imfuse(shiftbscan,imdilate(Infl2,[0 1 0;1 1 1;0 1 0]));
                imwrite(im2,fullfile(directory,'Error Folder','Errfig2.jpg'))
                end
                close(errfig)
            end
        end
        if ~exist(fullfile(directory,'Data Files','OrientedGradient.mat'),'file')
            save(fullfile(directory,'Data Files','OrientedGradient.mat'),'OG')
        end
        
        disp(['Done Loop ',num2str(iter)])
        %% Save Data before it's lost
        savedir=fullfile(directory,'Results');
        mkdir(savedir)
        save(fullfile(savedir,'TianFirstProcessData.mat'),'nodes','traces','other','EndHeights','y');
        disp(['Saved ',num2str(iter)])
        clearvars -except iter dirlist messedup runtime clock error
        close all
    catch exception
        error{iter}=exception;
        messedup=[messedup;iter];
        clearvars -except iter dirlist messedup runtime clock error
        close all
        if iter==length(dirlist) && ~isempty(gcp('nocreate'))
            delete(gcp('nocreate'))
        end
        continue
    end
end
runtime=toc(clock);
if ~isempty(gcp('nocreate'))
    delete(gcp('nocreate'))
end
end

%
% jp=1:10:n;
% imshow(bscan);hold all
% h1=plot(jp,yret(jp),'w>')
% set(h1,'linewidth',.001)
% set(h1,'markersize',4.5)
%
% h1=plot(jp,yRPE(jp),'k--')
% set(h1,'linewidth',1.5)
% set(h1,'markersize',4.5)
%
% h1=plot(jp,yBM(jp),'k.')
% set(h1,'linewidth',1.5)
% set(h1,'markersize',7)
%
% h1=plot(yCSI,'w-')
% set(h1,'linewidth',1.5)
% set(h1,'markersize',7)
%
% meand=mean(yCSI-yBM)
% h1=plot(yBM+meand,'w-.')
% set(h1,'linewidth',1.5)
% set(h1,'markersize',1)
%
% set(get(h1,'parent'),'visible','off')
