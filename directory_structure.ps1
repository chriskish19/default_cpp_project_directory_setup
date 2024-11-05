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
# needs more work!
class meta_path{
    [string]$m_full_path = $null
    [bool]$m_is_full_path_valid = $false
    [bool]$m_null_init_constructor_was_used = $false

    [string] get_full_path(){
        return $this.m_full_path
    }

    [bool] get_is_full_path_valid(){
        $this.m_is_full_path_valid = [meta_path]::is_path_valid($this.get_full_path())
        return $this.m_is_full_path_valid
    }

    [bool] get_was_null_init_constructor_used(){
        return $this.m_null_init_constructor_was_used
    }

    # null init constructor
    # all members are initialized in class
    # but for the sake of being explicit lets initialize all members to null here as well
    # and set flags for null init constructor being used
    meta_path(){
        $this.m_full_path = $null
        $this.m_is_full_path_valid = $null
        $this.m_null_init_constructor_was_used = $true
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

        $this.m_full_path = $resolved_path
        $this.m_is_full_path_valid = [meta_path]::is_path_valid($resolved_path)
    }


    [string] get_parent_path(){
        [string]$parent_path = $null
        if(($this.get_was_null_init_constructor_used() -eq $true) -or ($this.has_parent_path() -eq $false)){
            [string]$temp_no_parent = $this.get_full_path()
            Write-Output "No parent path exists on $temp_no_parent"
        }
        else{   # extract the parent path from the end of the path string
            # get the full path string to perform the extraction
            [string]$temp_full_path = $this.get_full_path()

            # setup the index and count to perform the substring
            [int]$index_from_end = $temp_full_path.Length -1 # we are guarrented to have a path with atleast one character
            
            # check whether the path has trailing slashes at the end
            # a loop to determine whether it has trailing slashes and if it does
            # set the index_from_end to begin after the slashes
            [bool]$has_an_ending_slash = $false
            [bool]$has_an_ending_double_slash = $false
            for([int]$i = $index_from_end;$i -gt 0;--$i){
                [char]$current_character = $temp_full_path[$i]
                
                if(($current_character -eq "/") -or ($current_character -eq "\")){
                    $has_an_ending_slash = $true

                    # use a loop to check if the next character is also a slash
                    for([int]$inner_i = $i;$inner_i -gt 0;--$inner_i){
                        [char]$next_character = $temp_full_path[$inner_i]

                        if(($next_character -eq "/") -or ($next_character -eq "\")){
                            $has_an_ending_double_slash = $true
                            break
                        }
                        else{
                            break
                        }
                    }
                }
                else{
                    # if the current character is not a slash exit the loop
                    break
                }
            }

            # use the bool flags to set the index_from_end to begin at the right location
            if($has_an_ending_slash -eq $true){
                --$index_from_end # ignore the slash
            }
            elseif($has_an_ending_double_slash -eq $true){
                $index_from_end = $index_from_end -2 # ignore the double slashes
            }



            # loop to determine if the path string is using double slashes (escape characters)
            [bool]$is_using_double_slashes = $false
            for([int]$i = $index_from_end;$i -gt 0;--$i){
                [char]$current_character = $temp_full_path[$i]
                
                if(($current_character -eq "/") -or ($current_character -eq "\")){
                    # use a for loop to look ahead and check whether the next character is a slash
                    # if it is set the bool flag (is_using_double_slashes) to true and break
                    # if it isnt a slash then break anyway
                    # use a loop to check if the next character is also a slash
                    for([int]$inner_i = $i;$inner_i -gt 0;--$inner_i){
                        [char]$next_character = $temp_full_path[$inner_i]

                        if(($next_character -eq "/") -or ($next_character -eq "\")){
                            $is_using_double_slashes = $true
                            break
                        }
                        else{
                            break
                        }
                    }
                }
            }

            if($is_using_double_slashes -eq $true){
                [int]$character_count = 0
                [int]$index_from_begining = 0
                [int]$starting_index_from_end = $index_from_end
                [int]$new_end_index = 0 # new index end of the path string

                # loop to count the character count and index in order to substring the parent path
                for([int]$i = $starting_index_from_end;$i -gt 0;--$i){
                    [char]$current_character = $temp_full_path[$i]

                    if(($current_character -eq "/") -or ($current_character -eq "\")){
                        # we can safely adavance ahead passed the next slash since
                        # we already know we are using double slashes in the path
                        [int]$delta_end_index = 0 # change in index from end of the path
                        $delta_end_index = $starting_index_from_end - $i
                        $new_end_index = $starting_index_from_end - $delta_end_index - 2 # minus 2 for double slashes 
                    }
                    else{
                        break
                    }
                }

                # finally we can substring the path
                [int]$parent_path_length = $new_end_index + 1
                $parent_path = $temp_full_path.SubString($index_from_begining,$parent_path_length)
            }
            else{
                [int]$character_count = 0
                [int]$index_from_begining = 0
                [int]$starting_index_from_end = $index_from_end
                [int]$new_end_index = 0 # new index end of the path string

                # loop to count the character count and index in order to substring the parent path
                for([int]$i = $starting_index_from_end;$i -gt 0;--$i){
                    [char]$current_character = $temp_full_path[$i]

                    if(($current_character -eq "/") -or ($current_character -eq "\")){
                        # we can safely adavance ahead passed the next slash since
                        # we already know we are using double slashes in the path
                        [int]$delta_end_index = 0 # change in index from end of the path
                        $delta_end_index = $starting_index_from_end - $i
                        $new_end_index = $starting_index_from_end - $delta_end_index - 1 # minus 1 for slash 
                    }
                    else{
                        break
                    }
                }

                # finally we can substring the path
                [int]$parent_path_length = $new_end_index + 1
                $parent_path = $temp_full_path.SubString($index_from_begining,$parent_path_length)
            }

        }

        # returns null when no parent path exists
        # returns the parent path string if it exists
        return $parent_path
    }

    [bool] has_parent_path(){
        if($this.get_was_null_init_constructor_used() -eq $true){
            return $false
        }
        

        [string]$temp_full_path = $this.get_full_path()
        
        # we need to know if we are dealing with double slashes
        [bool]$is_using_double_slashes = $false
        [int]$slash_count = 0

        # loop to determine if the path is using double slashes
        for([int]$i = 0;$i -lt $temp_full_path.Length;$i++){
            [char]$single_character = $temp_full_path[$i]

            if(($single_character -eq "\") -or ($single_character -eq "/")){
                $slash_count++
            }
            elseif($slash_count -gt 1){
                $is_using_double_slashes = $true
                break
            }
            else{
                break
            }
        }  
        

        # loop to get total slash count
        [int]$total_slash_count = 0
        for([int]$i = 0;$i -lt $temp_full_path.Length;$i++){
            [char]$single_character = $temp_full_path[$i]

            if(($single_character -eq "\") -or ($single_character -eq "/")){
                $total_slash_count++
            }
        }  

        [bool]$has_parent_path = $false
        # each slash needs a preceding character to be a valid child directory
        # so we just do some arithmetic to determine if there is a parent path
        if($is_using_double_slashes -eq $true){
            # if we are using \\ it typically means we are using windows paths
            # which means they begin with a drive letter and :
            [int]$path_length = $temp_full_path.Length - 2

            # minimum number of characters to have a possible parent path
            # //u//u has length 6
            [int]$min_path_characters = 6

            if($path_length -ge $min_path_characters){
                $has_parent_path = $true
            }
        }
        else{ # using single slashes here
            
            # we can do a simple check to see if we are dealing with a windows path
            [char]$first_character = $temp_full_path[0] # the string is always guaranteed to have atleast one character
            
            if($first_character -ne "/" -or $first_character -ne "\"){
                # is a windows path
                [int]$path_length = $temp_full_path.Length - 2 # remove drive letter and :

                # minimum number of characters to have a possible parent path
                # /u/u has length 4
                [int]$min_path_characters = 4

                if($path_length -ge $min_path_characters){
                    $has_parent_path = $true
                }
            }
            else{
                # is not a windows path
                [int]$path_length = $temp_full_path.Length

                # minimum number of characters to have a possible parent path
                # /u/u has length 4
                [int]$min_path_characters = 4

                if($path_length -ge $min_path_characters){
                    $has_parent_path = $true
                }
            }
        }

        return $has_parent_path
    }

    # returns a new meta_path object with a subdirectory added on
    # to the current object
    [meta_path] add_subdirectory([string]$path){
        # NOTE: this is incomplete and should handle cases where the $path string
        # has // or \ or / for lack of time and effort ill fix this later!
        [string]$new_path = $this.get_full_path() + '\' + $path
        return [meta_path]::new($new_path)
    }

    static [bool] is_path_valid([string]$path_to_check) {
        Write-Output "Checking path: $path_to_check"
        return Test-Path -Path $path_to_check.ToString()
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
            New-Item -Name $this.m_name.ToString() -Path $this.m_file_path.get_full_path().ToString() -ItemType $this.m_item_type.ToString()
            $this.m_was_file_created = [meta_file]::does_file_exist_on_system($this.m_file_path)
            return $this.m_was_file_created
        }
        catch{
            # Output the error message
            Write-Error "An error occurred: $_"

            $this.m_was_file_created = $false
            return $this.m_was_file_created
        }
    }

    static [bool] does_file_exist_on_system([meta_path]$file_path){
        return Test-Path -Path $file_path.get_full_path().ToString()
    }
}

# NOTE: this needs more work later! I just need something working for now...
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
        $this.m_directory_path = $path
    }

    # returns a meta_path that includes the current directory
    # useful for creating folders within a directory
    [meta_path] get_inside_this_directory_path(){
        return $this.m_directory_path.add_subdirectory($this.m_name)
    }

    [bool] attempt_to_create_directory_on_system(){
        try{ 
            New-Item -Path $this.m_directory_path.get_full_path().ToString() -Name $this.m_name.ToString() -ItemType $this.m_item_type.ToString()
            $this.m_was_directory_created = [meta_directory]::does_directory_exist_on_system($this.m_directory_path)
            return $this.m_was_directory_created
        }
        catch{
            # Output the error message
            Write-Error "An error occurred: $_"

            $this.m_was_directory_created = $false
            return $this.m_was_directory_created
        }
    }

    static [bool] does_directory_exist_on_system([meta_path]$directory_path){
        return Test-Path -Path $directory_path.get_full_path().ToString()
    }
}







# command line checks
# ///////////////////////////////////////////////////////////////////////////////////////

# make a meta_path object from the provided command line argument -dir
# see GLOBALS VARIABLES at top of script
[meta_path]$main_cpp_project_directory_path = [meta_path]::new($GLOBAL_cmd_arg_directory_path_string)


# Check if the help switch is provided
if ($help -eq $true) {
    Write-Output "./directory_structure.ps1 -dir `"C:/folder/project_folder`""
    Write-Output "./directory_structure.ps1 -dir `"./folder/project_folder`""
    Write-Output "./directory_structure.ps1 -dir `"./folder/create_this_directory`" -create"
    exit
}

# Check if the create switch was provided
# it will create the directory
if($create -eq $true){
    [meta_directory]$main_cpp_project_directory = [meta_directory]::new($main_cpp_project_directory_path)
    
    if($main_cpp_project_directory.attempt_to_create_directory_on_system() -eq $true){
        Write-Output "The main project directory given was sucessfully created!"
        Write-Output $main_cpp_project_directory.m_directory_path.get_full_path().ToString()
    }
    else{
        Write-Output "The main project directory given failed to be created..."
        Write-Output $main_cpp_project_directory.m_directory_path.get_full_path().ToString()
        exit
    }
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
######################################################################################

# setup top level folders
[meta_directory]$cmake_folder = [meta_directory]::new("cmake",$main_cpp_project_directory_path.get_full_path())
[meta_directory]$cpp_headers_folder = [meta_directory]::new("cpp_headers",$main_cpp_project_directory_path.get_full_path())
[meta_directory]$cpp_source_folder = [meta_directory]::new("cpp_source",$main_cpp_project_directory_path.get_full_path())
[meta_directory]$docs_folder = [meta_directory]::new("docs",$main_cpp_project_directory_path.get_full_path())

# setup subdirectory folders
[meta_directory]$build_folder = [meta_directory]::new("build",$cmake_folder.get_inside_this_directory_path().get_full_path())





# flag for errors
[bool]$create_success = $false

# Create Top level folders first
##########################################################################################
$create_success = $cmake_folder.attempt_to_create_directory_on_system()
# TODO: add better error handling in future!
if($create_success -eq $false){
    exit
}

$create_success = $cpp_headers_folder.attempt_to_create_directory_on_system()
# TODO: add better error handling in future!
if($create_success -eq $false){
    exit
}

$create_success = $cpp_source_folder.attempt_to_create_directory_on_system()
# TODO: add better error handling in future!
if($create_success -eq $false){
    exit
}

$create_success = $docs_folder.attempt_to_create_directory_on_system()
# TODO: add better error handling in future!
if($create_success -eq $false){
    exit
}


# lets do a github pull of cmake boiler plate from my github chriskish19
# and place it in the cmake folder
git clone "https://github.com/chriskish19/CMAKE_BOILERPLATE.git" $cmake_folder.get_inside_this_directory_path().get_full_path()


# Next create subfolders
##########################################################################
$create_success = $build_folder.attempt_to_create_directory_on_system()
if($create_success -eq $false){
    exit
}


