function info = GetStudyInfo(directory, dbase)

ID    = regexp(directory,['(?<=Patients\' filesep ')\w*(?=\s\.*)'],'match');
Date  = regexp(directory,'\d+-\d+-\d+','match');
Study = regexp(directory,[['(?<=\d+-\d+-\d+\' filesep ')'] '.*(?=\' filesep ')'],'match');
Eye   = regexp(directory,'O[SD]','match');
Repro = regexp(directory,'(?<=O[SD]\s)\d+','match');

if isempty(Repro)
    Repro = 0;
else
    Repro = str2num(Repro{:});
end

dbrow = find(strcmp(ID,dbase.ID) & strcmp(Date,dbase.ExamDate) &...
        strcmp(Study,dbase.Study) & strcmp(Eye,dbase.Eye) &...
        Repro==cell2mat(dbase.Reproducibility));

info = dbase(dbrow,:);
    
Age = year(datenum(info.ExamDate,'dd-mm-yyyy') - datenum(info.DateofBirth,'dd-mm-yyyy'));

info.Properties.VariableNames{'DateofBirth'} = 'Age';

info.Age = Age;

end

