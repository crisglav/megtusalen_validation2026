% Script that checks healthy control diagnosis based on the 8 neuropsychological
% assessments common to all Megtusalen subjects.
%
% Input data: 
%       - participants_megtusalen_corrected.xlsx
%
% Output data: 
%       - participants_megtusalen_corrected_diagcog.xlsx 
%
% Diacog coding
%       NaN - Not enough neuropsychological tests availabe to determine diagnosis
%       0 - Participant not healthy (passed less than 7 test, having performed more than 2 tests)
%       1 - Participant healthy (passed 7 or 8 tests)
%       2 - Participant superhealthy (passed 8 tests)
%
% TO DO:
% - Add thresholds for people younger than 50
% 
% Lucia Hernandez, C3N, 2024
% Cristina Gil, C3N, major revision 17/03/2025
% Cristina Gil, C3N, major revision 25/03/2026. Adjust to
% participants_megtusalen_corrected.xlsx


clear all
close all
clc

%% Load excel data
megtusalen = readtable('../results/participants_megtusalen_corrected.xlsx');
megtusalen.diagnosis = categorical(megtusalen.diagnosis);
out_file = '../results/participants_megtusalen_corrected_diagcog.xlsx';

n = size(megtusalen,1);               % Original sample size

% Extract variables from table
age = megtusalen.age;                 % Age
mmse = megtusalen.MMSE;               % Original MMSE score
edu_years = megtusalen.edu_years;       % Scholarization years

% Set thresholds
param.age = 50;                     % Age threshold
param.diagnosis = 'HC';             % Diagnosis of healthy participants
param.mmse = 26;                    % MMSE score threshold
param.mmse_age = 75;                % MMSE age threshold
param.edu_thres = [8, 17];              % Education years threshold for MMSE
param.edu_thresh_digits = [9, 17];       % Education years threshold for inverse digit task
param.ageranks = [50 56; 57 59; 60 62; 63 65; 66 68; 69 71; 72 74; 75 77; 78 80; 81 90];
param.tmt_a_time_thresh = [101; 109; 119; 111; 124; 157; 159; 159; 160; 159];
param.tmt_b_time_thresh = [380; 380; 380; 401; 317; 420; 448; 461; 428; 428];
param.fas_sem = [13, 12, 11, 11, 11, 10, 10, 9, 8, 9];

param.export_all = true;           % Variable to export all participants or only healthy participants

%% Crete log file
log_file = fullfile('..', 'results', 'logs', 'diagcog_log.txt');
fid = fopen(log_file, 'w');

fprintf(fid,'%d subjects in original sample.\n', n);
%% Filter participans by controls
mask_healthy = any(megtusalen.diagnosis == param.diagnosis,2);
fprintf(fid,'%d healthy participants in original sample.\n', sum(mask_healthy));

%% Filter participants by existance of age data and age threshold
% Do not take into account participants younger than param.age or without
% information about age.
mask_age = ~isnan(age);
fprintf(fid,'%d subjects with age data.\n', sum(mask_age));

mask_age_thres = mask_age & age >= param.age;
fprintf(fid,'%d healthy participants with age data and older than %d.\n', sum(mask_healthy & mask_age_thres), param.age);

%% Filter participants who have an (adjusted) MMSE < 26
% Note: For participants who do not have information about education years,
% use their original mmse

