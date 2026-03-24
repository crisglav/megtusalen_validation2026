clc
clear
close all

megtusalen_excel = '../results/participants_megtusalen_corrected.xlsx';

megtusalen = readtable(megtusalen_excel);

log_file = '../results/logs/full_diag_validation_log.txt';
fid_log = fopen(log_file, 'w');

n_errors = 0;

for i = 1:height(megtusalen)

    id = string(megtusalen.participant_id(i));

    diag = string(megtusalen.diagnosis(i));
    grp  = string(megtusalen.group(i));
    fh   = megtusalen.family_history(i);
    conv = megtusalen.converter(i);

    hasConvTime = ~ismissing(megtusalen.conversion_time(i)) & ~isnan(megtusalen.conversion_time(i));
    hasEvoTime  = ~ismissing(megtusalen.evolution_time(i)) & ~isnan(megtusalen.evolution_time(i));

    %% -----------------------------
    % 1. diagnosis vs group
    %% -----------------------------
    switch diag
        case "HC"
            valid_groups = ["SCDneg","MCIneg","FHneg"];
        case "SCD"
            valid_groups = ["SCDpos"];
        case "MCI"
            valid_groups = ["MCIa","MCIm"];
        case "FH"
            valid_groups = ["FHpos"];
        case "AD"
            valid_groups = ["AD"];
        otherwise
            valid_groups = [];
    end

    if ~isempty(valid_groups) && ~any(grp == valid_groups)
        fprintf(fid_log, 'ID %s: ERROR diagnosis-group -> %s vs %s\n', id, diag, grp);
        n_errors = n_errors + 1;
    end

    %% -----------------------------
    % 2. family_history vs group
    %% -----------------------------
    if grp == "FHneg" && ~ismember(fh, [0 2])
        fprintf(fid_log, 'ID %s: ERROR FHneg but family_history=%d\n', id, fh);
        n_errors = n_errors + 1;
    end

    if grp == "FHpos" && ~ismember(fh, [1 3])
        fprintf(fid_log, 'ID %s: ERROR FHpos but family_history=%d\n', id, fh);
        n_errors = n_errors + 1;
    end

    %% -----------------------------
    % 3. converter rules
    %% -----------------------------
    if conv == 1 && ~hasConvTime
        fprintf(fid_log, 'ID %s: ERROR converter=1 but missing conversion_time\n', id);
        n_errors = n_errors + 1;
    end

    if conv == 3 && ~hasEvoTime
        fprintf(fid_log, 'ID %s: ERROR converter=3 but missing evolution_time\n', id);
        n_errors = n_errors + 1;
    end

    if conv == 4 && ~(hasConvTime && hasEvoTime)
        fprintf(fid_log, 'ID %s: ERROR converter=4 but missing times\n', id);
        n_errors = n_errors + 1;
    end

end

fclose(fid_log);

fprintf('Validation finished.\n');
fprintf('Total errors found: %d\n', n_errors);
fprintf('Log saved to: %s\n', log_file);