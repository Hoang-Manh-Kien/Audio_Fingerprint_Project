function buildChromaDatabase()
    
    fprintf('Building Chroma Fingerprint Database...\n');
    
    nSongs = 50;
    hashTable = [];
    
    for songID = 1:nSongs
        fprintf('Processing song %d/%d... ', songID, nSongs);
        
        filename = sprintf('songDatabase/%d.mat', songID);
        
        if ~exist(filename, 'file')
            fprintf('SKIPPED (file not found)\n');
            continue;
        end
        
        try
            load(filename, '-mat');
            
            fingerprints = chromaFingerprinting(y, Fs);
            
            if isempty(fingerprints)
                fprintf('NO FINGERPRINTS\n');
                continue;
            end
            
            songHashes = chromaHash(fingerprints, songID);
            
            hashTable = [hashTable; songHashes];
            
            fprintf('OK (%d hashes)\n', size(songHashes, 1));
            
        catch ME
            fprintf('ERROR: %s\n', ME.message);
        end
    end
    
    fprintf('\nTotal hashes in database: %d\n', size(hashTable, 1));
    
    % Save database
    save('chromaDatabase.mat', 'hashTable');
    fprintf('Chroma database saved to chromaDatabase.mat\n');
    
    % Statistics
    uniqueSongs = unique(hashTable(:, 3));
    fprintf('Songs in database: %d\n', length(uniqueSongs));
    if length(uniqueSongs) > 0
        fprintf('Average hashes per song: %.1f\n', size(hashTable, 1) / length(uniqueSongs));
    end
    
    fprintf('Chroma database build complete!\n');
end