% Create a new column mmse_adj
mmse_adj = nan(n,1);
for isuj = 1 : n

    % Skip if participant has no age, their age is lower than param.age or
    % if participant does not have information about education years
    if isnan(age(isuj)) || age(isuj) < param.age || isnan(edu_years(isuj))
        continue;
    end

    % Compute adjusted mmse
    % If the chronological age is equal or higher than the MMSE age threshold (26)
    if age(isuj) >= param.mmse_age

        % Education years lower or equal than 8, increase MMSE by 2
        if edu_years(isuj) <= param.edu_thres(1)
            mmse_adj(isuj) = mmse(isuj)+2;

        % Education years between 9 and 17, increase MMSE by 1
        elseif edu_years(isuj) > param.edu_thres(1) && edu_years(isuj) <= param.edu_thres(2)
            mmse_adj(isuj) = mmse(isuj)+1;

        % 18 or more education years, use MMSE age
        elseif megtusalen.edu_years(isuj) >param.edu_thres(2)
            mmse_adj(isuj) = mmse(isuj);
        end

    % If the chronological age is lower than the MMSE age threshold
    else

        % Education years lower or equal than 8, increase MMSE by 1
        if edu_years(isuj) <= param.edu_thres(1)
            mmse_adj(isuj) = mmse(isuj)+1;

        % Education years between 9 and 17, use MMSE age
        elseif megtusalen.edu_years(isuj) > param.edu_thres(1) && megtusalen.edu_years(isuj) <= param.edu_thres(2)
            mmse_adj(isuj) = mmse(isuj);

        % 18 or more education years, decrease MMSE one year
        elseif megtusalen.edu_years(isuj) >param.edu_thres(2)
            mmse_adj(isuj) = mmse(isuj)-1;
        end
    end


    % Threshold adjusted mmse age for those participants that scored higher
    % than 30
    if mmse_adj(isuj) > 30
        mmse_adj(isuj) = 30;
    end
end

% Extend MMSE to participants who are missing the variable years of
% education
mmse_extended = mmse_adj;
mmse_extended(isnan(edu_years)) = mmse(isnan(edu_years));

% Create a new column mmse_ok
mmse_ok = nan(n,1);
mmse_ok(mmse_extended < param.mmse) = 0;
mmse_ok(mmse_extended >= param.mmse) = 1;

fprintf(fid,'%d healhty participants with age data, older than %d, and with variable mmse_adj.\n', sum(mask_healthy & mask_age_thres & ~isnan(mmse_adj)), param.age);
fprintf(fid,'%d healthy participants with age data, older than %d, and with variable mmse_extended.\n', sum(mask_healthy & mask_age_thres & ~isnan(mmse_extended)), param.age);
fprintf(fid,'%d healthy participants with age data, older than %d, and with mmse_extended < 26.\n', sum(mask_healthy & mask_age_thres & (mmse_ok==1)), param.age);

%% Adjust the eight neuropsychological tests that were common to all Megtusalen participants and assess tests
% Note: if participant is missing a test, their test result will be set to
% -1 instead of nan. This is to distinguish nan because of missing
% demographic data from missing test data.

% 1. Immediate logic memory (memoria lógica inmediata)
% Variable to save tests results: 1 - passed test, 0 - failed test.
LM_imm_result = nan(n,1);

for isuj = 1 : n
    
    % Skip if participant has no age, or their age is lower than param.age
    if ~mask_age_thres(isuj)
        continue;
    end

   % If there is no test data, set -1
    if isnan(megtusalen.LM_imm_units(isuj))
        LM_imm_result(isuj) = -1;
        continue;
    end

    % Assess test based on age thresholds specific to the test
    if age(isuj) >= 50 && age(isuj) < 55 && megtusalen.LM_imm_units(isuj) >= 20
        LM_imm_result(isuj) = 1;
    elseif age(isuj) >= 50 && age(isuj) < 55 && megtusalen.LM_imm_units(isuj) < 20
        LM_imm_result(isuj) = 0;
        
    elseif age(isuj) >= 55 && age(isuj) < 66 && megtusalen.LM_imm_units(isuj) >= 15
         LM_imm_result(isuj) = 1;
    elseif age(isuj) >= 55 && age(isuj) < 66 && megtusalen.LM_imm_units(isuj) < 15
         LM_imm_result(isuj) = 0;

    elseif age(isuj) >= 66 && age(isuj) < 74 && megtusalen.LM_imm_units(isuj) >= 11
         LM_imm_result(isuj) = 1;
    elseif age(isuj) >= 66 && age(isuj) < 74 && megtusalen.LM_imm_units(isuj) < 11
         LM_imm_result(isuj) = 0;
    
    elseif age(isuj) >= 74 && megtusalen.LM_imm_units(isuj) >= 8
         LM_imm_result(isuj) = 1;
    elseif age(isuj) >= 74 && megtusalen.LM_imm_units(isuj) < 8
         LM_imm_result(isuj) = 0;
    end 
