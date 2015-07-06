function convertSpectralis(varargin)

if length(varargin)==1
    
    if ispc
        dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
    elseif ismac
        dirlist = fullfile([filesep 'Volumes'],varargin{1});
    else
        dirlist = fullfile(filesep,'srv','samba',varargin{1});
    end
    
else
    
    if ispc
        load(fullfile([filesep filesep 'HMR-BRAIN'],'Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    elseif ismac
        load(fullfile([filesep 'Volumes'],'Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist = fullfile([filesep 'Volumes'],dirlist);
    else
        load(fullfile(filesep,'srv','samba','Share','SpectralisData','Code','Choroid Code','Directories','directories.mat'))
        dirlist=fullfile(filesep,'srv','samba',strrep(dirlist,'\','/'));
    end
    [missdata,missraw,missprocessim,missregims,missresults]=CheckDirContents(dirlist);
    dirlist=dirlist(~missraw);
    
end

for iter=1:length(dirlist)
    folder=dirlist{iter};
    if ~exist(fullfile(folder,'Processed Images'),'dir') || isempty(dir(fullfile(folder,'Processed Images')))
        mkdir(fullfile(folder,'Processed Images'));
        mkdir(fullfile(folder,'Data Files'));
        x=dir(fullfile(folder,'Raw Images','*.xml'));
        
        Heart=dir(fullfile(folder,'Raw Images','*.txt'));
        
        if ~isempty(Heart)
            
            fileID=fopen(fullfile(folder,'Raw Images',Heart.name),'r');
            fileID2=fopen(fullfile(folder,'Raw Images',[Heart.name '.txt']),'w');
            
            while ~feof(fileID)
                line=fgetl(fileID);
                line=strrep(line,':','.');
                fprintf(fileID2,'%s\r\n',line);
            end
            fclose(fileID);
            fclose(fileID2);
            
            delete(fullfile(folder,'Raw Images',Heart.name))
            movefile(fullfile(folder,'Raw Images',[Heart.name '.txt']),fullfile(folder,'Raw Images',Heart.name));
            
            hrtdata=load(fullfile(folder,'Raw Images',Heart.name));
            hrtindx=zeros(size(hrtdata,1),1);
            
        end
        
        try
            [~,ImageList]=analyzeSpectralisXML(fullfile(folder,'Raw Images',x.name));
        catch exc
            disp(logit(folder,['Error in ' fullfile(folder,'Raw Images',x.name) ' : ' exc.message]))
            continue;
        end
        
        tdif=ImageList(1).UTC/-60;
        
        imTime=zeros(size(ImageList,2),2);
        
        pause(.0002)
        
        dircontent=dir(fullfile(folder,'Raw Images','*.tif'));
        
        for i=1:size(ImageList,2);
            %         Processing_image=[i,size(ImageList,2)];
            no=[num2str(i-1,'%5.5d'),'.png'];
            try
                imtif=imread(fullfile(folder,'Raw Images',ImageList(i).fileName));
            catch
                ind=cell2mat(regexp(ImageList(i).fileName,{dircontent.name}));
                disp(logit(folder,['convertSpectralis: fixed ' folder]))
                ImageList(i).fileName=ImageList(i).fileName(ind:end);
                imtif=imread(fullfile(folder,'Raw Images',ImageList(i).fileName));
            end

            imout=rgb2gray(imtif);
            imwrite(imout,fullfile(folder,'Processed Images',no))
            
            imTime(i,1)=(ImageList(i).hour-tdif)+ImageList(i).minute*10^-2;
            imTime(i,2)=ImageList(i).second;
            
            if ~isempty(Heart)
                for it=1:size(hrtdata,1)
                    if imTime(i,1)==hrtdata(it,1) && abs(imTime(i,2)-hrtdata(it,2))<10^-2
                        hrtindx(it)=1;
                        
                    end
                end
            end
        end
        fundus=ImageList(1).fundusfileName;
        fundim=imread(fullfile(folder,'Raw Images',fundus));
        save(fullfile(folder,'Data Files','ImageList.mat'),'ImageList','fundim');
        if ~isempty(Heart)
            hrtdata(:,4)=hrtindx;
            save(fullfile(folder,'Data Files','HeartInfo.mat'),'hrtdata');
        end
        
        disp(logit(folder,['Done convertSpectralis in folder ' folder]))
    else
        continue
    end
    
    rmdir(fullfile(dirlist{iter},'Raw Images'),'s')
end