# command line arguments
# ////////////////////////////////////////////////////////////
param (
    [Parameter(Mandatory = $true)]
    [string]$dir, # -dir

    [Parameter(Mandatory = $false)]
    [switch]$help, # -help

    [Parameter(Mandatory = $false)]
    [switch]$create # -create
)

# GLOBAL SCRIPT VARIABLE
[string]$GLOBAL_cmd_arg_directory_path_string = $dir


# classes used throughout the script
# /////////////////////////////////////////////////////////////


# NOTE: meta_path needs more methods for handling components of a path
# get_parent_path() ect...
class meta_path{
    hidden [string]$m_private_full_path = $null # stored as a full and absolute path
    hidden [bool]$m_private_is_full_path_valid = $false
    hidden [bool]$m_private_null_init_constructor_was_used = $false

    # if the programmer modifys the public member copies it doesnt matter
    # the private members are always refered to anyway, so dont use the public
    # members at all. They are just for the getters and setters return value.
    [string]$m_public_full_path = $null
    [bool]$m_public_is_full_path_valid = $false
    [bool]$m_public_null_init_constructor_was_used = $false

    [string] get_full_path(){
        # this is powershell so im not concerned about extra copying
        # powershell is always going to be slow anyway 
        $this.m_public_full_path = $this.m_private_full_path
        return $this.m_public_full_path
    }

    [bool] get_is_full_path_valid(){
        $this.m_public_is_full_path_valid = $this.m_private_is_full_path_valid
        return $this.m_public_is_full_path_valid
    }

    [bool] get_was_null_init_constructor_used(){
        $this.m_public_null_init_constructor_was_used = $this.m_private_null_init_constructor_was_used
        return $this.m_public_null_init_constructor_was_used
    }

    # null init constructor
    # all members are initialized in class
    # but for the sake of being explicit lets initialize all members to null here as well
    # and set flags for null init constructor being used
    meta_path(){
        $this.m_private_full_path = $null
        $this.m_private_is_full_path_valid = $null # in powershell setting a bool type to $null behaves as false
        $this.m_public_full_path = $null
        $this.m_public_is_full_path_valid = $null
        $this.m_private_null_init_constructor_was_used = $true
        $this.m_public_null_init_constructor_was_used = $true
    }

    # Default constructor
    meta_path([string]$path) { 
        # if the $path string is empty or null we will default to the . operator being given
        if(($null -eq $path) -or ($path.Length -eq 0)){
            $path = "."
        }

        # get the first character
        [char]$dot_op_character = $path[0]
        
        # check for the .
        # resolve the . operator
        # if the $path contains . as the first character
        # resolve it the actual path string
        [string]$resolved_path = $null
        [string]$current_location = $null
        if($dot_op_character -eq "."){
            $current_location = Get-Location
            [string]$path_minus_dot = $path.Substring(1,$path.Length-1)
            $resolved_path = $current_location + $path_minus_dot
        }
        else{
            $resolved_path = $path
        }

        $this.m_private_full_path = $resolved_path
        $this.m_private_is_full_path_valid = [meta_path]::is_path_valid($resolved_path)
    }

    [string] get_parent_path(){
        [string]$parent_path = $null
        if($this.get_was_null_init_constructor_used() -eq $true){
            [string]$temp_no_parent = $this.get_full_path()
            Write-Output "No parent path exists on $temp_no_parent"
            return $parent_path # returning $null
        }
        else{
            # from the end
        }
    }

    [bool] has_parent_path(){
        if($this.get_was_null_init_constructor_used() -eq $true){
            return $false
        }
        
        [string]$temp_full_path = $this.get_full_path()
        [bool]$just_a_root_path = $false
        

        # loop from end of full path and look for directory seperators
        for([int]$i = $temp_full_path.Length-1; $i -gt 0; --$i){
            if($temp_full_path[$i] -eq ":"){
                $just_a_root_path = $true
                break
            }


        }

    }

    static [bool] is_path_valid([string]$path_to_check) {
        Write-Output "Checking path: $path_to_check"
        return Test-Path $path_to_check.ToString()
    }
}

class meta_file{
    [string]$m_name = $null # should include extension 
    [Int64]$m_size_in_bytes = 0 # for future use, currently not used
    [meta_path]$m_file_path = [meta_path]::new() # calls null init constructor
    [bool]$m_was_file_created = $null
    [string]$m_item_type = "file"

