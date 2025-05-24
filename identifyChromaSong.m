function songID = identifyChromaSong(y, Fs)

    if ~exist('chromaDatabase.mat', 'file')
        fprintf('Error: Chroma database not found. Run buildChromaDatabase first.\n');
        songID = 0;
        return;
    end
    
    load('chromaDatabase.mat', 'hashTable');

    fingerprints = chromaFingerprinting(y, Fs);
    
    if isempty(fingerprints)
        songID = 0;
        return;
    end
    
    inputHashes = chromaHash(fingerprints);
    
    matches = [];
    
    for i = 1:size(inputHashes, 1)
        inputHash = inputHashes(i, 1);
        inputTime = inputHashes(i, 2);
        
        dbMatches = find(hashTable(:, 1) == inputHash);
        
        for j = 1:length(dbMatches)
            dbIdx = dbMatches(j);
            dbTime = hashTable(dbIdx, 2);
            dbSong = hashTable(dbIdx, 3);
            
            timeOffset = dbTime - inputTime;
            
            matches = [matches; dbSong, timeOffset];
        end
    end
    
    if isempty(matches)
        songID = 0;
        return;
    end
    
    uniqueSongs = unique(matches(:, 1));
    bestScore = 0;
    bestSong = 0;
    
    for song = uniqueSongs'
        songMatches = matches(matches(:, 1) == song, :);
        
        % Find most common time offset
        [uniqueOffsets, ~, idx] = unique(songMatches(:, 2));
        offsetCounts = accumarray(idx, 1);
        [maxCount, ~] = max(offsetCounts);
        
        if maxCount > bestScore
            bestScore = maxCount;
            bestSong = song;
        end
    end
    
    % Apply confidence threshold
    totalHashes = size(inputHashes, 1);
    confidenceRatio = bestScore / totalHashes;
    
    clipDuration = size(fingerprints, 2) * 2048 / 22050;
    
    if clipDuration < 3
        minConfidence = 0.15; 
    elseif clipDuration < 6
        minConfidence = 0.10;
    else
        minConfidence = 0.08;
    end
    
    if confidenceRatio >= minConfidence && bestScore >= 3
        songID = bestSong;
    else
        songID = 0;
    end
end