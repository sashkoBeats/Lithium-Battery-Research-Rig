function updateVoltageGraph(source, event)
    %disp("startV")
    if source.UserData.data.dataIndex < 2
        return
    end
    cla(source.UserData.data.VoltageGraph);
    voltageLegend = {};
    range = 1:source.UserData.data.dataIndex;
    for i=1:length(source.UserData.data.ListCell.CheckedNodes)
        index = 1 + str2double(source.UserData.data.ListCell.CheckedNodes(i).Text(6:end));
        plot(source.UserData.data.VoltageGraph, source.UserData.data.graphTime(range), source.UserData.data.arduinoData{index}(range));
        voltageLegend{end+1} = source.UserData.data.ListCell.CheckedNodes(i).Text;
    end
    yline(source.UserData.data.VoltageGraph,source.UserData.data.ratedVoltageRange(1),"--r","Min Safe Voltage",LabelVerticalAlignment="top");
    yline(source.UserData.data.VoltageGraph,source.UserData.data.ratedVoltageRange(2),"--r","Max Safe Voltage",LabelVerticalAlignment="bottom");
    legend(source.UserData.data.VoltageGraph,voltageLegend,Location = "northwest");
    %disp("stopV")
end