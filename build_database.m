
clear all
close all
clc

fprintf('Building Shazam database (original approach)...\n');

gs = 9;
deltaTL = 3;
deltaTU = 6;
deltaF = 9;
fanOut = 3;

hashTable = [];
n_songs = 50;

for song_id = 1:n_songs
    fprintf('Processing song %d/%d... ', song_id, n_songs);
    
    filename = sprintf('songDatabase/%d.mat', song_id);
    
    if ~exist(filename, 'file')
        fprintf('SKIPPED (file not found)\n');
        continue;
    end
    
    try
        load(filename, '-mat');
        
        y = y(:, 1);
        new_Fs = 8000;
        resampledSong = resample(y, new_Fs, Fs);
        
        window = new_Fs * 64*10^-3;
        noverlap = new_Fs * 32*10^-3;
        nfft = window;
        
        [S, F, T] = spectrogram(resampledSong, window, noverlap, nfft, new_Fs);
        log_S = log10(abs(S) + 1);
        
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
        
        desiredNumPeaks = ceil(T(end)) * 35;
        sortedLocalPeak = sort(localPeakValues(:), 'descend');
        
        valid_peaks = sortedLocalPeak(sortedLocalPeak > 0);
        if length(valid_peaks) < desiredNumPeaks
            desiredNumPeaks = length(valid_peaks);
        end
        
        if desiredNumPeaks == 0
            fprintf('NO PEAKS\n');
            continue;
        end
        
        threshold = valid_peaks(desiredNumPeaks);
        localPeakLocation = (localPeakValues >= threshold);
        
        [freqLocation, timeLocation] = find(localPeakLocation);
        
        if length(freqLocation) < 2
            fprintf('INSUFFICIENT PEAKS\n');
            continue;
        end
        
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
                    % Add song_id as 5th column
                    table = [table; freqLocation_1, freqLocation_2(index), ...
                            timeLocation_1, (timeLocation_2(index) - timeLocation_1), song_id];
                end
            end
        end
        
        if ~isempty(table)
            % Generate hashes for this song
            songHashes = hash(table);
            hashTable = [hashTable; songHashes];
            fprintf('OK (%d hashes)\n', size(songHashes, 1));
        else
            fprintf('NO FINGERPRINTS\n');
        end
        
    catch ME
        fprintf('ERROR: %s\n', ME.message);
    end
end

fprintf('\nTotal hashes: %d\n', size(hashTable, 1));

save('song.mat', 'hashTable');
fprintf('Database saved to song.mat\n');

% Statistics
unique_songs = unique(hashTable(:, 3));
fprintf('Songs in database: %d\n', length(unique_songs));
fprintf('Average hashes per song: %.1f\n', size(hashTable, 1) / length(unique_songs));

fprintf('Database build complete!\n');