function s = clk2sec(source)
    % ~spaghetti~ crack cocaine stuff
    relativeClk = clock' - source.UserData.data.arduinoData{1}(:,1);
    s = relativeClk(6) + relativeClk(5)*60 + relativeClk(4)*3600;
    s = mod(s,86400);
    if (source.UserData.data.dayState)
        if (s < 21600)
            source.UserData.data.dayState = false;
            source.UserData.data.dayCount = source.UserData.data.dayCount + 1;
        end
    else
        if (43200 < s && s < 64800)
            source.UserData.data.dayState = true;
        end
    end
    s = s + (86400 * source.UserData.data.dayCount);
end