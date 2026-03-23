%% Script to compare megtusalen db with nemos original db
% Excel de referencia NEMOS: Base de Datos Proyecto NEMOS para MEGTUSALEN 17.03.26 .xlsx
%  Renombro a mano nombres de las columnas del excel para quitar tildes y ñ

function megtusalen = nemos_neuropsico_validation(megtusalen,nemos_neuro_excel, update)

% nemos_excel = '../data/source_data/Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx';
% megtusalen_excel = '../results2/participants_megtusalen_nemos_corrected.xlsx';
out_file = '../results2/participants_megtusalen_nemos_corrected.xlsx';
% update = true;

nemos_neuro = readtable(nemos_neuro_excel ,'Sheet','Datos');
% megtusalen = readtable(megtusalen_excel);

vars = struct( ...
    'megtusalen', ...
    {'age','sex','group', 'converter', 'conversion_time', 'edu_years', 'edu_level_nemos', 'occupation_nemos' ...
    'BADS_rules_test', 'BNT_spon', 'BNT_phon', 'clock_drawing', 'DTS_forward','DTS_backward', ...
    'FAQ', 'GDS_15', 'imitation_gestures', ...
    'LM_imm_units','LM_del_units','LM_imm_them','LM_del_them',...
    'MMSE','PTF_F','PTF_A','PTF_S', 'PTF', ...
    'SFT_animals', 'SFT_fruits',  ...
    'TMT_A_errors', 'TMT_A_time', 'TMT_B_errors', 'TMT_B_time', ...
    }, ...
    'nemos', ...
    {'Edad','Sexo','Diagnostico', 'Conversores', 'TiempoConversionEnMeses', 'EduYears', 'NivelDeEstudios', 'Ocupacion'...
    'CambioDeReglas', 'BNT', 'BNT_ClaveFon', 'RELOJ_Orden', 'DIGITOS_Directos', 'DIGITOS_Inversos', ...
    'FAQ', 'GDS', 'ImitacionDePosturas', ...
    'TEXTOS_UnidInmediatas', 'TEXTOS_UnidDemoradas', 'TEXTOS_TemRecInmed', 'TEXTOS_TemRecDemor', ...
    'MMSE', 'F', 'A', 'S', 'FASPromedioFonologico', ...
    'Animales', 'Frutas',  ...
    'TMT_A_Errores', 'TMT_A_Tiempo', 'TMT_B_Errores', 'TMT_B_Tiempo', ...
    });

% Unify ID Codes  in nemos
nemos_neuro.IDcorrected = sprintfc('NEMOS-%03d', nemos_neuro.IDMEG);
nemos_neuro = movevars(nemos_neuro, 'IDcorrected', 'Before', 1);

% Unify NaN values --> change 1000 por NaN
nan_val = varfun(@isnumeric, nemos_neuro, 'OutputFormat', 'uniform');
nemos_neuro{:, nan_val}(nemos_neuro{:, nan_val} == 1000) = NaN;

id_vars = struct ( 'megtusalen', {'participant_id'}, 'nemos' , {'IDcorrected'});
ids = nemos_neuro.(id_vars(1).nemos);
n = length(ids);


% % Open log file
% log_file = ['../results2/logs/nemos_neuro_validation_log_' vars_megtusalen{1} '.txt'];  % overwrites preexisting logs
% fid = fopen(log_file, 'w');
%
% log_lines = {};  % cell array vacío para guardar todas las líneas
%
n_filled = 0;
n_corrected = 0;
n_not_found = 0;

for ivar = 1:length(vars)

    % Get variable names for each excel
    varname_megtusalen = vars(ivar).megtusalen;
    varname_nemos = vars(ivar).nemos;

    % Open log file per variable
    log_file = fullfile('..', 'results', 'logs', ['nemos_neuro_validation_log_' varname_megtusalen '.txt']);
    fid = fopen(log_file, 'w');

    fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
    fprintf(fid, 'Variable: %s\n', varname_megtusalen);
    fprintf(fid, 'Updated values: %s\n\n', string(update));

    % Deal with typos in Diagnostico variable
    if strcmp(varname_nemos,'Diagnostico')
        % Remove blank spaces
        nemos_neuro.Diagnostico = strtrim(nemos_neuro.Diagnostico);
        % Remove ' duplicated
        nemos_neuro.Diagnostico = strrep(nemos_neuro.Diagnostico, '''', '');
    end

    for i = 1:n

        id = ids{i};

        % Find in megtusalen the participant with current id
        meg_row = find(strcmp(megtusalen.(id_vars(1).megtusalen), id), 1);

        if isempty(meg_row)
            warning('Could not find %s\n', id)
            fprintf(fid, 'ID %s: participant not found in megtusalen\n', id);
            n_not_found = n_not_found + 1;
            continue;
        end

        % Value for this participant an this variable
        nemos_val = nemos_neuro.(varname_nemos)(i);
        meg_val = megtusalen.(varname_megtusalen)(meg_row);

        % Deal with missing values
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

        % Adjust edu_years to max 20
        if strcmp(varname_nemos,'EduYears')
            if nemos_val > 20
                nemos_val = 20;
            end
        end

        % convert group variable
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

            n_filled = n_filled + 1;

            fprintf(fid, ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id, varname_megtusalen, nemos_str);

        % Case 2: both have values but differ → CORRECT
        elseif ~nemos_missing && ~meg_missing && ~isequal(nemos_val, meg_val)
            
            if isnumeric(nemos_val)
                megtusalen.(varname_megtusalen)(meg_row) = nemos_val;
            else
                megtusalen.(varname_megtusalen){meg_row} = nemos_val;
            end
            n_corrected = n_corrected + 1;

            fprintf(fid, ...
                'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
                id, varname_megtusalen, meg_str, nemos_str);

            % Case 3: nemos is missing → do nothing
        elseif nemos_missing
            fprintf(fid, ...
                'ID %s, variable %s: skipped (nemos_neuro missing, megtusalen=%s)\n', ...
                id, varname_megtusalen, meg_str);
        end


    end
        fclose(fid);


end


% Create summary log file
log_file = fullfile('..', 'results', 'logs', 'nemos_neuro_validation_log_summary.txt');
fid = fopen(log_file, 'w');

% Check participants in megtusalen not in nemos
all_meg_ids = string(megtusalen.(id_vars(1).megtusalen));
is_nemos = startsWith(all_meg_ids, 'nemos');
meg_ids = all_meg_ids(is_nemos);
nemos_ids = string(nemos_neuro.(id_vars(1).nemos));

n_not_in_nemos = 0;

for j = 1:length(meg_ids)
    meg_id = meg_ids(j);

    if ~any(strcmp(nemos_ids, meg_id))
        fprintf('ID %s: present in megtusalen but NOT in nemos_neuro\n', meg_id);
        n_not_in_nemos = n_not_in_nemos + 1;
    end
end
sprintf('Participants in megtusalen not in nemos: %d\n', n_not_in_nemos);

% Add summary comparisons to the log file
fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
fprintf(fid, 'Updated values: %s\n\n', string(update));

fprintf(fid,'Comparison: %s vs megtusalen_nemos_corrected\n', nemos_neuro_excel);
fprintf(fid,'Filled values: %d\n', n_filled);
fprintf(fid,'Corrected values: %d\n', n_corrected);
fprintf(fid,'Participants not found: %d\n', n_not_found);
fprintf(fid,'Participants in megtusalen not in nemos: %d\n\n\n', n_not_in_nemos);

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

fprintf('Validation finished.\n');

end