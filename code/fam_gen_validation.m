%% Script to compare megtusalen db with familiares original db
% Genética: cambio a mano el excel BBDD Conjunta 261 familiares:
%            col: APOEHaplotipo --> elimino epsilon
%            col: AACT_rs4934 --> cambio Thr por T y Ala por A. ( no hay G ni C)
%            reordeno a mano cols de genética BBDD Conjunta 261 familiares para que aparezcan igual que en megtusalen.

function megtusalen = fam_gen_validation(megtusalen,fam_gen_excel, update)

% fam_gen_excel = '../data/source_data/BBDD Conjunta 261 familiares.xlsx';
% megtusalen_excel = '../data/participants_megtusalen.xlsx';
out_file = '../results/participants_megtusalen_fam_corrected.xlsx';
% update = true;
% 
fam_gen = readtable(fam_gen_excel ,'Sheet','Genética','VariableNamingRule','preserve');
% megtusalen = readtable(megtusalen_excel);

vars_megtusalen = {'APOE','ERBB4','BDNF','NRG1','CR1','COMT','CLU','ACT','BACE1','CHRNA7','PICALM'};

% Match vars name with fam_gen cols:
vars_fam = cell(1,length(vars_megtusalen));

for i = 1:length(vars_megtusalen)
    col_match = find(contains(fam_gen.Properties.VariableNames, vars_megtusalen{i},'IgnoreCase', true));
    if ~isempty(col_match)
        vars_fam{i} = fam_gen.Properties.VariableNames{col_match(1)};
    else
        warning('Variable %s not found in fam_gen', vars_megtusalen{i});
        vars_fam{i} = ''; % o NaN, según prefieras
    end
end

vars = struct('megtusalen',vars_megtusalen,'fam',vars_fam);

id_vars = struct ( 'megtusalen', {'recording_id_orig'}, 'fam' , {'CodigoProyecto'});
ids = fam_gen.(id_vars(1).fam);
n = length(ids);

n_filled = 0;
n_corrected = 0;
n_not_found = 0;

% Loop over variables
for ivar = 1:length(vars)

    % Get variable names for each excel
    varname_megtusalen = vars(ivar).megtusalen;
    varname_fam = vars(ivar).fam;

    % Open log file per variable
    log_file = fullfile('..', 'results', 'logs', ['fam_gen_validation_log_' varname_megtusalen '.txt']);
    fid = fopen(log_file, 'w');

    fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
    fprintf(fid, 'Variable: %s\n', varname_megtusalen);
    fprintf(fid, 'Updated values: %s\n\n', string(update));

    % Loop over participants in fam
    for i = 1:n

        % ID familiares
        id_fam = string(fam_gen.(id_vars(1).fam){i});

        if strlength(id_fam) == 0
            warning('Could not find FAM-%03d in fam_gen', i)
            fprintf(fid, 'FAM-%03d: participant not found in fam_gen\n', i);
            n_not_found = n_not_found + 1;
            continue
        end

        meg_row = find(strcmp(megtusalen.(id_vars(1).megtusalen), id_fam), 1);

        if isempty(meg_row)
            warning('Could not find %s',  id_fam)
            % log_lines{end+1} = sprintf( 'ID FAM-%03d: participant not found in megtusalen\n', id_fam);
            fprintf(fid, 'ID %s: participant not found in megtusalen\n', id_fam);
            n_not_found = n_not_found + 1;
            continue;
        end

        % Value for this participant and this variable
        fam_val = fam_gen.(varname_fam)(i);
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

        % Convert APOE variable
        if strcmp(varname_megtusalen,'APOE')
            fam_val = regexp(fam_val, '\d', 'match');
            fam_val = str2double([fam_val{:}]);
        end

        % Convert AACT variable
        if strcmp(varname_megtusalen,'ACT')
            switch fam_val
                case 'Thr/Ala'
                    fam_val = 'TA';
                case 'Thr/Thr'
                    fam_val = 'TT';
                case 'Ala/Ala'
                    fam_val = 'AA';
                case 'Ala/Thr'
                    fam_val = 'AT';
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

            if iscell(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen){meg_row} = fam_val; % cell → usar {}
            elseif iscategorical(megtusalen.(varname_megtusalen)) || isstring(megtusalen.(varname_megtusalen)) || isnumeric(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen)(meg_row) = fam_val;% otros → usar ()
            end

            n_filled = n_filled + 1;

            fprintf(fid, ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id_fam, varname_megtusalen, fam_str);


            % Case 2: both have values but differ → CORRECT
        elseif ~fam_missing && ~meg_missing && ~isequal(fam_val, meg_val)

            if iscell(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen){meg_row} = fam_val; % cell → usar {}
            elseif iscategorical(megtusalen.(varname_megtusalen)) || isstring(megtusalen.(varname_megtusalen)) || isnumeric(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen)(meg_row) = fam_val;% otros → usar ()

            end

            n_corrected = n_corrected + 1;

            fprintf(fid, ...
                'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
                id_fam, varname_megtusalen, meg_str, fam_str);


            % Case 3: fam is missing → do nothing
        elseif fam_missing

            fprintf(fid, ...
                'ID %s, variable %s: skipped (fam_gen missing, megtusalen=%s)\n', ...
                id_fam, varname_megtusalen, meg_str);
        end

    end

    fclose(fid);

end

% Create summary log file
log_file = fullfile('..', 'results', 'logs', 'fam_gen_validation_log_summary.txt');
fid = fopen(log_file, 'w');

% Check participants in megtusalen not in fam
all_meg_ids = string(megtusalen.(id_vars(1).megtusalen));
is_fam = startsWith(all_meg_ids, 'FAM');
meg_ids = all_meg_ids(is_fam);
fam_ids = string(fam_gen.(id_vars(1).fam));

n_not_in_fam = 0;

for j = 1:length(meg_ids)
    meg_id = meg_ids(j);

    if ~any(strcmp(fam_ids, meg_id))
        fprintf('ID %s: present in megtusalen but NOT in fam_gen\n', meg_id);
        n_not_in_fam = n_not_in_fam + 1;
    end
end
sprintf('Participants in megtusalen not in fam: %d\n', n_not_in_fam);

% Add summary comparisons to the log file
fprintf(fid, 'Log created on: %s\n\n', datetime('now'));
fprintf(fid, 'Updated values: %s\n\n', string(update));

fprintf(fid,'Comparison: %s vs megtusalen_fam_corrected\n', fam_gen_excel);
fprintf(fid,'Filled values: %d\n', n_filled);
fprintf(fid,'Corrected values: %d\n', n_corrected);
fprintf(fid,'Participants not found: %d\n', n_not_found);
fprintf(fid,'Participants in megtusalen not in fam: %d\n\n\n', n_not_in_fam);

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