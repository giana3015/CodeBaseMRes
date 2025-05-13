function [poslim]  = getPosLim(posdata)
% For 2D spatial return the extent of the window that was tracked

win_max_x       =max(posdata.xy(:,1));
win_min_x       =min(posdata.xy(:,1));
win_max_y       =max(posdata.xy(:,2));
win_min_y       =min(posdata.xy(:,2));


poslim          =[win_max_x+50 ,0 , win_max_y+50 ,0];

end
