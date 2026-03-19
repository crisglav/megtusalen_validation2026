%% Script to compare megtusalen db with familiares original db
% Genética: cambio a mano el excel BBDD Conjunta 261 familiares:
%            col: APOEHaplotipo --> elimino epsilon
%            col: AACT_rs4934 --> cambio Thr por T y Ala por A. ( no hay G ni C)
%            reordeno a mano cols de genética BBDD Conjunta 261 familiares para que aparezcan igual que en megtusalen.


clc
clear
close all

fam_gen_excel = '../data/source_data/familiares Resultados resto pacientes abril 2019.xlsx';
megtusalen_excel = '../results/participants_megtusalen_fam_corrected.xlsx';
out_file = '../results/participants_megtusalen_fam_corrected.xlsx';
update = true;

fam_gen = readtable(fam_gen_excel );
megtusalen = readtable(megtusalen_excel);

% vars_megtusalen = {'ACT', ...
%                    'APOE', ...
%                    'BACE1', ...
%                    'BDNF', ...
%                    'CHRNA7', ...
%                    'CLU', ...
%                    'COMT', ...
%                    'CR1', ...
%                    'ERBB4', ...
%                    'NRG1', ...
%                    'PICALM'};
% 
% vars_fam = {'AACT_rs4934', ...
%             'APOE_Haplotipo', ...
%             'BACE1_rs638405', ...
%             'BDNF_rs6265', ...
%             'CHRNA7_P', ...
%             'CLU_rs11136000', ...
%             'COMT_rs4680', ...
%             'CR1_rs3818361', ...
%             'ERBB4_rs839523', ...
%             'NRG1_rs6994992', ...
%             'PICALM_rs3851179'};

vars_megtusalen = {'APOE', ...
                   'BDNF'};

vars_fam = {'APOE_Haplotipo', ...
            'BDNF_rs6265'};

vars = struct('megtusalen',vars_megtusalen,'fam',vars_fam);

id_vars = struct ( 'megtusalen', {'recording_id_orig'}, 'fam' , {'Id'});
ids = fam_gen.(id_vars(1).fam);
n = length(ids);

% IDs megtusalen
ids_meg = string(megtusalen.(id_vars(1).megtusalen));
% ids_meg = cellfun(@(x) str2double(x{1}), regexp(ids_meg, '\d{3}$', 'match'));

% % Open log file
% log_file = ['../results/logs/fam_gen_validation_log_' vars_megtusalen{1} '.txt'];  % overwrites preexisting logs
% fid = fopen(log_file, 'w');
% 
% log_lines = {};  % cell array vacío para guardar todas las líneas

n_updated = 0;
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
        % id_fam = str2double(regexp(id_fam, '\d{3}$', 'match'));
        % if isempty(id_fam)
        %     continue
        % end

        % % Find in megtusalen the participant with current id
        % match_idx = mod(ids_meg,1000) == id_fam; % Logical match on last 3 digits
        % isF = startsWith(megtusalen.(id_vars(1).megtusalen), 'F'); % Among matches, find starting with 'F'
        % meg_row = find(match_idx & isF, 1);   % first F match

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
            else
                error('Tipo de columna no soportado: %s', class(megtusalen.(varname_megtusalen)));
            end

            n_updated = n_updated + 1;

            fprintf(fid, ...
                'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
                id_fam, varname_megtusalen, fam_str);

            % log_lines{end+1} = sprintf( ...
            %     'ID %s, variable %s: filled missing - old=NaN, new=%s\n', ...
            %     id_fam, varname_megtusalen, fam_str);

            % Case 2: both have values but differ → CORRECT
        elseif ~fam_missing && ~meg_missing && ~isequal(fam_val, meg_val)

            if iscell(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen){meg_row} = fam_val; % cell → usar {}
            elseif iscategorical(megtusalen.(varname_megtusalen)) || isstring(megtusalen.(varname_megtusalen)) || isnumeric(megtusalen.(varname_megtusalen))
                megtusalen.(varname_megtusalen)(meg_row) = fam_val;% otros → usar ()
                % else
                %     error('Tipo de columna no soportado: %s', class(megtusalen.(varname_megtusalen)));
            end

            n_updated = n_updated + 1;

            fprintf(fid, ...
                'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
                id_fam, varname_megtusalen, meg_str, fam_str);

            % log_lines{end+1} = sprintf( ...
            %     'ID %s, variable %s: corrected - old=%s, new=%s\n', ...
            %     id_fam, varname_megtusalen, meg_str, fam_str);

            % Case 3: fam is missing → do nothing
        elseif fam_missing
            % log_lines{end+1} = sprintf( ...
            %     'ID %s, variable %s: skipped (fam_neuro missing, megtusalen=%s)\n', ...
            %     id_fam, varname_megtusalen, meg_str);

            fprintf(fid, ...
                'ID %s, variable %s: skipped (fam_neuro missing, megtusalen=%s)\n', ...
                id_fam, varname_megtusalen, meg_str);
        end

    end

    fclose(fid);

end

%%
%
% % Check participants in megtusalen not in fam
% all_meg_ids = string(megtusalen.(id_vars(1).megtusalen));
% is_fam = startsWith(all_meg_ids, 'FAM');
% meg_ids = all_meg_ids(is_fam);
%
% fam_ids = string(fam_gen.(id_vars(1).fam));
%
% n_not_in_fam = 0;
%
% for j = 1:length(meg_ids)
%     meg_id = meg_ids(j);
%
%     if ~any(strcmp(fam_ids, meg_id))
%         log_lines{end+1} = sprintf( 'ID %s: present in megtusalen but NOT in fam_neuro\n', meg_id);
%         n_not_in_fam = n_not_in_fam + 1;
%     end
% end
%
% fprintf('Validation finished. Log saved to %s\n', log_file);
%
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
if update
    writetable(megtusalen, out_file);

    fprintf('Correction finished.\n');
    % fprintf('Updated values: %d\n', n_updated);
    % fprintf('Participants not found: %d\n', n_not_found);
    % fprintf('Participants in megtusalen not in fam: %d\n', n_not_in_fam);
    % fprintf('Corrected file saved to: %s\n', out_file);
    % fprintf('Log saved to: %s\n', log_file);
end
