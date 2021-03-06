#!/bin/bash
# ===========================================================================
#
#                            PUBLIC DOMAIN NOTICE
#               National Center for Biotechnology Information
#
#  This software/database is a "United States Government Work" under the
#  terms of the United States Copyright Act.  It was written as part of
#  the author's official duties as a United States Government employee and
#  thus cannot be copyrighted.  This software/database is freely available
#  to the public for use. The National Library of Medicine and the U.S.
#  Government have not placed any restriction on its use or reproduction.
#
#  Although all reasonable efforts have been taken to ensure the accuracy
#  and reliability of the software and data, the NLM and the U.S.
#  Government do not and cannot warrant the performance or results that
#  may be obtained by using this software or data. The NLM and the U.S.
#  Government disclaim all warranties, express or implied, including
#  warranties of performance, merchantability or fitness for any particular
#  purpose.
#
#  Please cite the author in any work or product based on this material.
#
# ===========================================================================


# ===========================================================================
# input library types, and their handling
#
#  normal linkage
#   -l : find shared or static
#   -s : require static
#   -d : require shared
#
#  static linkage
#   -l : require static
#   -s : require static
#   -d : ignore
# ===========================================================================

# script name
SELF_NAME="$(basename $0)"

# parameters and common functions
source "${0%dlib.sh}cmn.sh"

# discover tool chain
case "$LD" in
g*)
    source "${0%dlib.sh}gcc.sh"
    ;;
i*)
    source "${0%dlib.sh}icc.sh"
    ;;
 *)
    echo "$SELF_NAME: unrecognized ld tool - '$LD'"
    exit 5
esac

# DLIB_CMD was started in tool-specific source
CMD="$DLIB_CMD $LDFLAGS"

# tack on object files
CMD="$CMD $OBJS"

# function to convert an archive into individual object files
convert-static ()
{
    # list members
    local path="$1"
    local mbrs="$(ar -t $path | grep -v '__.SYMDEF SORTED')"

    # unpack archive into temporary directory
    mkdir -p ld-tmp
    if ! cd ld-tmp
    then
        echo "$SELF_NAME: failed to cd to ld-tmp"
        exit 5
    fi
    ar -x "$path"

    # rename and add to source files list
    local m=
    for m in $mbrs
    do
        mv $m $LIBNAME-$m
        CMD="$CMD ld-tmp/$LIBNAME-$m"
    done

    # return to prior location
    cd - > /dev/null
}

# initial dependency upon Makefile and vers file
DEPS="$SRCDIR/Makefile"
if [ "$LIBS" != "" ]
then
    # tack on paths
    DIRS="$LDIRS:$XDIRS"
    while [ "$DIRS" != "" ]
    do
        DIR="${DIRS%%:*}"
        [ "$DIR" != "" ] && CMD="$CMD -L$DIR"
        DIRS="${DIRS#$DIR}"
        DIRS="${DIRS#:}"
    done

    # tack on libraries, finding as we go
    for LIB in $LIBS
    do

        # strip off switch
        LIBNAME="${LIB#-[lsd]}"

        # look at linkage
        case "$LIB" in
        -ldl|-ddl)

            # always load libdl as shared library
            load-ref-symbols
            load-dynamic
            CMD="$CMD -ldl"
            ;;

        -l*)

            # normal or dynamic linkage
            FOUND=0
            if [ $STATIC -eq 0 ]
            then
                find-lib $LIBNAME.dylib $LDIRS
                if [ "$LIBPATH" != "" ]
                then

                    # found it
                    FOUND=1

                    # load normally
                    load-ref-symbols
                    load-dynamic
                    CMD="$CMD -l$LIBNAME"

                fi
            fi

            # try static only
            if [ $FOUND -eq 0 ]
            then
                find-lib $LIBNAME-static.a $LDIRS
                if [ "$LIBPATH" != "" ]
                then

                    # found it
                    FOUND=1

                    # add it to dependencies
                    DEPS="$DEPS $LIBPATH"

                    # load static
