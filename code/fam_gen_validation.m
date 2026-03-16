fam_gen_excel = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\source_data\familiares_genetica.xlsx';
megtusalen_excel = 'C:\Users\Cristina\repos\megtusalen_validation2026\data\participants_megtusalen_corrected.xlsx';

fam_gen = readtable(fam_gen_excel);
megtusalen = readtable(megtusalen_excel);

genetic_vars = {'APOE','ERBB4','BDNF','NRG1','CR1','COMT','CLU','ACT','BACE1','CHRNA7','PICALM'};

% % Make genetic variables categorical
% for ivar = 1:length(genetic_vars)
%     varname = genetic_vars{ivar};
%     fam_gen.(varname) = categorical(fam_gen.(varname));
%     megtusalen.(varname) = categorical(megtusalen.(varname));
% end

ids = fam_gen.CodigoID;
n = length(ids);

% Open log file
log_file = 'genetic_validation_log.txt';
fid = fopen(log_file, 'w');

for i = 1:n

    id = string(fam_gen.CodigoID{i});

    % Find in megtusalen the participant with current id
    meg_row = find(strcmp(megtusalen.recording_id_orig, id), 1);

    if isempty(meg_row)
        warning('Could not find %s\n', id)
        fprintf(fid, 'ID %s: participant not found in megtusalen\n', id);
        continue;
    end

    % Make sure that genetic variable value in megtusalen is equal to
    % genetic variable value in fam_gen
    for ivar = 1:length(genetic_vars)

        varname = string(genetic_vars{ivar});

        fam_val = fam_gen.(varname)(i);
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

        % Print to a log file if it is not equal or if values are missing
        if ismissing(fam_val) || ismissing(meg_val)

            fprintf(fid, 'ID %s, variable %s: missing value(s) - fam_gen=%s, megtusalen=%s\n', id, varname, string(fam_val), string(meg_val));

        elseif ~isequal(fam_val, meg_val)

            fprintf(fid, 'ID %s, variable %s: mismatch - fam_gen=%s, megtusalen=%s\n', ...
                id, varname, fam_str, meg_str);
        end

    end

end

fclose(fid);
fprintf('Validation finished. Log saved to %s\n', log_file);




