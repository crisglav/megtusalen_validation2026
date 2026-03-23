clear all
close all

% Input file
megtusalen_excel = '../data/participants_megtusalen.xlsx';
megtusalen = readtable(megtusalen_excel);


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

%% NEMOS
update = false;

% ----- Correct genetics ----
% Source data
nemos_gen_excel = '../data/source_data/Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx';

megtusalen_corrected = nemos_gen_validation(megtusalen,nemos_gen_excel, update);

% ----- Correct neuro for the UMEC project ----
% Source data
nemos_neuro_excel = '../data/source_data/Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx';

megtusalen_corrected = nemos_neuropsico_validation(megtusalen_corrected,nemos_neuro_excel, update);