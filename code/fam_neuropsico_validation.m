%% Script to compare megtudalen db with familiares original db

clc
clear
close all

%% Script
fam_excel = '../data/source_data/BBDD Conjunta 261 familiares.xlsx';
megtusalen_excel = '../results/participants_megtusalen_fam_corrected.xlsx';
update = true;

fam_neuro = readtable(fam_excel ,'Sheet','Neuropsicología','VariableNamingRule','preserve');
fam_neuro_diag = readtable(fam_excel ,'Sheet','Diagnóstico','VariableNamingRule','preserve');

megtusalen = readtable(megtusalen_excel,'FileType','spreadsheet','VariableNamingRule','preserve');

% Add columns from other sources to fam_neuro
fam_neuro.Diagnostico = fam_neuro_diag.Diagnostico;

vars = struct( ...
    'megtusalen', ...
    {'age','sex','group', 'family_history', 'edu_years','edu_level','occupation', ...
    'BADS_rules_test', 'cog_res','DTS_forward','DTS_backward', ...
    'GDS_15', ...
    'LM_imm_units','LM_del_units','LM_imm_them','LM_del_them','MMSE','MOCA','PTF_F','PTF_A','PTF_S', ...
    'ROCFB_copy', 'ROCFB_memory', 'SFT_animals', 'TMT_A_hits', 'TMT_A_time', 'TMT_B_hits', 'TMT_B_time', ...
    'word_list_trial1', 'word_list_trial4', 'word_list_learning_total', 'word_list_delayed_recall', 'word_list_recognition'}, ...
    'fam', ...
    {'Edad','Sexo','Diagnostico','antec_familia_demenc','numañosescol','Estudios', 'rc_ocupac_labor', ...
    'CReglas_perfil', 'Rc_total','D_directos_total','D_inversos_total', ...
    'GDS', ...
    'ML_total_unid_inm','ML_total_unid_dem','ML_total_temas_inm','ML_total_temas_dem','Pre_MMSE','MOCA','F','A','S', ...
    'Rey_Acopia', 'Rey_Amemoria', 'animales', 'TMTa_a', 'TMTa_t', 'TMTb_a', 'TMTb_t', ...
    'LP_ap_inmediato', 'LP_4intento', 'LP_recuerdoT', 'LP_recuerdo_d', 'LP_reconoc'} ...
    );

id_vars = struct ( 'megtusalen', {'recording_id_orig'}, 'fam' , {'CodigoProyecto'});
ids = fam_neuro.(id_vars(1).fam);
n = length(ids);

n_updated = 0;
n_not_found = 0;

% Loop over variables
for ivar = 1:length(vars)

    % Get variable names for each excel
    varname_megtusalen = vars(ivar).megtusalen;
    varname_fam = vars(ivar).fam;

    % Open log file per variable
    log_file = fullfile('..', 'results', 'logs', ['fam_neuro_validation_log_' varname_megtusalen '.txt']);
    fid = fopen(log_file, 'a');

    fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
    fprintf(fid, 'Variable: %s\n', varname_megtusalen);
    fprintf(fid, 'Updated values: %s\n\n', string(update));

    % Loop over participants in fam
    for i = 1:n

        % Participant id from fam
        id = ids{i};

        % Find in megtusalen the participant with current id
        meg_row = find(strcmp(megtusalen.recording_id_orig, id), 1);

        if isempty(meg_row)
            warning('Could not find %s\n', id)
            fprintf(fid, 'ID %s: participant not found in megtusalen\n', id);
            n_not_found = n_not_found + 1;
            continue;
        end


        % Value for this participant an this variable
        fam_val = fam_neuro.(varname_fam)(i);
        meg_val = megtusalen.(varname_megtusalen)(meg_row);

        % Deal with missing values
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

        % % Deal with 999 values (missing in spss)
        % if fam_val == 999
        %     fam_val = nan;
        % end

        % Convert group variable
        if strcmp(varname_megtusalen,'group')
            switch fam_val
                case 0
                    fam_val = 'FH-';
                case 1
                    fam_val = 'FH+';
            end

        end

        % Convert sex variable
        if strcmp(varname_megtusalen,'sex')
            if fam_val == 1
                fam_val = 'm';
            elseif fam_val == 2
                fam_val = 'f';
            end
        end

        % Convert edu_level
        if strcmp(varname_megtusalen,'edu_level')
            switch fam_val
                case 3
                    fam_val = 2;
                case 4
                    fam_val = 3;
                case 5
                    fam_val = 4;
                otherwise
                    fam_val = nan;
            end
        end


        % Convert occupation
        if strcmp(varname_megtusalen,'occupation')
            switch fam_val
                case 0
                    fam_val = 1;
                case 1
                    fam_val = 2;
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
            if isnumeric(fam_val)
                megtusalen.(varname_megtusalen)(meg_row) = fam_val;
            else
                megtusalen.(varname_megtusalen){meg_row} = fam_val;
            end
            n_updated = n_updated + 1;

            fprintf(fid, ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id, varname_megtusalen, fam_str);

            % Case 2: both have values but differ → CORRECT
        elseif ~fam_missing && ~meg_missing && ~isequal(fam_val, meg_val)
            if isnumeric(fam_val)
                megtusalen.(varname_megtusalen)(meg_row) = fam_val;
            else
                megtusalen.(varname_megtusalen){meg_row} = fam_val;
            end
            n_updated = n_updated + 1;

            fprintf(fid, ...
                'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
                id, varname_megtusalen, meg_str, fam_str);

            % Case 3: fam is missing → do nothing
        elseif fam_missing
            fprintf(fid, ...
                'ID %s, variable %s: skipped (fam_neuro missing, megtusalen=%s)\n', ...
                id, varname_megtusalen, meg_str);
        end

    end

    fclose(fid);

