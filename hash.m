function hashTable = hash(table)
    hashTable = [];
    
    for j = 1:size(table, 1)
        entry = table(j, :);
        f_1 = entry(1);
        f_2 = entry(2);
        t_1 = entry(3);
        t_d = entry(4);
        
        if (size(table, 2) == 5)
            song_id = entry(5);
        else
            song_id = 0;
        end
        
        hash_entry = t_d*(2^16) + (f_1-1)*(2^8) + (f_2-1);
        new_entry = [hash_entry, t_1, song_id];
        hashTable = [hashTable; new_entry];
    end
end