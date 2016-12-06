#!/usr/bin/env bash

# for all currently running JVMs for the given class name, check the value of flags to check that it matches the specs given on the command line
# args: class-name {java-flag-value-spec}
# where java-flag-value-spec is one of:
# * <flag-name>=true : flag called <flag-name> must be set to true (e.g., HeapDumpOnOutOfMemoryError=true)
# * <flag-name>=false : flag called <flag-name> must be set to false (e.g., PrintGC=false)
# * <flag-name>=<flag-value> : flag called <flag-name> must match the given string value (e.g, HeapDumpPath=/var/log/storm)
# will exit with 0 only if we could verify that all flags met expectations

# tips from http://www.davidpashley.com/articles/writing-robust-shell-scripts/#id2382181
set -o nounset # exit if try to use undefined variable
set -o errexit # exit on first error

# parse command line args
class_name=$1
shift
flag_value_specs="$@"

echo "will check $class_name JVM processs for $flag_value_specs"

# executables we will use; if available in multiple locations, choses the location that sorts to last
jps=`find /usr/j* -name jps | sort | tail -1`
jinfo=`find /usr/j* -name jinfo | sort | tail -1`
# TODO: should verify that we found both of these

# find the JVM PIDs for this class
set +o errexit # don't exit on first error -- we'll handle grep not finding anything
jps_class_lines=`$jps | grep -w $class_name`
set -o errexit # resume exit on first error
if [ -z "$jps_class_lines" ]; then
    >&2 echo "no processes matching class name '$class_name' were found"
    exit 2
fi

jvm_pids=`echo "$jps_class_lines" | cut -d' ' -f 1`
echo "found these pids for $class_name: $jvm_pids"

# for all PIDs and for all specs, see if actual matches what we expected
no_match_count=0
for jvm_pid in $jvm_pids; do
    for spec in $flag_value_specs; do
        # first level parse the spec - get the flag name and other part
        equal_spec_regex='(\w+)=(.*)'
        equal_flag_spec=''
        if [[ $spec =~ $equal_spec_regex ]]; then
            flag_name=${BASH_REMATCH[1]}
            equal_flag_spec=${BASH_REMATCH[2]}
        fi
        if [ -z "$flag_name" ]; then
            >&2 echo "cound not find flag name in '$spec'"
             exit 2
        fi

        # look at spec to see what to expect
        if [ "$equal_flag_spec" == "true" ]; then
            expected_jinfo_output="-XX:+$flag_name"
        elif [ "$equal_flag_spec" == "false" ]; then
            expected_jinfo_output="-XX:-$flag_name"
        else
            expected_jinfo_output="-XX:$flag_name=$equal_flag_spec"
        fi

        # run jinfo for jvm and flag and see if matches expectation
        jinfo_output=`$jinfo -flag "$flag_name" $jvm_pid`
        if [ "$jinfo_output" != "$expected_jinfo_output" ]; then
            echo "for $class_name jvm with pid $jvm_pid, expected to find '$expected_jinfo_output', but found '$jinfo_output'"
            # increment count of no matches
            no_match_count=$((no_match_count + 1))
        fi
    done
done

# done checking, report result
if [ $no_match_count -gt 0 ]; then
    echo "$no_match_count non-matches were found"
    exit 3
else
    # all good
    echo "the flag values for running instances of $class_name were all as expected"
    exit 0
fi

