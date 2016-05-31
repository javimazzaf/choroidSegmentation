function mapPseudoRegistration(varargin)

dirlist = adaptToHMRpath(varargin{1});

for i=1:length(dirlist)
    
    directory = dirlist{i};
    
    try
    
    numframes=length(dir(strcat(directory,'/Processed Images/*.png')));
    
    load([directory '/Data Files/ImageList.mat']);
    
    imlist=dir(strcat(directory,'/Processed Images/*.png'));
    numAvg=vertcat(ImageList.numAvg);
    quality=vertcat(ImageList.quality);
    
    %Initialize Variables
    bscanstore=cell(numframes,1);
    skippedind=[];
    
    start=1;
    
    fileID = fopen([directory '/Data Files/TrimInfo.txt']);
    trimvalues=fscanf(fileID,'%d');
    CutLeft=trimvalues(1);
    CutRight=trimvalues(2);
    fclose(fileID);
    
    for frame=1:numframes
        bscan=imread([directory '/Processed Images/' imlist(frame).name]);
        bscanstore{frame}=bscan(:,CutLeft:CutRight);
    end
    save(fullfile(directory,'Data Files','RegisteredImages.mat'),'bscanstore','skippedind','imlist','start');
    
    catch exc  
        disp(logit(directory,['Error in MapPseudoRegistration while processing ' directory ' : ' exc.message]))
        continue         
    end
    
    disp(logit(directory,'Done MapPseudoRegistration'))
    
end



