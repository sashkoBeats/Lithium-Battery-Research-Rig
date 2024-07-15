function updatePackGraph(source, event)
    %disp("startP")
    if source.UserData.data.dataIndex < 2
        return
    end
    range = 1:source.UserData.data.dataIndex;
    yyaxis(source.UserData.data.PackStats,"left");
    plot(source.UserData.data.PackStats, source.UserData.data.graphTime(range), source.UserData.data.arduinoData{end-1}(range));
    yyaxis(source.UserData.data.PackStats,"right");
    plot(source.UserData.data.PackStats, source.UserData.data.graphTime(range), source.UserData.data.arduinoData{end}(range));
    %disp("stopP")
end