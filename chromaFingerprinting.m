function fingerprints = chromaFingerprinting(y, Fs)

    if size(y, 2) > 1
        y = y(:, 1);
    end

    targetFs = 22050;
    if Fs ~= targetFs
        y = resample(y, targetFs, Fs);
        Fs = targetFs;
    end

    frameSize = 4096;
    hopSize = 2048;
    
    chroma = chromaExtraction(y, Fs, frameSize, hopSize);
    
    chromaQuantized = round(chroma * 2);
    
    chromaDiff = diff(chromaQuantized, 1, 2);
    
    fingerprints = chromaDiff > 0;
    
    patternFingerprints = [];
    windowSize = 4;
    
    for i = 1:size(fingerprints, 2) - windowSize + 1
        window = fingerprints(:, i:i+windowSize-1);
        
        pattern = [];
        for j = 1:12
            rising = all(diff(double(window(j, :))) >= 0); 
            falling = all(diff(double(window(j, :))) <= 0);
            % Check if there's a peak
            peak = window(j, 2) > window(j, 1) && window(j, 2) > window(j, 3);
            
            pattern = [pattern; rising; falling; peak];
        end
        
        patternFingerprints = [patternFingerprints, pattern];
    end
    
    minCols = min(size(fingerprints, 2), size(patternFingerprints, 2));
    fingerprints = [fingerprints(:, 1:minCols); patternFingerprints(:, 1:minCols)];
end