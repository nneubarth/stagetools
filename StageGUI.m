classdef StageGUI < handle
    properties
        xPosition
        yPosition
        stepSize
    end
    events
    end
    methods
        function SG = StageGUI
            % create StageGUI object
            TLstage_init
            global h_stage_X;
            global h_stage_Y;
            
            SG.xPosition = 0; %stage has been homed so these will be 0
            SG.yPosition = 0;
            SG.stepSize = .5; %default, can be changed with changeStep method
            h_stage_X.SetJogStepSize(0,.5);
            h_stage_Y.SetJogStepSize(0,.5);
        end
        function changeStep(SG,stepSize)
            SG.stepSize = stepSize;
            global h_stage_X;
            global h_stage_Y;
            h_stage_X.SetJogStepSize(0,stepSize);
            h_stage_Y.SetJogStepSize(0,stepSize);
        end
        function updatePos(SG)
            global h_stage_X;
            global h_stage_Y;
            SG.xPosition = h_stage_X.GetPosition_Position(0);
            SG.yPosition = h_stage_Y.GetPosition_Position(0);
        end
        function moveStage(SG,xPosition,yPosition)
            global h_stage_X;
            global h_stage_Y;
            %Move an absolute distance in mm
            h_stage_X.SetAbsMovePos(0,xPosition);
            h_stage_X.MoveAbsolute(0,1);
            h_stage_Y.SetAbsMovePos(0,yPosition);
            h_stage_Y.MoveAbsolute(0,1);
            updatePos(SG)
        end
        function gridStage(SG,Grid)
            global moving
            global h_stage_X
            global h_stage_Y
            for i = 1:numel(Grid.xGrid)
                moving = 1;
                tic
                moveStage(SG,Grid.xGrid(i),Grid.yGrid(i));
                h_stage_X.registerevent({'MoveComplete' 'moveComplete'});
                h_stage_Y.registerevent({'MoveComplete' 'moveComplete'});
                toc
                
            end
        end
        function initMotor(h, SN)
            h.StartCtrl;
            set(h, 'HWSerialNum', SN); pause(0.1);
            h.Identify;
        end
        function moveComplete(varargin)
            global moving
            pause(0.5); 
            disp('Move Completed!');
            moving = 0;
        end
    end
    methods(Static)
        function TLstage_init
            %ThorLabs apt dc servo controller and linear motorized stage
            %ActiveX Matlab GUI
            %initialization and stage homing
            
            global h_control;
            global h_stage_X;
            global h_stage_Y;
            
            figure_pos    = get(0,'DefaultFigurePosition');
            figure_pos(3) = 540; % window size width
            figure_pos(4) = 750; % height
            
            f = figure('Position', figure_pos,...
                'Menu','None',...
                'Name','APT GUI');
            
            h_control = actxcontrol('MG17SYSTEM.MG17SystemCtrl.1',[0 30 540 750 ], f);
            
            h_control.StartCtrl;
            
            user_data.h_control = h_control;
            set(f, 'UserData', user_data);
            
            [~, num_stage] = h_control.GetNumHWUnits(6, 0);
            if num_stage ~= 2
                fprintf(['Check the number of connected stages (Found' num2str(num_stage) ')!\n']);
                return
            end
            
            % Get the serial numbers
            SN_stage = cell(1,2);
            for count = 1 : num_stage
                [~, SN_stage{count}] = h_control.GetHWSerialNum(6, count - 1, 0); % Get the serial number of the devices
            end
            
            h_stage_X = actxcontrol('MGMOTOR.MGMotorCtrl.1', [0 390 540 360], f);
            initMotor(h_stage_X, SN_stage{1});
            
            h_stage_Y = actxcontrol('MGMOTOR.MGMotorCtrl.1', [0 30 540 360], f);
            initMotor(h_stage_Y, SN_stage{2});
            
            user_data.h_stage_X = h_stage_X;
            user_data.h_stage_Y = h_stage_Y;
            
            set(f, 'UserData', user_data);
            % Home the stage. First 0 is the channel ID (channel 1)
            % second 0 is to move immediately
            h_stage_X.MoveHome(0,0);
            h_stage_Y.MoveHome(0,0);
            
            h_stage_X.registerevent({'MoveComplete' 'moveComplete'});
            h_stage_Y.registerevent({'MoveComplete' 'moveComplete'});
            
        end
        
    end
end