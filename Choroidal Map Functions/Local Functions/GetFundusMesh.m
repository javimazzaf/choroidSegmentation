function [qx,qy]=GetFundusMesh(directory,xvec,yvec)

load(fullfile(directory,'Data Files','ImageList.mat'));
 %% Fundus Info
    if isfield(ImageList,'fundusfileName')
        fundus=ImageList(1).fundusfileName;
        fwidth=ImageList(1).fwidth;
        fheight=ImageList(1).fheight;
        fscaleX=ImageList(1).fscaleX;
        fscaleY=ImageList(1).fscaleY;
    else
        x=dir([directory,'\Raw Images\*.xml']);
        
        fileID=fopen(fullfile(directory,'Raw Images',x.name));
        while ~feof(fileID)
            line=fgetl(fileID);
            if strcmp(line,'<Type>LOCALIZER</Type>')
                for i=1:18
                    line=fgetl(fileID);
                    if strncmp(line,'<Width>',7)
                        [e,s]=regexp(line,{'<Width>','</Width>'},'start','end');
                        fwidth=str2double((line(s{1}+1:e{2}-1)));
                    elseif strncmp(line,'<Height>',8)
                        [e,s]=regexp(line,{'<Height>','</Height>'},'start','end');
                        fheight=str2double((line(s{1}+1:e{2}-1)));
                    elseif strncmp(line,'<ScaleX>',7)
                        [e,s]=regexp(line,{'<ScaleX>','</ScaleX>'},'start','end');
                        fscaleX=str2double((line(s{1}+1:e{2}-1)));
                    elseif strncmp(line,'<ScaleY>',7)
                        [e,s]=regexp(line,{'<ScaleY>','</ScaleY>'},'start','end');
                        fscaleY=str2double((line(s{1}+1:e{2}-1)));
                    elseif strncmp(line,'<ExamURL>',9)
                        fundus=line;
                        ind1=regexp(fundus,'\');
                        ind2=regexp(fundus,'.tif');
                        fundus=fundus(ind1(end)+1:ind2+3);
                    end
                end
                break
            end
        end
        fclose(fileID);
    end
    
    k = fundim(:,:,1);
    % k=imadjust(k,[min(k(:)) max(k(:))],[0 1],.5);
    k     = intrans(k,'stretch',mean2(im2double(k)),2);
    Rfund = imref2d(size(fundim),[0 fwidth*fscaleX],[0 fheight*fscaleY]);
    fxvec = linspace(Rfund.XWorldLimits(1),Rfund.XWorldLimits(end),Rfund.ImageSize(1));
    fyvec = linspace(Rfund.YWorldLimits(1),Rfund.YWorldLimits(end),Rfund.ImageSize(2));
    % Indices In Fundus Image That Correspond To Cmap
    Xover = find( fxvec >= xvec(1) & fxvec <= xvec(end) );
    Yover = find( fyvec <= yvec(1) & fyvec >= yvec(end) );
    
    [qx,qy] = meshgrid(fxvec(Xover), fyvec(Yover));