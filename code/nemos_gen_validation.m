%% Script to compare megtusalen db with nemos original db
% Excel de referencia NEMOS: Base de Datos Proyecto NEMOS para MEGTUSALEN 17.03.26 .xlsx
%  Renombro a mano nombres de las columnas del excel para quitar tildes y ñ


function megtusalen = nemos_gen_validation(megtusalen,nemos_gen_excel, update)

% nemos_gen_excel = '../data/source_data/Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx';
% megtusalen_excel = '../results2/participants_megtusalen_nemos_corrected.xlsx';
out_file = '../results/participants_megtusalen_nemos_corrected.xlsx';
% update = true;

nemos_gen = readtable(nemos_gen_excel ,'Sheet','Datos','VariableNamingRule','preserve');
% megtusalen = readtable(megtusalen_excel);

vars_megtusalen = {'APOE','ERBB4','BDNF','NRG1','CR1','COMT','CLU','ACT','BACE1','CHRNA7','PICALM'};

% Match vars name with nemos_gen cols:
vars_nemos = cell(1,length(vars_megtusalen));
for i = 1:length(vars_megtusalen)
    col_match = find(contains(nemos_gen.Properties.VariableNames, vars_megtusalen{i}));
    if ~isempty(col_match)
        vars_nemos{i} = nemos_gen.Properties.VariableNames{col_match(1)};
    else
        warning('Variable %s not found in nemos_gen', vars_megtusalen{i});
        vars_nemos{i} = ''; % o NaN, según prefieras
    end
end

vars = struct('megtusalen',vars_megtusalen,'nemos',vars_nemos);

% Unify ID Codes
nemos_gen.IDcorrected = sprintfc('NEMOS-%03d', nemos_gen.ID_MEG);
nemos_gen = movevars(nemos_gen, 'IDcorrected', 'Before', 1);

% Unify NaN values --> change 1000 por NaN
vars_num = varfun(@isnumeric, nemos_gen, 'OutputFormat', 'uniform');
nemos_gen{:, vars_num}(nemos_gen{:, vars_num} == 1000) = NaN;

id_vars = struct ( 'megtusalen', {'participant_id'}, 'nemos' , {'IDcorrected'});
ids = nemos_gen.(id_vars(1).nemos);
n = length(ids);

% Variables string / cellstr / char
vars_str = varfun(@(x) isstring(x) || iscellstr(x) || ischar(x), ...
    nemos_gen, 'OutputFormat', 'uniform');

for i = find(vars_str)
    col = nemos_gen{:, i};

    if isstring(col)
        % Mantiene tipo string
        col(col == "1000") = missing;

    elseif iscellstr(col)
        % Mantiene cell array de char
        idx = strcmp(col, '1000');
        col(idx) = {''};   % o {'NaN'} si prefieres explícito

    elseif ischar(col)
        % Convertimos temporalmente a cellstr para trabajar
        tmp = cellstr(col);
        tmp(strcmp(tmp, '1000')) = {''};
        col = char(tmp);   % volvemos a char

    end

    nemos_gen{:, i} = col;
end

n_filled = 0;
n_corrected = 0;
n_not_found = 0;

for ivar = 1:length(vars)

    % Get variable names for each excel
    varname_megtusalen = vars(ivar).megtusalen;
    varname_nemos = vars(ivar).nemos;

    % Open log file per variable
    log_file = fullfile('..', 'results', 'logs', ['nemos_gen_validation_log_' varname_megtusalen '.txt']);
    fid = fopen(log_file, 'w');

    fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
    fprintf(fid, 'Variable: %s\n', varname_megtusalen);
    fprintf(fid, 'Updated values: %s\n\n', string(update));


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

        % Value for this participant and this variable
        nemos_val = nemos_gen.(varname_nemos)(i);
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
                megtusalen.(varname_megtusalen){meg_row} = nemos_val;
            elseif iscategorical(megtusalen.(varname_megtusalen)) || isstring(megtusalen.(varname_megtusalen)) || isnumeric(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen)(meg_row) = nemos_val;
            end

            n_filled = n_filled + 1;

            fprintf(fid, ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id, varname_megtusalen, nemos_str);

            % Case 2: both have values but differ → CORRECT
        elseif ~nemos_missing && ~meg_missing && ~isequal(nemos_val, meg_val)

            if iscell(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen){meg_row} = nemos_val;
            elseif iscategorical(megtusalen.(varname_megtusalen)) || isstring(megtusalen.(varname_megtusalen)) || isnumeric(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen)(meg_row) = nemos_val;
            end

            n_corrected = n_corrected + 1;

            fprintf(fid, ...
                'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
                id, varname_megtusalen, meg_str, nemos_str);

            % Case 3: nemos is missing → do nothing
        elseif nemos_missing
            fprintf(fid, ...
                'ID %s, variable %s: skipped (nemos_gen missing, megtusalen=%s)\n', ...
                id, varname_megtusalen, meg_str);
        end


    end
            fclose(fid);


end



% Create summary log file
log_file = fullfile('..', 'results', 'logs', 'nemos_gen_validation_log_summary.txt');
fid = fopen(log_file, 'w');

% Check participants in megtusalen not in nemos
all_meg_ids = string(megtusalen.(id_vars(1).megtusalen));
is_nemos = startsWith(all_meg_ids, 'nemos');
meg_ids = all_meg_ids(is_nemos);
nemos_ids = string(nemos_gen.(id_vars(1).nemos));

n_not_in_nemos = 0;

for j = 1:length(meg_ids)
    meg_id = meg_ids(j);

    if ~any(strcmp(nemos_ids, meg_id))
        fprintf('ID %s: present in megtusalen but NOT in nemos_gen\n', meg_id);
        n_not_in_nemos = n_not_in_nemos + 1;
    end
end
sprintf('Participants in megtusalen not in nemos: %d\n', n_not_in_nemos);

% Add summary comparisons to the log file
fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
fprintf(fid, 'Updated values: %s\n\n', string(update));

fprintf(fid,'Comparison: %s vs megtusalen_nemos_corrected\n', nemos_gen_excel);
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