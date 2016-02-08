function valid = validSpec(fname)

valid = false;

if ~exist(fname,'file'), return, end

load(fname,'validSpectrum');

if exist('validSpectrum','var')
    valid = validSpectrum;
end

end