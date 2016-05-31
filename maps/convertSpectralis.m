function convertSpectralis(varargin)

dirlist = adaptToHMRpath(varargin{1});

for k = 1:numel(dirlist)
    
    folder = dirlist{k};

    disp(logit(folder,['Initiating convertSpectralis on ' folder]))
    
    if ~exist(fullfile(folder,'RawImages'), 'dir')
        mkdir(fullfile(folder,'RawImages'));
        
    end
    
    try
        
        if ~exist(fullfile(folder,'ProcessedImages'),'dir')
            mkdir(fullfile(folder,'ProcessedImages'));
        end
        
        if ~exist(fullfile(folder,'Processed Images Files'),'dir')
            mkdir(fullfile(folder,'DataFiles'));
        end
        
        x = dir(fullfile(folder,'RawImages','*.xml'));
        
        Heart = dir(fullfile(folder,'RawImages','*.txt'));
        
        if ~isempty(Heart)
            
            fileID=fopen(fullfile(folder,'RawImages',Heart.name),'r');
            fileID2=fopen(fullfile(folder,'RawImages',[Heart.name '.txt']),'w');
            
            while ~feof(fileID)
                line=fgetl(fileID);
                line=strrep(line,':','.');
                fprintf(fileID2,'%s\r\n',line);
            end
            fclose(fileID);
            fclose(fileID2);
            
            delete(fullfile(folder,'RawImages',Heart.name))
            movefile(fullfile(folder,'RawImages',[Heart.name '.txt']),fullfile(folder,'RawImages',Heart.name));
            
            hrtdata=load(fullfile(folder,'RawImages',Heart.name));
            hrtindx=zeros(size(hrtdata,1),1);
            
        end
        
        try
            [~,ImageList]=analyzeSpectralisXML(fullfile(folder,'RawImages',x.name));
        catch exc
            disp(logit(folder,['Error in ' fullfile(folder,'RawImages',x.name) ' : ' exc.message]))
            continue;
        end
        
        tdif=ImageList(1).UTC/-60;
        
        imTime=zeros(size(ImageList,2),2);
        
        pause(.0002)
        
        dircontent=dir(fullfile(folder,'RawImages','*.tif'));
        
        for i=1:size(ImageList,2);
            %         Processing_image=[i,size(ImageList,2)];
            no=[num2str(i-1,'%5.5d'),'.png'];
            try
                imtif=imread(fullfile(folder,'RawImages',ImageList(i).fileName));
            catch
                ind=cell2mat(regexp(ImageList(i).fileName,{dircontent.name}));
                disp(logit(folder,['convertSpectralis: fixed error in ' folder]))
                ImageList(i).fileName=ImageList(i).fileName(ind:end);
                imtif=imread(fullfile(folder,'RawImages',ImageList(i).fileName));
            end
            
            imout=rgb2gray(imtif);
            imwrite(imout,fullfile(folder,'ProcessedImages',no))
            
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
        fundim=imread(fullfile(folder,'RawImages',fundus));
        save(fullfile(folder,'DataFiles','ImageList.mat'),'ImageList','fundim');
        if ~isempty(Heart)
            hrtdata(:,4)=hrtindx;
            save(fullfile(folder,'DataFiles','HeartInfo.mat'),'hrtdata');
        end
        
    catch dirExc
        disp(logit(folder,['Error (convertSpectralis) in folder ' folder ' : ' dirExc.message]))
        continue
    end
    
    disp(logit(folder,['Done convertSpectralis in folder ' folder]))
    
    
    rmdir(fullfile(dirlist{k},'RawImages'),'s')
end