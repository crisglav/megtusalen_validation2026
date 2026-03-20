%% Script to compare megtusalen db with nemos original db
% Excel de referencia NEMOS: Base de Datos Proyecto NEMOS para MEGTUSALEN 17.03.26 .xlsx
%  Renombro a mano nombres de las columnas del excel para quitar tildes y ñ

clc
clear
close all

%% Initital creation of participants_megtusalen_corrected.tsv
% megtusalen_excel = '../data/participants_megtusalen.xlsx';
% out_file = '../results/participants_megtusalen_nemos_corrected.xlsx';
% megtusalen = readtable(megtusalen_excel);
% writetable(megtusalen, out_file);

%% Script
nemos_excel = '../data/source_data/Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx';
megtusalen_excel = '../results/participants_megtusalen_nemos_corrected.xlsx';
out_file = '../results/participants_megtusalen_nemos_corrected.xlsx';
update = true;

nemos_neuro = readtable(nemos_excel ,'Sheet','Datos');
megtusalen = readtable(megtusalen_excel);


% vars_megtusalen = {'age','sex','edu_years','BADS_rules_test', 'cog_res','DTS_forward','DTS_backward','GDS_15', ...
%     'LM_imm_units','LM_del_units','LM_imm_them','LM_del_them','MMSE','MOCA','PTF_F','PTF_A','PTF_S', ...
%     'ROCFB_copy', 'ROCFB_memory', 'SFT_animals', 'TMT_A_hits', 'TMT_A_time', 'TMT_B_hits', 'TMT_B_time', ...
%     'word_list_trial1', 'word_list_trial4', 'word_list_learning_total', 'word_list_delayed_recall', 'word_list_recognition'};

% vars_megtusalen = {'edu_years', 'edu_level', 'occupation'};
vars_megtusalen = {'sex'};

% vars_nemos = {'EduYears', 'NivelDeEstudios', 'Ocupacion'};
vars_nemos = {'Sexo'};

% Unify ID Codes
nemos_neuro.IDcorrected = sprintfc('NEMOS-%03d', nemos_neuro.IDMEG);
nemos_neuro = movevars(nemos_neuro, 'IDcorrected', 'Before', 1);

%Unify NaN values --> change 1000 por NaN
vars = varfun(@isnumeric, nemos_neuro, 'OutputFormat', 'uniform');
nemos_neuro{:, vars}(nemos_neuro{:, vars} == 1000) = NaN;

ids = nemos_neuro.IDcorrected;
n = length(ids);

% Open log file
log_file = ['../results/logs/nemos_neuro_validation_log_' vars_megtusalen{1} '.txt'];  % overwrites preexisting logs
fid = fopen(log_file, 'w');

log_lines = {};  % cell array vacío para guardar todas las líneas

n_updated = 0;
n_not_found = 0;

