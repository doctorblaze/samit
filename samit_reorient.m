function samit_reorient(atlas,fixType,files,d)
%   Reoerient and Fix images
%   FORMAT samit_reset(files,d)
%       atlas   - Small animal atlas (see 'samit_defaults')
%       fixType - Different reorientations
%                 'VINCI' : Fix for orientation used in VINCI
%                 'PMOD2SPM' | 'SPM2PMOD' : Fix for orientation in PMOD
%                 'center' : Origin in the center of the image (default)
%                 'bregma' : Origin in bregma (info from the atlas)
%       files   - Files to be corrected
%       d       - Display (default: true)

%   Version: 17.10 (23 Oct 2017)
%   Author:  David V�llez Garc�a
%   Email:   samit@umcg.nl

%   Tested with SPM12

%% Check input variables
% Display
if ~exist('d','var')
    d = true;
end
if d ~= false
    display(' ');
    display('SAMIT: Reorient files');
    display('------------------------');
end

% Obtain defaults values from samit_defaults
if ~exist('atlas','var')
    samit_def = samit_defaults; % Load default values
else
    samit_def = samit_defaults(atlas);
end

bregma = samit_def.bregma;
clear samit_def;

% Fix info
if ~exist('fixType','var')
    fixType = 'vinci';
end

% Select image
if ~exist('files','var')
    [files, sts] = spm_select(Inf,'image','Select images...','', pwd);
    if ~sts
        warning('Operation cancelled: No files were selected');
        return
    else
        files = cellstr(files);
        %files = deblank(files);
    end    
end


%% Reorient
for i = 1:numel(files)
    
% Extracted from spm_image('resetorient')
        V   = spm_vol(files{i});
        M   = V.private.mat0;
        Y   = spm_read_vols(V);
        vox = sqrt(sum(M(1:3,1:3).^2)); % Voxel size

switch fixType
    case 'center'
        if det(V.mat(1:3,1:3))<0
            vox(1) = -vox(1);
        end
        dfm = diag(ones(1,4));
    
    case 'bregma'
        dfm = bregma;
        
    case 'VINCI'
        % VINCI NIfTI Fix (last version tested 4.81):
        % Matrix is corrected (V.mat ~= V.private.mat0)
                    
        if isequal(diag(V.mat), diag(V.private.mat0))
            warning(['The image ', spm_file(V.fname, 'filename'), ' seems to be reoriented!']);
        else
            dfm = bregma;
        end
        
    case {'PMOD2SPM','SPM2PMOD'}
        if ~isequal(diag(M), diag(V.private.mat0))
            warning(['The image ', spm_file(V.fname, 'filename'), ' seems to be reoriented!']);
        else
            %  Basic info
            Orig = abs([(M(1,4)/M(1,1)) (M(2,4)/M(2,2)) (M(3,4)/M(3,3))]);
                     
            % df: difference between center and origin coordinates
            df = Orig - ((V.dim+1)./2);
            dfm = df;
            dfm(1) = df(1);
            if isequal(fixType, 'PMOD2SPM')
                dfm(2) = df(3);
                dfm(3) = -df(2);
                theta = pi/2;
            elseif isequal(fixType, 'SPM2PMOD')
                dfm(2) = -df(3);
                dfm(3) = df(2);
                theta = -pi/2;
            end
            
            dfm = spm_matrix(dfm .* vox);
            
            % Rotate matrix: PMOD to SPM space (pitch rotation)
            X = [cos(theta) 0       -sin(theta)        0;
                0           1                0         0;
                sin(theta)  0       cos(theta)         0;
                0           0                0         1];

            tform = affine3d(X);
            RY = imref3d(size(Y),vox(1),vox(2),vox(3)); % Limits for otation
            Y = imwarp(Y,RY,tform);

            % Correct location of origin coordinates
            V.dim = size(Y);
        end      
                
end

% Common operations
cntr = spm_matrix(vox/2) \ spm_matrix([-(V.dim .* vox /2) 0 0 0 vox]);
M = dfm \ cntr;    


%% Write new file
V.mat = M;
V.private.mat = M;
V.private.mat0 = M;
V.fname = spm_file(V.fname,'prefix','r');
spm_write_vol(V,Y);        

if d ~= false
    display(['Image corrected: ', spm_file(files{i},'filename')]);
end
    
end


end