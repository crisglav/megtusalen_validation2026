clc
clear
close all

megtusalen_excel = '../results/participants_megtusalen_corrected.xlsx';
json_file = '../data/participants_megtusalen.json';
out_file = '../results/participants_megtusalen_corrected.xlsx';
update = true;

megtusalen = readtable(megtusalen_excel);
meta = jsondecode(fileread(json_file));

vars = fieldnames(meta);
n = length(vars);

n_updated = 0;
n_not_found = 0;
vars_updated = {};

% Log general para todas las variables
general_log_file = '../results/logs/participants_megtusalen_corrected_range_validation_log.txt';
fid_general = fopen(general_log_file, 'w');

for ivar = 1:n

    var = vars{ivar};
    log_lines = {};  % log temporal por variable

    % % Open log file
    % log_file = ['../results/logs/participants_megtusalen_corrected_validation_log_' var '.txt'];  % overwrites preexisting logs
    % fid = fopen(log_file, 'w');
    %
    % log_lines = {};  % cell array vacío para guardar todas las líneas

    % Check if variable exists
    if ~ismember (var, megtusalen.Properties.VariableNames)
        warning('Could not find %s in megtusalen\n', var)
        log_lines{end+1} = sprintf( 'Variable %s: NOT FOUND in megtusalen\n', var);
        n_not_found = n_not_found + 1;
        continue;
    end

    % Check range
    if isfield (meta.(var), 'Range')

        range = meta.(var).Range;

        if strcmp (range, 'non-bounded') continue;
        else
            minval = range(1);
            maxval = range(2);

            vals = megtusalen.(var);

            if isnumeric (vals)
                out_range = (vals < minval | vals > maxval ) & ~isnan(vals);
                idx = find ( out_range );

                for k = 1:length(idx)
                    if strcmp(var, 'edu_years')
                        i = idx(k);
                        id = string(megtusalen.participant_id (i));
                        val_str = string(vals(i));
                        megtusalen.(var)(i) = maxval;

                        n_updated = n_updated + 1;
                        log_lines{end+1} = sprintf( ...
                            'ID %s, variable %s: OUT OF RANGE [%g,%g]   - old=%s, new=%g\n', ...
                            id, var, minval, maxval, val_str, maxval);
                    else
                        i = idx(k);
                        id = string(megtusalen.participant_id (i));
                        val_str = string(vals(i));
                        megtusalen.(var)(i) = NaN;

                        n_updated = n_updated + 1;
                        log_lines{end+1} = sprintf( ...
                            'ID %s, variable %s: OUT OF RANGE [%g,%g]   - old=%s, new=NaN\n', ...
                            id, var, minval, maxval, val_str);
                    end
                end
            end
        end

        % Check levels
        if isfield (meta.(var), 'Levels')
            levels = fieldnames(meta.(var).Levels);

            vals = megtusalen.(var);

            if iscell (vals)
                out_level = ~ismember(vals, levels) & ~cellfun(@isempty, vals);
                idx = find ( out_level );

                for k = 1:length(idx)
                    i = idx(k);
                    id = string(megtusalen.participant_id (i));
                    megtusalen.(var){i} = NaN;

                    val_str = string(vals(i));
                    levels_str = strjoin(levels, ',');

                    n_updated = n_updated + 1;
                    log_lines{end+1} = sprintf( ...
                        'ID %s, variable %s: OUT OF LEVELS {%s} - old=%s, new=NaN\n', ...
                        id, var, levels_str, val_str);
                end
            elseif isnumeric (vals)
                levels = str2double(extractAfter(levels, 'x'));
                out_level = ~ismember(vals, levels) & ~isnan(vals);
                idx = find ( out_level );

                for k = 1:length(idx)
                    i = idx(k);
                    id = string(megtusalen.participant_id (i));
                    megtusalen.(var)(i) = NaN;

                    val_str = string(vals(i));
                    levels_str = strjoin(string(levels), ',');

                    n_updated = n_updated + 1;
                    log_lines{end+1} = sprintf( ...
                        'ID %s, variable %s: OUT OF LEVELS {%s} - old=%s, new=NaN\n', ...
                        id, var, levels_str, val_str);
                end
            else
                warning ('Variable %s: NON-FORMAT column for LEVELS\n', var);
            end
        end

        % Save log only if corrections made
        % if ~isempty (log_lines)
        %     vars_updated{end+1} = var;
        %     fprintf(fid, 'Changes for variable %s\n', var);
        %     for k = 1:length(log_lines)
        %         fprintf(fid, '%s\n', log_lines{k});
        %     end
        % end
        if ~isempty(log_lines)
            vars_updated{end+1} = var;
            fprintf(fid_general, '--- Changes for variable %s ---\n', var);
            for k = 1:length(log_lines)
                fprintf(fid_general, '%s\n', log_lines{k});
            end
        end

    end
end
fclose(fid_general);
fprintf('Validation finished. Log saved to %s\n', general_log_file);

if update
    writetable(megtusalen, out_file);
end

fprintf('\nValidation finished.\n');
fprintf('Total updated values: %d\n', n_updated);
fprintf('Variables affected: %s\n', strjoin(vars_updated, ', '));
fprintf('Variables not found in Excel: %d\n', n_not_found);
fprintf('Corrected file saved to: %s\n', out_file);
fprintf('Log saved to: %s\n', general_log_file);