    # default constructor
    meta_file([string]$name, [string]$path){
        # call default constructor
        $this.m_file_path = [meta_path]::new($path)
        
        # NOTE: depending on the OS some names will be rejected
        $this.m_name = $name
    }

    [bool] attempt_to_create_file_on_system(){
        try{
            New-Item 
            -Name $this.m_name.ToString() 
            -Path $this.m_file_path.get_full_path().ToString()
            -ItemType $this.m_item_type.ToString() 

            $this.m_was_file_created = [meta_file]::does_file_exist_on_system($this.m_file_path)
            return $this.m_was_file_created
        }
        catch{
            $this.m_was_file_created = $false
            return $this.m_was_file_created
        }
    }

    static [bool] does_file_exist_on_system([meta_path]$file_path){
        return Test-Path $file_path.get_full_path().ToString()
    }
}

class meta_directory{
    [string]$m_name = $null
    [Int64]$m_size_in_bytes = 0 # for future use, currently not used
    [meta_path]$m_directory_path = [meta_path]::new() # calls null init constructor
    [bool]$m_was_directory_created = $null
    [string]$m_item_type = "directory"

    # default constructor
    meta_directory([string]$name, [string]$path){
        # call default constructor
        $this.m_directory_path = [meta_path]::new($path)
        
        # NOTE: depending on the OS some names will be rejected
        $this.m_name = $name
    }

    # init meta_directory using a meta_path object
    meta_directory([meta_path]$path){
        $this.m_directory_path = [meta_path]::new($path)
    }

    [bool] attempt_to_create_directory_on_system(){
        try{ 
            New-Item 
            -Path $this.m_directory_path.get_full_path().ToString() 
            -Name $this.m_name.ToString() 
            -ItemType $this.m_item_type.ToString() 
            
            $this.m_was_directory_created = [meta_directory]::does_directory_exist_on_system($this.m_directory_path)
            return $this.m_was_directory_created
        }
        catch{
            $this.m_was_directory_created = $false
            return $this.m_was_directory_created
        }
    }

    static [bool] does_directory_exist_on_system([meta_path]$directory_path){
        return Test-Path $directory_path.get_full_path().ToString()
    }
}







# command line checks
# ///////////////////////////////////////////////////////////////////////////////////////

# make a meta_path object from the provided command line argument -dir
# see GLOBALS VARIABLES at top of script
[meta_path]$main_cpp_project_directory_path = [meta_path]::new($GLOBAL_cmd_arg_directory_path_string)


# Check if the help switch is provided
if ($help -eq $true) {
    Write-Output "./directory_structure -dir `"C:/folder/project_folder`""
    Write-Output "./directory_structure -dir `"./folder/project_folder`""
    Write-Output "./directory_structure -dir `"./folder/create_this_directory`" -create"
    exit
}

# Check if the create switch was provided
if($create -eq $true){
    
}

# Check if the path is valid
if ($main_cpp_project_directory_path.get_is_full_path_valid() -eq $false) {
    Write-Output "Please provide a valid directory path as a command-line argument."
    Write-Output $main_cpp_project_directory_path.get_full_path().ToString()
    exit
}



# Core execution 
# //////////////////////////////////////////////////////////////////////////////////////

# Setup the objects needed then attempt to create the actual files/folders

# setup the folders first
[meta_directory]$cmake_folder = [meta_directory]::new("cmake",$main_cpp_project_directory_path.get_full_path())
[meta_directory]$cpp_headers_folder = [meta_directory]::new("cpp_headers",$main_cpp_project_directory_path.get_full_path())
[meta_directory]$cpp_source_folder = [meta_directory]::new("cpp_source",$main_cpp_project_directory_path.get_full_path())
[meta_directory]$docs_folder = [meta_directory]::new("docs",$main_cpp_project_directory_path.get_full_path())

# attempt to create the folders on system
[bool]$fail_to_create = $false

$fail_to_create = $cmake_folder.attempt_to_create_directory_on_system()
$fail_to_create = $cpp_headers_folder.attempt_to_create_directory_on_system()
$fail_to_create = $cpp_source_folder.attempt_to_create_directory_on_system()
$fail_to_create = $docs_folder.attempt_to_create_directory_on_system()

# TODO: add better error handling in future!
if($fail_to_create -eq $true){
    exit
}

# setup the files next
[meta_file]$cmake_script_file = [meta_file]::new("CMakeLists.txt",$cmake_folder.m_directory_path) 

# attempt to create the files on system
$cmake_script_file.attempt_to_create_file_on_system()