% Correct recording_id_orig typos
megtusalen_in = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\participants_megtusalen.xlsx';

megtusalen_file = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\participants_megtusalen_umec_corrected.xlsx';

megtusalen = readtable(megtusalen_in,'Filetype','spreadsheet','VariableNamingRule','preserve');

ids = megtusalen.recording_id_orig;

meg_row = find(strcmp(megtusalen.participant_id, 'UMEC-023'));
megtusalen.recording_id_orig{meg_row} = 'umeccd029';

meg_row = find(strcmp(megtusalen.participant_id, 'UMEC-024'));
megtusalen.recording_id_orig{meg_row} = 'umeccd028';

meg_row = find(strcmp(megtusalen.participant_id, 'UMEC-047'));
megtusalen.recording_id_orig{meg_row} = 'umeccd036';

meg_row = find(strcmp(megtusalen.participant_id, 'UMEC-065'));
megtusalen.recording_id_orig{meg_row} = 'umeccd044';

meg_row = find(strcmp(megtusalen.participant_id, 'UMEC-095'));
megtusalen.recording_id_orig{meg_row} = 'umeccd057';

meg_row = find(strcmp(megtusalen.participant_id, 'UMEC-212'));
megtusalen.recording_id_orig{meg_row} = 'UMECMA085';

meg_row = find(strcmp(megtusalen.participant_id, 'UMEC-215'));
megtusalen.recording_id_orig{meg_row} = 'umeccd108';

meg_row = find(strcmp(megtusalen.participant_id, 'UMEC-215'));
megtusalen.recording_id_orig{meg_row} = 'umeccd108';

writetable(megtusalen, megtusalen_file,"FileType","spreadsheet");
