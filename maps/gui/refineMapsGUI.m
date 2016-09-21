function varargout = refineMapsGUI(varargin)
% REFINEMAPSGUI MATLAB code for refineMapsGUI.fig
%      REFINEMAPSGUI, by itself, creates a new REFINEMAPSGUI or raises the existing
%      singleton*.
%
%      H = REFINEMAPSGUI returns the handle to a new REFINEMAPSGUI or the handle to
%      the existing singleton*.
%
%      REFINEMAPSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REFINEMAPSGUI.M with the given input arguments.
%
%      REFINEMAPSGUI('Property','Value',...) creates a new REFINEMAPSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before refineMapsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to refineMapsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help refineMapsGUI

% Last Modified by GUIDE v2.5 26-Aug-2016 10:58:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @refineMapsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @refineMapsGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before refineMapsGUI is made visible.
function refineMapsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to refineMapsGUI (see VARARGIN)

% Checks that the folders array is provided
if nargin == 3
    error('Missing folders array')
end

if isempty(varargin{1})
    error('Folders array is empty')
end

% Complete the path according to the current computer
% if ispc,       dirlist = fullfile([filesep filesep 'HMR-BRAIN'],varargin{1});
%  elseif ismac, dirlist = fullfile([filesep 'Volumes'],varargin{1});
%  else          dirlist = fullfile(filesep,'srv','samba',varargin{1}); 
% end

dirlist = varargin{1};

handles.dirlist = dirlist;

handles.currentIndex = 1;

set(handles.xMaculaText,'String','X = ')
set(handles.yMaculaText,'String','Y = ')
set(handles.xOnhText,'String','X = ')
set(handles.yOnhText,'String','Y = ')

handles = loadAnnotationsFile(handles);

handles = loadData(handles);

% Choose default command line output for refineMapsGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes refineMapsGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = refineMapsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Load axes with the data in the current index
function handles = loadData(handles)

if handles.currentIndex > numel(handles.dirlist) 
   return
end

disableButtons(handles);

dname = handles.dirlist{handles.currentIndex};

set(handles.pathText,'String',dname);
set(handles.indexText,'String',[num2str(handles.currentIndex,'%03.0f') ' of ' num2str(numel(handles.dirlist),'%03.0f')]);

% loadcurrentPatientData(handles);

if annotationsComplete(handles)
    set(handles.anotText,'String','Done');
    set(handles.anotText,'BackgroundColor','g');
else
    set(handles.anotText,'String','Pending');
    set(handles.anotText,'BackgroundColor','r');
end

% Delete old map
if isfield(handles,'choroidMap')
    handles = rmfield(handles, 'choroidMap');
end

if isfield(handles, 'scansInfo')
    handles = rmfield(handles, 'scansInfo');
end

if isfield(handles, 'retinaMap')
    handles = rmfield(handles, 'retinaMap');
end

handles = loadAnnotationsFile(handles);

handles = showChoroidMap(handles);

handles.choroidMap.currentBscan = 1;
handles = loadBscan(handles);

handles = showRetinaMap(handles);

colormap('gray')

enableButtons(handles);

function handles = showChoroidMap(handles)

if ~isfield(handles,'choroidMap')
    
    dname = handles.dirlist{handles.currentIndex};
    
    load(fullfile(dname,'Results','ChoroidMap.mat'),'Cmap','fundimfinal',...
        'fscaleX','fscaleY','fwidth','fheight','xvec','yvec','mapInfo',...
        'mapRetina');
    
    Rfund = imref2d(size(fundimfinal),[0 fwidth*fscaleX],[0 fheight*fscaleY]);
    fxvec = linspace(Rfund.XWorldLimits(1),Rfund.XWorldLimits(end),Rfund.ImageSize(1));
    fyvec = linspace(Rfund.YWorldLimits(1),Rfund.YWorldLimits(end),Rfund.ImageSize(2));
    
    % Indices In Fundus Image That Correspond To Cmap
    Xover = find( fxvec >= xvec(1) & fxvec <= xvec(end) );
    Yover = find( fyvec <= yvec(1) & fyvec >= yvec(end) );
    
    [qx,qy] = meshgrid(fxvec(Xover), fyvec(Yover));
    
    % Compute choroid map
    F = scatteredInterpolant(mapInfo(:,1),mapInfo(:,2),mapInfo(:,3));
    handles.choroidMap.Cmap = F(qx,qy);
    
    handles.choroidMap.newRbscan  = imref2d(size(handles.choroidMap.Cmap),[qx(1,1) qx(1,end)],[qy(1,1) qy(end,1)]);
    
    handles.choroidMap.yvec = yvec;
    
    handles.choroidMap.nBscans = numel(yvec);
    
