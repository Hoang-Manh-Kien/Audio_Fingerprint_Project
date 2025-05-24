function chroma = chromaExtraction(y, Fs, frameSize, hopSize)
    % Extract chromagram from audio signal
    % Inputs:
    %   y - audio signal
    %   Fs - sampling frequency
    %   frameSize - window size for STFT
    %   hopSize - hop size for STFT
    % Output:
    %   chroma - 12 x N chroma feature matrix
    
    if nargin < 3
        frameSize = 4096;
    end
    if nargin < 4
        hopSize = frameSize / 2;
    end
    
    % Parameters
    numChroma = 12;
    minFreq = 80;  % Minimum frequency (Hz)
    maxFreq = 8000; % Maximum frequency (Hz)
    
    % STFT
    window = hann(frameSize);
    [S, F, T] = spectrogram(y, window, frameSize - hopSize, frameSize, Fs);
    
    % Magnitude spectrum
    magS = abs(S);
    
    % Find frequency indices within our range
    freqIdx = find(F >= minFreq & F <= maxFreq);
    F_valid = F(freqIdx);
    magS_valid = magS(freqIdx, :);
    
    % Create chroma mapping matrix
    A = zeros(numChroma, length(F_valid));
    
    for i = 1:length(F_valid)
        freq = F_valid(i);
        % Convert frequency to MIDI note number
        midiNote = 69 + 12 * log2(freq / 440);
        % Map to chroma bin (0-11)
        chromaBin = mod(round(midiNote), 12) + 1;
        A(chromaBin, i) = 1;
    end
    
    % Apply chroma mapping
    chroma = A * magS_valid;
    
    % Normalize each frame
    for i = 1:size(chroma, 2)
        norm_val = norm(chroma(:, i));
        if norm_val > 0
            chroma(:, i) = chroma(:, i) / norm_val;
        end
    end
end