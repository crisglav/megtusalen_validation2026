fam_gen_excel = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\source_data\familiares_neuropsicologia.xlsx';
megtusalen_excel = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\participants_megtusalen.xlsx';

fam_neuro = readtable(fam_gen_excel);
megtusalen = readtable(megtusalen_excel);
% 
% neuro_vars = {'age','sex','edu_years','BADS_rules_test', 'cog_res','DTS_forward','DTS_backward','GDS_15', ...
%     'LM_imm_units','LM_del_units','LM_imm_them','LM_del_them','MMSE','MOCA','PTF_F','PTF_A','PTF_S', ...
%     'ROCFB_copy', 'ROCFB_memory', 'SFT_animals', 'TMT_A_hits', 'TMT_A_time', 'TMT_B_hits', 'TMT_B_time', ...
%     'word_list_trial1', 'word_list_trial4', 'word_list_learning_total', 'word_list_delayed_recall', 'word_list_recognition'};

neuro_vars = {'age'}; 

ids = fam_neuro.CodigoID;
n = length(ids);

% Open log file
log_file = 'neuro_validation_log.txt';
fid = fopen(log_file, 'w');

for i = 1:n
    subject_ok = true;

    id = string(fam_neuro.CodigoID{i});

    % Find in megtusalen the participant with current id
    meg_row = find(strcmp(megtusalen.recording_id_orig, id), 1);

    if isempty(meg_row)
        warning('Could not find %s\n', id)
        fprintf(fid, 'ID %s: participant not found in megtusalen\n', id);
        continue;
    end

    % Make sure that variable value in megtusalen is equal to
    % variable value in fam_neuro
    for ivar = 1:length(neuro_vars)

        varname = string(neuro_vars{ivar});

        fam_val = fam_neuro.(varname)(i);
        meg_val = megtusalen.(varname)(meg_row);


        % Convert fam_val to string safely
        if ismissing(fam_val) || (isnumeric(fam_val) && isnan(fam_val))
            fam_str = "NaN";
        else
            fam_str = string(fam_val);
        end

        % Convert meg_val to string safely
        if ismissing(meg_val) || (isnumeric(meg_val) && isnan(meg_val))
            meg_str = "NaN";
        else
            meg_str = string(meg_val);
        end

        if strcmp(fam_str,'NaN') && strcmp(meg_str,'NaN')
            continue
        end


        % Print to a log file if it is not equal or if one of the values is missing
        if ismissing(fam_val) || ismissing(meg_val)
            subject_ok = false;

            fprintf(fid, 'ID %s, variable %s: missing value(s) - fam_neuro=%s, megtusalen=%s\n', id, varname, fam_str, meg_str);

        elseif ~isequal(fam_val, meg_val)
            subject_ok = false;

            fprintf(fid, 'ID %s, variable %s: mismatch - fam_neuro=%s, megtusalen=%s\n', ...
                id, varname, fam_str, meg_str);  
        end


    end

    if subject_ok
        fprintf(fid, 'ID %s: subject ok\n', id);
    end

end

fclose(fid);
fprintf('Validation finished. Log saved to %s\n', log_file);




