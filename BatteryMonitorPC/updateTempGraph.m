function updateTempGraph(source, event)
    %disp("startT")
    if source.UserData.data.dataIndex < 2
        return
    end
    cla(source.UserData.data.TempGraph);
    tempLegend = {};
    range = 1:source.UserData.data.dataIndex;
    for i=1:length(source.UserData.data.ListCell.CheckedNodes)
        index = 1 + str2double(source.UserData.data.ListCell.CheckedNodes(i).Text(6:end));
        plot(source.UserData.data.TempGraph, source.UserData.data.graphTime(range), source.UserData.data.arduinoData{16+index}(range));
        tempLegend{end+1} = source.UserData.data.ListCell.CheckedNodes(i).Text + "-1";
    end
    for i=1:length(source.UserData.data.ListCell.CheckedNodes)
        index = 1 + str2double(source.UserData.data.ListCell.CheckedNodes(i).Text(6:end));
        plot(source.UserData.data.TempGraph, source.UserData.data.graphTime(range), source.UserData.data.arduinoData{32+index}(range));
        tempLegend{end+1} = source.UserData.data.ListCell.CheckedNodes(i).Text + "-2";
    end
    yline(source.UserData.data.TempGraph,source.UserData.data.ratedTempRange(1),"--r","Min Safe Temperature",LabelVerticalAlignment="top");
    yline(source.UserData.data.TempGraph,source.UserData.data.ratedTempRange(2),"--r","Max Safe Temperature",LabelVerticalAlignment="bottom");
    legend(source.UserData.data.TempGraph,tempLegend, NumColumns=2, Location="northwest");
    %disp("stopT")
end