end

axes(handles.choroidAxes); 

h = imshow(handles.choroidMap.Cmap,handles.choroidMap.newRbscan,colormap('gray'));
set(h,'cdatamapping','scaled');
xlabel('X [mm]')
ylabel('Y [mm]')



% --- Executes on button press in upButton.
function upButton_Callback(hObject, eventdata, handles)
% hObject    handle to upButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

stepSize = str2double(get(handles.stepEdit,'String'));

handles.choroidMap.currentBscan = max(1, handles.choroidMap.currentBscan - stepSize);

handles = loadBscan(handles);

guidata(hObject, handles);




% --- Executes on button press in downButton.
function downButton_Callback(hObject, eventdata, handles)
% hObject    handle to downButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

stepSize = str2double(get(handles.stepEdit,'String'));

handles.choroidMap.currentBscan = min(handles.choroidMap.currentBscan + stepSize,handles.choroidMap.nBscans);

handles = loadBscan(handles);

guidata(hObject, handles);


function handles = loadBscan(handles)

if ~isfield(handles, 'scansInfo')
    
    % Load Scans
    dname = handles.dirlist{handles.currentIndex};
    
    if ~exist(fullfile(dname,'Results','bScans.mat'),'file')
       return 
    end
    
    load(fullfile(dname,'Results','bScans.mat'), 'scansInfo')
    handles.scansInfo = scansInfo;
    
end

thisScan = handles.scansInfo(handles.choroidMap.currentBscan);

% axes(handles.bscanAxes); 
set(gcf,'CurrentAxes',handles.bscanAxes)
cla
imshow(thisScan.bscan,[]), hold on
xlim([1 size(thisScan.bscan,2)])
ylim([1 size(thisScan.bscan,1)])

if ~isempty(thisScan.RPE)
  plot(thisScan.RPE * ones(1,size(thisScan.bscan,2)),'-m','LineWidth',2)
end

if ~isempty(thisScan.yCSI)
  errorbar(thisScan.xCSI,thisScan.yCSI,thisScan.wCSI / max(thisScan.wCSI) * 10,'.y')
end

set(gcf,'CurrentAxes',handles.choroidAxes)
cla
handles = showChoroidMap(handles);
line(xlim(), [1 1] * handles.choroidMap.yvec(handles.choroidMap.currentBscan),'LineStyle','--','Color','y')



% --- Executes on button press in prevButton.
function prevButton_Callback(hObject, eventdata, handles)
% hObject    handle to prevButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

updateAnnotationsFile(handles);

handles.currentIndex = max(handles.currentIndex - 1,1);

handles = loadData(handles);

guidata(hObject, handles);


% --- Executes on button press in nextButton.
function nextButton_Callback(hObject, eventdata, handles)
% hObject    handle to nextButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

updateAnnotationsFile(handles);

handles.currentIndex = min(handles.currentIndex + 1,numel(handles.dirlist));

handles = loadData(handles);

guidata(hObject, handles);

function disableButtons(handles)

set(handles.upButton,'Enable','off')
set(handles.downButton,'Enable','off')
set(handles.prevButton,'Enable','off')
set(handles.nextButton,'Enable','off')

set(handles.loadingText,'String','loading...')
set(handles.loadingText,'BackgroundColor','r')
drawnow

function enableButtons(handles)

set(handles.upButton,'Enable','on')
set(handles.downButton,'Enable','on')
set(handles.prevButton,'Enable','on')
set(handles.nextButton,'Enable','on')

set(handles.loadingText,'String','ready!')
set(handles.loadingText,'BackgroundColor','g')
drawnow



function stepEdit_Callback(hObject, eventdata, handles)
% hObject    handle to stepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stepEdit as text
%        str2double(get(hObject,'String')) returns contents of stepEdit as a double


% --- Executes during object creation, after setting all properties.
function stepEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function handles = showRetinaMap(handles)

