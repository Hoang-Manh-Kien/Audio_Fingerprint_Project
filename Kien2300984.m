function songID = Kien2300984(y, Fs)
    load('song', '-mat');
    
    gs = 9;
    deltaTL = 3;
    deltaTU = 6;
    deltaF = 9;
    
    y = y(:,1);
    new_Fs = 8000;
    resampledSong = resample(y, new_Fs, Fs);
    
    window = new_Fs * 64*10^-3;
    noverlap = new_Fs * 32*10^-3;
    nfft = window;
    
    [S, F, T] = spectrogram(resampledSong, window, noverlap, nfft, new_Fs);
    log_S = log10(abs(S) + 1);  % Keep original +1
    
    array = -floor(gs/2):floor(gs/2);
    localPeakLocation = ones(size(log_S));
    
    for i = 1:gs
        for j = 1:gs
            if (array(i) == 0 && array(j) == 0)
                localPeakLocation = localPeakLocation;
            else
                CA = circshift(log_S, [array(i), array(j)]);
                localPeakLocation = (log_S - CA > 0) .* localPeakLocation;
            end
        end
    end
    
    localPeakValues = log_S .* localPeakLocation;
    
    clip_duration = T(end);
    if clip_duration < 2
        peaks_per_second = 50;
    elseif clip_duration < 4
        peaks_per_second = 40;
    else
        peaks_per_second = 30;
    end
    
    desiredNumPeaks = ceil(clip_duration * peaks_per_second);
    sortedLocalPeak = sort(localPeakValues(:), 'descend');
    
    valid_peaks = sortedLocalPeak(sortedLocalPeak > 0);
    if length(valid_peaks) < desiredNumPeaks
        desiredNumPeaks = length(valid_peaks);
    end
    
    if desiredNumPeaks < 10
        songID = 0;
        return;
    end
    
    threshold = valid_peaks(desiredNumPeaks);
    localPeakLocation = (localPeakValues >= threshold);
    
    [freqLocation, timeLocation] = find(localPeakLocation);
    
    if length(freqLocation) < 5
        songID = 0;
        return;
    end
    
    fanOut = 3;
    table = [];
    
    for i = 1:length(timeLocation)
        freqLocation_1 = freqLocation(i);
        timeLocation_1 = timeLocation(i);
        
        freqLower = max(1, freqLocation_1 - deltaF);
        freqUpper = min(length(F), freqLocation_1 + deltaF);
        timeLower = timeLocation_1 + deltaTL;
        timeUpper = min(length(T), timeLocation_1 + deltaTU);
        
        if timeLower > timeUpper
            continue;
        end
        
        subArray = localPeakLocation(freqLower:freqUpper, timeLower:timeUpper);
        [subArrayRow, subArrayCol] = find(subArray, fanOut);
        
        if (~isempty(subArrayRow) && ~isempty(subArrayCol))
            freqLocation_2 = (subArrayRow + (freqLocation_1 - deltaF)) - 1;
            timeLocation_2 = (subArrayCol + (timeLocation_1 + deltaTL)) - 1;
            
            for index = 1:length(freqLocation_2)
                table = [table; freqLocation_1, freqLocation_2(index), ...
                        timeLocation_1, (timeLocation_2(index) - timeLocation_1)];
            end
        end
    end
    
    if size(table, 1) < 5
        songID = 0;
        return;
    end
    
    clipHash = hash(table);
    
    matchMatrix = [];
    
    for i2 = 1:size(clipHash, 1)
        indices = find(hashTable(:, 1) == clipHash(i2, 1));
        if ~isempty(indices)
            time_offsets = hashTable(indices, 2) - clipHash(i2, 2);
            song_ids = hashTable(indices, 3);
            matchMatrix = [matchMatrix; time_offsets, song_ids];
        end
    end
    
    if isempty(matchMatrix)
        songID = 0;
        return;
    end
    
    unique_songs = unique(matchMatrix(:, 2));
    best_score = 0;
    best_song = 0;
    
    for song = unique_songs'
        song_matches = matchMatrix(matchMatrix(:, 2) == song, :);
        
        [unique_offsets, ~, idx] = unique(song_matches(:, 1));
        offset_counts = accumarray(idx, 1);
        [max_count, max_idx] = max(offset_counts);
        
        if max_count > best_score
            best_score = max_count;
            best_song = song;
        end
    end

    total_hashes = size(clipHash, 1);
    
    if clip_duration < 1.5
        min_matches = max(3, round(total_hashes * 0.15));
    elseif clip_duration < 3
        min_matches = max(5, round(total_hashes * 0.12));
    else
        min_matches = max(8, round(total_hashes * 0.08));
    end
    
    if best_score >= min_matches && best_score >= 3
        songID = best_song;
    else
        songID = 0;
    end
end