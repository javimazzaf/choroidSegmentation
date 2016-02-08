% Simple function to write to a LOG file.
% The file is created for each day, if it does not exist. Otherwise, info
% is appended to the file. The inputs are the path and the text to append in a new
% line.

function outText = logit(dname,inText)

try
    
    fname = fullfile(dname,['log' datestr(now,'yyyymmdd') '.txt']);
    
    fid = fopen(fname,'a');
    
    if fid == -1, return, end
    
    outText = sprintf('%s: \t %s \n',datestr(now,'HH:MM:SS.FFF'),inText);
    
    fprintf(fid,'%s',outText);
    
    logFullFile(dname, inText);
    
catch
    
    outText = '';
    
end

fclose(fid);

end

function logFullFile(dname, inText)

try
    baseDir = regexp(dname,  ['.*SpectralisData' filesep ''],'match');
    
    if isempty(baseDir), return, end
    
    fname = fullfile(baseDir{:},'logs',['log' datestr(now,'yyyymmdd') '.txt']);
    
    fid = fopen(fname,'a');
    
    if fid == -1, return, end
    
    outText = sprintf('%s: \t %s \n',datestr(now,'yyyy-mm-dd HH:MM:SS.FFF'),inText);
    
    fprintf(fid,'%s',outText);
    
catch exc
end

fclose(fid);

end