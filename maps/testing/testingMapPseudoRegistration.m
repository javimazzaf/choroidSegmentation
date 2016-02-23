function testingMapPseudoRegistration(directory)

    
    numframes=length(dir(strcat(directory,'/Processed Images/*.TIFF')));
    imlist=dir(strcat(directory,'/Processed Images/*.TIFF'));
    
    %Initialize Variables
    bscanstore = cell(numframes,1);
    
    for frame=1:numframes
        bscan=imread([directory '/Processed Images/' imlist(frame).name]);
        bscanstore{frame} = uint8(mat2gray(mean(double(bscan(:,:,1:3)),3)) * 256);
    end
    
    skippedind = nan(numframes,1);
    start = 1;
    
    save(fullfile(directory,'Data Files','RegisteredImages.mat'),'bscanstore','skippedind','imlist','start');
    
end



