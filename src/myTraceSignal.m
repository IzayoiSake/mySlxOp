function out = myTraceSignal(direction,hBlock,porttype,sigidx,verbose,enblHilite)
% myTraceSignal Trace Simulink signals
% 
% myTraceSignal traces Simulink signals. Unlike the builtin 
% "Highlight to Destination" it will only highlight signal 
% routes which end on a non-virtual destination block (signal
% routes which end in e.g. a Terminator block, or signals which
% are never extracted from a bus will not be highlighted).
%
% out = myTraceSignal(direction,hBlock,porttype,sigidx,verbose)
%   direction   [char]      'forward' or 'back' (or 'f' or 'b')
%   hBlock      [handle]    originating block
%   porttype    [char]      'inport' or 'outport' (or 'i' or 'o')
%   sigidx      [number]    port index (optional, default ':' all ports)
%   verbose     [bool]      command prompt text (optional, default true)
% 
% Example - trace all signals entering the selected block 
%           (e.g. a BusCreator) to their destinations
% out = myTraceSignal('f',gcbh,'i'); 
% 
% Note: Function is intended to trace signals (not buses) so, for example,
% for forward tracing use myTraceSignal('f',gcbh,'i') to trace destinations
% of signals entering a BusCreator, and use myTraceSignal('f',gcbh,'o')
% to trace destinations of signals leaving a BusSelector.
% 
% Note: Goto blocks in back-trace are not highlighted (but the From-
% blocks and the lines are).

% Author: 77656965, 2011

% input arguments
if ~exist('sigidx','var')
    sigidx = ':';
end
if ~exist('verbose','var')
    verbose = true;
end
if ~exist('enblHilite','var')
    enblHilite = false;
end
if strmatch('i',lower(porttype))
    % use signal connected to block inport
    porttype = 'Inport';
elseif strmatch('o',lower(porttype))
    % use signal connected to block outport
    porttype = 'Outport';
end
if strmatch('f',lower(direction))
    % forward-trace
    traceProp = 'TraceDestinationInputPorts';
    traceDirection = 'forward';
elseif strmatch('b',lower(direction))
    % back-trace
    traceProp = 'TraceSourceOutputPorts';
    traceDirection = 'back';
end
% filter definitions (more in loop)
listAlwaysVirtual = {'Goto','From','GotoTagVisibility','Mux','Demux','Ground','Terminator','Inport','Outport','SignalSpecification'};
listRoutingOnly = {'Goto','From','GotoTagVisibility','Inport','Outport','SubSystem','BusSelector','BusCreator','BusAssignment'};
listSinks = {'Terminator','Display','Scope','Stop','ToFile','ToWorkspace'};
% get porthandles
hPort = get_param(hBlock,'porthandles');
% get line handles
hLine = get_param(hPort.(porttype)(sigidx),'line');
if iscell(hLine), hLine = cell2mat(hLine); end
out.block = [get_param(hBlock,'Parent') '/' get_param(hBlock,'Name')];
out.porttype = porttype;
if ischar(sigidx)
    out.portindex = 1:length(hLine);
else
    out.portindex = sigidx;
end
% the use of TraceDestinationInputPorts / TraceSourceOutputPorts
% will open subsystems. store the currently open ones so we can 
% restore the view afterwards.
beforeOpenSubSys = find_system(bdroot,'LookUnderMasks','all',...
    'FollowLinks','on','BlockType','SubSystem','Open','on');
