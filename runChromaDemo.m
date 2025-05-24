function runChromaDemo()
    
    fprintf('=== CHROMA-BASED AUDIO FINGERPRINTING DEMO ===\n\n');
    
    fprintf('Step 1: Building chroma fingerprint database...\n');
    buildChromaDatabase();
    
    fprintf('\nPress any key to continue to testing...\n');
    pause;
    
    fprintf('\nStep 2: Testing chroma fingerprinting system...\n');
    testChromaSystem();
    
    fprintf('\nDemo complete!\n');
end