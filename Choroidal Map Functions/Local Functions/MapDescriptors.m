function [desc] = MapDescriptors(dirlist)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if ispc
    dirlist = fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
elseif ismac
    dirlist = fullfile([filesep 'Volumes'],dirlist);
else
    dirlist = fullfile(filesep,'srv','samba',dirlist);
end

desc=table([],[],[],[],[],[],[],[],[],[],[],[],'VariableNames',{'meanthick','maxthick','minthick',...
           'stdthick','smoothness','uniformity','entropy','minima','maxima','angleBM','angleFund','normal'});

for i=1:length(dirlist)
    
    load(fullfile(dirlist{i},'Results','ChoroidMapNew.mat'))
    load(fullfile(dirlist{i},'Data Files','ImageList.mat'))
    %% Dimensions
    meanThick=mean(Cmap(:));
    maxThick=max(Cmap(:));
    minThick=min(Cmap(:));
    stdThick=std(Cmap(:));

    Volume=sum(Cmap(:))*1E-9; %[microlitres]
    %% Texture
    t=statxture(uint16(Cmap/max(Cmap(:))*65535));
    smooth=t(3);
    uniformity=t(5);
    entropy=t(6);
   
    %% Geometry  
    Cmapmm=Cmap/1000;
    [qx,qy]=GetFundusMesh(dirlist{i},xvec,yvec);
    % Get Plane fit to Cmap with least squares fit
    [n,V,p] = affine_fit([qx(:) qy(:) -Cmapmm(:)]);
    % Assuming the image is still flattened, the BM should be horizontal so its normal is [0 0 1]
    angleBM=atan2d(norm(cross(n,[0 0 1])) , dot(n,[0 0 1]) );
    
    %Flip the X axis for left eyes so that the 0 angle line is always
    %pointing in the nasal direction.
    Eye=regexp(dirlist{i},'O[SD]','match');
    if strfind(Eye{:},'OS')
        angleFund=atan2d(n(2),-n(1));
    else
        angleFund=atan2d(n(2),n(1));
    end
    
    ncsi=n;
    
    %Extrema Deeper than 10 um and larger than 50 um
    depth=20;
    patchsize=10;
    
    minima=regionprops(imextendedmin(-Cmapmm,depth/1000),'Area','PixelIdxList'); 
    minArea=[minima.Area]*fscaleX*fscaleY*1000; 
    minNum=length(minArea(minArea>patchsize));
    minIdx=vertcat(minima(minArea>patchsize).PixelIdxList);
    
    maxima=regionprops(imextendedmax(-Cmapmm,depth/1000),'Area','PixelIdxList'); 
    maxArea=[maxima.Area]*fscaleX*fscaleY*1000; 
    maxNum=length(maxArea(maxArea>patchsize));
    maxIdx=vertcat(maxima(maxArea>patchsize).PixelIdxList);
    %% Visualize
%     figure
%     planeCSIfunc=@(x,y) -(n(1)*(x-p(1))+n(2)*(y-p(2)))/n(3)+p(3);
%     planeCSI=planeCSIfunc(qx(1:50:end,1:50:end),qy(1:50:end,1:50:end));
% 
%     planeBMfunc=@(x,y) -(0*(x-p(1))+0*(y-p(2)))/1+0;
%     planeBM=planeBMfunc(qx(1:50:end,1:50:end),qy(1:50:end,1:50:end));
%     
%     C=surf(qx,qy,-Cmapmm,'edgecolor','none');hold all;axis('ij','tight');set(get(C,'parent'),'color','none')
%     xlabel('x [mm]');ylabel('y [mm]');zlabel('z [mm]');
%     
%     lims=get(get(C,'parent'),'Zlim');
%     ratio=round(max(max(qx(:)),max(qy(:)))/max(Cmapmm(:)))
%     set(get(C,'parent'),'Zlim',[min(-Cmapmm(:)) .1],'plotboxaspectratio',[ratio/2 ratio/2 1])
%     set(get(C','parent'),'Xlim',[min(qx(:)) max(qx(:))])
%     set(get(C','parent'),'Ylim',[min(qy(:)) max(qy(:))],'color','none')

%     plCSI=surf(qx(1:50:end,1:50:end),qy(1:50:end,1:50:end),planeCSI,'facecolor',[0 0 0],'edgecolor','none','facealpha',0.5);
%     hold all
%     nvec1=quiver3(p(1),p(2),p(3),n(1),n(2),n(3),'autoscalefactor',5);
%     
%     plBM=surf(qx(1:50:end,1:50:end),qy(1:50:end,1:50:end),planeBM,'facecolor',[0 0 0],'edgecolor','none','facealpha',0.5);
%     hold all;
%     [n2,V2,p2] = affine_fit([reshape(qx(1:50:end,1:50:end),numel(planeBM),1),reshape(qy(1:50:end,1:50:end),...
%         numel(planeBM),1) planeBM(:)]);
%     nvec2=quiver3(p2(1),p2(2),p2(3),n2(1),n2(2),n2(3),'autoscalefactor',5);
    
%     plot3(qx(minIdx),qy(minIdx),-Cmapmm(minIdx),'r.')
%     plot3(qx(maxIdx),qy(maxIdx),-Cmapmm(maxIdx),'m.')

    temp=table(meanThick,maxThick,minThick,stdThick,smooth,uniformity,entropy,minNum,maxNum,angleBM,angleFund,{ncsi},'VariableNames',desc.Properties.VariableNames);
    desc=[desc;temp];
%     close all
end


end


