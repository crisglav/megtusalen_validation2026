
clc
clear 
close all

fam_excel = '../data/source_data/BBDD Conjunta 261 familiares.xlsx';
nemos_excel = '../data/source_data/Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx';
umec_excel = '../data/source_data/UMEC_DAVID.csv';
megtusalen_excel = '../data/participants_megtusalen.xlsx'; 

fam_neuro = readtable(fam_excel, 'Sheet', 'Neuropsicología');
nemos_neuro = readtable(nemos_excel ,'Sheet','Datos');
umec_neuro = readtable(umec_excel); 
megtusalen = readtable(megtusalen_excel);

cols_fam = fam_neuro.Properties.VariableNames(:, 45:end)'; 
cols_nemos = nemos_neuro.Properties.VariableNames(:, 13:43)'; 
cols_umec = umec_neuro.Properties.VariableNames(:, 52:109)'; 
cols_megtusalen = megtusalen.Properties.VariableNames(:,14:53)'; 



