fam_gen_excel = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\source_data\BBDD Conjunta 261 familiares.xlsx';
megtusalen_excel = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\participants_megtusalen.xlsx';
out_file = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\participants_megtusalen_corrected.tsv';


fam_neuro = readtable(fam_gen_excel,'Sheet','Neuropsicología');
megtusalen = readtable(megtusalen_excel);
% 
% vars_megtusalen = {'age','sex','edu_years','BADS_rules_test', 'cog_res','DTS_forward','DTS_backward','GDS_15', ...
%     'LM_imm_units','LM_del_units','LM_imm_them','LM_del_them','MMSE','MOCA','PTF_F','PTF_A','PTF_S', ...
%     'ROCFB_copy', 'ROCFB_memory', 'SFT_animals', 'TMT_A_hits', 'TMT_A_time', 'TMT_B_hits', 'TMT_B_time', ...
%     'word_list_trial1', 'word_list_trial4', 'word_list_learning_total', 'word_list_delayed_recall', 'word_list_recognition'};

vars_megtusalen = {'age'}; 

vars_fam = {'Edad'}; 

ids = fam_neuro.CodigoProyecto;
n = length(ids);

% Open log file
log_file = ['fam_neuro_validation_log_' vars_megtusalen{1} '.txt'];
fid = fopen(log_file, 'w');

n_updated = 0;
n_not_found = 0;

for i = 1:n
    subject_ok = true;

    id = string(fam_neuro.CodigoProyecto{i});

    % Find in megtusalen the participant with current id
    meg_row = find(strcmp(megtusalen.recording_id_orig, id), 1);

    if isempty(meg_row)
        warning('Could not find %s\n', id)
        fprintf(fid, 'ID %s: participant not found in megtusalen\n', id);
        n_not_found = n_not_found + 1;
        continue;
    end

    % Make sure that variable value in megtusalen is equal to
    % variable value in fam_neuro
    for ivar = 1:length(vars_fam)

        varname_fam = string(vars_fam{ivar});
        varname_megtusalen = string(vars_megtusalen{ivar});

        fam_val = fam_neuro.(varname_fam)(i);
        meg_val = megtusalen.(varname_megtusalen)(meg_row);

        if iscell(fam_val)
            if isempty(fam_val)
                fam_val = [];
            else
                fam_val = fam_val{1};
            end
        end
        
        if iscell(meg_val)
            if isempty(meg_val)
                meg_val = [];
            else
                meg_val = meg_val{1};
            end
        end
    
        % Convert sex variable
        if strcmp(varname_fam,'Sexo')
            if fam_val == 1
                fam_val = 'm';
            elseif fam_val == 2
                fam_val = 'f';
            end
        end

        % Define missing flags clearly
        fam_missing = isempty(fam_val) || ...
              (isnumeric(fam_val) && isnan(fam_val)) || ...
              (isstring(fam_val) && strlength(fam_val)==0);

        meg_missing = isempty(meg_val) || ...
              (isnumeric(meg_val) && isnan(meg_val)) || ...
              (isstring(meg_val) && strlength(meg_val)==0);


        % Convert fam_val to string safely
        if fam_missing
            fam_str = "NaN";
        else
            fam_str = string(fam_val);
        end

        % Convert meg_val to string safely
        if meg_missing
            meg_str = "NaN";
        else
            meg_str = string(meg_val);
        end

        % Case 1: fam has value and megtusalen is missing → FILL
        if ~fam_missing && meg_missing
            megtusalen.(varname){meg_row} = fam_val;
            n_updated = n_updated + 1;

            fprintf(fid, ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id, varname, fam_str);

        % Case 2: both have values but differ → CORRECT
        elseif ~fam_missing && ~meg_missing && ~isequal(fam_val, meg_val)
            megtusalen.(varname){meg_row} = fam_val;
            n_updated = n_updated + 1;

            fprintf(fid, ...
                'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
                id, varname, meg_str, fam_str);

        % Case 3: fam is missing → do nothing
        elseif fam_missing
            fprintf(fid, ...
                'ID %s, variable %s: skipped (fam_neuro missing, megtusalen=%s)\n', ...
                id, varname, meg_str);
        end


    end

    if subject_ok
        % fprintf(fid, 'ID %s: subject ok\n', id);
    end

end

fclose(fid);
fprintf('Validation finished. Log saved to %s\n', log_file);

writetable(megtusalen, out_file, 'FileType', 'text', 'Delimiter', '\t');

fprintf('Correction finished.\n');
fprintf('Updated values: %d\n', n_updated);
fprintf('Participants not found: %d\n', n_not_found);
fprintf('Corrected file saved to: %s\n', out_file);
fprintf('Log saved to: %s\n', log_file);

