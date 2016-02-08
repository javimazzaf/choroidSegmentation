function getFundus(dirlist)

dirlist = fullfile([filesep 'Volumes'],dirlist);



for k = 1:numel(dirlist)
    directory=dirlist{k};
    
    ID    = regexp(directory,['(?<=Patients\' filesep ')\w*(?=\s\.*)'],'match');
    Date  = regexp(directory,'\d+-\d+-\d+','match');
    Study = regexp(directory,[['(?<=\d+-\d+-\d+\' filesep ')'] '.*(?=\' filesep ')'],'match');
    Eye   = regexp(directory,'O[SD]','match');
    Repro = regexp(directory,'(?<=O[SD]\s)\d+','match');
    
    load(fullfile(directory,'Data Files','ImageList.mat'),'fundim')
    
    fname = [ID{:} '_' Date{:} '_' Study{:} '_' Eye{:} '_' Repro{:} '.png'];
    imwrite(fundim, ['~/Desktop/fundus/' fname])
%     imshow(fundim,[])
end


end