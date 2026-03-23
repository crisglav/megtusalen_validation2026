% clear all
% close all

function megtusalen = umec_neuropsico_validation(megtusalen,umec_neuro_excel, update)

% umec_excel = '../data/source_data/UMEC_DAVID.csv';
% megtusalen_excel = '../results/participants_megtusalen_umec_corrected.xlsx';
% update = true;
out_file = '../results/participants_megtusalen_umec_corrected.xlsx';

umec_neuro = readtable(umec_neuro_excel,'VariableNamingRule','preserve');
% megtusalen = readtable(megtusalen_excel,'FileType','spreadsheet','VariableNamingRule','preserve');

vars = struct( ...
    'megtusalen', ...
    {'age','sex','group','conversion_time', 'family_history', 'edu_years','edu_level_umec','occupation_umec', ...
    'BADS_rules_test', 'BNT_spon', 'BNT_phon', 'BNT_sem', 'clock_drawing', 'cog_res','DST_forward','DST_backward', ...
    'FAQ', 'GDS_15', 'imitation_gestures', ...
    'LM_imm_units','LM_del_units','LM_imm_them','LM_del_them','MMSE','PFT_F','PFT_A','PFT_S', ...
    'ROCFB_simp_copy', 'ROCFB_simp_mem', 'SFT_animals', 'SFT_fruits', 'SFT_names', 'TMT_A_errors','TMT_A_time', 'TMT_B_errors', 'TMT_B_time', ...
    'word_list_trial1', 'word_list_trial4', 'word_list_learning_total', 'word_list_delayed_recall', 'word_list_recognition'}, ...
    'umec', ...
    {'Edad','sexo','Diagnostico','T_Conversion','antec_familia_demenc','numanosescol','Estudios', 'rc_ocupac_labor', ...
    'Pre_CReglas_perfil', 'Pre_BNT_r_espontaneas', 'Pre_BNT_clave_f', 'Pre_BNT_clave_s', 'Pre_sieteM_reloj', 'Rc_total','Pre_D_directos_total','Pre_D_inversos_total', ...
    'Pre_FAQ', 'Pre_GDS', 'Pre_imitac_posturas', ...
    'Pre_ML_total_unid_inm','Pre_ML_total_unid_dem','Pre_ML_total_temas_inm','Pre_ML_total_temas_dem','Pre_MMSE','Pre_F','Pre_A','Pre_S', ...
    'Pre_Rey_copia', 'Pre_Rey_memoria', 'Pre_animales', 'Pre_frutas', 'Pre_nombres', 'Pre_TMTa_e', 'Pre_TMTa_t', 'Pre_TMTb_e','Pre_TMTb_t', ...
    'Pre_LP_ap_inmediato', 'Pre_LP_4intento', 'Pre_LP_recuerdoT', 'Pre_LP_recuerdo_d', 'Pre_LP_reconoc'} );

id_vars = struct ( 'megtusalen', {'recording_id_orig'}, 'umec' , {'CodigoCentroPaciente'});
ids = umec_neuro.(id_vars(1).umec);
n = length(ids);

n_filled = 0;
n_corrected = 0;
n_not_found = 0;

% Loop over variables
for ivar = 1:length(vars)

    % Get variable names for each excel
    varname_megtusalen = vars(ivar).megtusalen;
    varname_umec = vars(ivar).umec;

    % Open log file per variable
    log_file = fullfile('..', 'results', 'logs', ['umec_neuro_validation_log_' varname_megtusalen '.txt']);
    fid = fopen(log_file, 'w');

    fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
    fprintf(fid, 'Variable: %s\n', varname_megtusalen);
    fprintf(fid, 'Updated values: %s\n\n', string(update));

    % Loop over participants in umec
    for i = 1:n

        % Participant id from umec
        id = ids{i};

        % Find in megtusalen the participant with current id
        meg_row = find(strcmp(megtusalen.recording_id_orig, id), 1);

        if isempty(meg_row)
            warning('Could not find %s\n', id)
            fprintf(fid, 'ID %s: participant not found in megtusalen\n', id);
            n_not_found = n_not_found + 1;
            continue;
        end


        % Value for this participant and this variable
        umec_val = umec_neuro.(varname_umec)(i);
        meg_val = megtusalen.(varname_megtusalen)(meg_row);

        % Deal with missing values
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

        % Deal with 999 values (missing in spss)
        if umec_val == 999
            umec_val = nan;
        end

        % Convert group variable
        if strcmp(varname_megtusalen,'group')
            switch umec_val
                case 1
                    umec_val = 'SCD-';
                case 2
                    umec_val = 'SCD+';
                case 3
                    umec_val = 'MCIa';
            end

        end

        % Convert sex variable
        if strcmp(varname_megtusalen,'sex')
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
            if isnumeric(umec_val)
                megtusalen.(varname_megtusalen)(meg_row) = umec_val;
            else
                megtusalen.(varname_megtusalen){meg_row} = umec_val;
            end
            n_filled = n_filled + 1;

            fprintf(fid, ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id, varname_megtusalen, umec_str);

            % Case 2: both have values but differ → CORRECT
        elseif ~umec_missing && ~meg_missing && ~isequal(umec_val, meg_val)
            if isnumeric(umec_val)
                megtusalen.(varname_megtusalen)(meg_row) = umec_val;
            else
                megtusalen.(varname_megtusalen){meg_row} = umec_val;
            end
            n_corrected = n_corrected + 1;

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

    fclose(fid);

end

% Create summary log file
log_file = fullfile('..', 'results', 'logs', 'umec_neuro_validation_log_summary.txt');
fid = fopen(log_file, 'w');

% Check participants in megtusalen not in umec
all_meg_ids = string(megtusalen.(id_vars(1).megtusalen));
is_umec = startsWith(all_meg_ids, 'UMEC');
meg_ids = all_meg_ids(is_umec);
umec_ids = string(umec_neuro.(id_vars(1).umec));

n_not_in_umec = 0;

for j = 1:length(meg_ids)
    meg_id = meg_ids(j);

    if ~any(strcmp(umec_ids, meg_id))
        fprintf('ID %s: present in megtusalen but NOT in umec_neuro\n', meg_id);
        n_not_in_umec = n_not_in_umec + 1;
    end
end
sprintf('Participants in megtusalen not in umec: %d\n', n_not_in_umec);

% Add summary comparisons to the log file
fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
fprintf(fid, 'Updated values: %s\n\n', string(update));

fprintf(fid,'Comparison: %s vs megtusalen_umec_corrected\n', umec_neuro_excel);
fprintf(fid,'Filled values: %d\n', n_filled);
fprintf(fid,'Corrected values: %d\n', n_corrected);
fprintf(fid,'Participants not found: %d\n', n_not_found);
fprintf(fid,'Participants in megtusalen not in umec: %d\n\n\n', n_not_in_umec);

fclose(fid);

fprintf('Validation finished.\n');
if update
    writetable(megtusalen, out_file, 'FileType', 'spreadsheet');

    fprintf('Correction finished.\n');
    fprintf('Filled values: %d\n', n_filled);
    fprintf('Corrected values: %d\n', n_corrected);
    fprintf('Participants not found: %d\n', n_not_found);
    fprintf('Corrected file saved to: %s\n', out_file);
end
end