# command line arguments
# ////////////////////////////////////////////////////////////
param (
    [Parameter(Mandatory = $true)]
    [string]$dir,

    [Parameter(Mandatory = $false)]
    [switch]$help
)

# classes used throughout the script
# /////////////////////////////////////////////////////////////

class meta_path{
    hidden [string]$m_private_full_path # must be full and absolute path
    hidden [bool]$m_private_is_full_path_valid = $false

    # if the programmer modifys the public member copies it doesnt matter
    # the private members are always refered to anyway, so dont use the public
    # members at all. They are just for the getters and setters return value.
    [string]$m_public_full_path 
    [bool]$m_public_is_full_path_valid = $false

    [string] get_full_path(){
        # this is powershell so im not concerned about extra copying
        # powershell is always going to be slow anyway 
        $this.m_public_full_path = $this.m_private_full_path
        return $this.m_public_full_path
    }

    [bool] get_is_full_path_valid(){
        $this.m_public_is_full_path_valid = $this.m_private_is_full_path_valid
        return $this.m_private_is_full_path_valid
    }

    # Default constructor
    meta_path([string]$path) { 
        # resolve the . operator
        # if the $path contains ./ in the first two characters we should
        # resolve it the actual path string
        [bool]$is_relative_path = $false
        for (
            $i = 0
            $i -lt $path.Length -or $i -lt 2
            $i++
        ){
            # simple character comparison
            [char]$character_to_check = $path[$i] 

            if($character_to_check -eq '.'){
                continue
            }
            elseif(($character_to_check -eq '/') -or ($character_to_check -eq '\')){
                $is_relative_path = $true
            }
        }

        [string]$resolved_path = $null
        if($is_relative_path -eq $true){
            $path_info_temp_obj = Get-Location;
            [string]$temp_current_location = $path_info_temp_obj.Path.ToString()

            # remove the dot and stitch the $path to the current location
            [string]$path_without_dot_operator = $path.Substring(0,1)
            $resolved_path = $temp_current_location + $path_without_dot_operator
        }
        else{
            $resolved_path = $path
        }

        $this.m_private_full_path = $resolved_path
        $this.m_private_is_full_path_valid = [meta_path]::is_path_valid($this.m_private_full_path)
    }

    static [bool] is_path_valid([string]$path_to_check) {
        # Check if the path is absolute
        if ([System.IO.Path]::IsPathRooted($path_to_check)) {
            # Check if the directory exists
            if (Test-Path -Path $path_to_check -PathType Container) {
                return $true
            } else {
                return $false
            }
        } else {
            return $false
        }
    }
}

class meta_file{
    [string]$m_name
    [Int64]$m_size_in_bytes = 0 # for future use, currently not used

}

class meta_directory{

}







# command line checks
# ///////////////////////////////////////////////////////////////////////////////////////

# Check if the help switch is provided
if ($help) {
    Write-Output "Example --top_level_project_directory `"C:\folder\project_folder`""
    exit
}

# Check if the path is not empty
if ([string]::IsNullOrWhiteSpace($source_directory) -or (is_directory_valid -path $source_directory)) {
    Write-Output "Please provide a valid directory path as a command-line argument."
    exit
}



# Core execution 
# //////////////////////////////////////////////////////////////////////////////////////

# Attempt to create the directory structure
try {
    

    Write-Output "Folder structure created successfully at: $source_directory"
}
catch {
    Write-Output "Failed to create folder structure: $_"
}