if ~isfield(handles,'retinaMap') || ~isfield(handles.retinaMap,'Rfund') ||...
   ~isfield(handles.retinaMap,'Cmap') || ~isfield(handles.retinaMap,'newRbscan') ||...
   ~isfield(handles.retinaMap,'fundFinal') 
    
    dname = handles.dirlist{handles.currentIndex};
    
    load(fullfile(dname,'Results','ChoroidMap.mat'),'fundimfinal',...
        'fscaleX','fscaleY','fwidth','fheight','xvec','yvec',...
        'mapRetina');
    
    load(fullfile(dname,'DataFiles','ImageList.mat'),'fundusIm');
    
%     Rfund = imref2d(size(fundimfinal),[0 fwidth*fscaleX],[0 fheight*fscaleY]);
    Rfund = imref2d(size(fundusIm(:,:,1)),[0 fwidth*fscaleX],[0 fheight*fscaleY]); 
    fxvec = linspace(Rfund.XWorldLimits(1),Rfund.XWorldLimits(end),Rfund.ImageSize(1));
    fyvec = linspace(Rfund.YWorldLimits(1),Rfund.YWorldLimits(end),Rfund.ImageSize(2));
    
    handles.retinaMap.Rfund = Rfund;
    
    % Indices In Fundus Image That Correspond To Cmap
    Xover = find( fxvec >= xvec(1) & fxvec <= xvec(end) );
    Yover = find( fyvec <= yvec(1) & fyvec >= yvec(end) );
    
    [qx,qy] = meshgrid(fxvec(Xover), fyvec(Yover));
    
    % Compute choroid map
    F = scatteredInterpolant(mapRetina(:,1),mapRetina(:,2),mapRetina(:,3),'natural','nearest');
    handles.retinaMap.Cmap = F(qx,qy);
    
    handles.retinaMap.newRbscan  = imref2d(size(handles.retinaMap.Cmap),[qx(1,1) qx(1,end)],[qy(1,1) qy(end,1)]);
    
    % Combine with fundus:
    mn = prctile(handles.retinaMap.Cmap(:),1);
    mx = prctile(handles.retinaMap.Cmap(:),99);
    CMapScaled = im2uint8(min(1,max(0,(handles.retinaMap.Cmap - mn) / (mx - mn))));
    X          = grayslice(CMapScaled,256);
    CMapRGB    = ind2rgb(X,jet(256));
    CMapHSV    = rgb2hsi(CMapRGB);
    fundimHSV  = rgb2hsi(ind2rgb(grayslice(im2uint8(fundusIm(:,:,1)),256),gray(256)));
    
    fundimHSV(Yover,Xover,1) = CMapHSV(:,:,1);
    fundimHSV(Yover,Xover,2) = CMapHSV(:,:,2);
%     fundimHSV(:,:,3) = fundusIm(:,:,1);
    fundim = fundusIm(:,:,1);
    fundim = intrans(fundim,'stretch',mean2(im2double(fundim)),2);
    fundimHSV(:,:,3) = fundim;
%     fundimHSV(:,:,3) = intrans(fundusIm(:,:,1),'stretch',mean2(im2double(fundusIm(:,:,1))),2) + 1/256;
    handles.retinaMap.fundFinal = hsi2rgb(fundimHSV);
    
end

axes(handles.retinaAxes);
cla

imshow(handles.retinaMap.fundFinal,handles.retinaMap.Rfund,colormap('jet'));
xlabel('X [mm]')
ylabel('Y [mm]')

if isfield(handles.retinaMap,'maculaCenter')
   hold on
   plot(handles.retinaMap.maculaCenter.x,handles.retinaMap.maculaCenter.y,'og','MarkerSize',5)
   hold off
end

if isfield(handles.retinaMap,'onhCenter')
   hold on
   plot(handles.retinaMap.onhCenter.x,handles.retinaMap.onhCenter.y,'xr','MarkerSize',5)
   hold off
end

colormap('gray')


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1

contents = cellstr(get(hObject,'String'));
clr = contents{get(hObject,'Value')};

colormap(clr)


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setMaculaButton.
function setMaculaButton_Callback(hObject, eventdata, handles)
% hObject    handle to setMaculaButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[x,y] = ginput(1);

handles.retinaMap.maculaCenter.x = x;
handles.retinaMap.maculaCenter.y = y;