end

fprintf(fid,'\n1. Immediate logic memory (memoria lógica inmediata) \n');
fprintf(fid,'%d healthy participants passed the test mem log uni inm \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & LM_imm_result == 1));
fprintf(fid,'%d healthy participants failed the test mem log uni inm \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & LM_imm_result == 0));
fprintf(fid,'%d healthy participants do not have the test mem log uni inm \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & LM_imm_result == -1));



% 2. Delayed logic memory (Memoria lógica demorada)
% Variable to save tests results: 1 - passed test, 0 - failed test.
LM_del_result = nan(n,1);

for isuj = 1 : n
    
    % Skip if participant has no age, or their age is lower than param.age
    if ~mask_age_thres(isuj)
        continue;
    end

    % If there is no test data, set -1
    if isnan(megtusalen.LM_del_units(isuj))
        LM_del_result(isuj) = -1;
        continue;
    end

    % Assess test based on age thresholds specific to the test
    if age(isuj) >= 50 && age(isuj) < 55 && megtusalen.LM_del_units(isuj) >= 9
        LM_del_result(isuj) = 1;
    elseif age(isuj) >= 50 && age(isuj) < 55 && megtusalen.LM_del_units(isuj) < 9
        LM_del_result(isuj) = 0;
        
    elseif age(isuj) >= 55 && age(isuj) < 66 && megtusalen.LM_del_units(isuj) >= 6
         LM_del_result(isuj) = 1;
    elseif age(isuj) >= 55 && age(isuj) < 66 && megtusalen.LM_del_units(isuj) < 6
         LM_del_result(isuj) = 0;

    elseif age(isuj) >= 66 && age(isuj) < 74 && megtusalen.LM_del_units(isuj) >= 2
         LM_del_result(isuj) = 1;
    elseif age(isuj) >= 66 && age(isuj) < 74 && megtusalen.LM_del_units(isuj) < 2
         LM_del_result(isuj) = 0;
    
    elseif age(isuj) >= 74 && megtusalen.LM_del_units(isuj) >= 1
         LM_del_result(isuj) = 1;
    elseif age(isuj) >= 74 && megtusalen.LM_del_units(isuj) < 1
         LM_del_result(isuj) = 0;
    end 
end

fprintf(fid,'\n2. Delayed logic memory (Memoria lógica demorada) \n');
fprintf(fid,'%d healthy participants passed the test mem log uni dem \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & LM_del_result == 1));
fprintf(fid,'%d healthy participants failed the test mem log uni dem \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) &LM_del_result == 0));
fprintf(fid,'%d healthy participants do not have the test mem log uni dem \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & LM_del_result == -1));




% 3. Direct digit task (Dig directos). It measures attention span.
% Variable to save tests results: 1 - passed test, 0 - failed test.
DST_forward_result = nan(n,1);

% First adjust variable DST_forward by years of scholarization. If no data 
% availabe for scholarization years, use the original DST_forward score.
DST_forward_adj = nan(n,1);

for isuj = 1 : n

    % Skip if participant has no age, or their age is lower than param.age
    if ~mask_age_thres(isuj)
        continue;
    end

    % If there is no test data, set -1
    if isnan(megtusalen.DST_forward(isuj))
        DST_forward_adj(isuj) = -1;
        continue;
    end

    % If there is no variable years of scholarizaton, use the original
    % score
    if isnan(edu_years(isuj))
        DST_forward_adj(isuj) = megtusalen.DST_forward(isuj);
        continue;
    end

    if edu_years(isuj) <= param.edu_thres(1)
        DST_forward_adj(isuj) = megtusalen.DST_forward(isuj) + 1;

    elseif edu_years(isuj) > param.edu_thres(1) && edu_years(isuj) < param.edu_thres(2)
        DST_forward_adj(isuj) = megtusalen.DST_forward(isuj);

    elseif edu_years(isuj) >= param.edu_thres(2)
        DST_forward_adj(isuj) = megtusalen.DST_forward(isuj) - 1;

    end

end

% Assess test
DST_forward_result(DST_forward_adj >= 4) = 1;
DST_forward_result(DST_forward_adj < 4) = 0;
DST_forward_result(DST_forward_adj == -1) = -1;

fprintf(fid,'\n3. Direct digit task \n');
fprintf(fid,'%d healthy participants passed the test dig dir \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & DST_forward_result == 1));
fprintf(fid,'%d healthy participants failed the test dig dir \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & DST_forward_result == 0));
fprintf(fid,'%d healthy participants do not have the test dig dir \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & DST_forward_result == -1));




% 4. Inverse digit task (Dig inversos). It measures working memory.
% Variable to save tests results: 1 - passed test, 0 - failed test.
DST_backward_result = nan(n,1);

% First adjust variable DST_forward by years of scholarization. If no data 
% availabe for scholarization years, use the original DST_backward score.
DST_backward_adj = nan(n,1);

for isuj = 1 : n

    % Skip if participant has no age, or their age is lower than param.age
    if ~mask_age_thres(isuj)
        continue;
    end

    % If there is no test data, set -1
    if isnan(megtusalen.DST_backward(isuj))
        DST_backward_adj(isuj) = -1;
        continue;
    end

    % If there is no variable years of scholarizaton, use original score
    if isnan(edu_years(isuj))
        DST_backward_adj(isuj) = megtusalen.DST_backward(isuj);
        continue;
    end

    if edu_years(isuj) <= param.edu_thresh_digits(1)
        DST_backward_adj(isuj) = megtusalen.DST_backward(isuj) + 1;

    elseif edu_years(isuj) > param.edu_thresh_digits(1) && edu_years(isuj) < param.edu_thresh_digits(2)
        DST_backward_adj(isuj) = megtusalen.DST_backward(isuj);

    elseif edu_years(isuj) >= param.edu_thresh_digits(2)
        DST_backward_adj(isuj) = megtusalen.DST_backward(isuj) - 1;

    end

end

% Assess test based on age ranks
for isuj = 1:n

    if age(isuj) >= 50 && age(isuj) <= 56
        if DST_backward_adj(isuj) >=3
            DST_backward_result(isuj) = 1;
        else
            DST_backward_result(isuj) = 0;
        end

    elseif age(isuj)> 56
        if DST_backward_adj(isuj) >= 2
            DST_backward_result(isuj) = 1;
        else
            DST_backward_result(isuj) = 0;
        end
    end
end
DST_backward_result(DST_backward_adj == -1) = -1;


fprintf(fid,'\n4. Inverse digit task \n');
fprintf(fid,'%d healthy participants passed the test dig inv \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & DST_backward_result == 1));
fprintf(fid,'%d healthy participants failed the test dig inv \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & DST_backward_result == 0));
fprintf(fid,'%d healthy participants do not have the test dig inv \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & DST_backward_result == -1));




% 5. TMTA. It measures processing speed, sustained attention.
% Note: only the variable TMT_A_timeime was used here and corrected. The variable
% TMTA_AC (aciertos) was not corrected because it was not reliable.
% Variable to save tests results: 1 - passed test, 0 - failed test.
tmta_result = nan(n,1);

for isuj = 1 : n

    % Skip if participant has no age, or their age is lower than param.age
    if ~mask_age_thres(isuj)
        continue;
    end

    % If there is no test data, set -1
    if isnan(megtusalen.TMT_A_time(isuj))
        tmta_result(isuj) = -1;
        continue;
    end

    % Assess test based on specific age ranks
    for iage = 1:length(param.ageranks) 

        if age(isuj) >= param.ageranks(iage, 1) && age(isuj) <= param.ageranks(iage, 2) && megtusalen.TMT_A_time(isuj) <= param.tmt_a_time_thresh(iage)
            tmta_result(isuj) = 1;

        elseif age(isuj) >= param.ageranks(iage, 1) && age(isuj) <= param.ageranks(iage, 2) && megtusalen.TMT_A_time(isuj) > param.tmt_a_time_thresh(iage)
            tmta_result(isuj) = 0;

        end

    end 
end

fprintf(fid,'\n5. TMTA \n');
fprintf(fid,'%d healthy participants passed the test tmta \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & tmta_result == 1));
fprintf(fid,'%d healthy participants failed the test tmta \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & tmta_result == 0));
fprintf(fid,'%d healthy participants do not have the test tmta \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & tmta_result == -1));



% TMTB
% Variable to save tests results: 1 - passed test, 0 - failed test.
tmtb_result = nan(n,1);

for isuj = 1 : n

    % Skip if participant has no age, or their age is lower than param.age
    if ~mask_age_thres(isuj)
        continue;
    end

    % If there is no test data, set -1
    if isnan(megtusalen.TMT_B_time(isuj))
        tmtb_result(isuj) = -1;
        continue;
    end

    % Assess test based on specific age ranks
    for iage = 1:length(param.ageranks) 

        if age(isuj) >= param.ageranks(iage, 1) && age(isuj) <= param.ageranks(iage, 2) && megtusalen.TMT_B_time(isuj) <= param.tmt_b_time_thresh(iage)
            tmtb_result(isuj) = 1;

        elseif age(isuj) >= param.ageranks(iage, 1) && age(isuj) <= param.ageranks(iage, 2) && megtusalen.TMT_B_time(isuj) > param.tmt_b_time_thresh(iage)
            tmtb_result(isuj) = 0;

        end

    end 
end

fprintf(fid,'\n5. TMTB \n');
fprintf(fid,'%d healthy participants passed the test tmtb \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & tmtb_result == 1));
fprintf(fid,'%d healthy participants failed the test tmtb \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & tmtb_result == 0));
fprintf(fid,'%d healthy participants do not have the test tmtb \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & tmtb_result == -1));




% 7. FAS phonology.
% Variable to save tests results: 1 - passed test, 0 - failed test.
PTF_result = nan(n,1);
sumFAS = megtusalen.PFT_F + megtusalen.PFT_A +megtusalen.PFT_S;

for isuj = 1 : n

    % Skip if participant has no age, or their age is lower than param.age
    if ~mask_age_thres(isuj)
        continue;
    end

    % If there is no test data, set -1
    if isnan(sumFAS(isuj))
        PTF_result(isuj) = -1;
        continue;
    end


    % Assess test
    if age(isuj) < 60

        % Assume that the participant is in the low rank of years of
        % scholarization if the variable edu_years is missing
        if(edu_years(isuj) < 13 || isnan(edu_years(isuj)))

            if sumFAS(isuj) >= 27.55
                PTF_result(isuj) = 1;
            else
                PTF_result(isuj) = 0;
            end

        else % edu_years >= 13
            if sumFAS(isuj) >= 29.5
                PTF_result(isuj) = 1;
            else
                PTF_result(isuj) = 0;
            end

        end

    else % age(isuj >= 60)

        if(edu_years(isuj) < 13 || isnan(edu_years(isuj)))

            if sumFAS(isuj) >= 10.3
                PTF_result(isuj) = 1;
            else
                PTF_result(isuj) = 0;
            end

        else % edu_years >= 13
            if sumFAS(isuj) >= 29.5
                PTF_result(isuj) = 1;
            else
                PTF_result(isuj) = 0;
            end


        end
    end

end
fprintf(fid,'\n7. FAS fon \n');
fprintf(fid,'%d healthy participants passed the test FAS fon \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & PTF_result == 1));
fprintf(fid,'%d healthy participants failed the test FAS fon \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & PTF_result == 0));
fprintf(fid,'%d healthy participants do not have the test FAS fon \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & PTF_result == -1));



% 8. FAS semantics.
% Only use the variable animals, which was the only one common to the
% three Megtusalen studies.
% Variable to save tests results: 1 - passed test, 0 - failed test.
SFT_result = nan(n,1);

for isuj = 1 : n

    % Skip if participant has no age, or their age is lower than param.age
    if ~mask_age_thres(isuj)
        continue;
    end

    % If there is no test data, set -1
    if isnan(megtusalen.SFT_animals(isuj))
        SFT_result(isuj) = -1;
        continue;
    end

    % Assess test
    for iage = 1:size(param.ageranks,1)
        if age(isuj) >= param.ageranks(iage, 1) && age(isuj) <= param.ageranks(iage, 2) 
            
            if megtusalen.SFT_animals(isuj) >= param.fas_sem(iage)
                SFT_result(isuj) = 1;
            else
                SFT_result(isuj) = 0;
            end

        end
    end

end
fprintf(fid,'\n8. FAS sem \n');
fprintf(fid,'%d healthy participants passed the test FAS sem \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & SFT_result == 1));
fprintf(fid,'%d healthy participants failed the test FAS sem \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & SFT_result == 0));
fprintf(fid,'%d healthy participants do not have the test FAS sem \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & SFT_result == -1));



%% Classify healthy subjects
% The criterion to consider pathologic a subject is when they have two or
% more failed tests, having written at least 3 tests.

% Collate all tests
tests = [LM_imm_result, LM_del_result, DST_forward_result, DST_backward_result, tmta_result, tmtb_result, PTF_result, SFT_result];

% Participants who have not completed any of the neuropyschological tests
no_neuro_atall = all(tests == -1,2);

% Participants who have not completed enough neuropsychological tests (2
% or less tests)
no_neuro = (sum(tests == -1 ,2) > 2) & ~no_neuro_atall;

% Participants who are not considered healthy (they failed two or more
% tests)
no_healthy = sum(tests == 1 ,2) < 7 & ~no_neuro_atall & ~no_neuro;

% Participants who are considered healthy (they failed one or zero tests)
healthy = sum(tests == 1 ,2) >= 7;

% Participants who are considered superhealthy (they did not fail any test)
superhealthy = sum(tests == 1 ,2) == 8;

fprintf(fid,'\nAssessment summary \n');
fprintf(fid,'%d healthy participants did not complete any neuropsychological test \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & no_neuro_atall));
fprintf(fid,'%d healthy participants did not complete enough neuropsychological tests \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & no_neuro));
fprintf(fid,'%d healthy participants failed two ore more tests \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & no_healthy));
fprintf(fid,'%d healthy participants failed one or zero tests \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & healthy));
fprintf(fid,'%d healthy participants failed zero tests \n', sum(mask_healthy & mask_age_thres & (mmse_ok==1) & superhealthy));

% Create new variable diagcog with the final diagnosis based on
% neuropsychological tests
diagcog = nan(n,1);             % Not enough data to assess
diagcog(no_healthy & mask_healthy) = 0;        % No healthy
diagcog(healthy & mask_healthy) = 1;           % Healhty
diagcog(superhealthy & mask_healthy) = 2;      % Superhealthy

%% Save data
data_out = megtusalen;

data_out.mmse_adj = mmse_adj;
data_out.mmse_extended = mmse_extended;
data_out.mmse_ok = mmse_ok;
data_out.DST_forward_adj = DST_forward_adj;
data_out.DST_backward_adj = DST_backward_adj;

data_out.LM_imm_result = LM_imm_result;
data_out.LM_del_result = LM_del_result;
data_out.DST_forward_result = DST_forward_result;
data_out.DST_backward_result = DST_backward_result;
data_out.TMT_A_result = tmta_result;
data_out.TMT_B_result = tmtb_result;
data_out.PTF_result = PTF_result;
data_out.SFT_result = SFT_result;

data_out.diagcog = diagcog;

% Save each sheet to excel file
writetable(data_out, out_file, 'FileType','spreadsheet');

fclose(fid);