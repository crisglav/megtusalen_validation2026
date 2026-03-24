clc
clear
close all

umec_excel = '../data/source_data/UMEC_DAVID.xlsx';
megtusalen_excel = '../data/participants_megtusalen.xlsx';
out_file = '../data/participants_megtusalen_conversorumec_corrected.xlsx';
update = true;

log_file    = '../results/logs/participants_megtusalen_umec_converter_log.txt';

umec_neuro = readtable(umec_excel);
megtusalen = readtable(megtusalen_excel);

% Open log
fid_log = fopen(log_file, 'w');

n_updated = 0;

for i = 1:height(megtusalen)
    old_value = megtusalen.converter(i);

    hasEvolution   = ~ismissing(megtusalen.evolution_time(i)) & ~isnan(megtusalen.evolution_time(i));
    hasConversion  = ~ismissing(megtusalen.conversion_time(i)) & ~isnan(megtusalen.conversion_time(i));

    new_value = old_value; % inicializamos

    if hasEvolution && ~hasConversion
        new_value = 3;
    elseif hasEvolution && hasConversion
        new_value = 4;
    end

    % Convertir old_value a string seguro
    if ismissing(old_value) || isnan(old_value)
        old_str = 'NaN';
    else
        old_str = num2str(old_value);
    end

    % Guardar cambio solo si hubo modificación
    if ~isequaln(old_value, new_value)
        megtusalen.converter(i) = new_value;
        n_updated = n_updated + 1;
        id = string(megtusalen.participant_id(i));
        fprintf(fid_log, 'ID %s: converter changed from NaN to %d\n', id, new_value);
    end
end

fclose(fid_log);

if update 
    writetable(megtusalen, out_file);
end 

fprintf('Conversion update finished.\n');
fprintf('Total updated entries: %d\n', n_updated);
fprintf('Updated Excel saved to: %s\n', out_file);
fprintf('Log saved to: %s\n', log_file);
