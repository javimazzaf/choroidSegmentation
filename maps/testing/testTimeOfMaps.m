function testTimeOfMaps(varargin)

if ispc
    dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
elseif ismac
    dirlist = fullfile([filesep 'Volumes'],varargin{1});
else
    dirlist = fullfile(filesep,'srv','samba',varargin{1});
end

timeRate = NaN(size(dirlist));

for iter = 1:numel(dirlist)
    
        directory = dirlist{iter};
        
        fname  = fullfile(directory,'Data Files','ImageList.mat');
        if ~exist(fname,'file')
            disp(['File not found:' fname])
            continue
        end
        
        load(fname,'ImageList');
        
        h = [ImageList(:).hour];
        m = [ImageList(:).minute];
        s = [ImageList(:).second];
        
        time = h * 60^2 + m * 60 + s;
        time = time - min(time);
        
        n = (1:numel(time))';
        time = time';
        
        fo = fit(n,time,'poly1');
        
%         plot(fo,n,time)
%         title(['Seconds per b-scan: ' num2str(fo.p1)])
%         cla
        
        timeRate(iter) = fo.p1;
        
        disp(iter)        
end

figure;
hist(timeRate,0:0.1:4)

end
