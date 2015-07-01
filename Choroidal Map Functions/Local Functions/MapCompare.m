function MapCompare(dirlist)

for i=1:length(dirlist)
    
    directory=dirlist{i};
    load(fullfile(directory,'Results','ChoroidMap.mat'));
    
    xmap{i}=xvec;
    ymap{i}=yvec;
    Chormap{i}=gridC;
    ref{i}=imref2d(size(gridC),[xvec(1) xvec(end)],[yvec(end) yvec(1)]);
    
end

fixed=Chormap{1};
rfixed=ref{1};
[optimizer,metric]=imregconfig('monomodal');
for i=2:length(dirlist)
    tform=imregtform(Chormap{i},ref{i},fixed,rfixed,'rigid',optimizer,metric);
    [aligned{i},r_aligned{i}]=imwarp(Chormap{i},ref{i},tform,'outputview',rfixed);
    
    mask=ones(size(Chormap{i}));
    [m_aligned,mr_aligned]=imwarp(mask,ref{i},tform,'outputview',rfixed);
    
    change=abs(aligned{i}-fixed);
    change(m_aligned<0.5)=0;
    
    %     createCompareFig(xmap{1},ymap{1},fixed,change,xmap{i},ymap{i},Cmap{i})
    h=figure;
    lims=get(h,'outerposition');
    
    sp1=subplot(1,3,1);
    [~,h1]=contourf(xmap{1},ymap{1},Chormap{1},50);
    set(h1,'linecolor','none')
    title('Scan 1, Choroidal Thickness [\mum]')
    xlabel('Fundus X Position [mm]')
    ylabel('Fundus Y Position [mm]')
    pos1=get(sp1,'outerposition');
    set(sp1,'outerposition',[0 0 .333 1])
    pos1=get(sp1,'outerposition');

    sp2=subplot(1,3,2);
    change=abs(aligned{i}-fixed);
    change(m_aligned<0.5)=0;
    [~,h2]=contourf(xmap{1},ymap{1},change,50);
    set(h2,'linecolor','none')
    title('Absolute Difference, Choroidal Thickness [\mum]')
    xlabel('Fundus X Position [mm]')
    ylabel('Fundus Y Position [mm]')
    set(sp2,'outerposition',[pos1(3) pos1(2) pos1(3) pos1(4)])
    pos2=get(sp2,'outerposition');
    
    sp3=subplot(1,3,3);
    [~,h3]=contourf(xmap{i},ymap{i},Chormap{i},50);
    set(h3,'linecolor','none')
    title('Scan 2, Choroidal Thickness [\mum]')
    xlabel('Fundus X Position [mm]')
    ylabel('Fundus Y Position [mm]')
    set(sp3,'outerposition',[pos1(3)+pos2(3) pos2(2) pos2(3) pos2(4)])
    pos3=get(sp3,'outerposition');
       
    set(get(h,'children'),'ydir','reverse')
    
    colorbar('peer',sp1,'location','southoutside');
    colorbar('peer',sp2,'location','southoutside');
    colorbar('peer',sp3,'location','southoutside');
    set(ancestor(h1,'axes'),'DataAspectRatio',[1 1 1])
    set(ancestor(h2,'axes'),'DataAspectRatio',[1 1 1])
    set(ancestor(h3,'axes'),'DataAspectRatio',[1 1 1])
end


