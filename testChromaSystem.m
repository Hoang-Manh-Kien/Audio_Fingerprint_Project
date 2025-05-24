function testChromaSystem()
    
    fprintf('=== CHROMA-BASED FINGERPRINTING TEST ===\n\n');
    
    nSongs = 50;
    results = struct();
    results.songID = zeros(1, nSongs);
    results.timeTaken = zeros(1, nSongs);
    results.clipLength = zeros(1, nSongs);
    
    correctIdentifications = 0;
    totalSongs = 0;
    
    for i = 1:nSongs
        filename = sprintf('songDatabase/%d.mat', i);
        
        if ~exist(filename, 'file')
            continue;
        end
        
        fprintf('Testing song %d/%d... ', i, nSongs);
        
        try
            load(filename, '-mat');
            totalSongs = totalSongs + 1;
            
            clipDuration = 5 + rand() * 10;
            maxStart = max(1, length(y)/Fs - clipDuration);
            startTime = rand() * maxStart;
            
            startSample = round(startTime * Fs);
            endSample = min(length(y), startSample + round(clipDuration * Fs));
            
            testClip = y(startSample:endSample, :);
            results.clipLength(i) = (endSample - startSample) / Fs;
            
            tic;
            identifiedSong = identifyChromaSong(testClip, Fs);
            identificationTime = toc;
            
            results.songID(i) = identifiedSong;
            results.timeTaken(i) = identificationTime;
            
            if identifiedSong == i
                correctIdentifications = correctIdentifications + 1;
                fprintf('CORRECT (%.2fs)\n', identificationTime);
            elseif identifiedSong > 0
                fprintf('WRONG (got %d, %.2fs)\n', identifiedSong, identificationTime);
            else
                fprintf('FAILED (%.2fs)\n', identificationTime);
            end
            
        catch ME
            fprintf('ERROR: %s\n', ME.message);
        end
    end
    
    % Calculate results
    accuracy = correctIdentifications / totalSongs;
    avgTime = mean(results.timeTaken(results.timeTaken > 0));
    
    fprintf('\n=== CHROMA SYSTEM TEST RESULTS ===\n');
    fprintf('Total songs tested: %d\n', totalSongs);
    fprintf('Correct identifications: %d\n', correctIdentifications);
    fprintf('Wrong identifications: %d\n', sum(results.songID > 0 & results.songID ~= 1:nSongs));
    fprintf('Failed identifications: %d\n', sum(results.songID == 0 & results.clipLength > 0));
    fprintf('Accuracy: %.2f%%\n', accuracy * 100);
    fprintf('Average identification time: %.3f seconds\n', avgTime);
    
    % Save results
    save('chromaTestResults.mat', 'results');
    fprintf('\nResults saved to chromaTestResults.mat\n');
end