function [info] = GetPatientDetails(dirlist)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


if ispc
    dirlist = fullfile([filesep filesep 'HMR-BRAIN'],dirlist);
    workersAvailable = Inf; %Uses parallel computing
    databasedir=fullfile('\\HMR-BRAIN','share','SpectralisData');
elseif ismac
    dirlist = fullfile([filesep 'Volumes'],dirlist);
    workersAvailable = 0; %Uses 1 worker computing
    databasedir=fullfile(filesep,'Volumes','share','SpectralisData');
else
    dirlist = fullfile(filesep,'srv','samba',dirlist);
    workersAvailable = 0; %Uses 1 worker computing
    databasedir=fullfile(filesep,'srv','samba','share','SpectralisData');
end


load(fullfile(databasedir,'DatabaseFile.mat'))

info=table([],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]);

info.Properties.VariableNames=[dbase.Properties.VariableNames([1,4,5,7:22]),'Data'];

info.Properties.VariableNames{'DateofBirth'} = 'Age';

for i=1:length(dirlist)
    directory=dirlist{i};
%     ID=regexp(directory,['(?<=Patients\\)\w*(?=\s\.*)'],'match');
    ID=regexp(directory,['(?<=Patients\' filesep ')\w*(?=\s\.*)'],'match');
    Date=regexp(directory,'\d+-\d+-\d+','match');
%     Study=regexp(directory,[['(?<=\d+-\d+-\d+' filesep filesep ')'] '.*(?=' filesep filesep ')'],'match');
    Study=regexp(directory,[['(?<=\d+-\d+-\d+\' filesep ')'] '.*(?=\' filesep ')'],'match');
    Eye=regexp(directory,'O[SD]','match');
    Repro=regexp(directory,'(?<=O[SD]\s)\d+','match');
    
    if isempty(Repro)
        Repro=0;
    else
        Repro=str2num(Repro{:});
    end
    
    dbrow=find(strcmp(ID,dbase.ID) & strcmp(Date,dbase.ExamDate) &...
                strcmp(Study,dbase.Study) & strcmp(Eye,dbase.Eye) &...
                Repro==cell2mat(dbase.Reproducibility));
            
    Group = dbase.Group(dbrow);
    Sex   = dbase.Sex(dbrow);
    
%     [Y,M,D]=datevec(datenum(dbase.DateofBirth(dbrow),'dd-mm-yyyy'));
%     [Y2,M2,D2]=datevec(now);
%     if M2<M
%         Age=Y2-Y-1;
%     elseif M2==M
%         if D2<D
%             Age=Y2-Y-1;
%         else
%             Age=Y2-Y;
%         end
%     else
%         Age=Y2-Y;
%     end
    
    Age = year(datenum(dbase.ExamDate(dbrow),'dd-mm-yyyy') - datenum(dbase.DateofBirth(dbrow),'dd-mm-yyyy'));

    row=dbase(dbrow,[1,4,5,7:22,26]);
    row.Properties.VariableNames{'DateofBirth'}='Age';
    row.Age=Age;
    
    load(fullfile(directory,'Results','ChoroidMapNew.mat'),'Cmap','xvec','yvec')
    [gx,gy]=GetFundusMesh(directory,xvec,yvec);
    
    row.Data={Cmap,gx,gy};
    
    
    
    info=[info;row];
    
    

end

