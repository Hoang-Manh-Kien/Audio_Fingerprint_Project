function hashTable = chromaHash(chromaFingerprints, songID)
    % Convert chroma fingerprints to hash values
    % Inputs:
    %   chromaFingerprints - fingerprint matrix
    %   songID - song identifier (optional, default = 0)
    % Output:
    %   hashTable - [hash_value, time_index, song_id]
    
    if nargin < 2
        songID = 0;
    end
    
    hashTable = [];
    
    for t = 1:size(chromaFingerprints, 2)
        fingerprint = chromaFingerprints(:, t);
        
        % Convert binary fingerprint to hash
        hashValue = 0;
        for i = 1:length(fingerprint)
            hashValue = hashValue + fingerprint(i) * (2^(i-1));
        end
        
        % Add to hash table
        hashTable = [hashTable; hashValue, t, songID];
    end
end