end

fprintf('Validation finished.\n');

if update
    writetable(megtusalen, megtusalen_excel, 'FileType', 'spreadsheet');

    fprintf('Correction finished.\n');
    fprintf('Updated values: %d\n', n_updated);
    fprintf('Participants not found: %d\n', n_not_found);
    fprintf('Corrected file saved to: %s\n', megtusalen_excel);
    fprintf('Log saved to: %s\n', log_file);
end

fprintf('Validation finished.\n');

%%

% Check participants in megtusalen not in fam
all_meg_ids = string(megtusalen.recording_id_orig);
is_fam = startsWith(all_meg_ids, 'FAM');
meg_ids = all_meg_ids(is_fam);

fam_ids = string(fam_neuro.CodigoProyecto);

n_not_in_fam = 0;

for j = 1:length(meg_ids)
    meg_id = meg_ids(j);

    if ~any(strcmp(fam_ids, meg_id))
        fprintf('ID %s: present in megtusalen but NOT in fam_neuro\n', meg_id);
        n_not_in_fam = n_not_in_fam + 1;
    end
end
sprintf('Participants in megtusalen not in fam: %d\n', n_not_in_fam)

% % Add summary comparisons to the log file
% summary_lines = {
%     sprintf('Comparison: %s vs %s', fam_gen_excel, megtusalen_excel)
%     sprintf('Variable to compare: %s', varname_megtusalen)
%     sprintf('Date: %s', datestr (datetime('now', 'Format', 'dd mmm yyyy  HH:mm:ss')))
%     sprintf('Updated values: %d', n_updated)
%     sprintf('Participants not found: %d', n_not_found)
%     sprintf('Participants in megtusalen not in fam: %d', n_not_in_fam)
%     '----------------------------------------'  % separador
%     };
% fid = fopen(log_file, 'w');  % abre para escribir (sobrescribe)
% for k = 1:length(summary_lines)
%     fprintf(fid, '%s\n', summary_lines{k});
% end
% for k = 1:length(log_lines)
%     fprintf(fid, '%s\n', log_lines{k});
% end
% fclose(fid);
% 
% % writetable(megtusalen, out_file, 'FileType', 'text', 'Delimiter', '\t');      % for -tsv
% writetable(megtusalen, megtusalen_file);
% 
% fprintf('Correction finished.\n');
% fprintf('Updated values: %d\n', n_updated);
% fprintf('Participants not found: %d\n', n_not_found);
% fprintf('Participants in megtusalen not in fam: %d\n', n_not_in_fam);
% fprintf('Corrected file saved to: %s\n', megtusalen_excel);
% fprintf('Log saved to: %s\n', log_file);

