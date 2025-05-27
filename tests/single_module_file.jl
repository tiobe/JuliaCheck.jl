module single_module_file

module SubModuleIsOK
end  # SubModuleIsOK

end     # module single_module_file

module SecondModuleNotOK
end  # SecondModuleNotOK

function out_of_module_is_wrong()
    return nothing
end

module ThirdInFile
end  # ThirdInFile
