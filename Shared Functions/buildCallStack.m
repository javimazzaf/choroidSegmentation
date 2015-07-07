function outString = buildCallStack(exception)

outString = [];

if ~ismember('stack',fieldnames(exception)), return, end

for s = 1:numel(exception.stack)
    thisText = [' | Function: ' exception.stack(s).name ' (at: ' num2str(exception.stack(s).line) ').'];
    outString = [outString, thisText];
end

end