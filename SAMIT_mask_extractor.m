%% --DESCRIPTION ----------------------------------------------------------
% This script creates sub-masks of the samit mask. For example, the user
% may want to extract the hippocampus and create a mask from that. The user
% may also want to extract several areas, and create a mask covering those 
% areas. Refer to SAMIT.txt file or SAMIT_merged.txt for anatonmical region 
% indexes to be used when calling the function.
%
% Usage: specify the areas you would like to extract from the mask in a 
% vector e.g. 
% 
% Usage: SAMIT_mask_extractor(areastoextract, outfile)
%       areastoextract: a 1-by-n vector containg the areas to extract e.g.
%                       areastoextract = [1 2 3] or 
%                       areastoextract = [1:10 12:15]
%       outfile: a string specifying the path for the new mask e.g
%                       '/Users/nicolas/Desktop/hippocampus_mask.nii'
%
% e.g. SAMIT_mask_extractor([1:10 12:15], '/Users/nicolas/Desktop/hippocampus_mask.nii')
% -------------------------------------------------------------------------
%%
function SAMIT_mask_extractor(areastoextract, outfile)
    % Specify paths
    samit_mask = '/Users/nicolas/Desktop/workdir/SAMIT-Merged.nii';
    
    % Import samit mask
    samit_V = spm_vol(samit_mask);       %imports nifti into structure
    samit_Vm = spm_read_vols(samit_V);   %converts structure into array
    
    % Extract index of all voxels in samit_mask which satisfy areastoextract
    areastoextract_indices = [];
    for i = 1:size(areastoextract,2)
        areastoextract_indices = [areastoextract_indices; find(samit_Vm == areastoextract(i))];
    end
    
    % Create a new mask array/volume which takes values 0 everywhere, 
    % and values 1 in voxels which satisfy areastoextract
    newmask_Vm = zeros(96,120,96);
    newmask_Vm(areastoextract_indices) = 1;
    
    % Export new mask to outfile, with origin at Bregma ([48 35 71])
    voxelsize = [0.2 0.2 0.2];
    origin = [48 35 71];
    datatype = 16;
    nii = make_nii(newmask_Vm, voxelsize, origin, datatype); %creates volume
    
    nii.hdr.dime.datatype = datatype; %sets datatype for save_nii function
    nii.hdr.dime.bitpix = datatype; %sets datatype for save_nii function
    save_nii(nii, outfile); %saves image
end