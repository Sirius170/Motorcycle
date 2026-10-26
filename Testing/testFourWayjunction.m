% Copyright 2020 - 2020 The MathWorks, Inc.
%%
% Set-up: Create Scenario and Network
s = createFourWayJunctionScenario();
net = createFourWayJunctionNetwork(s);

s.StopTime=100;
s.SampleTime = 0.05;

%%
InjectionRate = [700, 700, 700, 700]; % veh/hour
TurnRatio = [20, 60, 30];
[cars, motorcycles] = createVehiclesForFourWayJunction(s,net,InjectionRate, TurnRatio);
%%
nodesInJunction = net(9:end);
cliques = [1,1,1,2,2,2,3,3,3,4,4,4];
cycle = [0,15,30,45,60];
traffic = trafficControl.TrafficLight(nodesInJunction,'Cliques',cliques,'Cycle',cycle);
%%
% MATLAB R2026a compatibility fix
initializeOTLScenario(s);
%%
% Record video
recordVid = false;
if recordVid
    vid = VideoWriter('FourWay_Junction_with_lights');
    vid.FrameRate=1/s.SampleTime;
    vid.Quality = 100;
    open(vid)
end

plot(s)
sPlot = gca;

% 在畫面上方建立模擬計時器
timerLabel = annotation(gcf, 'textbox', [0.35 0.93 0.30 0.05], ...
    'String', '模擬時間: 0.00 / 100.00 秒', 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontSize', 12, 'FontWeight', 'bold', ...
    'EdgeColor', 'none');

% 建立獨立的機車視覺化圖層
hold(sPlot, 'on');
motorcycleDots = scatter(sPlot, nan, nan, 30, 'r', 'filled');

xLim = sPlot.XLim + [-5,5];
yLim = sPlot.YLim + [-5,5];
set(sPlot,'XLim',xLim)
set(sPlot,'YLim',yLim)

%Waiting time calculation
totalCarWaitingTime = 0;
%%
%Run simulation
 while advance(s)
    % Calculation Car waiting time
    for k=1:numel(cars)

        speed = norm(cars(k).Velocity);

        if speed<0.5
            totalCarWaitingTime = totalCarWaitingTime + s.SampleTime;
        end
    end

    set(sPlot,'XLim',xLim)
    set(sPlot,'YLim',yLim)
    traffic.plotOpenPaths()
    % 更新目前模擬時間
    timerLabel.String = sprintf('模擬時間: %.2f / %.2f 秒', ...
        s.SimulationTime, s.StopTime);

    % 更新每台機車的圓點位置
    if ~isempty(motorcycles)
        motoX = arrayfun(@(m) m.Position(1), motorcycles);
        motoY = arrayfun(@(m) m.Position(2), motorcycles);

        % 只顯示目前可見的機車
        visible = arrayfun(@(m) m.IsVisible, motorcycles);
        set(motorcycleDots, ...
            'XData', motoX(visible), ...
            'YData', motoY(visible));
    end

    %drawnow
    %Record video
    if recordVid
        frame = getframe(gcf);
        writeVideo(vid,frame);
    end
     
 end
 
if recordVid
 close(vid)
end

fprintf("Total car waitiing time = %.2f second\n", totalCarWaitingTime);

