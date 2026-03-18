megtusalen_excel = '../data/participants_megtusalen.xlsx';
out_file = '../results/participants_megtusalen_fam_corrected.xlsx';
megtusalen = readtable(megtusalen_excel);
writetable(megtusalen, out_file);