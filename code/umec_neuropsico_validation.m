umec_excel = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\source_data\UMEC_DAVID.csv';
megtusalen_file = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\participants_megtusalen_corrected.tsv';

umec_neuro = readtable(umec_excel,"VariableNamingRule",'preserve');
megtusalen = readtable(megtusalen_file,'FileType','text');
% 
% vars_megtusalen = {'age','sex','edu_years','BADS_rules_test', 'cog_res','DTS_forward','DTS_backward','GDS_15', ...
%     'LM_imm_units','LM_del_units','LM_imm_them','LM_del_them','MMSE','MOCA','PTF_F','PTF_A','PTF_S', ...
%     'ROCFB_copy', 'ROCFB_memory', 'SFT_animals', 'TMT_A_hits', 'TMT_A_time', 'TMT_B_hits', 'TMT_B_time', ...
%     'word_list_trial1', 'word_list_trial4', 'word_list_learning_total', 'word_list_delayed_recall', 'word_list_recognition'};

vars_megtusalen = {'sex'}; 

vars_umec = {'sexo'}; 

ids = umec_neuro.CodigoCentroPaciente;
n = length(ids);

% Open log file
log_file = ['umec_neuro_validation_log_' vars_megtusalen{1} '.txt'];
fid = fopen(log_file, 'w');

n_updated = 0;
n_not_found = 0;

for i = 1:n
    subject_ok = true;

    % id = string(umec_neuro.CodigoProyecto{i});
    id = ids{i};

    % Find in megtusalen the participant with current id
    meg_row = find(strcmp(megtusalen.recording_id_orig, id), 1);

    if isempty(meg_row)
        warning('Could not find %s\n', id)
        fprintf(fid, 'ID %s: participant not found in megtusalen\n', id);
        n_not_found = n_not_found + 1;
        continue;
    end

    % Make sure that variable value in megtusalen is equal to
    % variable value in umec_neuro
    for ivar = 1:length(vars_umec)

        varname_umec = string(vars_umec{ivar});
        varname_megtusalen = string(vars_megtusalen{ivar});

        umec_val = umec_neuro.(varname_umec)(i);
        meg_val = megtusalen.(varname_megtusalen)(meg_row);

        if iscell(umec_val)
            if isempty(umec_val)
                umec_val = [];
            else
                umec_val = umec_val{1};
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
        if strcmp(varname_umec,'sexo')
            if umec_val == 1
                umec_val = 'm';
            elseif umec_val == 2
                umec_val = 'f';
            end
        end

        % Define missing flags clearly
        umec_missing = isempty(umec_val) || ...
              (isnumeric(umec_val) && isnan(umec_val)) || ...
              (isstring(umec_val) && strlength(umec_val)==0);

        meg_missing = isempty(meg_val) || ...
              (isnumeric(meg_val) && isnan(meg_val)) || ...
              (isstring(meg_val) && strlength(meg_val)==0);


        % Convert umec_val to string safely
        if umec_missing
            umec_str = "NaN";
        else
            umec_str = string(umec_val);
        end

        % Convert meg_val to string safely
        if meg_missing
            meg_str = "NaN";
        else
            meg_str = string(meg_val);
        end

        % Case 1: umec has value and megtusalen is missing → FILL
        if ~umec_missing && meg_missing
            megtusalen.(varname_megtusalen){meg_row} = umec_val;
            n_updated = n_updated + 1;

            fprintf(fid, ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id, varname, umec_str);

        % Case 2: both have values but differ → CORRECT
        elseif ~umec_missing && ~meg_missing && ~isequal(umec_val, meg_val)
            megtusalen.(varname_megtusalen){meg_row} = umec_val;
            n_updated = n_updated + 1;

            fprintf(fid, ...
                'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
                id, varname_megtusalen, meg_str, umec_str);

        % Case 3: umec is missing → do nothing
        elseif umec_missing
            fprintf(fid, ...
                'ID %s, variable %s: skipped (umec_neuro missing, megtusalen=%s)\n', ...
                id, varname_megtusalen, meg_str);
        end


    end

    if subject_ok
        % fprintf(fid, 'ID %s: subject ok\n', id);
    end

end

fclose(fid);
fprintf('Validation finished. Log saved to %s\n', log_file);

writetable(megtusalen, megtusalen_file, 'FileType', 'text', 'Delimiter', '\t');

fprintf('Correction finished.\n');
fprintf('Updated values: %d\n', n_updated);
fprintf('Participants not found: %d\n', n_not_found);
fprintf('Corrected file saved to: %s\n', megtusalen_file);
fprintf('Log saved to: %s\n', log_file);