for i = 1:n
    subject_ok = true;

    id = string(nemos_neuro.IDcorrected{i});

    % Find in megtusalen the participant with current id
    meg_row = find(strcmp(megtusalen.participant_id, id), 1);

    if isempty(meg_row)
        warning('Could not find %s\n', id)
        log_lines{end+1} = sprintf( 'ID %s: participant not found in megtusalen\n', id);
        n_not_found = n_not_found + 1;
        continue;
    end

    % Make sure that variable value in megtusalen is equal to variable value in nemos_neuro
    for ivar = 1:length(vars_nemos)

        varname_nemos = string(vars_nemos{ivar});
        varname_megtusalen = string(vars_megtusalen{ivar});

        nemos_val = nemos_neuro.(varname_nemos)(i);
        if iscell(megtusalen.(varname_megtusalen))
            meg_val = megtusalen.(varname_megtusalen){meg_row};  % cell → usar {}
        elseif iscategorical(megtusalen.(varname_megtusalen)) || isstring(megtusalen.(varname_megtusalen)) || isnumeric(megtusalen.(varname_megtusalen))
            meg_val = megtusalen.(varname_megtusalen)(meg_row);  % otros → usar ()
        else
            error('Tipo de columna no soportado: %s', class(megtusalen.(varname_megtusalen)));
        end
        

        if iscell(nemos_val)
            if isempty(nemos_val)
                nemos_val = [];
            else
                nemos_val = nemos_val{1};
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
        if strcmp(varname_nemos,'Sexo')
            if nemos_val == 1
                nemos_val = 'm';
            elseif nemos_val == 2
                nemos_val = 'f';
            end
        end

        % Convert group variable
            % Quitar espacios en blanco
            nemos_neuro.Diagnostico = strtrim(nemos_neuro.Diagnostico);
            % Quitar comillas simples sobrantes
            nemos_neuro.Diagnostico = strrep(nemos_neuro.Diagnostico, '''', '');

        if strcmp(varname_nemos,'Diagnostico')
            if strcmp(nemos_val,'DCLa')
                nemos_val = 'MCIa';
            elseif strcmp(nemos_val,'DCLm')
                nemos_val = 'MCIm';
            elseif strcmp(nemos_val,'Control')
                nemos_val = 'MCI-';
            elseif strcmp(nemos_val,'EA')
                nemos_val = 'AD';
            end
        end

        % Define missing flags clearly
        nemos_missing = isempty(nemos_val) || ...
            (isnumeric(nemos_val) && isnan(nemos_val)) || ...
            (isstring(nemos_val) && strlength(nemos_val)==0);

        meg_missing = isempty(meg_val) || ...
            (isnumeric(meg_val) && isnan(meg_val)) || ...
            (isstring(meg_val) && strlength(meg_val)==0);


        % Convert nemos_val to string safely
        if nemos_missing
            nemos_str = "NaN";
        else
            nemos_str = string(nemos_val);
        end

        % Convert meg_val to string safely
        if meg_missing
            meg_str = "NaN";
        else
            meg_str = string(meg_val);
        end

        % Case 1: nemos has value and megtusalen is missing → FILL
        if ~nemos_missing && meg_missing
           
            if iscell(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen){meg_row} = nemos_val; % cell → usar {}
            elseif iscategorical(megtusalen.(varname_megtusalen)) || isstring(megtusalen.(varname_megtusalen)) || isnumeric(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen)(meg_row) = nemos_val;% otros → usar ()
            else
                error('Tipo de columna no soportado: %s', class(megtusalen.(varname_megtusalen)));
             end

            n_updated = n_updated + 1;

            log_lines{end+1} = sprintf( ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id, varname_megtusalen, nemos_str);

            % Case 2: both have values but differ → CORRECT
        elseif ~nemos_missing && ~meg_missing && ~isequal(nemos_val, meg_val)

            if iscell(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen){meg_row} = nemos_val; % cell → usar {}
            elseif iscategorical(megtusalen.(varname_megtusalen)) || isstring(megtusalen.(varname_megtusalen)) || isnumeric(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen)(meg_row) = nemos_val;% otros → usar ()
            else
                error('Tipo de columna no soportado: %s', class(megtusalen.(varname_megtusalen)));
             end

            n_updated = n_updated + 1;

            log_lines{end+1} = sprintf( ...
                'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
                id, varname_megtusalen, meg_str, nemos_str);

            % Case 3: nemos is missing → do nothing
        elseif nemos_missing
            log_lines{end+1} = sprintf( ...
                'ID %s, variable %s: skipped (nemos_neuro missing, megtusalen=%s)\n', ...
                id, varname_megtusalen, meg_str);
        end


    end

    if subject_ok
        % log_lines{end+1} = sprintf( 'ID %s: subject ok\n', id);
    end

end


% Check participants in megtusalen not in nemos
all_meg_ids = string(megtusalen.participant_id);
is_nemos = startsWith(all_meg_ids, 'NEMOS');
meg_ids = all_meg_ids(is_nemos);

nemos_ids = string(nemos_neuro.IDcorrected);

n_not_in_nemos = 0;

for j = 1:length(meg_ids)
    meg_id = meg_ids(j);

    if ~any(strcmp(nemos_ids, meg_id))
        log_lines{end+1} = sprintf( 'ID %s: present in megtusalen but NOT in nemos_neuro\n', meg_id);
        n_not_in_nemos = n_not_in_nemos + 1;
    end
end

fprintf('Validation finished. Log saved to %s\n', log_file);

% Add summary comparisons to the log file
summary_lines = {
    sprintf('Comparison: %s vs %s', nemos_excel, megtusalen_excel)
    sprintf('Variable to compare: %s', varname_megtusalen)
    sprintf('Date: %s', datestr (datetime('now', 'Format', 'dd mmm yyyy  HH:mm:ss')))
    sprintf('Updated excel: %s', string(update))
    sprintf('Updated values: %d', n_updated)
    sprintf('Participants not found: %d', n_not_found)
    sprintf('Participants in megtusalen not in nemos: %d', n_not_in_nemos)
    '----------------------------------------'  % separador
    };
fid = fopen(log_file, 'w');  % abre para escribir (sobrescribe)
for k = 1:length(summary_lines)
    fprintf(fid, '%s\n', summary_lines{k});
end
for k = 1:length(log_lines)
    fprintf(fid, '%s\n', log_lines{k});
end
fclose(fid);

if update
% writetable(megtusalen, out_file, 'FileType', 'text', 'Delimiter', '\t');      % for -tsv
writetable(megtusalen, out_file);
end 

fprintf('Correction finished.\n');
fprintf('Updated excel: %s\n', string(update));
fprintf('Updated values: %d\n', n_updated);
fprintf('Participants not found: %d\n', n_not_found);
fprintf('Participants in megtusalen not in nemos: %d\n', n_not_in_nemos);
fprintf('Corrected file saved to: %s\n', out_file);
fprintf('Log saved to: %s\n', log_file);

