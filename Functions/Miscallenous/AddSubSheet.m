function strSubSheet  = AddSubSheet(casVariables, casCellNames, casSubSectors, casSectors, casRegions, lSectoral, lRegional, lSectorOrigin, lRegionOrigin, inbsectors_p, inbsubsectors_p, inbregions_p)
    % function strSubSheet  = AddSubSheet(casVariables, casCellNames, casSubSectors, casRegions, lSectoral, lRegional, inbsubsectors_p, inbregions_p)
    % to define ranges for the data sheet in the ModelSimulationandCalibration<Number of Secotrs>Sectorsand<Numberof Regions>Regions.xlsx.
    % Inputs: 
    %   - casVariables		[cell array]  	string cell array with names of vartiables
    %   - casCellNames		[cell array]  	string cell array with names of excel cells
    %   - casSubSectors		[cell array]  	string cell array with names of subsectors
    %   - casSectors		[cell array]  	string cell array with names of sectors    
    %   - casRegions		[cell array]  	string cell array with names of regions
    %   - lSectors  		[logical array] logical array indicating whether a parameter is sector specific or not.
    %   - lRegional  		[logical array] logical array indicating whether a parameter is regional specific or not.	
    %   - lSectorOrigin     [logical array] logical array indicating whether a paramater depends
    %                                       on the sector of origin. e.g. input demand 
    %   - lRegionOrigin     [logical array] logical array indicating whether a paramater depends
    %                                       on the regional origin. e.g. sectoral output demand     
    %   - inbsubsectors_p   [integer]  		number of subsectors
    %   - inbregions_p      [integer]  		number of regions
    %
    % Output: 
    %   - strSubSheet	[structure]	  strucutre with all ranges and the cell names of the cells in the respective range
    
    if  lSectoral && lRegional && lSectorOrigin && ~lRegionOrigin
        caHeader = [{'Subsector'}, {'Region'}, {'Sector of Origin'}, cellfun(@(x,y) [x ' (' y ')'], casVariables, casCellNames, 'UniformOutput', false)];
        casData = repmat({'enter value here'}, inbregions_p * inbsubsectors_p * inbsectors_p, size(caHeader,2)-3);
        casCategories = [caHeader; ...
            [reshape(casSubSectors(sort(repmat(1:inbsubsectors_p,1, inbregions_p * inbsectors_p))),[],1)...
             reshape(casRegions(repmat(sort(repmat(1:inbregions_p, 1, inbsectors_p)),1, inbsubsectors_p)),[],1) ...
             reshape(casSectors(repmat(1:inbsectors_p,1, inbregions_p * inbsubsectors_p)),[],1) ...
            casData]];
        casDataCellNames = repmat({[]}, size(casCategories));
        temp = arrayfun(@(x,y,z) ['_' num2str(x) '_' num2str(y) '_' num2str(z) '_p'], sort(repmat(1:inbsubsectors_p, 1, inbregions_p*inbsectors_p)),...
            repmat(sort(repmat(1:inbregions_p, 1, inbsectors_p)),1, inbsubsectors_p),...
            repmat(1:inbsectors_p, 1, inbsubsectors_p*inbregions_p),...
            'UniformOutput', false);
        temp = cellfun(@(x) cellfun(@(y) [x y], temp, 'UniformOutput', false), casCellNames, 'UniformOutput', false);
        lUpdate = ismember(casCategories,'enter value here');
        casDataCellNames(lUpdate) = [temp{:}];
    elseif  lSectoral && lRegional && ~lSectorOrigin && lRegionOrigin
        caHeader = [{'Subsector'}, {'Region of Origin'}, {'Region of Destination'}, cellfun(@(x,y) [x ' (' y ')'], casVariables, casCellNames, 'UniformOutput', false)];
        casData = repmat({'enter value here'}, inbregions_p^2 * inbsubsectors_p, size(caHeader,2)-3);
        casCategories = [caHeader; ...
            [reshape(casSubSectors(sort(repmat(1:inbsubsectors_p, 1, inbregions_p * inbregions_p))),[],1)...
            reshape(casRegions(repmat(sort(repmat(1:inbregions_p, 1, inbregions_p)), 1, inbsubsectors_p)),[],1) ...
            reshape(casRegions(repmat(1:inbregions_p, 1, inbregions_p * inbsubsectors_p)),[],1) ...            
            casData]];
        casDataCellNames = repmat({[]}, size(casCategories));
        temp = arrayfun(@(x,y,z) ['_' num2str(x) '_' num2str(y) '_' num2str(z) '_p'], sort(repmat(1:inbsubsectors_p, 1, inbregions_p*inbregions_p)),...
            repmat(sort(repmat(1:inbregions_p, 1, inbregions_p)),1, inbsubsectors_p),...
            repmat(1:inbregions_p, 1, inbsubsectors_p*inbregions_p),...
            'UniformOutput', false);
        temp = cellfun(@(x) cellfun(@(y) [x y], temp, 'UniformOutput', false), casCellNames, 'UniformOutput', false);
        lUpdate = ismember(casCategories,'enter value here');
        casDataCellNames(lUpdate) = [temp{:}];
    elseif lSectoral && lRegional && ~lSectorOrigin && ~lRegionOrigin
        caHeader = [{'Sector'}, {'Region'}, cellfun(@(x,y) [x ' (' y ')'], casVariables, casCellNames, 'UniformOutput', false)];
        casData = repmat({'enter value here'}, inbregions_p * inbsubsectors_p, size(caHeader,2)-2);
        casCategories = [caHeader; ...
            [reshape(casSubSectors(sort(repmat(1:inbsubsectors_p,1, inbregions_p))),[],1)...
             reshape(casRegions(repmat(1:inbregions_p,1, inbsubsectors_p)),[],1) ...
            casData]];
        casDataCellNames = repmat({[]}, size(casCategories));
        temp = arrayfun(@(x,y) ['_' num2str(x) '_' num2str(y) '_p'],sort(repmat(1:inbsubsectors_p,1,inbregions_p)) , repmat(1:inbregions_p,1,inbsubsectors_p), 'UniformOutput', false);
        temp = cellfun(@(x) cellfun(@(y) [x y], temp, 'UniformOutput', false), casCellNames, 'UniformOutput', false);
        lUpdate = ismember(casCategories,'enter value here');
        casDataCellNames(lUpdate) = [temp{:}];
    elseif ~lSectoral && lRegional && ~lSectorOrigin && ~lRegionOrigin
        caHeader = [{'Region'}, cellfun(@(x,y) [x ' (' y ')'], casVariables, casCellNames, 'UniformOutput', false)];
        casData = repmat({'enter value here'}, inbregions_p, size(caHeader,2)-1);
        casCategories = [caHeader; ...
            [casRegions(1:inbregions_p)...
            casData]];
        casDataCellNames = repmat({[]}, size(casCategories));
        temp = arrayfun(@(x) ['_' num2str(x) '_p'],1:inbregions_p, 'UniformOutput', false);
        temp = cellfun(@(x) cellfun(@(y) [x y], temp, 'UniformOutput', false), casCellNames,'UniformOutput', false);
        lUpdate = ismember(casCategories,'enter value here');
        casDataCellNames(lUpdate) = [temp{:}];
    elseif lSectoral && ~lRegional && ~lSectorOrigin && ~lRegionOrigin
        caHeader = [{'Sector'}, cellfun(@(x,y) [x ' (' y ')'], casVariables, casCellNames, 'UniformOutput', false)];
        casData = repmat({'enter value here'}, inbsubsectors_p, size(caHeader,2)-1);
        casCategories = [caHeader; ...
            [casSubSectors(1:inbsubsectors_p)...
            casData]];
        casDataCellNames = repmat({[]}, size(casCategories));
        temp = arrayfun(@(x) ['_' num2str(x) '_p'],1:inbsubsectors_p, 'UniformOutput', false);
        temp = cellfun(@(x) cellfun(@(y) [x y], temp, 'UniformOutput', false), casCellNames,'UniformOutput', false);
        lUpdate = ismember(casCategories,'enter value here');
        casDataCellNames(lUpdate) = [temp{:}];                
    elseif ~lSectoral && ~lRegional && ~lSectorOrigin && ~lRegionOrigin
        casCategories = [{'Name', 'Value'}; ...
            [casVariables' repmat({'enter value here'}, size(casVariables', 1), 1)]];
        casDataCellNames = repmat({[]}, size(casCategories));
        lUpdate = ismember(casCategories,'enter value here');
        casDataCellNames(lUpdate) = casCellNames;   
    else
        casCategories ={''};
        casDataCellNames ={''};
        warning('Combination is not implemented.')
    end
    strSubSheet.Data  = casCategories;
    strSubSheet.CellNames = casDataCellNames;
end