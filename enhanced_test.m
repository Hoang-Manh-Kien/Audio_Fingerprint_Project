clear all
close all
clc

n = 50;

clipLength = zeros(1, n);
initialTime = zeros(1, n);
songID = zeros(1, n);
timeTaken = zeros(1, n);
confidence_scores = zeros(1, n);

fprintf('Initializing test parameters...\n');
for i = 1:n
    toRead = strcat('songDatabase/', num2str(i), '.mat');
    if exist(toRead, 'file')
        load(toRead, '-mat');
        clipLength(i) = length(y) / Fs;
        max_start = max(1, round(clipLength(i) - 12));
        initialTime(i) = randi(max_start);
    else
        fprintf('Warning: Song %d not found\n', i);
        clipLength(i) = 0;
        initialTime(i) = 0;
    end
end

fprintf('Starting enhanced Shazam testing...\n');
correct_identifications = 0;
total_clips_used = 0;
failed_identifications = 0;

for i = 1:n
    if clipLength(i) == 0
        continue;
    end
    
    fprintf('Testing song %d/%d... ', i, n);
    
    toRead = strcat('songDatabase/', num2str(i), '.mat');
    load(toRead, '-mat');
    
    timeTaken(i) = 0;
    songID(i) = 0;
    max_attempts = 10; 
    
    while songID(i) == 0 && timeTaken(i) < max_attempts
        timeTaken(i) = timeTaken(i) + 1;
        
        start_sample = initialTime(i) * Fs;
        end_sample = min(length(y), start_sample + timeTaken(i) * Fs);
        
        if end_sample <= start_sample
            break;
        end
        
        yInput = y(start_sample:end_sample, :);
        
        try
            songID(i) = Kien2300984(yInput, Fs);
        catch ME
            fprintf('Error in Kien2300984 for song %d: %s\n', i, ME.message);
            songID(i) = 0;
            break;
        end
        
        if songID(i) > 0
            break;
        end
    end
    
    total_clips_used = total_clips_used + timeTaken(i);
    
    if songID(i) == i
        correct_identifications = correct_identifications + 1;
        fprintf('CORRECT (%.1fs)\n', timeTaken(i));
    elseif songID(i) > 0
        fprintf('WRONG (got %d, %.1fs)\n', songID(i), timeTaken(i));
        failed_identifications = failed_identifications + 1;
    else
        fprintf('FAILED (%.1fs)\n', timeTaken(i));
        failed_identifications = failed_identifications + 1;
    end
end

fprintf('\n=== ENHANCED SHAZAM TEST RESULTS ===\n');

valid_songs = sum(clipLength > 0);
accuracy = correct_identifications / valid_songs;
average_time = total_clips_used / valid_songs;

points_earned = 0;
for i = 1:n
    if clipLength(i) > 0
        if songID(i) == i
            points_earned = points_earned + 2;  % Correct identification: +2 points
        elseif songID(i) > 0
            points_earned = points_earned - 1;  % Wrong identification: -1 point
        end
        % No identification (songID == 0): 0 points
    end
end

if total_clips_used > 0
    final_score = points_earned / total_clips_used;
else
    final_score = 0;
end

fprintf('Valid songs tested: %d/%d\n', valid_songs, n);
fprintf('Correct identifications: %d\n', correct_identifications);
fprintf('Wrong identifications: %d\n', sum(songID > 0 & songID ~= [1:n]));
fprintf('Failed identifications: %d\n', sum(songID == 0 & clipLength > 0));
fprintf('Accuracy: %.2f%%\n', accuracy * 100);
fprintf('Average time per song: %.2f seconds\n', average_time);
fprintf('Total points earned: %d\n', points_earned);
fprintf('Total clips used: %d\n', total_clips_used);
fprintf('Final score (points/clips): %.4f\n', final_score);

fprintf('\n=== DETAILED ANALYSIS ===\n');
fprintf('Time distribution:\n');
for t = 1:10
    count = sum(timeTaken == t & clipLength > 0);
    if count > 0
        fprintf('  %d second clips: %d songs\n', t, count);
    end
end

fprintf('\nAccuracy by clip length:\n');
for t = 1:5
    mask = timeTaken == t & clipLength > 0;
    if sum(mask) > 0
        acc = sum(songID(mask) == find(mask)) / sum(mask);
        fprintf('  %d seconds: %.1f%% (%d/%d)\n', t, acc*100, ...
                sum(songID(mask) == find(mask)), sum(mask));
    end
end

results = struct();
results.songID = songID;
results.timeTaken = timeTaken;
results.accuracy = accuracy;
results.averageTime = average_time;
results.finalScore = final_score;
results.pointsEarned = points_earned;
results.totalClipsUsed = total_clips_used;

save('test_results.mat', 'results');
fprintf('\nResults saved to test_results.mat\n');