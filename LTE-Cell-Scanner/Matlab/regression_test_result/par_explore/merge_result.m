% function merge_result
clear all; close all;

load CellSearch_test1to4_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat
cell_info_save = cell_info;

load CellSearch_test5to8_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat
cell_info_save(test_sp:test_ep) = cell_info(test_sp:test_ep);

load CellSearch_test9to12_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat
cell_info_save(test_sp:test_ep) = cell_info(test_sp:test_ep);

load CellSearch_test13to16_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat
cell_info_save(test_sp:test_ep) = cell_info(test_sp:test_ep);

load CellSearch_test17to20_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat
cell_info_save(test_sp:test_ep) = cell_info(test_sp:test_ep);

load CellSearch_test21to24_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat
cell_info_save(test_sp:test_ep) = cell_info(test_sp:test_ep);

load CellSearch_test25to28_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat
cell_info_save(test_sp:test_ep) = cell_info(test_sp:test_ep);

load CellSearch_test29to33_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat
cell_info_save(test_sp:test_ep) = cell_info(test_sp:test_ep);

cell_info = cell_info_save;

test_sp = 1;
test_ep = 33;

clear cell_info_save;

save CellSearch_test1to33_twist0_fo-140to140_resv2_numPtry1_Prange-1_parTh8_numPth0.5.mat

