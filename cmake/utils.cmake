# Get all build targets starting from specified directory
#
# Parameters:
# - _result, output
# - _dir, directory from which to start collecting build targets
function(get_all_targets _result _dir)
  get_property(_subdirs DIRECTORY "${_dir}" PROPERTY SUBDIRECTORIES) # retrieve subdirs of dir
  
  foreach(_subdir IN LISTS _subdirs)
    get_all_targets(${_result} "${_subdir}")
  endforeach()

  get_directory_property(_sub_targets DIRECTORY "${_dir}" BUILDSYSTEM_TARGETS) # get all targets built by _dir
  set(${_result} ${${_result}} ${_sub_targets} PARENT_SCOPE) # add to result (PARENT_SCOPE = to set result for the call side)
endfunction()