set(handles.xMaculaText,'String',['X = ' num2str(x,'%1.2f')])
set(handles.yMaculaText,'String',['Y = ' num2str(y,'%1.2f')])

showRetinaMap(handles);

guidata(hObject, handles);




% --- Executes on button press in setONHButton.
function setONHButton_Callback(hObject, eventdata, handles)
% hObject    handle to setONHButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[x,y] = ginput(1);

handles.retinaMap.onhCenter.x = x;
handles.retinaMap.onhCenter.y = y;

set(handles.xOnhText,'String',['X = ' num2str(x,'%1.2f')])
set(handles.yOnhText,'String',['Y = ' num2str(y,'%1.2f')])

showRetinaMap(handles);

guidata(hObject, handles);

function updateAnnotationsFile(handles)
    
fname = fullfile(handles.dirlist{handles.currentIndex},'Results','postProcessingAnnotations.mat');

if exist(fname,'file')
    load(fname,'annotations');
end

if isfield(handles.retinaMap,'maculaCenter')
   annotations.maculaCenter.x = handles.retinaMap.maculaCenter.x;
   annotations.maculaCenter.y = handles.retinaMap.maculaCenter.y;
end

if isfield(handles.retinaMap,'onhCenter')
   annotations.onhCenter.x = handles.retinaMap.onhCenter.x;
   annotations.onhCenter.y = handles.retinaMap.onhCenter.y;
end

annotations.skip = get(handles.skipCheckbox,'Value');

annotations.skipCause = get(get(handles.skipCauseGroup,'SelectedObject'), 'Tag');

save(fname,'annotations'); 


function handles = loadAnnotationsFile(handles)
    
fname = fullfile(handles.dirlist{handles.currentIndex},'Results','postProcessingAnnotations.mat');

if ~exist(fname,'file')
    set(handles.skipCheckbox,'Value',false);
    
    set(handles.xMaculaText,'String','X = ')
    set(handles.yMaculaText,'String','Y = ')
    
    set(handles.xOnhText,'String','X = ')
    set(handles.yOnhText,'String','Y = ')    
    
    return
end

load(fname,'annotations');

if isfield(annotations,'maculaCenter')
    handles.retinaMap.maculaCenter.x = annotations.maculaCenter.x;
    handles.retinaMap.maculaCenter.y = annotations.maculaCenter.y;
    
    set(handles.xMaculaText,'String',['X = ' num2str(annotations.maculaCenter.x,'%1.2f')])
    set(handles.yMaculaText,'String',['Y = ' num2str(annotations.maculaCenter.y,'%1.2f')])
else
    set(handles.xMaculaText,'String','X = ')
    set(handles.yMaculaText,'String','Y = ')
end

if isfield(annotations,'onhCenter')
    handles.retinaMap.onhCenter.x = annotations.onhCenter.x;
    handles.retinaMap.onhCenter.y = annotations.onhCenter.y;
    
    set(handles.xOnhText,'String',['X = ' num2str(annotations.onhCenter.x,'%1.2f')])
    set(handles.yOnhText,'String',['Y = ' num2str(annotations.onhCenter.y,'%1.2f')])
else
    set(handles.xOnhText,'String','X = ')
    set(handles.yOnhText,'String','Y = ')
end

set(handles.skipCheckbox,'Value',annotations.skip); 

if isfield(annotations,'skipCause')
   set(getfield(handles, annotations.skipCause),'Value',true); 
else
   set(getfield(handles, 'noneRadio'),'Value',true);  
end





% --- Executes on button press in skipCheckbox.
function skipCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to skipCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of skipCheckbox

function complete = annotationsComplete(handles)

complete = false;

fname = fullfile(handles.dirlist{handles.currentIndex},'Results','postProcessingAnnotations.mat');

if ~exist(fname,'file')
    return
end

load(fname,'annotations');

if ~isfield(annotations,'skip')
    return
end

if ~annotations.skip && (~isfield(annotations,'maculaCenter') || ~isfield(annotations,'onhCenter'))
    return
end

complete = true;

% function loadcurrentPatientData(handles)
% 
% dname = handles.dirlist{handles.currentIndex};
% 
% fname = fullfile(dname,'Data Files','VisitData.mat');
% 
% if ~exist(fname,'file'), return, end
% 
% load(fname,'visitdata')
% 
% disp(1)

% set(handles.pathText,'String',dname);
