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

default: all

TOP ?= $(shell ../../build/abspath.sh ../..)
MODULE = libs/kns

INT_LIBS = \
	libkns

ALL_LIBS = \
	$(INT_LIBS)

TEST_TOOLS = \

include $(TOP)/build/Makefile.env

RWORKDIR = $(TOP)/$(MODULE)

#-------------------------------------------------------------------------------
# outer targets
#

# we are building it on all platforms now, because dependency on libcurl is removed
all std: makedirs
	@ $(MAKE_CMD) $(TARGDIR)/std

$(INT_LIBS): makedirs
	@ $(MAKE_CMD) $(ILIBDIR)/$@

$(TEST_TOOLS): makedirs
	@ $(MAKE_CMD) $(TEST_BINDIR)/$@

.PHONY: all std $(ALL_LIBS)

#-------------------------------------------------------------------------------
# std
#
$(TARGDIR)/std: \
	$(addprefix $(ILIBDIR)/,$(INT_LIBS))

.PHONY: $(TARGDIR)/std

#-------------------------------------------------------------------------------
# clean
#
clean: stdclean

.PHONY: clean

#-------------------------------------------------------------------------------
# kns
#
$(ILIBDIR)/libkns: $(addprefix $(ILIBDIR)/libkns.,$(ILIBEXT))

KNS_NO_HTTP_SRC = \
	kns_manager-ext \
	manager \
	stream \
	stream-from-files \
	stream-from-streams \
	endpoint \
	sysendpoint \
	syssock \
	sysstream \
    sysmgr

ifneq (win,$(OS))
KNS_NO_HTTP_SRC += \
	syspoll
endif

KNS_SRC = \
	$(KNS_NO_HTTP_SRC) \
	http \
	undyinghttp

KNS_OBJ = \
	$(addsuffix .$(LOBX),$(KNS_SRC))

KNS_LIB = \
    -lkfs \
	-dklib

$(ILIBDIR)/libkns.$(LIBX): $(KNS_OBJ)
	$(LD) --slib -o $@ $^ $(KNS_LIB)


#-------------------------------------------------------------------------------
# white-box test
#

TEST_SRC = \
	http-test

TEST_OBJ = \
	$(addsuffix .$(OBJX),$(TEST_SRC))

TEST_LIB = \
	-skapp \
    -skns \
	-svfs \
	-skrypto \
	-skfg \
	-skfs \
	-skproc \
	-sklib 

$(TEST_BINDIR)/test-http: $(TEST_OBJ)
	$(LD) --exe -o $@ $^ $(TEST_LIB)