#                    load-static
#                    load-all-symbols
#                    CMD="$CMD -l$LIBNAME-static"
                    convert-static "$LIBPATH" || exit $?

                fi
            fi

            if [ $FOUND -eq 0 ]
            then
                find-lib $LIBNAME.a $LDIRS
                if [ "$LIBPATH" != "" ]
                then

                    # found it
                    FOUND=1

                    # add it to dependencies
                    DEPS="$DEPS $LIBPATH"

                    # load static
#                    load-static
#                    load-all-symbols
#                    CMD="$CMD -l$LIBNAME"
                    convert-static "$LIBPATH" || exit $?

                fi
            fi

            # not found within our directories
            if [ $FOUND -eq 0 ]
            then

                if [ $STATICSYSLIBS -eq 1 ]
                then
                    case "$LIBNAME" in
                    z|bz2)
                        # set load to static
                        load-static
                        load-all-symbols
                        ;;

                    *)
                        # set load to dynamic
                        load-ref-symbols
                        load-dynamic
                        ;;

                    esac
                else
                    # set load to normal
                    load-ref-symbols
                    load-dynamic
                fi

                CMD="$CMD -l$LIBNAME"
            fi
            ;;

        -s*)

            # force static load
            FOUND=0
            find-lib $LIBNAME-static.a $LDIRS
            if [ "$LIBPATH" != "" ]
            then

                # found it
                FOUND=1

                # add it to dependencies
                DEPS="$DEPS $LIBPATH"

                # load static
#                load-static
#                load-all-symbols
#                CMD="$CMD -l$LIBNAME-static"
                convert-static "$LIBPATH" || exit $?

            fi

            if [ $FOUND -eq 0 ]
            then
                find-lib $LIBNAME.a $LDIRS
                if [ "$LIBPATH" != "" ]
                then

                    # found it
                    FOUND=1

                    # add it to dependencies
                    DEPS="$DEPS $LIBPATH"

                    # load static
#                    load-static
#                    load-all-symbols
#                    CMD="$CMD -l$LIBNAME"
                    convert-static "$LIBPATH" || exit $?

                fi
            fi

            # not found within our directories
            if [ $FOUND -eq 0 ]
            then

                if [ $STATIC -eq 1 ] || [ $STATICSYSLIBS -eq 1 ]
                then
                    # set load to static
                    load-static
                    load-all-symbols
                else

                    case "$LIBNAME" in
                    z|bz2)
                        # set load to dynamic
                        load-ref-symbols
                        load-dynamic
                        ;;

                    *)
                        # set load to static
                        load-static
                        load-all-symbols
                        ;;
                    esac
                fi

                CMD="$CMD -l$LIBNAME"
            fi
            ;;

        -d*)

            # only dynamic linkage
            FOUND=0
            if [ $STATIC -eq 0 ]
            then
                find-lib $LIBNAME.dylib $LDIRS
                if [ "$LIBPATH" != "" ]
                then

                    # found it
                    FOUND=1

                    # load normally
                    load-ref-symbols
                    load-dynamic
                    CMD="$CMD -l$LIBNAME"

                fi
            fi

            # not found within our directories
            if [ $FOUND -eq 0 ]
            then
                # set load to normal
                load-ref-symbols
                load-dynamic
                CMD="$CMD -l$LIBNAME"
            fi
            ;;

        esac

    done
fi

# put state back to normal
load-ref-symbols
load-dynamic

# add in pthreads
if [ $THREADS -ne 0 ]
then
    CMD="$CMD -lpthread"
fi

# add in xml
if [ $HAVE_XML -ne 0 ]
then
    CMD="$CMD -lxml2"
fi

# add in math library
if [ $HAVE_M -ne 0 ]
then
    CMD="$CMD -lm"
fi

# produce shared library
echo "$CMD"
$CMD || exit $?

# remove temporaries
rm -rf ld-tmp

# produce dependencies
if [ "$DEPFILE" != "" ]
then
    echo "$TARG: $DEPS" > "$DEPFILE"
fi
