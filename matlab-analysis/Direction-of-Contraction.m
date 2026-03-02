%% Dense Optical Flow (Farneback) - pixel por pixel
videoFile = "CM-4X.avi";

v = VideoReader(videoFile);

% Flujo óptico denso (requiere Computer Vision Toolbox)
opticFlow = opticalFlowFarneback( ...
    'NumPyramidLevels', 3, ...
    'PyramidScale', 0.5, ...
    'NeighborhoodSize', 5, ...
    'FilterSize', 15);

magMean = [];
t = [];

frameRGB = readFrame(v);
frameGray = im2gray(frameRGB);
estimateFlow(opticFlow, frameGray);

figure('Name','Optical Flow - Farneback');
hImg = imshow(frameRGB); hold on;
hQ = quiver([],[],[],[],'r'); % <-- rojo
title('Flujo óptico denso (pixel a pixel)');
hold off;

useROI = false;

frameIdx = 1;
while hasFrame(v)
    frameRGB = readFrame(v);
    frameGray = im2gray(frameRGB);

    flow = estimateFlow(opticFlow, frameGray);

    mag = hypot(flow.Vx, flow.Vy);

    t(frameIdx,1) = (frameIdx-1) / v.FrameRate;

    if useROI
        x = roiPos(1); y = roiPos(2); w = roiPos(3); h = roiPos(4);
        magROI = mag(y:y+h-1, x:x+w-1);
        magMean(frameIdx,1) = mean(magROI(:));
    else
        magMean(frameIdx,1) = mean(mag(:));
    end

    step = 12;
    [H,W,~] = size(frameRGB);
    [X,Y] = meshgrid(1:step:W, 1:step:H);
    VxS = flow.Vx(1:step:end, 1:step:end);
    VyS = flow.Vy(1:step:end, 1:step:end);

    set(hImg, 'CData', frameRGB);
    cla; imshow(frameRGB); hold on;
    quiver(X, Y, VxS, VyS, 2, 'r'); 
    title(sprintf('Frame %d | t=%.3f s', frameIdx, t(frameIdx)));
    drawnow;

    frameIdx = frameIdx + 1;
end

figure('Name','Actividad (magnitud media del flujo)');
plot(t, magMean);
xlabel('Tiempo (s)');
ylabel('Magnitud media del flujo (pix/frame)');
title('Movimiento promedio (pixel a pixel) a lo largo del tiempo');
grid on;