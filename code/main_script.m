clear all
close all

% Input file
megtusalen_excel = '../data/participants_megtusalen_blank.xlsx';
opts = detectImportOptions(megtusalen_excel);
opts.VariableTypes = {'char'	'char'	'double'	'char'	'char'	'char'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'double'	'char'	'char'	'char'	'char'	'char'	'char'	'char'	'char'	'char'	'char'	'double'	'double'	'double'	'char'};
megtusalen = readtable(megtusalen_excel,opts);

if ~exist('../results','dir')
    mkdir('../results');
end
if ~exist('../results/logs','dir')
    mkdir('../results/logs');
end
%% FAM
% Set to true if you want to update participants_megtusalen_fam_corrected.
% If false only the log files are created
update = true;

% ----- Correct genetics for the familiares project ----
% Source data
fam_gen_excel = '../data/source_data/BBDD Conjunta 261 familiares.xlsx';

megtusalen_corrected = fam_gen_validation(megtusalen,fam_gen_excel, update);

% ---- Update the corrected genetic data with missing rows -----
% Source data
fam_gen_excel = '../data/source_data/familiares Resultados pendientes julio 2019.xlsx';

megtusalen_corrected = fam_gen_validation_update_missing(megtusalen_corrected,fam_gen_excel, update);

% ----- Correct neuro for the familiares project ----
% Source data
fam_neuro_excel = '../data/source_data/BBDD Conjunta 261 familiares.xlsx';

megtusalen_corrected = fam_neuropsico_validation(megtusalen_corrected,fam_neuro_excel, update);

%% UMEC
% Set to true if you want to update participants_megtusalen_umec_corrected
% If false only the log files are created
update = true;

% ----- Update umec ids and correct typos ----
megtusalen_corrected = umec_update_recording_id_orig(megtusalen, update);

% ----- No source date for UMEC genetics - no validation posible ----

% ----- Correct neuro for the UMEC project ----
% Source data
umec_neuro_excel = '../data/source_data/UMEC_DAVID.csv';

megtusalen_corrected = umec_neuropsico_validation(megtusalen_corrected,umec_neuro_excel, update);

% UMEC extension (UMEC-236 onwards) TO DO
umec_extension_excel = '../data/source_data/cortisolyluna_inma.xlsx';

megtusalen_corrected = umec_extension_validation(megtusalen_corrected,umec_extension_excel, update);



%% NEMOS
update = true;

% ----- Correct genetics ----
% Source data
nemos_gen_excel = '../data/source_data/Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx';

megtusalen_corrected = nemos_gen_validation(megtusalen,nemos_gen_excel, update);

% ----- Correct neuro for the UMEC project ----
% Source data
nemos_neuro_excel = '../data/source_data/Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx';

megtusalen_corrected = nemos_neuropsico_validation(megtusalen_corrected,nemos_neuro_excel, update);

%% UNIFY THE THREE PROJECTS
umec_path = '../results/participants_megtusalen_umec_corrected.xlsx';
nemos_path = '../results/participants_megtusalen_nemos_corrected.xlsx';
fam_path = '../results/participants_megtusalen_fam_corrected.xlsx';

umec = readtable(umec_path,'FileType','spreadsheet');
nemos = readtable(nemos_path,'FileType','spreadsheet');
fam = readtable(fam_path,'FileType','spreadsheet');

project_id = categorical(umec.project_id);

megtusalen_corrected = [umec(project_id == 'UMEC',:); nemos(project_id == 'NEMOS',:); fam(project_id == 'FAM',:)];

writetable(megtusalen_corrected,'../results/participants_megtusalen_corrected.xlsx');
