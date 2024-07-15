% This function is the logic core of the Battery Monitor PC application.
% TimerUpdate handles data fetching from Arduino, processing, and storing
% (optionally to file).
function TimerUpdate(source, event)
    if source.UserData.data.connected
        % readData = [];

        % add time stamp at start of data array and increment data index
        source.UserData.data.dataIndex = source.UserData.data.dataIndex + 1;
        source.UserData.data.arduinoData{1}(:,source.UserData.data.dataIndex) = clock';

        % update X-axis (time) for graphs
        source.UserData.data.graphTime(source.UserData.data.dataIndex) = clk2sec(source);

        % request battery electrical data
        write(source.UserData.data.serialConnection, "1", "char")
        % receive and store battery electrical data
        readData = readline(source.UserData.data.serialConnection);
        % check if data length matches the expected length
        if strlength(string(readData)) == (source.UserData.data.numOfCells+2)*2
            % convert data string to char array
            readData = char(readData);
            % convert data to usable values (combine 2 bytes)
            convData(source.UserData.data.numOfCells+2) = 0;
            for i=1:source.UserData.data.numOfCells+2
                convData(i) = double(uint8(readData((i*2)-1))) + (double(uint8(readData((i*2))))*256);
            end
            % populate main arduino data array with new converted data
            for i=1:source.UserData.data.numOfCells
                source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex) = convData(i)*(5/1024);
            end
            source.UserData.data.arduinoData{end-1}(source.UserData.data.dataIndex) = convData(end-1)*(5/1024)*16;
            source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex) = ((convData(end) / 1023) - 0.5)*2.5*source.UserData.data.ratedCurrentCT; % change rated current to match sensor
        elseif source.UserData.data.dataIndex < 2
            % if incoming data is invalid and is the first data packet
            % since start, reset to 0 and return
            source.UserData.data.dataIndex = 0;
            return
        else
            % if incoming data is invalid but there is at least 1 previous
            % valid data entry, carry it over to current time slot
            for i=1:source.UserData.data.numOfCells
                source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex) = source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex-1);
            end
            source.UserData.data.arduinoData{end-1}(source.UserData.data.dataIndex) = source.UserData.data.arduinoData{end-1}(source.UserData.data.dataIndex-1);
            source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex) = source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex-1);
        end
        flush(source.UserData.data.serialConnection);

        % update cell voltages
        source.UserData.data.Cell01EditField.Value = source.UserData.data.arduinoData{2}(source.UserData.data.dataIndex);
        source.UserData.data.Cell02EditField.Value = source.UserData.data.arduinoData{3}(source.UserData.data.dataIndex);
        source.UserData.data.Cell03EditField.Value = source.UserData.data.arduinoData{4}(source.UserData.data.dataIndex);
        source.UserData.data.Cell04EditField.Value = source.UserData.data.arduinoData{5}(source.UserData.data.dataIndex);
        source.UserData.data.Cell05EditField.Value = source.UserData.data.arduinoData{6}(source.UserData.data.dataIndex);
        source.UserData.data.Cell06EditField.Value = source.UserData.data.arduinoData{7}(source.UserData.data.dataIndex);
        source.UserData.data.Cell07EditField.Value = source.UserData.data.arduinoData{8}(source.UserData.data.dataIndex);
        source.UserData.data.Cell08EditField.Value = source.UserData.data.arduinoData{9}(source.UserData.data.dataIndex);
        source.UserData.data.Cell09EditField.Value = source.UserData.data.arduinoData{10}(source.UserData.data.dataIndex);
        source.UserData.data.Cell10EditField.Value = source.UserData.data.arduinoData{11}(source.UserData.data.dataIndex);
        source.UserData.data.Cell11EditField.Value = source.UserData.data.arduinoData{12}(source.UserData.data.dataIndex);
        source.UserData.data.Cell12EditField.Value = source.UserData.data.arduinoData{13}(source.UserData.data.dataIndex);
        source.UserData.data.Cell13EditField.Value = source.UserData.data.arduinoData{14}(source.UserData.data.dataIndex);
        source.UserData.data.Cell14EditField.Value = source.UserData.data.arduinoData{15}(source.UserData.data.dataIndex);
        source.UserData.data.Cell15EditField.Value = source.UserData.data.arduinoData{16}(source.UserData.data.dataIndex);
        source.UserData.data.Cell16EditField.Value = source.UserData.data.arduinoData{17}(source.UserData.data.dataIndex);

        % update power state, energy, timers
        % check for non-zero data
        if source.UserData.data.dataIndex > 1
            % check if application is in run state
            if source.UserData.data.running
                deltaTime = source.UserData.data.graphTime(source.UserData.data.dataIndex) - source.UserData.data.graphTime(source.UserData.data.dataIndex-1);
                source.UserData.data.totalTime = source.UserData.data.totalTime + deltaTime;
                source.UserData.data.TimeElapsed.Value = sec2DisplayTime(source.UserData.data.totalTime);
                source.UserData.data.currentCharge = source.UserData.data.currentCharge + ((source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex) * deltaTime)/3.6);
                source.UserData.data.currentCharge = max(0,min(source.UserData.data.currentCharge,source.UserData.data.BatteryCapacitymAhEditField.Value));
            end
            % if current flow is negative, process discharge metrics
            if source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex) < 0
                source.UserData.data.powerState = 'd';
                source.UserData.data.PowerFlowEditField.Value = "Discharging";
                if source.UserData.data.running
                    source.UserData.data.eOut = source.UserData.data.eOut + ((abs(source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex)) * deltaTime)/3.6);
                    source.UserData.data.EnergyOutmAhEditField.Value = source.UserData.data.eOut;
                    source.UserData.data.dchgTime = source.UserData.data.dchgTime + deltaTime;
                    source.UserData.data.DischargeTimeEditField.Value = sec2DisplayTime(source.UserData.data.dchgTime);
                end
            % if current flow is positive, process charge metrics
            elseif source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex) > 0
                source.UserData.data.powerState = 'c';
                source.UserData.data.PowerFlowEditField.Value = "Charging";
                if source.UserData.data.running
                    source.UserData.data.eIn = source.UserData.data.eIn + ((abs(source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex)) * deltaTime)/3.6);
                    source.UserData.data.EnergyInmAhEditField.Value = source.UserData.data.eIn;
                    source.UserData.data.chgTime = source.UserData.data.chgTime + deltaTime;
                    source.UserData.data.DischargeTimeEditField.Value = sec2DisplayTime(source.UserData.data.dchgTime);
                end
            % power idle
            else
                source.UserData.data.powerState = 'i';
                source.UserData.data.PowerFlowEditField.Value = "Idle";
            end
        end
        source.UserData.data.power = source.UserData.data.arduinoData{end-1}(source.UserData.data.dataIndex) * source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex);

        % update cell statistics
        % update min/max cell, mean, delta
        maxC = 0;
        minC = 6;
        maxIndex = 0;
        minIndex = 0;
        meanSum = 0;
        for i=1:source.UserData.data.numOfCells
            if source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex) > maxC
                maxC = source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex);
                maxIndex = i;
            end
            if source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex) < minC
                minC = source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex);
                minIndex = i;
            end
            meanSum = meanSum + source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex);
        end
        source.UserData.data.minCell = minIndex;
        source.UserData.data.maxCell = maxIndex;
        source.UserData.data.deltaCell = maxC - minC;
        source.UserData.data.meanCell = meanSum / source.UserData.data.numOfCells;
        source.UserData.data.MinCellEditField.Value = source.UserData.data.minCell;
        source.UserData.data.MaxCellEditField.Value = source.UserData.data.maxCell;
        source.UserData.data.CellDeltaVEditField.Value = source.UserData.data.deltaCell;
        source.UserData.data.CellMeanVEditField.Value = source.UserData.data.meanCell;

        % update power (autoscale gauge)
        while(abs(source.UserData.data.power) > source.UserData.data.PowerWGauge.Limits(2))
            source.UserData.data.PowerWGauge.Limits = source.UserData.data.PowerWGauge.Limits + [-10 10];
        end
        source.UserData.data.PowerWGauge.Value = source.UserData.data.power;
        source.UserData.data.WLabel.Text = sprintf("%.2f W", source.UserData.data.power);

        % update SOC estimate
        if source.UserData.data.running
            if minC <= source.UserData.data.ratedVoltageRange(1)
                %source.UserData.data.currentCharge = 0; % uncomment this
                %line when voltage readouts are working
            end
            if maxC >= source.UserData.data.ratedVoltageRange(2)
                source.UserData.data.currentCharge = source.UserData.data.BatteryCapacitymAhEditField.Value;
            end
            source.UserData.data.estimatedSoc = (source.UserData.data.currentCharge/source.UserData.data.BatteryCapacitymAhEditField.Value)*100;
            source.UserData.data.EstimatedSOCGauge.Value = source.UserData.data.estimatedSoc;
            source.UserData.data.CurrentSOCEditField.Value = source.UserData.data.estimatedSoc;
        end

        % request battery temp data
        write(source.UserData.data.serialConnection, "2", "char")
        % receive and store battery temp data
        readData = readline(source.UserData.data.serialConnection);
        % check if data length matches the expected length
        if strlength(string(readData)) == (source.UserData.data.numOfCells*4)
            % convert data string to char array
            readData = char(readData);
            % convert data to usable values (combine 2 bytes)
            convData(source.UserData.data.numOfCells*2) = 0;
            for i=1:source.UserData.data.numOfCells*2
                convData(i) = double(uint8(readData((i*2)-1))) + (double(uint8(readData((i*2))))*256);
            end
            % populate main arduino data array with new converted data
            for i=1:source.UserData.data.numOfCells
                source.UserData.data.arduinoData{17+i}(source.UserData.data.dataIndex) = convData(i)/16;
                source.UserData.data.arduinoData{33+i}(source.UserData.data.dataIndex) = convData(source.UserData.data.numOfCells+i)/16;
            end
        elseif source.UserData.data.dataIndex < 2
            % if incoming data is invalid and is the first data packet
            % since start, reset to 0 and return
            source.UserData.data.dataIndex = 0;
            return
        else
            % if incoming data is invalid but there is at least 1 previous
            % valid data entry, carry it over to current time slot
            for i=1:source.UserData.data.numOfCells
                source.UserData.data.arduinoData{17+i}(source.UserData.data.dataIndex) = source.UserData.data.arduinoData{17+i}(source.UserData.data.dataIndex-1);
                source.UserData.data.arduinoData{33+i}(source.UserData.data.dataIndex) = source.UserData.data.arduinoData{33+i}(source.UserData.data.dataIndex-1);
            end
        end
        flush(source.UserData.data.serialConnection);

        % update cell temps
        % Slot BT1
        source.UserData.data.Cell01EditField_t_1.Value = source.UserData.data.arduinoData{18}(source.UserData.data.dataIndex);
        source.UserData.data.Cell02EditField_t_1.Value = source.UserData.data.arduinoData{19}(source.UserData.data.dataIndex);
        source.UserData.data.Cell03EditField_t_1.Value = source.UserData.data.arduinoData{20}(source.UserData.data.dataIndex);
        source.UserData.data.Cell04EditField_t_1.Value = source.UserData.data.arduinoData{21}(source.UserData.data.dataIndex);
        source.UserData.data.Cell05EditField_t_1.Value = source.UserData.data.arduinoData{22}(source.UserData.data.dataIndex);
        source.UserData.data.Cell06EditField_t_1.Value = source.UserData.data.arduinoData{23}(source.UserData.data.dataIndex);
        source.UserData.data.Cell07EditField_t_1.Value = source.UserData.data.arduinoData{24}(source.UserData.data.dataIndex);
        source.UserData.data.Cell08EditField_t_1.Value = source.UserData.data.arduinoData{25}(source.UserData.data.dataIndex);
        source.UserData.data.Cell09EditField_t_1.Value = source.UserData.data.arduinoData{26}(source.UserData.data.dataIndex);
        source.UserData.data.Cell10EditField_t_1.Value = source.UserData.data.arduinoData{27}(source.UserData.data.dataIndex);
        source.UserData.data.Cell11EditField_t_1.Value = source.UserData.data.arduinoData{28}(source.UserData.data.dataIndex);
        source.UserData.data.Cell12EditField_t_1.Value = source.UserData.data.arduinoData{29}(source.UserData.data.dataIndex);
        source.UserData.data.Cell13EditField_t_1.Value = source.UserData.data.arduinoData{30}(source.UserData.data.dataIndex);
        source.UserData.data.Cell14EditField_t_1.Value = source.UserData.data.arduinoData{31}(source.UserData.data.dataIndex);
        source.UserData.data.Cell15EditField_t_1.Value = source.UserData.data.arduinoData{32}(source.UserData.data.dataIndex);
        source.UserData.data.Cell16EditField_t_1.Value = source.UserData.data.arduinoData{33}(source.UserData.data.dataIndex);
        % Slot BT2
        source.UserData.data.Cell01EditField_t_2.Value = source.UserData.data.arduinoData{34}(source.UserData.data.dataIndex);
        source.UserData.data.Cell02EditField_t_2.Value = source.UserData.data.arduinoData{35}(source.UserData.data.dataIndex);
        source.UserData.data.Cell03EditField_t_2.Value = source.UserData.data.arduinoData{36}(source.UserData.data.dataIndex);
        source.UserData.data.Cell04EditField_t_2.Value = source.UserData.data.arduinoData{37}(source.UserData.data.dataIndex);
        source.UserData.data.Cell05EditField_t_2.Value = source.UserData.data.arduinoData{38}(source.UserData.data.dataIndex);
        source.UserData.data.Cell06EditField_t_2.Value = source.UserData.data.arduinoData{39}(source.UserData.data.dataIndex);
        source.UserData.data.Cell07EditField_t_2.Value = source.UserData.data.arduinoData{40}(source.UserData.data.dataIndex);
        source.UserData.data.Cell08EditField_t_2.Value = source.UserData.data.arduinoData{41}(source.UserData.data.dataIndex);
        source.UserData.data.Cell09EditField_t_2.Value = source.UserData.data.arduinoData{42}(source.UserData.data.dataIndex);
        source.UserData.data.Cell10EditField_t_2.Value = source.UserData.data.arduinoData{43}(source.UserData.data.dataIndex);
        source.UserData.data.Cell11EditField_t_2.Value = source.UserData.data.arduinoData{44}(source.UserData.data.dataIndex);
        source.UserData.data.Cell12EditField_t_2.Value = source.UserData.data.arduinoData{45}(source.UserData.data.dataIndex);
        source.UserData.data.Cell13EditField_t_2.Value = source.UserData.data.arduinoData{46}(source.UserData.data.dataIndex);
        source.UserData.data.Cell14EditField_t_2.Value = source.UserData.data.arduinoData{47}(source.UserData.data.dataIndex);
        source.UserData.data.Cell15EditField_t_2.Value = source.UserData.data.arduinoData{48}(source.UserData.data.dataIndex);
        source.UserData.data.Cell16EditField_t_2.Value = source.UserData.data.arduinoData{49}(source.UserData.data.dataIndex);

        % Log to file if enabled
        if source.UserData.data.logging
            % open log file
            source.UserData.data.logFileStruct = fopen(string(source.UserData.data.logFilePath) + string(source.UserData.data.logFile), "a");
            % print time stamp
            fprintf(source.UserData.data.logFileStruct, "%f,", source.UserData.data.arduinoData{1}(source.UserData.data.dataIndex));
            % print voltage data
            for i=1:source.UserData.data.numOfCells
                fprintf(source.UserData.data.logFileStruct, "%f,", source.UserData.data.arduinoData{i+1}(source.UserData.data.dataIndex));
            end
            % print temp data for BT1
            for i=1:source.UserData.data.numOfCells
                fprintf(source.UserData.data.logFileStruct, "%f,", source.UserData.data.arduinoData{17+i}(source.UserData.data.dataIndex));
            end
            % print temp data for BT2
            for i=1:source.UserData.data.numOfCells
                fprintf(source.UserData.data.logFileStruct, "%f,", source.UserData.data.arduinoData{33+i}(source.UserData.data.dataIndex));
            end
            % print pack voltage and current
            fprintf(source.UserData.data.logFileStruct, "%f,", source.UserData.data.arduinoData{end-1}(source.UserData.data.dataIndex));
            fprintf(source.UserData.data.logFileStruct, "%f\n", source.UserData.data.arduinoData{end}(source.UserData.data.dataIndex));
            % close the log file
            fclose(source.UserData.data.logFileStruct);
        end
    end
end