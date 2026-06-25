function openDesktop()
    %OPENDESKTOP Open the desktop.
    %   OPENDESKTOP() opens the desktop.
    %
    %   See also HIDE_DESKTOP. 
    %   Author(s): P. Pacheco
    desktop;
    myOp.path.clearChangedPath();
    myOp.ai.startAgenticToolkit();
end