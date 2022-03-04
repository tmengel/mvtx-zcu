"""Create the file lists used for synthesis and simulation.
Created lists:
- vhdl_sources.txt
- vlog_sources.txt
- vhdl_sources_sim.txt
- vlog_sources_sim.txt
"""

import sys
import json
import copy
from collections import OrderedDict
from pathlib import Path


def parse_filelist(filelist_path, filename, paths):
    file_path = filelist_path / filename
    if not file_path.exists():
        return []

    # add reference to own sources
    paths = copy.deepcopy(paths)
    paths['self'] = filelist_path.parent
    source_path = filelist_path.parent

    output = []
    with file_path.open() as fl_file:
        for line in fl_file :
            # strip whitespace at end of line
            line = line.rstrip()
            if line.startswith("#") or (not line):
                # Ignore commented or empty lines
                continue
            output_line = line
            for k, v in paths.items():
                output_line = output_line.replace('$' + k + '_rtl', str(v / 'source/rtl'))
                output_line = output_line.replace('$' + k + '_bench', str(v / 'source/bench'))
                output_line = output_line.replace('$' + k + '_ip',  str(v / 'source/ip'))

            if output_line.startswith('+incdir+'):
                lsplit = output_line.split(' ')
                assert(len(lsplit) == 2)
                output_line = lsplit[0] + ' ' + str(source_path / lsplit[1])
            else:
                output_line = str(source_path / output_line)
            output.append(output_line.strip())
    return output


def main():
    """Main execution: Look for source lists in all directories"""
    assert len(sys.argv) == 2  # Path of top level

    filelist = OrderedDict()
    filelist['vhdl_sources.txt'] = []
    filelist['vhdl_sources_sim.txt'] = []
    filelist['vlog_sources.txt'] = []
    filelist['vlog_sources_sim.txt'] = []
    filelist['ip_sources.txt'] = []
    filelist['sdc_sources.txt'] = []
    filelist['vlog_includes.txt'] = []

    path = Path(sys.argv[1])

    # Resolve modules first
    module_dependencies = path / 'modules/DEPENDENCIES'
    assert module_dependencies.exists()
    module_dependencies = json.load(module_dependencies.open(), object_pairs_hook=OrderedDict)
    module_dependencies_abs = {}

    for k in module_dependencies:
        module_dependencies_abs[k] = path / module_dependencies[k]
        # read file list of module
        module_sources = module_dependencies_abs[k] / 'filelist'
        for key, value in filelist.items():
            value.extend(parse_filelist(module_sources, key, module_dependencies_abs))

    # Main source list
    sources = path / 'filelist'
    for key, value in filelist.items():
        value.extend(parse_filelist(sources, key, module_dependencies_abs))


    # make vlog_includes unique
    vlog_include_unique = OrderedDict.fromkeys(filelist['vlog_includes.txt'])
    filelist['vlog_includes.txt'] = list(vlog_include_unique.keys())

    output_path = path # / 'sim/RUv0a_top/run'
    for filename, files in filelist.items():
        with (output_path / filename).open(mode='w') as ofile:
            for item in files:
                ofile.write("%s\n" % item.replace('\\','/')) # modelsim\questa fix for backwards slashes

if __name__ == "__main__":
    main()
