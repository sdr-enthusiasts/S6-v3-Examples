#!/bin/bash

# This script is used to migrate the S6-v3-Examples to the new directory structure

# The user should pass in one argument, which is the path to the directory structure to migrate.
# The script will then copy the files from the old directory structure to the new one.


# function to move the services.d directory
# should take in the name of the directory to move

cont_init_files=()

function move_services_d {
    service=$(basename $file)
    echo "Creating etc/s6-overlay/s6-rc.d/user/contents.d/$service" || exit 1
    touch $dir/etc/s6-overlay/s6-rc.d/user/contents.d/$service || exit 1
    echo "Creating etc/s6-overlay/s6-rc.d/$service" || exit 1
    mkdir -p $dir/etc/s6-overlay/s6-rc.d/$service || exit 1
    echo "Creating etc/s6-overlay/s6-rc.d/$service/type" || exit 1
    echo "longrun" > $dir/etc/s6-overlay/s6-rc.d/$service/type || exit 1
    echo "Creating etc/s6-overlay/s6-rc.d/$service/up" || exit 1
    echo "#!/bin/sh" > $dir/etc/s6-overlay/s6-rc.d/$service/up || exit 1
    echo "exec $dir/etc/s6-overlay/s6-rc.d/scripts/$service" >> $dir/etc/s6-overlay/s6-rc.d/$service/up || exit 1
    echo "Moving $file to etc/s6-overlay/s6-rc.d/scripts/$service" || exit 1
    # if there is a run file, move it to the scripts directory
    if [ -f $file/run ]
    then
        cp $file/run $dir/etc/s6-overlay/s6-rc.d/scripts/$service || exit 1
        sed -i 's/#!\/usr\/bin\/with-contenv bash/#!\/command\/with-contenv bash/g' $dir/etc/s6-overlay/s6-rc.d/scripts/$service || exit 1
        echo "Making $dir/etc/s6-overlay/s6-rc.d/scripts/$service executable" || exit 1
        chmod +x $dir/etc/s6-overlay/s6-rc.d/scripts/$service || exit 1
    else
        echo "No run file. Skipping"
    fi
    # replace #!/usr/bin/with-contenv bash with #!/command/with-contenv bash
    echo "Creating $dir/etc/s6-overlay/s6-rc.d/$service/dependencies.d" || exit 1
    mkdir -p $dir/etc/s6-overlay/s6-rc.d/$service/dependencies.d || exit 1
    # if we have any cont-init files, add them to the dependencies.d directory, else add base
    if [ ${#cont_init_files[@]} -eq 0 ]
    then
        echo "Creating $dir/etc/s6-overlay/s6-rc.d/$service/dependencies.d/base" || exit 1
        touch $dir/etc/s6-overlay/s6-rc.d/$service/dependencies.d/base || exit 1
    else
        for cont_init_file in ${cont_init_files[@]}
        do
            echo "Creating $dir/etc/s6-overlay/s6-rc.d/$service/dependencies.d/$cont_init_file" || exit 1
            touch $dir/etc/s6-overlay/s6-rc.d/$service/dependencies.d/$cont_init_file || exit 1
        done
    fi
}

# get the path to the directory structure to migrate
if [ $# -eq 0 ]
then
    echo "Please pass in the path to the directory structure to migrate."
    exit 1
fi

# save the dir to a variable and ensure it exists

dir=$1
if [ ! -d $dir ]
then
    echo "The directory $dir does not exist."
    exit 1
fi

# ensure the directory structure is correct. It should have etc/services.d

if [ ! -d $dir/etc/services.d ]
then
    echo "The directory $dir does not have etc/services.d"
    exit 1
fi

echo "Migrating $dir"

# create the new directory structure

mkdir -p $dir/etc/s6-overlay/s6-rc.d/user/contents.d || exit 1
mkdir -p $dir/etc/s6-overlay/s6-rc.d/scripts || exit 1

# check and see if there are etc/cont-init.d files. if so, move them to etc/s6-overlay/s6-rc/scripts
# for every file we find, create a file with the name of the service in etc/s6-overlay/user/contents.d
# and also create a directory in etc/s6-overlay/s6-rc.d/s6-rc.d with the name of the service, and also create
# a file called "type" in that directory with the contents "oneshot", and also a file called "up" that contains
# the name of the file in etc/s6-overlay/s6-rc/scripts

if [ -d $dir/etc/cont-init.d ]
then
    echo "Found etc/cont-init.d"
    for file in $dir/etc/cont-init.d/*
    do
        echo "Found $file" || exit 1
        service=$(basename $file) || exit 1
        echo "Creating etc/s6-overlay/s6-rc.d/user/contents.d/$service" || exit 1
        touch $dir/etc/s6-overlay/s6-rc.d/user/contents.d/$service || exit 1
        echo "Creating etc/s6-overlay/s6-rc.d/$service" || exit 1
        mkdir -p $dir/etc/s6-overlay/s6-rc.d/$service || exit 1
        echo "Creating etc/s6-overlay/s6-rc.d/$service/type" || exit 1
        echo "oneshot" > $dir/etc/s6-overlay/s6-rc.d/$service/type || exit 1
        echo "Creating etc/s6-overlay/s6-rc.d/$service/up" || exit 1
        echo "#!/bin/sh" > $dir/etc/s6-overlay/s6-rc.d/$service/up || exit 1
        echo "exec $dir/etc/s6-overlay/s6-rc.d/scripts/$service" >> $dir/etc/s6-overlay/s6-rc.d/$service/up || exit 1
        echo "Moving $file to etc/s6-overlay/s6-rc.d/scripts/$service" || exit 1
        cp $file $dir/etc/s6-overlay/s6-rc.d/scripts/$service || exit 1
        # replace #!/usr/bin/with-contenv bash with #!/command/with-contenv bash
        sed -i 's/#!\/usr\/bin\/with-contenv bash/#!\/command\/with-contenv bash/g' $dir/etc/s6-overlay/s6-rc.d/scripts/$service || exit 1
        echo "Making $dir/etc/s6-overlay/s6-rc.d/scripts/$service executable" || exit 1
        chmod +x $dir/etc/s6-overlay/s6-rc.d/scripts/$service || exit 1
        # save the file name to an array
        cont_init_files+=($service) || exit 1
    done
fi

# check and see if there are etc/services.d files. if so, move them to etc/s6-overlay/s6-rc.d/user/contents.d
# for every file we find, create a file with the name of the service in etc/s6-overlay/user/contents.d
# and also create a directory in etc/s6-overlay/s6-rc.d/s6-rc.d with the name of the service, and also create
# a file called "type" in that directory with the contents "longrun", and also a file called "up" that contains
# the name of the file in etc/s6-overlay/s6-rc/scripts
# we also need to create a dependencies.d directory in the service directory, and create a file called "base" in it

if [ -d $dir/etc/services.d ]
then
    echo "Found etc/services.d"
    for file in $dir/etc/services.d/*
    do
        echo "Found $file" || exit 1
        move_services_d $file || exit 1

        # if $file includes any directories, we need call move_services_d on them
        for subfile in $file/*
        do
            if [ -d $subfile ]
            then
                echo "Found a sub directory, $subfile" || exit 1
                move_services_d $subfile || exit 1
                # we need to add the name of the parent to the dependencies.d directory of the subfile
                service_parent=$(basename $file) || exit 1
                service=$(basename $subfile) || exit 1
                echo "Creating $dir/etc/s6-overlay/s6-rc.d/$service/dependencies.d/$service_parent" || exit 1
                touch $dir/etc/s6-overlay/s6-rc.d/$service/dependencies.d/$service_parent || exit 1
            fi
        done
    done
fi

# move all of the cont-init.d and services.d files to $dir/back

# remove $dir/back if it exists
if [ -d $dir/back ]
then
    echo "Removing $dir/back"
    rm -rf $dir/back || exit 1
fi

mkdir -p $dir/back || exit 1
mv -v $dir/etc/cont-init.d $dir/back || exit 1
mv -v $dir/etc/services.d $dir/back || exit 1