% here we use the undocumented feature to get the trace of each line
% the result is the port handles involved in the trace
hTracePorts = get_param(hLine,traceProp);
if ~iscell(hTracePorts), hTracePorts = {hTracePorts}; end
hHighlight = cell(1,length(hLine));
% loop over lines
for iLine = 1:length(hLine)
    % get the blocks associated with the traced ports
    blockList = get_param(hTracePorts{iLine},'Parent'); 
    if ischar(blockList), blockList = {blockList}; end
    blockTypes = get_param(blockList,'BlockType');
    % initialise filter results
    isVirtual = false(size(blockList));
    isRouting = false(size(blockList));
    isSink = false(size(blockList));
    % loop over all blocks associated with the trace to check interesting properties
    for k=1:length(blockList)
        isRouting(k) = any(strcmp(blockTypes(k),listRoutingOnly));
        isSink(k) = any(strcmp(blockTypes(k),listSinks));
        switch blockTypes{k}
            case listAlwaysVirtual
                isVirtual(k) = true;
            case {'SubSystem'}
                isVirtual(k) = strcmp(get_param(blockList{k},'IsSubsystemVirtual'),'on');
            case {'BusCreator'}
                isVirtual(k) = strcmp(get_param(blockList{k},'UseBusObject'),'off') ...
                    || strcmp(get_param(blockList{k},'NonVirtualBus'),'off');
            case {'BusSelector'}
                isVirtual(k) = true; % fixme, borde kolla att insignalen är virtuell
            otherwise
                % ...
        end
    end
    % display results
    if verbose
        % if iLine==1
        %     disp(['Trace result for ' lower(porttype) 's of ' get_param(hBlock,'BlockType') '-block "' get_param(hBlock,'Name') '" (' get_param(hBlock,'Parent') '/' get_param(hBlock,'Name') ')'])
        % end
        % disp(['- ' porttype ' ' num2str(out.portindex(iLine)) ' ' get_param(hLine(iLine),'Name') ':'])
        % disp(['  - trace involves ' num2str(length(blockList)) ' blocks'])
        % disp(['  - traced ' num2str(length(isVirtual)-sum(isVirtual)) ' non-virtual blocks'])
        if strcmp(traceDirection,'back')
            % check for non-routing blocks (possible sources)
            condres = length(isRouting)-sum(isRouting);
            if condres~=1
                msg = ' (expect exactly 1 for back-trace)';
            else
                msg = '';
            end
            % disp(['  - traced ' num2str(condres) ' non-routing blocks' msg])
        else % forward trace
            % check for non-routing blocks (possible destinations)
            condres = length(isRouting)-sum(isRouting);
            if condres<1
                msg = ' (expect >=1 for forward trace)';
            else
                msg = '';
            end
            % disp(['  - traced ' num2str(condres) ' non-routing blocks' msg])
            % check for non-routing, non-sink blocks (possible real destinations)
            condres = length(isRouting)-sum(isRouting)-sum(isSink);
            if condres<1
                msg = ' (if 0 signal may be unused in algorithm)';
            else
                msg = '';
            end
            % disp(['  - traced ' num2str(condres) ' non-routing, non-sink blocks' msg])
        end
    end
    hTraceBlocks = get_param(blockList,'Handle');
    if iscell(hTraceBlocks), hTraceBlocks = cell2mat(hTraceBlocks); end
    hTraceLines = get_param(hTracePorts{iLine},'Line');
    if iscell(hTraceLines), hTraceLines = cell2mat(hTraceLines); end
    % should do this bit nicer
    tmp1 = get_param(hTraceLines,'LineParent');
    if iscell(tmp1), tmp1 = cell2mat(tmp1); end
    hTraceLineParents = tmp1(ishandle(tmp1));
    tmp2 = get_param(hTraceLineParents,'LineParent');
    if iscell(tmp2), tmp2 = cell2mat(tmp2); end
    hTraceLineParents = union(hTraceLineParents,tmp2(ishandle(tmp2)));
    % assign output
    out.trace(iLine).signal = get_param(hLine(iLine),'Name');
    out.trace(iLine).blocks = blockList;
    out.trace(iLine).blockhandles = hTraceBlocks;
    out.trace(iLine).blocktypes = blockTypes;
    out.trace(iLine).ports = hTracePorts{iLine};
    out.trace(iLine).lines = hTraceLines;
    out.trace(iLine).lineparents = hTraceLineParents;
    out.trace(iLine).isVirtual = isVirtual;
    out.trace(iLine).isRouting = isRouting;
    out.trace(iLine).isSink = isSink;
    % right, so create a visual trace to the real destination blocks only
    % the if-statements protects for infinte recursive calls (fixme, do differently?)
    if enblHilite && strcmp(traceDirection,'forward')
        % this is only executed for foward trace, note that it contains a
        % recursive call generating a back trace
        realDestBlock = blockList(~isRouting & ~isSink);
        realDestPortNbr = get_param(hTracePorts{iLine}(~isRouting & ~isSink),'PortNumber');
        if iscell(realDestPortNbr), realDestPortNbr = cell2mat(realDestPortNbr); end
        hTmpBackTrace = []; hTmpFrom = [];
        for bt=1:length(realDestBlock)
            % recursive function call, the if-condition above need to
            % ensure we don't get an infinite loop
            % do a back trace from all the "real" destinations found in the
            % forward trace above
            backTrace = myTraceSignal('b',realDestBlock{bt},'i',realDestPortNbr(bt),false,false);
            % collect all relevant handles from the back trace
            hTmpBackTrace = union(hTmpBackTrace,backTrace.trace.blockhandles);
            hTmpBackTrace = union(hTmpBackTrace,backTrace.trace.lines);
            hTmpBackTrace = union(hTmpBackTrace,backTrace.trace.lineparents);
            hTmpFrom = union(hTmpFrom,backTrace.trace.blockhandles(strcmp(backTrace.trace.blocktypes,'From')));
        end
        % collect all the relevant handles of the original forward trace
        hTmpTrace = union(hTraceBlocks,hTraceLines);
        hTmpTrace = union(hTmpTrace,hTraceLineParents);
        hTmpTrace = union(hTmpTrace,hTmpFrom); % fulfix för from-block
        % by highlighting the intersect of the two groups we get a nice
        % trace of "real" destinations only
        hHighlight{iLine} = intersect(hTmpBackTrace,hTmpTrace);
        hHighlight{iLine} = union(hHighlight{iLine},hTraceBlocks(strcmp(blockTypes,'Goto'))); % fulfix för goto-block
    elseif enblHilite %&& length(hLine)>1
        % the builtin function only displays the last processed signal
        % so collect all handles here. this does not hilite the goto's
        % though...
        hTmpTrace = union(hTraceBlocks,hTraceLines);
        hHighlight{iLine} = union(hTmpTrace,hTraceLineParents);
    end
end
if enblHilite
    % remove the hilite added by builtin function
    set_param(bdroot,'HiliteAncestors','none')
    % add the new hilite
    for hh=1:length(hHighlight)
        hilite_system(hHighlight{hh},'default')
    end
    % bring focus to original block
    hilite_system(hBlock,'none')
    afterOpenSubSys = find_system(bdroot,'LookUnderMasks','all',...
        'FollowLinks','on','BlockType','SubSystem','Open','on');
    wasOpenedByFcn = setdiff(afterOpenSubSys,[beforeOpenSubSys;bdroot]);
    if length(afterOpenSubSys)>length(wasOpenedByFcn)
        close_system(wasOpenedByFcn);
    end
end
if nargout==0
    % prevent "ans" display
    clear out
end
end % eof
