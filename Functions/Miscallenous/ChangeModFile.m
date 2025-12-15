function ChangeModFile(sScenario,sSubsecstart,sSubsecend,sRegions,...
    sSimulation, sExoNX, sCapandTrade, sClimRegional, sClimNational, sTargetBase)
    % function ChangeModFile(sScenario,sSubsecstart,sSubsecend,sRegions) to change the macroprocessor
    % variable YEndogenous
    % Inputs: 
    %   - sScenario    [character]  name of current scenario simulated
    %   - sSubsecstart [character]  first subsectors belonging to one aggregate sector
    %   - sSubsecend   [character]  last  subsector belonging to one aggregate sector
    %   - sRegions     [character]  number of regions in the model
    %   - sExoNX       [character]  integer specifying whether net export to GDP is constant or not
    %   - sCapandTrade [character]  integer specifying whether cap and
    %                               trade or emission tax
    %   - sTargetBase  [character]  integer specifiying whether growth of Y
    %                               (sTargetBase=1) or Q (sTargetBase=0) 
    %                               should be targeted. Another option 
    %                               targets Y withconstaant P (sTargetBase=2).
	


    temp = fileread('DGE_CRED_Model.mod');
    temp = strsplit(temp, '\n');
    iposline = find(cellfun(@(x) contains(x,"@# define YEndogenous"), temp));
    if length(iposline) == 1 && iposline > 0 
        if isequal(sScenario, 'Baseline')
            temp{iposline} = '@# define YEndogenous = 0';
        else
            temp{iposline} = '@# define YEndogenous = 1';
        end
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define YEndogenous' )
    end

    iposline = find(cellfun(@(x) contains(x,"@# define YTarget"), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['@# define YTarget = ' sTargetBase];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define YEndogenous' )
    end


    iposline = find(cellfun(@(x) contains(x,"@# define Subsecstart"), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['@# define Subsecstart = ' sSubsecstart];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define Subsecstart')
    end
    
    iposline = find(cellfun(@(x) contains(x,"@# define Subsecend"), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['@# define Subsecend = ' sSubsecend];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define Subsecend')
    end    

    iposline = find(cellfun(@(x) contains(x,"@# define Regions"), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['@# define Regions = ' sRegions];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define Regions')
    end    

    iposline = find(cellfun(@(x) contains(x,"@# define ExoNX"), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['@# define ExoNX = ' sExoNX];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define Regions')
    end   
    
    iposline = find(cellfun(@(x) contains(x,"options_.iStepSimulation"), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['options_.iStepSimulation = ' sSimulation ';'];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for options_.iStepSimulation')
    end 

    iposline = find(cellfun(@(x) contains(x,"@# define CapandTrade ="), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['@# define CapandTrade = ' sCapandTrade];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define CapandTrade')
    end 

    iposline = find(cellfun(@(x) contains(x,'@# define ClimateVarsRegional ='), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['@# define ClimateVarsRegional = ' sClimRegional];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define CapandTrade')
    end 

    iposline = find(cellfun(@(x) contains(x,'@# define ClimateVarsNational ='), temp));
    if length(iposline) == 1 && iposline > 0 
        temp{iposline} = ['@# define ClimateVarsNational = ' sClimNational];
        [fid] = fopen('DGE_CRED_Model.mod', 'w');
        fwrite(fid, strjoin(temp, '\n'));
        fclose(fid);    
    else
        error('No unique match for @# define CapandTrade')
    end 
end